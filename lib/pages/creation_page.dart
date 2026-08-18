// lib/pages/creation_page.dart
// 创作模块 — 任务看板（速通任务 + 探究任务 + 步骤复盘汇总）

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../widgets/fullscreen_editor.dart';

enum ViewMode { list, quadrant }

class CreationPage extends StatefulWidget {
  const CreationPage({super.key});

  @override
  CreationPageState createState() => CreationPageState();
}

class CreationPageState extends State<CreationPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();

  List<Task> _tasks = [];
  List<Subtask> _subtasks = [];
  final TextEditingController _newTaskController = TextEditingController();
  final TextEditingController _newSubtaskController = TextEditingController();
  String? _expandedTaskId;

  late TabController _tabController;
  ViewMode _viewMode = ViewMode.list;

  String _urgencyFilter = '全部';
  String _necessityFilter = '全部';
  bool _isLoading = true;

  Timer? _reminderTimer;

  // ─── 公开刷新方法（供外部调用） ─────────────────────────────
  void refreshTasks() {
    _loadTasks();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadTasks();
      }
    });
    _loadTasks();
    _loadSubtasks();
    _startReminderTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newTaskController.dispose();
    _newSubtaskController.dispose();
    _reminderTimer?.cancel();
    super.dispose();
  }

  void switchToTaskTab() {
    _tabController.animateTo(1);
    _loadTasks();
  }

  // ─── 提醒定时器 ─────────────────────────────
  void _startReminderTimer() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    final now = DateTime.now();
    for (var task in _tasks) {
      if (task.reminderTime != null && !task.isDone) {
        final diff = task.reminderTime!.difference(now);
        if (diff.inSeconds.abs() <= 60) {
          _showReminderDialog(task);
          setState(() {
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = _tasks[index].copyWith(reminderTime: null);
            }
          });
          _saveTasks();
        }
      }
    }
  }

  void _showReminderDialog(Task task) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.alarm, color: Colors.orange),
            SizedBox(width: 8),
            Text('⏰ 任务提醒'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('提醒时间到了！该完成任务了 🚀', style: TextStyle(color: Colors.grey.shade600)),
            const Text('⚡ 速通任务（建议30分钟内完成）', style: TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeQuickTask(task);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('现在完成'),
          ),
        ],
      ),
    );
  }

  // ─── 数据加载 ─────────────────────────────
  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('tasks') ?? [];
      setState(() {
        _tasks = jsonList
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
        _tasks = _tasks.where((t) => !t.isDone).toList();
        _tasks.sort((a, b) => _getPriorityScore(b).compareTo(_getPriorityScore(a)));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubtasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('subtasks') ?? [];
      setState(() {
        _subtasks = jsonList
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
      });
    } catch (e) {
      setState(() => _subtasks = []);
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _tasks.map((task) => jsonEncode(task.toJson())).toList();
      await prefs.setStringList('tasks', jsonList);
    } catch (e) {
      print('保存任务失败: $e');
    }
  }

  Future<void> _saveSubtasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _subtasks.map((st) => jsonEncode(st.toJson())).toList();
      await prefs.setStringList('subtasks', jsonList);
    } catch (e) {
      print('保存步骤失败: $e');
    }
  }

  // ─── 优先级评分 ─────────────────────────────
  int _getPriorityScore(Task task) {
    int score = 0;
    switch (task.urgency) {
      case Urgency.high: score += 300; break;
      case Urgency.medium: score += 200; break;
      case Urgency.low: score += 100; break;
    }
    switch (task.necessity) {
      case Necessity.critical: score += 30; break;
      case Necessity.important: score += 20; break;
      case Necessity.optional: score += 10; break;
    }
    switch (task.difficulty) {
      case Difficulty.hard: score += 3; break;
      case Difficulty.medium: score += 2; break;
      case Difficulty.easy: score += 1; break;
    }
    return score;
  }

  // ─── 筛选 ─────────────────────────────
  List<Task> _getFilteredTasks() {
    return _tasks.where((t) {
      final urgencyMatch = _urgencyFilter == '全部' || _urgencyLabel(t.urgency) == _urgencyFilter;
      final necessityMatch = _necessityFilter == '全部' || _necessityLabel(t.necessity) == _necessityFilter;
      return urgencyMatch && necessityMatch;
    }).toList();
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

  // ─── 速通任务操作 ─────────────────────────────
  void _addQuickTask(String title) {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务内容'), duration: Duration(seconds: 1)),
      );
      return;
    }
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      type: TaskType.quick,
      difficulty: Difficulty.medium,
      urgency: Urgency.medium,
      necessity: Necessity.important,
    );
    setState(() {
      _tasks.insert(0, newTask);
    });
    _saveTasks();
    _newTaskController.clear();
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 任务已添加'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _deleteTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    if (task.type == TaskType.explore) {
      _subtasks.removeWhere((st) => st.parentTaskId == id);
      _saveSubtasks();
    }
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    _saveTasks();
    _loadTasks();
  }

  // ─── 步骤操作 ─────────────────────────────
  void _addSubtask(String taskId, String title) {
    if (title.trim().isEmpty) return;
    final subtask = Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentTaskId: taskId,
      title: title.trim(),
    );
    setState(() {
      _subtasks.add(subtask);
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          subtaskIds: [..._tasks[index].subtaskIds, subtask.id],
        );
      }
    });
    _saveSubtasks();
    _saveTasks();
    _newSubtaskController.clear();
    _loadTasks();
  }

  void _deleteSubtask(String subtaskId) {
    final subtask = _subtasks.firstWhere((st) => st.id == subtaskId);
    final taskId = subtask.parentTaskId;
    setState(() {
      _subtasks.removeWhere((st) => st.id == subtaskId);
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(
          subtaskIds: _tasks[taskIndex].subtaskIds.where((id) => id != subtaskId).toList(),
        );
      }
    });
    _saveSubtasks();
    _saveTasks();
    _loadTasks();
  }

  // ─── 进度计算 ─────────────────────────────
  double _getProgress(String taskId) {
    final sub = _subtasks.where((st) => st.parentTaskId == taskId).toList();
    if (sub.isEmpty) return 0;
    final done = sub.where((st) => st.isDone).length;
    return done / sub.length;
  }

  int _getDoneCount(String taskId) {
    final sub = _subtasks.where((st) => st.parentTaskId == taskId).toList();
    return sub.where((st) => st.isDone).length;
  }

  int _getTotalCount(String taskId) {
    return _subtasks.where((st) => st.parentTaskId == taskId).length;
  }

  // ─── 保存到智库 ─────────────────────────────
  Future<void> _saveToWisdom({
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    try {
      final noteMap = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': content,
        'status': 'active',
        'editorMode': 'plain',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await _db.insertNote(noteMap);

      final folderId = await _db.ensureReviewFolder();
      await _db.attachNoteToNode(
        noteId: noteMap['id'] as String,
        title: title,
        parentId: folderId,
        tags: tags,
      );
    } catch (e) {
      print('保存到智库失败: $e');
    }
  }

  // ─── 设置速通任务提醒 ─────────────────────────────
  void _setReminder(Task task) async {
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    final initialTime = TimeOfDay(hour: oneHourLater.hour, minute: oneHourLater.minute);

    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (selected != null) {
      final reminderTime = DateTime(now.year, now.month, now.day, selected.hour, selected.minute);
      final finalReminderTime = reminderTime.isBefore(now) ? reminderTime.add(const Duration(days: 1)) : reminderTime;

      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(reminderTime: finalReminderTime);
        }
      });
      _saveTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ 提醒已设置：${_formatTime(finalReminderTime)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ─── 速通任务完成 ─────────────────────────────
  void _completeQuickTask(Task task) {
    _showQuickReviewDialog(task);
  }

  void _showQuickReviewDialog(Task task) {
    String? selectedEmoji;
    final contentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.sentiment_satisfied, color: Colors.orange),
                SizedBox(width: 8),
                Text('心情复盘'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('任务：${task.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEmojiButton('😊', selectedEmoji, (emoji) {
                        setDialogState(() => selectedEmoji = emoji);
                      }),
                      _buildEmojiButton('😐', selectedEmoji, (emoji) {
                        setDialogState(() => selectedEmoji = emoji);
                      }),
                      _buildEmojiButton('😞', selectedEmoji, (emoji) {
                        setDialogState(() => selectedEmoji = emoji);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '一句话总结...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('放弃', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final content = contentController.text.trim();
                  final emoji = selectedEmoji ?? '😊';
                  final summary = content.isNotEmpty ? content : '无总结';

                  await _saveToWisdom(
                    title: '复盘：${task.title}',
                    content: '心情：$emoji\n总结：$summary\n完成时间：${_formatDateTime(DateTime.now())}',
                    tags: ['复盘', '速通'],
                  );

                  setState(() {
                    _tasks.removeWhere((t) => t.id == task.id);
                  });
                  _saveTasks();
                  Navigator.of(dialogContext).pop();
                  _loadTasks();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ 任务已完成，已归档到智库 → 复盘文件夹')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('保存复盘'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String? selected, Function(String) onTap) {
    final isSelected = selected == emoji;
    return GestureDetector(
      onTap: () => onTap(emoji),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  // ─── 步骤复盘弹窗 ─────────────────────────────
  void _showSubtaskReviewDialog(Subtask subtask, Task parentTask) {
    String? selectedEmoji;
    final contentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.subdirectory_arrow_right, color: Colors.purple),
                SizedBox(width: 8),
                Text('步骤复盘'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${parentTask.title} → ${subtask.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEmojiButton('😊', selectedEmoji, (emoji) {
                        setDialogState(() => selectedEmoji = emoji);
                      }),
                      _buildEmojiButton('😐', selectedEmoji, (emoji) {
                        setDialogState(() => selectedEmoji = emoji);
                      }),
                      _buildEmojiButton('😞', selectedEmoji, (emoji) {
                        setDialogState(() => selectedEmoji = emoji);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '这个步骤做了什么？学到了什么？',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('放弃', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final content = contentController.text.trim();
                  final emoji = selectedEmoji ?? '😊';
                  final summary = content.isNotEmpty ? content : '无总结';

                  final reviewContent =
                      '### ${subtask.title}\n- 心情：$emoji\n- 总结：$summary\n- 完成时间：${_formatDateTime(DateTime.now())}\n';

                  await _saveSubtaskReview(subtask.id, reviewContent);

                  setState(() {
                    final index = _subtasks.indexWhere((st) => st.id == subtask.id);
                    if (index != -1) {
                      _subtasks[index] = _subtasks[index].copyWith(
                        isDone: true,
                        completedAt: DateTime.now(),
                      );
                    }
                  });
                  _saveSubtasks();

                  Navigator.of(dialogContext).pop();

                  final allDone = _checkAllSubtasksDone(parentTask.id);
                  if (allDone) {
                    _generateExploreNote(parentTask);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ 步骤已完成'), duration: Duration(seconds: 1)),
                      );
                    }
                    _loadTasks();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('保存复盘'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveSubtaskReview(String subtaskId, String review) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subtask_review_$subtaskId', review);
    } catch (e) {
      print('保存步骤复盘失败: $e');
    }
  }

  Future<String?> _getSubtaskReview(String subtaskId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('subtask_review_$subtaskId');
    } catch (e) {
      return null;
    }
  }

  bool _checkAllSubtasksDone(String taskId) {
    final subtasks = _subtasks.where((st) => st.parentTaskId == taskId).toList();
    if (subtasks.isEmpty) return false;
    return subtasks.every((st) => st.isDone);
  }

  // ─── 生成探究笔记 ─────────────────────────────
  Future<void> _generateExploreNote(Task task) async {
    final subtasks = _subtasks.where((st) => st.parentTaskId == task.id).toList();
    final List<String> reviews = [];

    for (var st in subtasks) {
      final review = await _getSubtaskReview(st.id);
      if (review != null) {
        reviews.add(review);
      } else {
        reviews.add('### ${st.title}\n- 无详细复盘\n');
      }
    }

    final allReviews = reviews.join('\n');

    final content = '''
# ${task.title}

## 📋 探究任务概述

${task.description ?? '无概述'}

---

## 📌 步骤复盘汇总

$allReviews

---

## 🎯 整体总结

（请在此写下整体总结...）

''';

    final tempNote = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '探究笔记：${task.title}',
      content: content,
      tags: ['探究', '复盘'],
      updatedAt: DateTime.now(),
      editorMode: 'markdown',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: tempNote,
          isFromCollection: false,
          onSave: (entry, title, content, mode, tags) async {
            final noteMap = {
              'id': entry.id,
              'title': title,
              'content': content,
              'status': 'active',
              'editorMode': mode,
              'updatedAt': DateTime.now().toIso8601String(),
            };
            await _db.insertNote(noteMap);

            final folderId = await _db.ensureReviewFolder();
            await _db.attachNoteToNode(
              noteId: entry.id,
              title: title,
              parentId: folderId,
              tags: tags,
            );

            setState(() {
              final index = _tasks.indexWhere((t) => t.id == task.id);
              if (index != -1) {
                _tasks[index] = _tasks[index].copyWith(
                  noteId: entry.id,
                  isDone: true,
                  completedAt: DateTime.now(),
                );
              }
            });
            _saveTasks();

            for (var st in subtasks) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('subtask_review_${st.id}');
            }

            return true;
          },
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
        _subtasks.removeWhere((st) => st.parentTaskId == task.id);
      });
      _saveTasks();
      _saveSubtasks();
      _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📚 探究笔记已保存到智库 → 复盘文件夹')),
      );
    }
  }

  void _toggleSubtask(String subtaskId, Task parentTask) {
    final subtask = _subtasks.firstWhere((st) => st.id == subtaskId);
    if (subtask.isDone) return;
    _showSubtaskReviewDialog(subtask, parentTask);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ─── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创作模块'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📝 写作'),
            Tab(text: '✅ 任务'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWritingTab(),
          _buildTaskTab(),
        ],
      ),
    );
  }

  Widget _buildWritingTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('📝 写作模式', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('点击智库中的笔记进入全屏编辑器', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTasks = _getFilteredTasks();

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '🎯 还没有任务',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '在采集页输入速通任务，或前往智库创建探究任务',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showQuickAddDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加速通任务'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final allDone = _tasks.every((t) => t.isDone);
    if (allDone && _tasks.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '🎉 所有任务已完成！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '复盘已归档到智库 → 复盘文件夹',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  ToggleButtons(
                    isSelected: [_viewMode == ViewMode.list, _viewMode == ViewMode.quadrant],
                    onPressed: (index) {
                      setState(() {
                        _viewMode = index == 0 ? ViewMode.list : ViewMode.quadrant;
                      });
                    },
                    children: const [Icon(Icons.list, size: 20), Icon(Icons.grid_view, size: 20)],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _newTaskController,
                      decoration: InputDecoration(
                        hintText: '⚡ 添加速通任务...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        _addQuickTask(value);
                        _newTaskController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _addQuickTask(_newTaskController.text);
                      _newTaskController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade800,
                    ),
                    child: const Text('添加'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('筛选：', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    _buildFilterChip('全部', _urgencyFilter, (value) { setState(() => _urgencyFilter = value); }),
                    _buildFilterChip('高', _urgencyFilter, (value) { setState(() => _urgencyFilter = value); }),
                    _buildFilterChip('中', _urgencyFilter, (value) { setState(() => _urgencyFilter = value); }),
                    _buildFilterChip('低', _urgencyFilter, (value) { setState(() => _urgencyFilter = value); }),
                    const SizedBox(width: 8),
                    _buildFilterChip('必要', _necessityFilter, (value) { setState(() => _necessityFilter = value); }),
                    _buildFilterChip('重要', _necessityFilter, (value) { setState(() => _necessityFilter = value); }),
                    _buildFilterChip('可选', _necessityFilter, (value) { setState(() => _necessityFilter = value); }),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 48, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text(
                        '🎉 所有任务已完成！',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '复盘已归档到智库 → 复盘文件夹',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : _viewMode == ViewMode.list
                  ? _buildListView(filteredTasks)
                  : _buildQuadrantView(filteredTasks),
        ),
      ],
    );
  }

  void _showQuickAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加速通任务'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入任务标题...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _addQuickTask(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              _addQuickTask(controller.text);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String current, Function(String) onSelected) {
    final isSelected = current == label;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => onSelected(label),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ─── 列表视图 ─────────────────────────────
  Widget _buildListView(List<Task> tasks) {
    final quickTasks = tasks.where((t) => t.type == TaskType.quick).toList();
    final exploreTasks = tasks.where((t) => t.type == TaskType.explore).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (exploreTasks.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('🔍 探究任务', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          ...exploreTasks.map((task) => _buildExploreTaskCard(task)),
          const SizedBox(height: 8),
        ],
        if (quickTasks.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('⚡ 速通任务', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          ...quickTasks.map((task) => _buildQuickTaskCard(task)),
        ],
      ],
    );
  }

  // ─── 优先级标签 ─────────────────────────────
  Widget _buildPriorityBadges(Task task) {
    Color urgencyColor;
    switch (task.urgency) {
      case Urgency.high: urgencyColor = Colors.red; break;
      case Urgency.medium: urgencyColor = Colors.orange; break;
      case Urgency.low: urgencyColor = Colors.green; break;
    }
    Color necessityColor;
    switch (task.necessity) {
      case Necessity.critical: necessityColor = Colors.red.shade700; break;
      case Necessity.important: necessityColor = Colors.blue; break;
      case Necessity.optional: necessityColor = Colors.grey; break;
    }
    final urgencyLabel = _urgencyLabel(task.urgency);
    final necessityLabel = _necessityLabel(task.necessity);
    final difficultyLabel = task.difficulty.label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: urgencyColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(urgencyLabel, style: TextStyle(fontSize: 10, color: urgencyColor, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: necessityColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(necessityLabel, style: TextStyle(fontSize: 10, color: necessityColor, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(difficultyLabel, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // ─── 速通任务卡片 ─────────────────────────────
  Widget _buildQuickTaskCard(Task task) {
    bool _isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        final hasReminder = task.reminderTime != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildPriorityBadges(task),
                const SizedBox(width: 10),
                Expanded(child: Text(task.title, style: const TextStyle(fontSize: 14))),
                const SizedBox(width: 8),
                Tooltip(
                  message: hasReminder ? '⏰ ${_formatTime(task.reminderTime!)}' : '设置提醒',
                  child: GestureDetector(
                    onTap: () => _setReminder(task),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasReminder ? Colors.orange.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasReminder ? Colors.orange.shade300 : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasReminder ? Icons.alarm : Icons.alarm_outlined,
                            size: 16,
                            color: hasReminder ? Colors.orange : Colors.grey.shade400,
                          ),
                          if (hasReminder) ...[
                            const SizedBox(width: 2),
                            Text(
                              _formatTime(task.reminderTime!),
                              style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: () => _completeQuickTask(task),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHovered ? Colors.green.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isHovered ? Colors.green.shade400 : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isHovered ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: _isHovered ? Colors.green.shade600 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHovered ? '完成' : '待办',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _isHovered ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => _deleteTask(task.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 探究任务卡片 ─────────────────────────────
  Widget _buildExploreTaskCard(Task task) {
    final isExpanded = _expandedTaskId == task.id;
    final total = _getTotalCount(task.id);
    final done = _getDoneCount(task.id);
    final progress = total > 0 ? done / total : 0.0;
    final isComplete = total > 0 && done == total;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedTaskId = isExpanded ? null : task.id;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildPriorityBadges(task),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: isComplete ? TextDecoration.lineThrough : null,
                            color: isComplete ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                      Text('$done/$total', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 4),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: Colors.grey),
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
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._subtasks
                      .where((st) => st.parentTaskId == task.id)
                      .map((st) => _buildSubtaskItem(st, task)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newSubtaskController,
                          decoration: const InputDecoration(
                            hintText: '➕ 添加步骤...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            _addSubtask(task.id, value);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.purple, size: 22),
                        onPressed: () {
                          _addSubtask(task.id, _newSubtaskController.text);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteTask(task.id),
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

  Widget _buildSubtaskItem(Subtask st, Task parentTask) {
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
                    onTap: () => _toggleSubtask(st.id, parentTask),
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
                  onPressed: () => _deleteSubtask(st.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── 四象限视图 ─────────────────────────────
  Widget _buildQuadrantView(List<Task> tasks) {
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
    bool _isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (task.type == TaskType.explore) {
                        setState(() {
                          _expandedTaskId = _expandedTaskId == task.id ? null : task.id;
                        });
                      } else {
                        _completeQuickTask(task);
                      }
                    },
                    child: Text(task.title, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (task.type == TaskType.explore) ...[
                  const SizedBox(width: 4),
                  Text('${_getDoneCount(task.id)}/${_getTotalCount(task.id)}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
                const SizedBox(width: 4),
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      if (task.type == TaskType.explore) {
                        setState(() {
                          _expandedTaskId = _expandedTaskId == task.id ? null : task.id;
                        });
                      } else {
                        _completeQuickTask(task);
                      }
                    },
                    child: Icon(
                      _isHovered ? Icons.check_circle : Icons.check_circle_outline,
                      size: 14,
                      color: _isHovered ? Colors.green : Colors.grey,
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