import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../services/review_service.dart';

class FullscreenEditor extends StatefulWidget {
  final NotebookEntry entry;
  final bool isFromCollection;
  final Future<bool> Function(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
  ) onSave;
  final bool isSaving;

  // 🆕 探究任务相关
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

  static void triggerSave() {
    print('✅ FullscreenEditor.triggerSave() 被调用');
    _FullscreenEditorState.triggerSave();
  }
}

class _FullscreenEditorState extends State<FullscreenEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late TextEditingController _subtaskController;
  bool _isMarkdown = false;
  List<String> _tags = [];
  final ReviewService _reviewService = ReviewService();
  final FocusNode _contentFocus = FocusNode();

  static _FullscreenEditorState? _currentEditor;

  @override
  void initState() {
    super.initState();
    print('📌 FullscreenEditor initState');
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _tagController = TextEditingController();
    _subtaskController = TextEditingController();
    _isMarkdown = widget.entry.editorMode == 'markdown';
    _tags = List.from(widget.entry.tags);

    _currentEditor = this;
  }

  @override
  void dispose() {
    print('📌 FullscreenEditor dispose');
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _subtaskController.dispose();
    _contentFocus.dispose();
    if (_currentEditor == this) {
      _currentEditor = null;
    }
    super.dispose();
  }

  static void triggerSave() {
    print('📌 _FullscreenEditorState.triggerSave() 被调用');
    if (_currentEditor != null) {
      _currentEditor!._handleSave();
    } else {
      print('❌ _currentEditor 为 null');
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) {
      _showLightToast('标签已存在');
      return;
    }
    setState(() {
      _tags.add(trimmed);
    });
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showLightToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
    );
  }

  Future<void> _createReviewCard() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      _showLightToast('笔记内容为空，无法制卡');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🧠 制卡功能开发中...'), duration: Duration(seconds: 2)),
    );
  }

  // 🆕 添加子任务：在光标位置插入 "- [ ] "
  void _addSubtaskFromEditor() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) {
      _showLightToast('请输入子任务标题');
      return;
    }

    // 构建子任务行
    final subtaskLine = '- [ ] $title\n';

    // 如果有外部回调，调用（用于创建任务关联）
    if (widget.onAddSubtask != null) {
      widget.onAddSubtask!(title);
    }

    // 在内容中插入
    final currentText = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;

    if (cursorPosition < 0 || cursorPosition > currentText.length) {
      // 如果光标无效，在末尾插入
      _contentController.text = currentText + subtaskLine;
    } else {
      // 在光标位置插入
      final newText = currentText.substring(0, cursorPosition) +
          subtaskLine +
          currentText.substring(cursorPosition);
      _contentController.text = newText;
      // 将光标移动到插入内容的末尾
      final newCursor = cursorPosition + subtaskLine.length;
      _contentController.selection = TextSelection.collapsed(offset: newCursor);
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
              // ─── 标题 ────────────────────────────
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 16),

              // ─── 标签 ────────────────────────────
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
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (value) {
                            if (value.contains(',')) {
                              for (var tag in value.split(',')) {
                                _addTag(tag);
                              }
                            } else {
                              _addTag(value);
                            }
                          },
                          onChanged: (value) {
                            if (value.endsWith(',')) {
                              final tag = value.substring(0, value.length - 1);
                              _addTag(tag);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(tag).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _getTagColor(tag).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getTagColor(tag),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeTag(tag),
                              child: Icon(Icons.close, size: 12, color: _getTagColor(tag)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
              const Divider(height: 16),

              // ─── 内容编辑区 ──────────────────────────
              Expanded(
                child: _isMarkdown
                    ? _buildMarkdownEditor()
                    : _buildPlainEditor(),
              ),
              const Divider(height: 8),

              // ─── 🆕 探究任务：添加子任务行 ────────────────────
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
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _addSubtaskFromEditor(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.purple),
                      onPressed: _addSubtaskFromEditor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                      if (_isMarkdown)
                        Text('📄 $lineCount 行', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 16),
                      if (_tags.isNotEmpty)
                        Text('🏷️ ${_tags.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Tooltip(
                        message: '制作复习卡片',
                        child: IconButton(
                          icon: const Icon(Icons.psychology, size: 20, color: Colors.purple),
                          onPressed: _createReviewCard,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
                              onChanged: (value) {
                                setState(() {
                                  _isMarkdown = value;
                                });
                              },
                              activeColor: Colors.blue,
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
                            backgroundColor: widget.isFromCollection
                                ? Colors.blue.shade700
                                : null,
                            foregroundColor: widget.isFromCollection
                                ? Colors.white
                                : null,
                          ),
                          child: widget.isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  widget.isFromCollection ? '📥 收入智库' : '💾 保存',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
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
      decoration: const InputDecoration(
        hintText: '开始写内容...',
        border: InputBorder.none,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildMarkdownEditor() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
              onChanged: (_) => setState(() {}),
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
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
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
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    print('📌 _handleSave 被调用');
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
    );

    print('📌 保存结果: $success');
    if (success && mounted) {
      Navigator.pop(context, true);
    }
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