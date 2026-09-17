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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../database_service.dart';
import '../models/note.dart';
import '../services/epub_export/epub_exporter.dart';
import '../services/epub_export/epub_platform_saver.dart';
import '../services/richtext_adapter/richtext_adapter.dart';
import '../services/richtext_adapter/shared/attributes.dart';

class RichtextEditorPage extends StatefulWidget {
  final NotebookEntry entry;

  const RichtextEditorPage({
    super.key,
    required this.entry,
  });

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

  // ✅ 第四轮批 1 新增：笔记级标记（⭐ 重要 / ❓ 待解决）
  // 依据老白裁定 + v5 方案 §6.2：批 1 只做笔记级标记，blockId=null。
  // 保存时写回 entry.tags，经 DatabaseService._syncSearchIndexForNote 进 tag_index。
  late List<String> _currentTags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _titleController.addListener(_onTitleChanged);
    _currentTags = List<String>.from(widget.entry.tags);

    try {
      // 1. 解析 entry.content 为自定义结构
      final structure =
          jsonDecode(widget.entry.content) as Map<String, dynamic>;

      // 2. 结构 → Delta + memo
      final result = RichtextAdapter.structureToDelta(structure);
      _memo = result.memo;

      // 3. Delta 喂 QuillController
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(result.delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // T-213：不静默回退。记错误，build 走错误页。
      // 用户看不到空白编辑器，也不会误保存覆盖原内容。
      _initError = e.toString();
    }
  }

  void _onTitleChanged() {
    setState(() {});
  }

  /// 切换笔记级标记（⭐ 重要 / ❓ 待解决）。
  /// 第四轮批 1 新增。依据 v5 方案 §6.2。
  void _toggleTag(String tag) {
    setState(() {
      if (_currentTags.contains(tag)) {
        _currentTags.remove(tag);
      } else {
        _currentTags.add(tag);
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // T-213：错误页时不可达；双保险。
    final controller = _quillController;
    final memo = _memo;
    if (controller == null || memo == null) return;

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. 从 QuillController 取 Delta
      final delta = controller.document.toDelta().toJson();

      // 2. Delta → 自定义结构（带 memo 恢复 id / marks）
      final newStructure = RichtextAdapter.deltaToStructure(
        delta.cast<Map<String, dynamic>>(),
        memo: memo,
      );

      // 3. 标题
      final newTitle = _titleController.text.trim();

      // 4. 构造新 entry 并落盘
      final updated = widget.entry.copyWith(
        title: newTitle.isEmpty ? widget.entry.title : newTitle,
        content: jsonEncode(newStructure),
        updatedAt: DateTime.now(),
        tags: _currentTags,
      );
      await DatabaseService().updateNote(updated.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 已保存'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 导出当前笔记为 EPUB（单篇）
  ///
  /// 流程：编辑器内容 → 静默保存 → EpubExporter.exportBook([entry]) → 平台保存
  Future<void> _exportEpub() async {
    final controller = _quillController;
    final memo = _memo;
    if (controller == null || memo == null) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      // 1. 从编辑器取当前 Delta
      final delta = controller.document.toDelta().toJson();

      // 2. Delta → 结构
      final newStructure = RichtextAdapter.deltaToStructure(
        delta.cast<Map<String, dynamic>>(),
        memo: memo,
      );

      // 3. 构造新 entry
      final newTitle = _titleController.text.trim();
      final updated = widget.entry.copyWith(
        title: newTitle.isEmpty ? widget.entry.title : newTitle,
        content: jsonEncode(newStructure),
        updatedAt: DateTime.now(),
        tags: _currentTags,
      );

      // 4. 静默保存到数据库（老白裁定：导出触发一次保存）
      await DatabaseService().updateNote(updated.toMap());

      // 5. 导出
      final book = EpubExporter.exportBook([updated]);

      // 6. 平台特定保存（抽出的公共 service）
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
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancel() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    // T-213：解析失败 → 错误页。不提供保存入口。
    if (_initError != null) {
      return _buildErrorPage();
    }

    return Scaffold(
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
          // ✅ 第四轮批 1 新增：笔记级标记 ⭐/❓
          // 依据 v5 方案 §6.2：批 1 只做笔记级标记，不碰光标映射。
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
            icon: const Icon(Icons.ios_share),
            tooltip: '导出 EPUB',
            onPressed: _isSaving ? null : _exportEpub,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            quill.QuillSimpleToolbar(
              controller: _quillController!,
              config: const quill.QuillSimpleToolbarConfig(),
            ),
            const Divider(height: 1),
            Expanded(
              child: quill.QuillEditor.basic(
                controller: _quillController!,
                config: quill.QuillEditorConfig(
                  placeholder: '开始写…',
                  embedBuilders: [_DividerEmbedBuilder()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// T-213：解析失败错误页。
  ///
  /// - 显示原始错误信息（便于排查）
  /// - 不提供保存入口
  /// - 提供返回按钮，用户可退出
  Widget _buildErrorPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
        actions: [
          TextButton(
            onPressed: _cancel,
            child: const Text('返回'),
          ),
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
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '内容损坏，无法编辑',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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

/// 分割线嵌入对象的渲染器。
///
/// 对应 Delta 里的 `{ "insert": { "divider": true } }`。
/// 若未注册，flutter_quill 会渲染成占位符或崩。
class _DividerEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => DeltaAttributes.divider;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return const Divider(thickness: 1);
  }
}