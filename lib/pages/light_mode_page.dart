// lib/pages/light_mode_page.dart
// 轻模式 — 采集页 raw 笔记的整理入口（弹窗内容体）

import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/note.dart';
import '../services/card_service.dart';
import '../services/note_service.dart';
import '../utils/app_string_utils.dart';
import '../widgets/floating_pet.dart';
import '../widgets/folder_selector_dialog.dart';

class LightModePage extends StatefulWidget {
  final NotebookEntry entry;
  final ScrollController? scrollController;

  const LightModePage({
    super.key,
    required this.entry,
    this.scrollController,
  });

  @override
  State<LightModePage> createState() => _LightModePageState();
}

class _LightModePageState extends State<LightModePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late List<String> _tags;
  String? _selectedFolderId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _tags = List<String>.from(widget.entry.tags);
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const FolderSelectorDialog(),
    );
    if (result != null && mounted) {
      setState(() => _selectedFolderId = result);
    }
  }

  Future<void> _organize() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final updated = await NoteService().organizeRawNote(
      entry: widget.entry,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      editorMode: widget.entry.editorMode,
      tags: _tags,
      targetFolderId: _selectedFolderId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('收入失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    floatingPetKey.currentState?.showMessage('水开始蒸发了。');
    Navigator.pop(context, true);
  }

  /// 安全截断：避开半个 emoji
  String _safeCut(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    final code = s.codeUnitAt(maxLen - 1);
    final end = (code >= 0xD800 && code <= 0xDBFF) ? maxLen - 1 : maxLen;
    return s.substring(0, end);
  }

  void _openQuickIndexCardDialog() {
    final selection = _contentController.selection;
    final String rawSelected;
    if (selection.isValid &&
        !selection.isCollapsed &&
        selection.start >= 0 &&
        selection.end <= _contentController.text.length) {
      rawSelected =
          _contentController.text.substring(selection.start, selection.end);
    } else {
      rawSelected = '';
    }

    final selectedText =
        rawSelected.trim().isEmpty ? _contentController.text : rawSelected;

    if (selectedText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正文为空，无法生成卡片')),
      );
      return;
    }

    final initialTitle = selectedText.length > 50
        ? '${_safeCut(selectedText, 50)}…'
        : selectedText;

    showDialog(
      context: context,
      builder: (_) => _QuickIndexCardDialog(
        initialTitle: initialTitle,
        initialHighlight: selectedText,
        onConfirm: ({
          required String title,
          required String highlight,
          required String author,
          required List<String> tags,
        }) async {
          final card = CardModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            cardType: CardType.indexCard,
            sourceType: 'note',
            sourceId: widget.entry.id,
            sourceTitle: widget.entry.title,
            tags: tags,
            indexTitle: title,
            highlight: highlight,
            author: author,
            importance: Importance.medium,
            stage: 0,
            nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
          );
          await CardService().addCard(card);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('📇 索引卡已生成')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── 顶部：标题栏（固定） ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: const Text(
            '整理',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),

        // ─── 正文：可拉伸（自身可滚） ───
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 16, height: 1.6),
              decoration: const InputDecoration(
                hintText: '写下内容…',
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // ─── 下方紧凑串（固定，不随滚动） ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              TextField(
                controller: _titleController,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: AppStringUtils.virtualNoteTitle(
                    _contentController.text,
                  ),
                  labelText: '标题',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),

              // 标签
              TextField(
                decoration: const InputDecoration(
                  labelText: '标签（用逗号分隔）',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  _tags = value
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();
                },
              ),
              const SizedBox(height: 8),

              // 归类
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFolderId == null ? '未归类（挂根）' : '已选文件夹',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: _pickFolder,
                    child: const Text('选择文件夹'),
                  ),
                ],
              ),

              // 按钮栏
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : _openQuickIndexCardDialog,
                    child: const Text('卡片'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _organize,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('收入智库'),
                  ),
                ],
              ),
            ],
          ),
        ),

        SafeArea(top: false, child: const SizedBox(height: 8)),
      ],
    );
  }
}

class _QuickIndexCardDialog extends StatefulWidget {
  final String initialTitle;
  final String initialHighlight;
  final String initialAuthor;
  final List<String> initialTags;
  final Future<void> Function({
    required String title,
    required String highlight,
    required String author,
    required List<String> tags,
  }) onConfirm;

  const _QuickIndexCardDialog({
    super.key,
    required this.initialTitle,
    required this.initialHighlight,
    this.initialAuthor = '',
    this.initialTags = const [],
    required this.onConfirm,
  });

  @override
  State<_QuickIndexCardDialog> createState() => _QuickIndexCardDialogState();
}

class _QuickIndexCardDialogState extends State<_QuickIndexCardDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _highlightController;
  late final TextEditingController _authorController;
  late final TextEditingController _tagsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _highlightController =
        TextEditingController(text: widget.initialHighlight);
    _authorController = TextEditingController(text: widget.initialAuthor);
    _tagsController =
        TextEditingController(text: widget.initialTags.join(', '));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _highlightController.dispose();
    _authorController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await widget.onConfirm(
        title: _titleController.text.trim(),
        highlight: _highlightController.text.trim(),
        author: _authorController.text.trim(),
        tags: tags,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('_QuickIndexCardDialog._confirm 失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成卡片失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📇 索引卡'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _highlightController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '高光句',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签（用逗号分隔）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _confirm,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }
}