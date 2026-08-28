// lib/widgets/explore_task_card.dart
// 探究任务卡片（含子任务展开）

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task.dart' as model;

class ExploreTaskCard extends StatefulWidget {
  final Task task;
  final List<model.Subtask> subtasks;
  final VoidCallback onToggleExpand;
  final Function(model.Subtask) onToggleSubtask;
  final VoidCallback onDelete;
  final Function(String) onAddSubtask;

  const ExploreTaskCard({
    super.key,
    required this.task,
    required this.subtasks,
    required this.onToggleExpand,
    required this.onToggleSubtask,
    required this.onDelete,
    required this.onAddSubtask,
  });

  @override
  State<ExploreTaskCard> createState() => _ExploreTaskCardState();
}

class _ExploreTaskCardState extends State<ExploreTaskCard> {
  bool _isExpanded = false;
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.subtasks.length;
    final done = widget.subtasks.where((s) => s.isDone).length;
    final progress = total > 0 ? done / total : 0.0;
    final isComplete = total > 0 && done == total;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
              widget.onToggleExpand();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildPriorityBadges(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: isComplete ? TextDecoration.lineThrough : null,
                            color: isComplete ? Colors.grey : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$done/$total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 4),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        color: isComplete ? Colors.green : Colors.purple.shade300,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.subtasks.map((st) => _buildSubtaskItem(st)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: '➕ 添加步骤...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              widget.onAddSubtask(value.trim());
                              _subtaskController.clear();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.purple, size: 22),
                        onPressed: () {
                          final text = _subtaskController.text.trim();
                          if (text.isNotEmpty) {
                            widget.onAddSubtask(text);
                            _subtaskController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                        label: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityBadges() {
    final urgencyColors = {
      Urgency.high: Colors.red,
      Urgency.medium: Colors.orange,
      Urgency.low: Colors.green,
    };
    final necessityColors = {
      Necessity.critical: Colors.red.shade700,
      Necessity.important: Colors.blue,
      Necessity.optional: Colors.grey,
    };
    final urgencyColor = urgencyColors[widget.task.urgency] ?? Colors.grey;
    final necessityColor = necessityColors[widget.task.necessity] ?? Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip(_urgencyLabel(widget.task.urgency), urgencyColor),
        const SizedBox(width: 4),
        _buildChip(_necessityLabel(widget.task.necessity), necessityColor),
        const SizedBox(width: 4),
        _buildChip(widget.task.difficulty.label, Colors.grey),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _urgencyLabel(Urgency u) {
    switch (u) {
      case Urgency.high: return '高';
      case Urgency.medium: return '中';
      case Urgency.low: return '低';
    }
  }

  String _necessityLabel(Necessity n) {
    switch (n) {
      case Necessity.critical: return '必要';
      case Necessity.important: return '重要';
      case Necessity.optional: return '可选';
    }
  }

  Widget _buildSubtaskItem(model.Subtask st) {
    bool _isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              if (st.isDone)
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade100,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 11, color: Colors.green),
                )
              else
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: () => widget.onToggleSubtask(st),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isHovered ? Colors.green : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: _isHovered ? Colors.green.shade50 : Colors.transparent,
                      ),
                      child: _isHovered
                          ? Icon(Icons.check, size: 11, color: Colors.green.shade600)
                          : null,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  st.title,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: st.isDone ? TextDecoration.lineThrough : null,
                    color: st.isDone ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              if (!st.isDone)
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                  onPressed: () => widget.onToggleSubtask(st),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }
}