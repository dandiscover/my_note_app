// lib/pages/richtext_editor_page.dart
// 富文本编辑页 — flutter_quill 接入
//
// 职责：
//   1. 接收 NotebookEntry（contentFormat='richtext'）
//   2. 读 entry.content（自定义结构 JSON）
//   3. RichtextAdapter.structureToDelta → Delta + BlockMemo
//   4. Delta 喂 QuillController，memo 存 State
//   5. 保存：取 Delta → deltaToStructure(delta, memo) → 写 entry.content
//   6. DatabaseService.updateNote 落盘
//
// ✅ 标题可编辑且保存（老白裁 1）
// ✅ T-206：布局避开键盘 overflow（无固定高度子区 + SafeArea）
// ✅ divider 自定义嵌入：EmbedBuilder（B 部分实测确认）
// ✅ T-213：initState 解析失败不静默回退——显示错误页，禁保存
// ✅ 第四轮批 1：AppBar 加 ⭐/❓ 笔记级标记入口（依据 v5 方案 §6.2）
// ✅ R-16 第一段：修复插入图片无响应，改用 file_picker，并加入选区兜底
import '../models/card.dart';
import '../services/card_service.dart';
import '../services/spark_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/material_item.dart';
import '../services/command_palette_launcher.dart';
import '../widgets/writing/material_panel.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../services/epub_export/epub_exporter.dart';
import '../services/epub_export/epub_platform_saver.dart';
import '../services/richtext_adapter/richtext_adapter.dart';
import '../services/richtext_adapter/shared/attributes.dart';
import '../utils/debouncer.dart';
import '../widgets/spark_dialog.dart';
import '../services/image_path_service.dart';

class RichtextEditorPage extends StatefulWidget {
  final NotebookEntry entry;

  const RichtextEditorPage({super.key, required this.entry});

  @override
  State<RichtextEditorPage> createState() => _RichtextEditorPageState();
}

class _RichtextEditorPageState extends State<RichtextEditorPage> {
  late final TextEditingController _titleController;

  // T-213：解析失败时保持 null，build 走错误页。
  quill.QuillController? _quillController;
  List<BlockMemo>? _memo;
  String? _initError;

  bool _isSaving = false;
  final Debouncer _autoSaveDebouncer = Debouncer(const Duration(seconds: 3));
  bool _isDirty = false;
  bool _showMaterialPanel = false;
  List<MaterialItem> _materialItems = [];

  // ✅ 第四轮批 1 新增：笔记级标记（⭐ 重要 / ❓ 待解决）
  late List<String> _currentTags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _titleController.addListener(_onTitleChanged);
    _currentTags = List<String>.from(widget.entry.tags);
    _loadMaterialItems();

    try {
      final structure =
          jsonDecode(widget.entry.content) as Map<String, dynamic>;
      final result = RichtextAdapter.structureToDelta(structure);
      _memo = result.memo;

      _quillController = quill.QuillController(
        document: quill.Document.fromJson(result.delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _quillController!.addListener(_onQuillContentChanged);
    } catch (e) {
      _initError = e.toString();
    }
  }

  void _onTitleChanged() {
    setState(() {});
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_currentTags.contains(tag)) {
        _currentTags.remove(tag);
      } else {
        _currentTags.add(tag);
      }
    });
  }

  Future<void> _loadMaterialItems() async {
    final cards = await CardService().getAllCards();
    final maps = await DatabaseService().getAllNotes(includeDeleted: false);
    final notes = maps.map((m) => NotebookEntry.fromMap(m)).toList();
    final indexCards = cards
        .where((c) => c.cardType == CardType.indexCard)
        .toList();
    if (!mounted) return;
    setState(() {
      _materialItems = [
        ...indexCards.map((c) => MaterialItem.fromCard(c)),
        ...notes.map((n) => MaterialItem.fromNote(n)),
      ];
    });
  }

  void _insertCardAtCursor(CardModel card) {
    final quote = card.highlight ?? card.indexTitle ?? card.displayFront;
    final citation =
        '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}\n';
    _insertTextAtCursor(citation);
  }

  void _insertNoteAtCursor(NotebookEntry note) {
    // 富文本插笔记暂 no-op——归后批
  }

  void _insertTextAtCursor(String text) {
    if (_quillController == null) return;
    final sel = _quillController!.selection;
    _quillController!.replaceText(
      sel.start,
      sel.end - sel.start,
      text,
      TextSelection.collapsed(offset: sel.start + text.length),
    );
  }

  @override
  void dispose() {
    _autoSaveDebouncer.cancel();
    _quillController?.removeListener(_onQuillContentChanged);
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  void _onQuillContentChanged() {
    if (!mounted) return;
    if (_isDirty) return;
    setState(() => _isDirty = true);
    _autoSaveDebouncer.run(() {
      if (mounted && _isDirty && !_isSaving) {
        _save(isAuto: true);
      }
    });
  }

  Future<void> _insertImageToRichtext() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files == null || files.isEmpty || files.single.path == null) return;

      final originalPath = files.single.path!;
      final ext = p.extension(originalPath);
      final filename = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = ImagePathService.instance.targetPath(filename);
      
      final file = File(targetPath);
      await file.writeAsBytes(await File(originalPath).readAsBytes());

      final relPath = 'note_images/$filename';
      
      // 安全兜底：如果光标无效，插在文末；否则插在光标处
      final int index = _quillController!.selection.baseOffset == -1 
          ? _quillController!.document.length - 1 
          : _quillController!.selection.baseOffset;
          
      _quillController!.document.insert(index, quill.BlockEmbed.image(relPath));
      // 恢复焦点并后移
      _quillController!.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        quill.ChangeSource.local,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('插入图片失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save({bool isAuto = false}) async {
    final controller = _quillController;
    final memo = _memo;
    if (controller == null || memo == null) return;

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final delta = controller.document.toDelta().toJson();
      final newStructure = RichtextAdapter.deltaToStructure(
        delta.cast<Map<String, dynamic>>(),
        memo: memo,
      );

      final newTitle = _titleController.text.trim();
      final updated = widget.entry.copyWith(
        title: newTitle.isEmpty ? widget.entry.title : newTitle,
        content: jsonEncode(newStructure),
        updatedAt: DateTime.now(),
        tags: _currentTags,
      );
      await DatabaseService().updateNote(updated.toMap());

      if (!mounted) return;
      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 已保存'), duration: Duration(seconds: 1)),
        );
      }
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
      if (!isAuto) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      } else {
        debugPrint('自动保存失败: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportEpub() async {
    final controller = _quillController;
    final memo = _memo;
    if (controller == null || memo == null) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final delta = controller.document.toDelta().toJson();
      final newStructure = RichtextAdapter.deltaToStructure(
        delta.cast<Map<String, dynamic>>(),
        memo: memo,
      );

      final newTitle = _titleController.text.trim();
      final updated = widget.entry.copyWith(
        title: newTitle.isEmpty ? widget.entry.title : newTitle,
        content: jsonEncode(newStructure),
        updatedAt: DateTime.now(),
        tags: _currentTags,
      );

      await DatabaseService().updateNote(updated.toMap());
      final book = await EpubExporter.exportBook([updated]);
      await EpubPlatformSaver.save(book.bytes, book.suggestedFilename);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 已导出：${book.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancel() {
    Navigator.pop(context, false);
  }

  Future<void> _showExitDialog() async {
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('当前编辑内容未保存，是否保存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      await _save();
    } else if (choice == 'discard') {
      if (_isSaving) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('正在保存中，请稍候')));
        return;
      }
      setState(() => _isDirty = false);
      if (!mounted) return;
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return _buildErrorPage();
    }

    return PopScope(
      canPop: !_isDirty && !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '标题',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(
                _currentTags.contains('重要') ? Icons.star : Icons.star_border,
                color: _currentTags.contains('重要') ? Colors.amber : null,
              ),
              tooltip: '重要',
              onPressed: _isSaving ? null : () => _toggleTag('重要'),
            ),
            IconButton(
              icon: Icon(
                _currentTags.contains('待解决') ? Icons.help : Icons.help_outline,
                color: _currentTags.contains('待解决') ? Colors.orange : null,
              ),
              tooltip: '待解决',
              onPressed: _isSaving ? null : () => _toggleTag('待解决'),
            ),
            TextButton(
              onPressed: _isSaving ? null : _cancel,
              child: const Text('取消'),
            ),
            const SizedBox(width: 4),

            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.keyboard_command_key),
              tooltip: '命令面板',
              onPressed: () => CommandPaletteLauncher.open(),
            ),
            IconButton(
              icon: Icon(
                _showMaterialPanel
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
              ),
              tooltip: _showMaterialPanel ? '收起素材栏' : '展开素材栏',
              onPressed: () =>
                  setState(() => _showMaterialPanel = !_showMaterialPanel),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: '导出 EPUB',
              onPressed: _isSaving ? null : _exportEpub,
            ),
          ],
        ),
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController!,
                      config: quill.QuillSimpleToolbarConfig(
                        multiRowsDisplay: true, // 自动换行成多行，防溢出
                        showDividers: true,
                        showBoldButton: true,
                        // ... 保持你原有的其他配置不变 ...
                        customButtons: [
                          quill.QuillToolbarCustomButtonOptions(
                            icon: const Icon(Icons.image),
                            tooltip: '插入图片',
                            onPressed: _insertImageToRichtext,
                          ),
                          quill.QuillToolbarCustomButtonOptions(
                            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                            tooltip: '火花',
                            onPressed: () async {
                              final result = await showDialog<SparkDialogResult>(
                                context: context,
                                builder: (_) => const SparkDialog(),
                              );
                              if (result == null || result.content.isEmpty) return;
                              
                              final noteId = widget.entry.id;
                              final rawTitle = widget.entry.title.trim();
                              final safeTitle = rawTitle.isEmpty ? '无标题笔记' : rawTitle;
                              
                              if (result.action == 'send') {
                                // 1. 插入正文
                                _insertTextAtCursor(result.content);
                              } else if (result.action == 'save_card') {
                                // 2. 存入素材库 (生成索引卡)
                                final card = CardModel(
                                  id: 'spark_${DateTime.now().millisecondsSinceEpoch}',
                                  cardType: CardType.indexCard,
                                  sourceType: 'note',
                                  sourceId: noteId,
                                  sourceTitle: safeTitle,
                                  indexTitle: result.content.length > 50 ? '${result.content.substring(0, 50)}...' : result.content,
                                  highlight: result.content,
                                  anchor: _quillController!.selection.baseOffset.toString(),
                                );
                                await CardService().addCard(card);
                                _loadMaterialItems(); // 👈 加了这一行，刷新右侧列表
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('💫 已存入素材库'), duration: Duration(seconds: 1)),
                                  );
                                }
                              } else if (result.action == 'stash') {
                                // 3. 暂存火花
                                final spark = Spark(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  content: result.content,
                                  anchorNoteId: noteId,
                                  anchorLocation: _quillController!.selection.baseOffset.toString(),
                                  createdAt: DateTime.now(),
                                );
                                await SparkService().create(spark);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('💫 火花已暂存'), duration: Duration(seconds: 1)),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showInlineCode: true,
                        showColorButton: true,
                        showBackgroundColorButton: true,
                        showClearFormat: true,
                        showAlignmentButtons: true, // 居中/左对齐/右对齐
                        showHeaderStyle: true, // 标题层级 H1-H6
                        showListNumbers: true, // 有序列表
                        showListBullets: true, // 无序列表
                        showListCheck: true, // 待办列表
                        showCodeBlock: true, // 代码块
                        showQuote: true, // 引用
                        showIndent: true, // 缩进
                        showLink: true, // 超链接
                        showUndo: true,
                        showRedo: true,
                        showSearchButton: false, // 先关搜索，免得占位
                        showSubscript: false,
                        showSuperscript: false,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: DragTarget<MaterialItem>(
                        onAcceptWithDetails: (details) {
                          final item = details.data;
                          String text = '';
                          if (item.type == MaterialItemType.card && item.card != null) {
                            text = item.card!.highlight ?? item.card!.displayFront ?? '';
                          } else if (item.type == MaterialItemType.note && item.note != null) {
                            text = item.note!.content.isNotEmpty ? item.note!.content : item.note!.title;
                          }
                          
                          if (text.isNotEmpty) {
                            _insertTextAtCursor(text);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return quill.QuillEditor.basic(
                            controller: _quillController!,
                            config: quill.QuillEditorConfig(
                              placeholder: '开始写…',
                              embedBuilders: [_DividerEmbedBuilder(), _RichtextImageEmbedBuilder()],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_showMaterialPanel) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 280,
                  child: MaterialPanel(
                    items: _materialItems,
                    enabled: true,
                    onInsertCard: _insertCardAtCursor,
                    onInsertNote: _insertNoteAtCursor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
        actions: [
          TextButton(onPressed: _cancel, child: const Text('返回')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '内容损坏，无法编辑',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '为避免覆盖原数据，本页未提供保存入口。',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    _initError!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RichtextImageEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'image';

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final dynamic data = embedContext.node.value.data;
    if (data is! String || data.isEmpty) {
      return const Icon(Icons.broken_image, size: 48);
    }
    final uri = Uri.tryParse(data);
    if (uri == null) return const Icon(Icons.broken_image, size: 48);
    
    if (uri.hasScheme) {
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return Image.network(data, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
      }
      if (uri.scheme == 'file') {
        return Image.file(File(uri.toFilePath()), errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
      }
      if (uri.scheme == 'data') {
        try {
          final bytes = uri.data?.contentAsBytes();
          if (bytes == null || bytes.isEmpty) return const Icon(Icons.broken_image, size: 48);
          return Image.memory(bytes, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
        } catch (_) {
          return const Icon(Icons.broken_image, size: 48);
        }
      }
    }
    
    final fullPath = ImagePathService.instance.resolve(data);
    return Image.file(File(fullPath), errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48));
  }
}

class _DividerEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => DeltaAttributes.divider;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return const Divider(thickness: 1);
  }
}