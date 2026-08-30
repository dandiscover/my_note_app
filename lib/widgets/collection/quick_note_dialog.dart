// lib/widgets/collection/quick_note_dialog.dart
// 采集页 - 快速笔记对话框（使用回调）

import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/task.dart';
import '../../database_service.dart';
import '../../services/task_service.dart';

class QuickNoteDialog extends StatefulWidget {
  final DatabaseService db;
  final TaskService taskService;
  final VoidCallback onSave;
  final VoidCallback? onTaskCreated;  // ✅ 使用回调，不再直接依赖 creationKey

  const QuickNoteDialog({
    super.key,
    required this.db,
    required this.taskService,
    required this.onSave,
    this.onTaskCreated,
  });

  @override
  State<QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<QuickNoteDialog> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isTask = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('标签已存在'), duration: Duration(seconds: 1)),
      );
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

  Future<void> _performSave() async {
    if (_isSaving) return;
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容'), duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final status = _isTask ? 'task' : 'raw';
    final title = content.length > 30 ? '${content.substring(0, 30)}...' : content;

    final newEntry = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      status: status,
      tags: _tags,
      editorMode: 'plain',
    );

    await widget.db.insertNote(newEntry.toMap());

    if (_isTask) {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        type: TaskType.quick,
        difficulty: Difficulty.medium,
        urgency: Urgency.medium,
        necessity: Necessity.important,
      );
      await widget.taskService.addTask(task);
      // ✅ 调用回调，由父组件刷新
      widget.onTaskCreated?.call();
    }

    widget.onSave();
    if (mounted) Navigator.pop(context);
    setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('快速笔记'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ctrl+S 保存',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _contentController,
              autofocus: true,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: '输入你的想法...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _buildTagSection(),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isTask,
                  onChanged: (value) {
                    setState(() {
                      _isTask = value ?? false;
                    });
                  },
                ),
                const Text('转为任务（收入创作区）'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _performSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            const Text('标签', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '输入标签，按回车添加',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                style: const TextStyle(fontSize: 12),
                onSubmitted: (value) {
                  if (value.contains(',')) {
                    for (var t in value.split(',')) {
                      _addTag(t);
                    }
                  } else {
                    _addTag(value);
                  }
                },
                onChanged: (value) {
                  if (value.endsWith(',')) {
                    final t = value.substring(0, value.length - 1);
                    _addTag(t);
                  }
                },
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 3,
            children: _tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getTagColor(tag).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getTagColor(tag).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getTagColor(tag),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  GestureDetector(
                    onTap: () => _removeTag(tag),
                    child: Icon(Icons.close, size: 10, color: _getTagColor(tag)),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }
}