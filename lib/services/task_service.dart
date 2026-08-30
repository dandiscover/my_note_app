// lib/services/task_service.dart
// 任务数据服务（统一管理任务 CRUD）
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';
  static const String _subtasksKey = 'subtasks';

  // ─── 加载所有任务 ──────────────────────────────────────────

  Future<List<Task>> loadAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_tasksKey) ?? [];
      return jsonList
          .map((json) {
            try {
              final map = jsonDecode(json) as Map<String, dynamic>;
              return Task.fromJson(map);
            } catch (_) {
              return null;
            }
          })
          .whereType<Task>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── 保存所有任务 ──────────────────────────────────────────

  Future<void> saveAllTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tasks.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_tasksKey, jsonList);
    } catch (e) {
      print('保存任务失败: $e');
    }
  }

  // ─── 添加任务 ──────────────────────────────────────────────

  Future<void> addTask(Task task) async {
    final tasks = await loadAllTasks();
    tasks.add(task);
    await saveAllTasks(tasks);
  }

  // ─── 更新任务 ──────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    final tasks = await loadAllTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await saveAllTasks(tasks);
    }
  }

  // ─── 删除任务 ──────────────────────────────────────────────

  Future<void> deleteTask(String taskId) async {
    final tasks = await loadAllTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveAllTasks(tasks);
    await deleteSubtasksForTask(taskId);
  }

  // ─── 子任务操作 ────────────────────────────────────────────

  Future<List<Subtask>> loadSubtasksForTask(String taskId) async {
    final all = await loadAllSubtasks();
    return all.where((s) => s.parentTaskId == taskId).toList();
  }

  Future<List<Subtask>> loadAllSubtasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_subtasksKey) ?? [];
      return jsonList
          .map((json) {
            try {
              final map = jsonDecode(json) as Map<String, dynamic>;
              return Subtask.fromJson(map);
            } catch (_) {
              return null;
            }
          })
          .whereType<Subtask>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAllSubtasks(List<Subtask> subtasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = subtasks.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_subtasksKey, jsonList);
    } catch (e) {
    print('保存子任务失败: $e');
    }
  }

  Future<void> addSubtask(Subtask subtask) async {
    final all = await loadAllSubtasks();
    all.add(subtask);
    await saveAllSubtasks(all);
  }

  Future<void> updateSubtask(Subtask subtask) async {
    final all = await loadAllSubtasks();
    final index = all.indexWhere((s) => s.id == subtask.id);
    if (index != -1) {
      all[index] = subtask;
      await saveAllSubtasks(all);
    }
  }

  Future<void> deleteSubtask(String subtaskId) async {
    final all = await loadAllSubtasks();
    all.removeWhere((s) => s.id == subtaskId);
    await saveAllSubtasks(all);
  }

  Future<void> deleteSubtasksForTask(String taskId) async {
    final all = await loadAllSubtasks();
    all.removeWhere((s) => s.parentTaskId == taskId);
    await saveAllSubtasks(all);
  }

  // ─── 统计 ──────────────────────────────────────────────────

  Future<int> getPendingTaskCount() async {
    final tasks = await loadAllTasks();
    return tasks.where((t) => !t.isDone).length;
  }

  Future<double> getCompletionRate() async {
    final tasks = await loadAllTasks();
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isDone).length;
    return done / tasks.length;
  }
}