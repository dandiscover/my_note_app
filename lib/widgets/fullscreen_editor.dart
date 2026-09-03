// lib/widgets/fullscreen_editor.dart
// 全屏编辑器 — 制卡功能完整实现
// ✅ 新增：深度笔记入口（停2秒显示提示，点击后内联输入探究问题）

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../widgets/note_card_dialog.dart';

class FullscreenEditor extends StatefulWidget {
  final NotebookEntry entry;
  final bool isFromCollection;
  final Future<bool> Function(
    NotebookEntry entry, String title, String content, String editorMode, List<String> tags, String? inquiryQuestion,
  ) onSave;
  final bool isSaving;
  final String? exploreTaskId;
  final Function(String)? onAddSubtask;

  const FullscreenEditor({
    super.key,
    required this.entry,
    this.isFromCollection = false,
    required this.onSave,
    this.isSaving = false,
    this.exploreTaskId,
    this.onAddSubtask,
  });

  @override
  State<FullscreenEditor> createState() => _FullscreenEditorState();

  // ✅ 静态成员：当前编辑器实例
  static _FullscreenEditorState? _currentEditor;

  static bool get isActive => _currentEditor != null;

  static void triggerSave() {
    if (_currentEditor == null) return;
    _currentEditor!._handleSave();
  }
}

class _FullscreenEditorState extends State<FullscreenEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late TextEditingController _subtaskController;
  bool _isMarkdown = false;
  List<String> _tags = [];
  final CardService _cardService = CardService();
  final FocusNode _contentFocus = FocusNode();
  bool _isGeneratingCard = false;

  // ─── 深度笔记入口状态 ─────────────────────────────
  String? _inquiryQuestion;
  bool _showInquiryPrompt = false;
  bool _hasShownPrompt = false;
  bool _isInquiryEditing = false;
  Timer? _typingTimer;
  late TextEditingController _inquiryController;
  late FocusNode _inquiryFocusNode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _tagController = TextEditingController();
    _subtaskController = TextEditingController();
    _isMarkdown = widget.entry.editorMode == 'markdown';
    _tags = List.from(widget.entry.tags);

    // ✅ 深度笔记入口初始化
    _inquiryController = TextEditingController();
    _inquiryFocusNode = FocusNode();
    _inquiryQuestion = widget.entry.inquiryQuestion;
    if (_inquiryQuestion != null) {
      _inquiryController.text = _inquiryQuestion!;
      _hasShownPrompt = true; // 已有问题，不再提示
    }

    // ✅ 注册当前实例
    FullscreenEditor._currentEditor = this;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _subtaskController.dispose();
    _contentFocus.dispose();
    _typingTimer?.cancel();
    _inquiryController.dispose();
    _inquiryFocusNode.dispose();
    if (FullscreenEditor._currentEditor == this) {
      FullscreenEditor._currentEditor = null;
    }
    super.dispose();
  }

  // ─── 深度笔记入口交互 ─────────────────────────────

  void _onContentChanged(String value) {
    setState(() {
      // 用户打字 → 提示消失
      if (_showInquiryPrompt) {
        _showInquiryPrompt = false;
      }
    });
    _resetTypingTimer();
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _checkAndShowPrompt();
    });
  }

  void _checkAndShowPrompt() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    if (_inquiryQuestion != null) return;
    if (_hasShownPrompt) return;
    if (mounted) {
      setState(() {
        _showInquiryPrompt = true;
      });
    }
  }

  void _onPromptTap() {
    setState(() {
      _showInquiryPrompt = false;
      _hasShownPrompt = true;
      _isInquiryEditing = true;
      _inquiryController.clear();
    });
    // 延迟一帧让输入框出现后获得焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_inquiryFocusNode);
    });
  }

  void _confirmInquiry() {
    final text = _inquiryController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _inquiryQuestion = text;
      _isInquiryEditing = false;
    });
  }

  void _cancelInquiryEdit() {
    setState(() {
      _isInquiryEditing = false;
      // 如果有原问题，恢复显示；如果没有，回到显示模式但保持原值
      if (_inquiryQuestion != null) {
        _inquiryController.text = _inquiryQuestion!;
      } else {
        _inquiryController.clear();
      }
    });
  }

  void _onInquiryTap() {
    setState(() {
      _isInquiryEditing = true;
      _inquiryController.text = _inquiryQuestion ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_inquiryFocusNode);
    });
  }

  void _deleteInquiry() {
    setState(() {
      _inquiryQuestion = null;
      _isInquiryEditing = false;
      _showInquiryPrompt = false;
    });
    _inquiryController.clear();
    _typingTimer?.cancel();
    // ⚠️ 不重置 _hasShownPrompt，本次会话不再提示
  }

  // ─── 原有方法 ─────────────────────────────

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) { _showLightToast('标签已存在'); return; }
    setState(() { _tags.add(trimmed); });
    _tagController.clear();
  }

  void _removeTag(String tag) { setState(() { _tags.remove(tag); }); }

  void _showLightToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100, elevation: 0, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1), margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
    );
  }

  Future<void> _createReviewCard() async {
    if (_isGeneratingCard) return;
    setState(() => _isGeneratingCard = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      _showLightToast('笔记内容为空，无法制卡');
      setState(() => _isGeneratingCard = false);
      return;
    }

    final previewContent = content.length > 200 ? '${content.substring(0, 200)}...' : content;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => NoteCardDialog(
        selectedText: previewContent,
        comment: title,
        sourceId: widget.entry.id,
        sourceType: 'note',
      ),
    );

    if (result != null) {
      final card = CardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardType: result['cardType'] as CardType,
        sourceType: 'note',
        sourceId: widget.entry.id,
        sourceTitle: title.isEmpty ? '无标题笔记' : title,
        tags: (result['tags'] as List<String>?) ?? [],
        front: result['front'] as String?,
        back: result['back'] as String?,
        indexTitle: result['indexTitle'] as String?,
        author: result['author'] as String?,
        highlight: result['highlight'] as String?,
        question: result['question'] as String?,
        answer: result['answer'] as String?,
        fillQuestion: result['fillQuestion'] as String?,
        fillAnswer: result['fillAnswer'] as String?,
        tfStatement: result['tfStatement'] as String?,
        tfIsTrue: result['tfIsTrue'] as bool?,
        importance: result['importance'] ?? Importance.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _cardService.addCard(card);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 卡片已生成！可在「智库 → 卡片盒」查看'), duration: Duration(seconds: 2)),
      );
    }
    setState(() => _isGeneratingCard = false);
  }

  void _addSubtaskFromEditor() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) { _showLightToast('请输入子任务标题'); return; }
    final subtaskLine = '- [ ] $title\n';
    if (widget.onAddSubtask != null) widget.onAddSubtask!(title);
    final currentText = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > currentText.length) {
      _contentController.text = currentText + subtaskLine;
    } else {
      final newText = currentText.substring(0, cursorPosition) + subtaskLine + currentText.substring(cursorPosition);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: cursorPosition + subtaskLine.length);
    }
    _subtaskController.clear();
    _showLightToast('✅ 子任务已添加');
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = _contentController.text.length;
    final lineCount = _contentController.text.split('\n').length;
    final isExploreMode = widget.exploreTaskId != null;

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ─── 标题 ──────────────────────────────
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: '标题', border: InputBorder.none),
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 8),

              // ─── 已保存的探究问题（在标题下方、正文上方） ────
              if (_inquiryQuestion != null && !_isInquiryEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: GestureDetector(
                          onTap: _onInquiryTap,
                          child: Text(
                            _inquiryQuestion!,
                            style: const TextStyle(fontSize: 13, color: Colors.purple),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _deleteInquiry,
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              // ─── 标签 ──────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('标签', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: '输入标签，按回车或逗号添加',
                            border: InputBorder.none, isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (value) {
                            if (value.contains(',')) { for (var tag in value.split(',')) {
                              _addTag(tag);
                            } }
                            else {
                              _addTag(value);
                            }
                          },
                          onChanged: (value) {
                            if (value.endsWith(',')) { final tag = value.substring(0, value.length - 1); _addTag(tag); }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: _tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(tag).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _getTagColor(tag).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag, style: TextStyle(fontSize: 11, color: _getTagColor(tag), fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            GestureDetector(onTap: () => _removeTag(tag), child: Icon(Icons.close, size: 12, color: _getTagColor(tag))),
                          ],
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
              const Divider(height: 16),

              // ─── 正文 ──────────────────────────────
              Expanded(
                child: _isMarkdown ? _buildMarkdownEditor() : _buildPlainEditor(),
              ),

              // ─── 深度笔记提示：停2秒后显示 ──────────────
              if (_showInquiryPrompt && !_isInquiryEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: _onPromptTap,
                    child: Row(
                      children: [
                        const Text('💭 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '你停下来了。有个疑问吗？',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── 内联输入行 ──────────────────────────
              if (_isInquiryEditing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: TextField(
                          controller: _inquiryController,
                          focusNode: _inquiryFocusNode,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '你在想什么？',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _confirmInquiry(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _cancelInquiryEdit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('取消', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: _confirmInquiry,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('确认', style: TextStyle(fontSize: 12, color: Colors.purple)),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 8),

              if (isExploreMode) ...[
                Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 18, color: Colors.purple),
                    const SizedBox(width: 6),
                    const Text('子任务', style: TextStyle(fontSize: 13, color: Colors.purple)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: const InputDecoration(
                          hintText: '输入子任务，按回车添加',
                          border: InputBorder.none, isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _addSubtaskFromEditor(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.purple),
                      onPressed: _addSubtaskFromEditor,
                      padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 8),
              ],

              // ─── 底部工具栏 ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('📝 $wordCount 字', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 16),
                      if (_isMarkdown) Text('📄 $lineCount 行', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 16),
                      if (_tags.isNotEmpty) Text('🏷️ ${_tags.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: '生成复习卡片',
                        child: IconButton(
                          icon: _isGeneratingCard
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple))
                              : const Icon(Icons.auto_awesome, size: 20, color: Colors.purple),
                          onPressed: _isGeneratingCard ? null : _createReviewCard,
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 14)),
                            Switch(
                              value: _isMarkdown,
                              onChanged: (value) { setState(() { _isMarkdown = value; }); },
                              activeThumbColor: Colors.blue,
                              inactiveTrackColor: Colors.grey.shade300,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const Text('📄', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: widget.isSaving ? null : () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: widget.isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(100, 40),
                            backgroundColor: widget.isFromCollection ? Colors.blue.shade700 : null,
                            foregroundColor: widget.isFromCollection ? Colors.white : null,
                          ),
                          child: widget.isSaving
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : Text(widget.isFromCollection ? '📥 收入智库' : '💾 保存', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainEditor() {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocus,
      maxLines: null,
      expands: true,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(hintText: '开始写内容...', border: InputBorder.none),
      onChanged: _onContentChanged,
    );
  }

  Widget _buildMarkdownEditor() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
              onChanged: _onContentChanged,
              decoration: const InputDecoration(
                hintText: '支持 Markdown 语法...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: _contentController.text.isEmpty
                ? const Center(child: Text('预览', style: TextStyle(color: Colors.grey)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: MarkdownBody(
                      data: _contentController.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15),
                        h1: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        codeblockDecoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      _showLightToast('标题和内容不能都为空');
      return;
    }
    final success = await widget.onSave(
      widget.entry,
      title,
      content,
      _isMarkdown ? 'markdown' : 'plain',
      _tags,
      _inquiryQuestion,
    );
    if (success && mounted) Navigator.pop(context, true);
  }

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue, Colors.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.pink, Colors.indigo, Colors.cyan,
      Colors.deepPurple, Colors.red,
    ];
    return colors[hash % colors.length];
  }
}