// lib/widgets/writing/editor_area.dart
// 编辑器区域 — 标题 + 内容 + Markdown预览

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/note.dart';
import '../../models/card.dart';

class EditorArea extends StatefulWidget {
  final NotebookEntry note;
  final Function(String, String, String, List<String>) onSave;
  final Function(String) onInsertText;
  final Function(CardModel) onInsertCard;  // ✅ 改为 CardModel 类型

  const EditorArea({
    super.key,
    required this.note,
    required this.onSave,
    required this.onInsertText,
    required this.onInsertCard,
  });

  @override
  State<EditorArea> createState() => EditorAreaState();
}

class EditorAreaState extends State<EditorArea> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<String> _tags;
  bool _isMarkdown = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _tags = List.from(widget.note.tags);
    _isMarkdown = widget.note.editorMode == 'markdown';
  }

  @override
  void didUpdateWidget(EditorArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.note.id != oldWidget.note.id) {
      _titleController.text = widget.note.title;
      _contentController.text = widget.note.content;
      _tags = List.from(widget.note.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void insertText(String text) {
    final cursorPosition = _contentController.selection.baseOffset;
    final currentText = _contentController.text;
    if (cursorPosition < 0 || cursorPosition > currentText.length) {
      _contentController.text = currentText + text;
    } else {
      final newText = currentText.substring(0, cursorPosition) +
          text +
          currentText.substring(cursorPosition);
      _contentController.text = newText;
      final newCursor = cursorPosition + text.length;
      _contentController.selection = TextSelection.collapsed(offset: newCursor);
    }
    setState(() {});
  }

  void save() {
    widget.onSave(
      _titleController.text.trim(),
      _contentController.text.trim(),
      _isMarkdown ? 'markdown' : 'plain',
      _tags,
    );
  }

  void clear() {
    _titleController.text = '无标题';
    _contentController.text = '';
    _tags = [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = _contentController.text.length;
    final lineCount = _contentController.text.split('\n').length;

    return Column(
      children: [
        // 标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '输入标题...',
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        // 标签栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '标签（用逗号分隔）',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (value) {
                    _tags = value
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    setState(() {});
                  },
                ),
              ),
              // Markdown开关
              Row(
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
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Text('📄', style: TextStyle(fontSize: 14)),
                ],
              ),
              // 预览开关（Markdown模式）
              if (_isMarkdown)
                IconButton(
                  icon: Icon(
                    _showPreview ? Icons.code : Icons.preview,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPreview = !_showPreview;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '预览',
                ),
            ],
          ),
        ),
        // 内容
        Expanded(
          child: _isMarkdown && _showPreview
              ? _buildMarkdownPreview()
              : _buildPlainEditor(),
        ),
        // 底部统计
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📝 $wordCount 字 · $lineCount 行',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: _tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getTagColor(tag).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getTagColor(tag),
                      ),
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlainEditor() {
    return TextField(
      controller: _contentController,
      maxLines: null,
      expands: true,
      style: const TextStyle(fontSize: 16, height: 1.6),
      decoration: const InputDecoration(
        hintText: '开始写作...',
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(16),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildMarkdownPreview() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: '支持 Markdown 语法...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Container(
          width: 1,
          color: Colors.grey.shade200,
        ),
        Expanded(
          flex: 5,
          child: _contentController.text.isEmpty
              ? const Center(
                  child: Text('预览', style: TextStyle(color: Colors.grey)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: _contentController.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, height: 1.6),
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
      ],
    );
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