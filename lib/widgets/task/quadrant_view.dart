// lib/widgets/task/quadrant_view.dart
// 四象限视图

import 'package:flutter/material.dart';
import '../../models/task.dart';

class QuadrantView extends StatelessWidget {
  final List<Task> tasks;
  final List<Subtask> subtasks;
  final String? expandedTaskId;
  final ValueChanged<String?> onToggleExpand;
  final ValueChanged<Task> onCompleteQuick;

  const QuadrantView({
    super.key,
    required this.tasks,
    required this.subtasks,
    this.expandedTaskId,
    required this.onToggleExpand,
    required this.onCompleteQuick,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      childAspectRatio: 0.85,
      children: [
        _buildQuadrantCell(
          title: '🔴 紧急且必要',
          color: Colors.red,
          tasks: tasks.where((t) => t.urgency == Urgency.high && t.necessity == Necessity.critical).toList(),
        ),
        _buildQuadrantCell(
          title: '🟡 重要但不紧急',
          color: Colors.orange,
          tasks: tasks.where((t) => t.urgency != Urgency.high && t.necessity == Necessity.critical).toList(),
        ),
        _buildQuadrantCell(
          title: '🟠 紧急但不必要',
          color: Colors.deepOrange,
          tasks: tasks.where((t) => t.urgency == Urgency.high && t.necessity != Necessity.critical).toList(),
        ),
        _buildQuadrantCell(
          title: '🟢 不紧急不必要',
          color: Colors.green,
          tasks: tasks.where((t) => t.urgency != Urgency.high && t.necessity != Necessity.critical).toList(),
        ),
      ],
    );
  }

  Widget _buildQuadrantCell({
    required String title,
    required Color color,
    required List<Task> tasks,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text('${tasks.length}', style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text('✨ 空', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildQuadrantTaskItem(task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantTaskItem(Task task) {
    bool isHovered = false;

    return StatefulBuilder(
      key: ValueKey('quadrant_${task.id}'),
      builder: (context, setState) {
        final taskSubtasks = subtasks.where((s) => s.parentTaskId == task.id).toList();
        final doneCount = taskSubtasks.where((s) => s.isDone).length;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (task.type == TaskType.explore) {
                        onToggleExpand(expandedTaskId == task.id ? null : task.id);
                      } else {
                        onCompleteQuick(task);
                      }
                    },
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (task.type == TaskType.explore) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$doneCount/${taskSubtasks.length}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
                const SizedBox(width: 4),
                MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true),
                  onExit: (_) => setState(() => isHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      if (task.type == TaskType.explore) {
                        onToggleExpand(expandedTaskId == task.id ? null : task.id);
                      } else {
                        onCompleteQuick(task);
                      }
                    },
                    child: Icon(
                      isHovered ? Icons.check_circle : Icons.check_circle_outline,
                      size: 14,
                      color: isHovered ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}