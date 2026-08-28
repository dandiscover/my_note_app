// lib/widgets/task/task_list_view.dart
// 任务列表视图

import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../quick_task_card.dart';
import '../explore_task_card.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final List<Subtask> subtasks;
  final String? expandedTaskId;
  final ValueChanged<String?> onToggleExpand;
  final ValueChanged<Task> onCompleteQuick;
  final ValueChanged<String> onDeleteTask;
  final ValueChanged<Task> onSetReminder;
  final ValueChanged<Subtask> onToggleSubtask;
  final ValueChanged<String> onAddSubtask;  // ✅ 修改：只接收 taskId

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
    final exploreTasks = tasks.where((t) => t.type == TaskType.explore).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (exploreTasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('🔍 探究任务', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          ...exploreTasks.map((task) => ExploreTaskCard(
            key: ValueKey('explore_${task.id}'),
            task: task,
            subtasks: subtasks.where((s) => s.parentTaskId == task.id).toList(),
            onToggleExpand: () => onToggleExpand(expandedTaskId == task.id ? null : task.id),
            onToggleSubtask: onToggleSubtask,
            onDelete: () => onDeleteTask(task.id),
            onAddSubtask: (title) => onAddSubtask(task.id),  // ✅ 只传 taskId
          )),
          const SizedBox(height: 8),
        ],
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