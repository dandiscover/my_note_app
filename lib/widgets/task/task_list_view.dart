// lib/widgets/task/task_list_view.dart
// 任务列表视图
// ✅ 删除探究任务区块，只保留速通任务

import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../quick_task_card.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final List<Subtask> subtasks;
  final String? expandedTaskId;
  final ValueChanged<String?> onToggleExpand;
  final ValueChanged<Task> onCompleteQuick;
  final ValueChanged<String> onDeleteTask;
  final ValueChanged<Task> onSetReminder;
  final ValueChanged<Subtask> onToggleSubtask;
  final ValueChanged<String> onAddSubtask;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.subtasks,
    this.expandedTaskId,
    required this.onToggleExpand,
    required this.onCompleteQuick,
    required this.onDeleteTask,
    required this.onSetReminder,
    required this.onToggleSubtask,
    required this.onAddSubtask,
  });

  @override
  Widget build(BuildContext context) {
    final quickTasks = tasks.where((t) => t.type == TaskType.quick).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (quickTasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('⚡ 速通任务', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          ...quickTasks.map((task) => QuickTaskCard(
            key: ValueKey('quick_${task.id}'),
            task: task,
            onComplete: () => onCompleteQuick(task),
            onDelete: () => onDeleteTask(task.id),
            onSetReminder: () => onSetReminder(task),
          )),
        ],
      ],
    );
  }
}