// test/services/task_service_test.dart
// TaskService 完整单元测试

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_note_app/services/task_service.dart';
import 'package:my_note_app/models/task.dart';

void main() {
  late TaskService taskService;

  // ─── 测试前准备 ──────────────────────────────────────────

  setUp(() async {
    // 模拟 SharedPreferences（隔离真实存储）
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    taskService = TaskService();
  });

  // 每个测试后清理
  tearDown(() async {
    // 无需额外清理，SharedPreferences 模拟每次重置
  });

  // ─── 组1：基础 CRUD 操作 ──────────────────────────────

  group('基础 CRUD 操作', () {
    test('空数据应返回空列表', () async {
      final tasks = await taskService.loadAllTasks();
      expect(tasks, isEmpty);
    });

    test('添加任务后应能通过列表获取', () async {
      final task = Task(
        id: 'test_1',
        title: '测试任务',
        type: TaskType.quick,
        difficulty: Difficulty.medium,
        urgency: Urgency.medium,
        necessity: Necessity.important,
      );

      await taskService.addTask(task);
      final tasks = await taskService.loadAllTasks();

      expect(tasks.length, 1);
      expect(tasks.first.id, 'test_1');
      expect(tasks.first.title, '测试任务');
      expect(tasks.first.type, TaskType.quick);
    });

    test('更新任务应正确修改字段', () async {
      final task = Task(
        id: 'test_2',
        title: '原始标题',
        type: TaskType.quick,
        urgency: Urgency.low,
      );

      await taskService.addTask(task);

      final updated = task.copyWith(
        title: '更新后的标题',
        urgency: Urgency.high,
      );
      await taskService.updateTask(updated);

      final tasks = await taskService.loadAllTasks();
      expect(tasks.first.title, '更新后的标题');
      expect(tasks.first.urgency, Urgency.high);
    });

    test('删除任务应移除该任务', () async {
      final task = Task(
        id: 'test_3',
        title: '待删除任务',
        type: TaskType.quick,
      );

      await taskService.addTask(task);
      await taskService.deleteTask('test_3');

      final tasks = await taskService.loadAllTasks();
      expect(tasks, isEmpty);
    });

    test('添加100个任务不崩溃', () async {
      for (var i = 0; i < 100; i++) {
        await taskService.addTask(Task(
          id: 'bulk_$i',
          title: '批量任务 $i',
          type: TaskType.quick,
        ));
      }
      final tasks = await taskService.loadAllTasks();
      expect(tasks.length, 100);
    });
  });

  // ─── 组2：子任务操作 ────────────────────────────────────

  group('子任务操作', () {
    test('添加子任务后应关联到父任务', () async {
      final parentId = 'parent_1';
      final subtask = Subtask(
        id: 'sub_1',
        parentTaskId: parentId,
        title: '子任务1',
      );

      await taskService.addSubtask(subtask);
      final subtasks = await taskService.loadSubtasksForTask(parentId);

      expect(subtasks.length, 1);
      expect(subtasks.first.title, '子任务1');
      expect(subtasks.first.parentTaskId, parentId);
    });

    test('更新子任务应修改状态', () async {
      final parentId = 'parent_2';
      final subtask = Subtask(
        id: 'sub_2',
        parentTaskId: parentId,
        title: '原始子任务',
        isDone: false,
      );

      await taskService.addSubtask(subtask);

      final updated = subtask.copyWith(
        title: '更新子任务',
        isDone: true,
        completedAt: DateTime.now(),
      );
      await taskService.updateSubtask(updated);

      final subtasks = await taskService.loadSubtasksForTask(parentId);
      expect(subtasks.first.title, '更新子任务');
      expect(subtasks.first.isDone, true);
    });

    test('删除子任务应从列表移除', () async {
      final parentId = 'parent_3';
      final subtask = Subtask(
        id: 'sub_3',
        parentTaskId: parentId,
        title: '待删除子任务',
      );

      await taskService.addSubtask(subtask);
      await taskService.deleteSubtask('sub_3');

      final subtasks = await taskService.loadSubtasksForTask(parentId);
      expect(subtasks, isEmpty);
    });

    test('删除父任务应同时删除所有子任务', () async {
      final parentId = 'parent_4';

      for (var i = 0; i < 5; i++) {
        await taskService.addSubtask(Subtask(
          id: 'sub_bulk_$i',
          parentTaskId: parentId,
          title: '子任务 $i',
        ));
      }

      await taskService.deleteTask(parentId);

      final subtasks = await taskService.loadSubtasksForTask(parentId);
      expect(subtasks, isEmpty);
    });
  });

  // ─── 组3：统计功能 ──────────────────────────────────────

  group('统计功能', () {
    test('getPendingTaskCount 应返回未完成任务数', () async {
      await taskService.addTask(Task(
        id: 'stat_1',
        title: '已完成任务',
        type: TaskType.quick,
        isDone: true,
      ));
      await taskService.addTask(Task(
        id: 'stat_2',
        title: '未完成任务1',
        type: TaskType.quick,
        isDone: false,
      ));
      await taskService.addTask(Task(
        id: 'stat_3',
        title: '未完成任务2',
        type: TaskType.quick,
        isDone: false,
      ));

      final pending = await taskService.getPendingTaskCount();
      expect(pending, 2);
    });

    test('getCompletionRate 应返回正确完成率', () async {
      // 2个完成，1个未完成 → 2/3 ≈ 0.667
      await taskService.addTask(Task(
        id: 'rate_1',
        title: '已完成',
        type: TaskType.quick,
        isDone: true,
      ));
      await taskService.addTask(Task(
        id: 'rate_2',
        title: '已完成2',
        type: TaskType.quick,
        isDone: true,
      ));
      await taskService.addTask(Task(
        id: 'rate_3',
        title: '未完成',
        type: TaskType.quick,
        isDone: false,
      ));

      final rate = await taskService.getCompletionRate();
      expect(rate, closeTo(2 / 3, 0.001));
    });

    test('getCompletionRate 空任务应返回0', () async {
      final rate = await taskService.getCompletionRate();
      expect(rate, 0);
    });
  });

  // ─── 组4：边界情况 ──────────────────────────────────────

  group('边界情况', () {
    test('更新不存在的任务不抛出异常', () async {
      final task = Task(
        id: 'not_exist',
        title: '不存在',
        type: TaskType.quick,
      );
      // 不应抛出异常
      await taskService.updateTask(task);
      // 如果执行到这里，说明通过
      expect(true, true);
    });

    test('删除不存在的任务不抛出异常', () async {
      await taskService.deleteTask('not_exist');
      expect(true, true);
    });

    test('获取不存在的父任务的子任务返回空列表', () async {
      final subtasks = await taskService.loadSubtasksForTask('not_exist_parent');
      expect(subtasks, isEmpty);
    });
  });

  // ─── 组5：任务类型筛选 ──────────────────────────────────

  group('任务类型筛选', () {
    test('速通任务和探究任务应能区分', () async {
      final quickTask = Task(
        id: 'type_1',
        title: '速通任务',
        type: TaskType.quick,
      );
      final exploreTask = Task(
        id: 'type_2',
        title: '探究任务',
        type: TaskType.explore,
      );

      await taskService.addTask(quickTask);
      await taskService.addTask(exploreTask);

      final all = await taskService.loadAllTasks();
      expect(all.where((t) => t.type == TaskType.quick).length, 1);
      expect(all.where((t) => t.type == TaskType.explore).length, 1);
    });
  });
}