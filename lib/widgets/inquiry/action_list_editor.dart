// lib/widgets/inquiry/action_list_editor.dart
// 行动列表编辑器 — 独立管理 NoteSubtask 列表的增删
// 接收 initialActions 拷贝，内部维护状态，通过 onActionsChanged 回传
// 注意：此组件为只读展示模式，行动项不可勾选完成，仅支持添加和删除

import 'package:flutter/material.dart';
import '../../models/note_subtask.dart';

class ActionListEditor extends StatefulWidget {
  final List<NoteSubtask> initialActions;
  final void Function(List<NoteSubtask> actions) onActionsChanged;
  final String? hintText;

  const ActionListEditor({
    super.key,
    required this.initialActions,
    required this.onActionsChanged,
    this.hintText = '输入具体行动...',
  });

  @override
  State<ActionListEditor> createState() => _ActionListEditorState();
}

class _ActionListEditorState extends State<ActionListEditor> {
  late List<NoteSubtask> _actions;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 深拷贝 initialActions
    _actions = widget.initialActions
        .map((a) => NoteSubtask(
              id: a.id,
              title: a.title,
              isDone: a.isDone,
              completedAt: a.completedAt,
              mood: a.mood,
              moodSummary: a.moodSummary,
              createdAt: a.createdAt,
            ))
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAction() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final newAction = NoteSubtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    setState(() {
      _actions.add(newAction);
      _controller.clear();
    });
    widget.onActionsChanged(_actions);
  }

  void _deleteAction(String id) {
    setState(() {
      _actions.removeWhere((a) => a.id == id);
    });
    widget.onActionsChanged(_actions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 输入行
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _addAction(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.purple),
              onPressed: _addAction,
              tooltip: '添加行动',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 行动列表（只读展示，不可勾选）
        if (_actions.isNotEmpty)
          ..._actions.map((action) => _buildActionItem(action)),
        if (_actions.isEmpty)
          const Text(
            '还没有行动，添加一条吧',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildActionItem(NoteSubtask action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // ✅ 只读箭头图标，不可点击
           Icon(
            Icons.subdirectory_arrow_right,
            color: Colors.grey.shade500,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action.title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          // 保留删除功能
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
            onPressed: () => _deleteAction(action.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}