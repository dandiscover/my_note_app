// lib/pages/creation_page.dart
// 创作模块 — 添加云端同步
// ✅ 修复复盘弹窗：取消“放弃”按钮，心情必须选择才能保存
// ✅ 适配 FullscreenEditor 新签名：onSave 增加 inquiryQuestion 参数
// ✅ 新增：探究任务自动判定（扫描笔记三条件：问题 + 云核 + 行动）

import '../models/card.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/card_service.dart';
import '../services/sync/cloud_sync_service.dart';
import '../services/sync/sync_manager.dart';
import '../mixins/state_mixin.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/task/task_toolbar.dart';
import '../widgets/task/task_list_view.dart';
import '../widgets/task/quadrant_view.dart';
import '../widgets/quick_task_card.dart';
import '../widgets/writing/material_panel.dart';
import 'inquiry_page.dart';
import '../widgets/floating_pet.dart';
import 'writing_page.dart';
import '../utils/app_date_utils.dart';

enum ViewMode { list, quadrant }

class CreationPage extends StatefulWidget {
  const CreationPage({super.key});

  @override
  CreationPageState createState() => CreationPageState();
}

class CreationPageState extends State<CreationPage>
    with StateMixin, SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();
  final TaskService _taskService = TaskService();

  List<Task> _tasks = [];
  List<Subtask> _subtasks = [];
  final TextEditingController _newTaskController = TextEditingController();

  ViewMode _viewMode = ViewMode.list;
  String _urgencyFilter = '全部';
  String _necessityFilter = '全部';
  Timer? _reminderTimer;
  String? _expandedTaskId;

  late TabController _tabController;
  List<CardModel> _indexCards = [];
  List<NotebookEntry> _exploreNotes = [];

  Future<void> refreshTasks() async {
    await _loadTasks();
    await _loadIndexCards();
    await _loadExploreNotes();
  }

  void switchToTaskTab() {
    _tabController.animateTo(1);
    _loadTasks();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
    _loadIndexCards();
    _loadExploreNotes();
    _startReminderTimer();
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    _reminderTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadIndexCards() async {
    try {
      final allCards = await _cardService.getAllCards();
      setState(() { _indexCards = allCards.where((c) => c.cardType == CardType.indexCard).toList(); });
    } catch (e) { print('加载索引卡失败: $e'); }
  }

  Future<void> _loadTasks() async {
    isLoading = true;
    try {
      _tasks = await _taskService.loadAllTasks();
      _subtasks = await _taskService.loadAllSubtasks();
      _tasks = _tasks.where((t) => !t.isDone).toList();
      _tasks.sort((a, b) => _getPriorityScore(b).compareTo(_getPriorityScore(a)));
    } catch (e) { print('加载任务失败: $e'); }
    isLoading = false;
  }

  Future<void> _loadExploreNotes() async {
    try {
      final allNotes = await _db.getAllNotes(includeDeleted: false);
      final notes = allNotes.map((m) => NotebookEntry.fromMap(m)).toList();
      final exploreNotes = notes.where((note) {
        final hasQuestion = note.inquiryQuestion != null && note.inquiryQuestion!.isNotEmpty;
        final hasScaffold = note.scaffoldSessions.isNotEmpty;
        final hasSubtasks = note.subtasks.isNotEmpty;
        return hasQuestion && hasScaffold && hasSubtasks;
      }).toList();
      setState(() {
        _exploreNotes = exploreNotes;
      });
    } catch (e) {
      print('加载探究任务失败: $e');
    }
  }

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

  // ✅ 添加任务时同步
  Future<void> _addQuickTask(String title) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入任务内容'), duration: Duration(seconds: 1)));
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
    await _taskService.addTask(newTask);
    await _loadTasks();
    _newTaskController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 任务已添加'), duration: Duration(seconds: 1)));
  }

  Future<void> _deleteTask(String id) async {
    final task = _tasks.firstWhere((t) => t.id == id);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除任务 "${task.title}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _taskService.deleteTask(id);
      await _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除任务'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _completeQuickTask(Task task) async {
    await _showQuickReviewDialog(task);
  }

  /// ✅ 修复复盘弹窗：
  /// - 取消“放弃”按钮
  /// - 必须选择心情才能保存
  /// - 总结可为空
  Future<void> _showQuickReviewDialog(Task task) async {
    String? selectedEmoji;
    final contentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // ✅ 判断是否有选择心情
          final bool hasSelectedEmoji = selectedEmoji != null;

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
              // ✅ 只保留“保存复盘”按钮，且未选心情时置灰
              ElevatedButton(
                onPressed: hasSelectedEmoji
                    ? () {
                        Navigator.pop(dialogContext, {
                          'emoji': selectedEmoji!,
                          'content': contentController.text.trim(),
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSelectedEmoji ? Colors.green : Colors.grey.shade300,
                  foregroundColor: hasSelectedEmoji ? Colors.white : Colors.grey.shade600,
                ),
                child: const Text('保存复盘'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await _saveToWisdom(
        title: '复盘：${task.title}',
        content: '心情：${result['emoji']}\n总结：${result['content']}\n完成时间：${AppDateUtils.formatFull(DateTime.now())}',
        tags: ['复盘', '速通'],
      );
      await _taskService.deleteTask(task.id);
      await _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 任务已完成，已归档到智库 → 复盘文件夹'), duration: Duration(seconds: 2)));
    }
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

  Future<void> _toggleSubtask(Subtask subtask, Task parentTask) async {
    if (subtask.isDone) return;
    await _showSubtaskReviewDialog(subtask, parentTask);
  }

  Future<void> _showSubtaskReviewDialog(Subtask subtask, Task parentTask) async {
    String? selectedEmoji;
    final contentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bool hasSelectedEmoji = selectedEmoji != null;

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
              ElevatedButton(
                onPressed: hasSelectedEmoji
                    ? () {
                        Navigator.pop(dialogContext, {
                          'emoji': selectedEmoji!,
                          'content': contentController.text.trim(),
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSelectedEmoji ? Colors.purple : Colors.grey.shade300,
                  foregroundColor: hasSelectedEmoji ? Colors.white : Colors.grey.shade600,
                ),
                child: const Text('保存复盘'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await _saveSubtaskReview(subtask.id, result);
      final updated = subtask.copyWith(isDone: true, completedAt: DateTime.now());
      await _taskService.updateSubtask(updated);
      await _loadTasks();

      final allSubtasks = await _taskService.loadSubtasksForTask(parentTask.id);
      final allDone = allSubtasks.every((s) => s.isDone);
      if (allDone && allSubtasks.isNotEmpty) {
        await _generateExploreNote(parentTask);
      }
    }
  }

  Future<void> _saveSubtaskReview(String subtaskId, Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subtask_review_$subtaskId', jsonEncode(result));
  }

  Future<Map<String, dynamic>?> _getSubtaskReview(String subtaskId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('subtask_review_$subtaskId');
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> _generateExploreNote(Task task) async {
    final subtasks = await _taskService.loadSubtasksForTask(task.id);
    final List<String> reviews = [];

    for (var st in subtasks) {
      final review = await _getSubtaskReview(st.id);
      if (review != null) {
        reviews.add('### ${st.title}\n- 心情：${review['emoji']}\n- 总结：${review['content']}\n');
      } else {
        reviews.add('### ${st.title}\n- 无详细复盘\n');
      }
    }

    final content = '''
# ${task.title}

## 📋 探究任务概述

${task.description ?? '无概述'}

---

## 📌 步骤复盘汇总

${reviews.join('\n')}

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

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: tempNote,
          isFromCollection: false,
          onSave: (entry, title, content, mode, tags, inquiryQuestion) async {
            final noteMap = {
              'id': entry.id,
              'title': title,
              'content': content,
              'status': 'active',
              'editorMode': mode,
              'updatedAt': DateTime.now().toIso8601String(),
              'inquiryQuestion': inquiryQuestion,
            };
            await _db.insertNote(noteMap);
            final folderId = await _db.ensureReviewFolder();
            await _db.attachNoteToNode(noteId: entry.id, title: title, parentId: folderId, tags: tags);
            for (var st in subtasks) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('subtask_review_${st.id}');
            }
            // ✅ 同步到云端
            if (CloudSyncService().isLoggedIn) {
              try {
                final note = NotebookEntry.fromMap(noteMap);
                await CloudSyncService().syncNote(note);
                final node = await _db.getNode(entry.id);
                if (node != null) await CloudSyncService().syncNode(node);
              } catch (_) {
                SyncManager().markDirty();
              }
            }
            await _taskService.deleteTask(task.id);
            await _loadTasks();
            return true;
          },
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📚 探究笔记已保存到智库 → 复盘文件夹'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _saveToWisdom({required String title, required String content, required List<String> tags}) async {
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
      await _db.attachNoteToNode(noteId: noteMap['id'] as String, title: title, parentId: folderId, tags: tags);
      // ✅ 同步到云端
      if (CloudSyncService().isLoggedIn) {
        try {
          final note = NotebookEntry.fromMap(noteMap);
          await CloudSyncService().syncNote(note);
        } catch (_) {
          SyncManager().markDirty();
        }
      }
    } catch (e) { print('保存到智库失败: $e'); }
  }

  Future<void> _setReminder(Task task) async {
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));
    final initialTime = TimeOfDay(hour: oneHourLater.hour, minute: oneHourLater.minute);

    final selected = await showTimePicker(context: context, initialTime: initialTime);
    if (selected != null) {
      final reminderTime = DateTime(now.year, now.month, now.day, selected.hour, selected.minute);
      final finalReminderTime = reminderTime.isBefore(now) ? reminderTime.add(const Duration(days: 1)) : reminderTime;
      final updated = task.copyWith(reminderTime: finalReminderTime);
      await _taskService.updateTask(updated);
      await _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⏰ 提醒已设置：${_formatTime(finalReminderTime)}'), duration: Duration(seconds: 1)),
      );
    }
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _startReminderTimer() {
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) => _checkReminders());
  }

  void _checkReminders() {
    final now = DateTime.now();
    for (var task in _tasks) {
      if (task.reminderTime != null && !task.isDone) {
        final diff = task.reminderTime!.difference(now);
        if (diff.inSeconds.abs() <= 60) {
          _showReminderDialog(task);
          _taskService.updateTask(task.copyWith(reminderTime: null));
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
        title: Row(children: const [Icon(Icons.alarm, color: Colors.orange), SizedBox(width: 8), Text('⏰ 任务提醒')]),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _completeQuickTask(task); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('现在完成'),
          ),
        ],
      ),
    );
  }

  void _openMaterialPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => MaterialPanel(
          cards: _indexCards,
          onInsertText: (text) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📝 已引用：$text'), duration: const Duration(seconds: 2))); Navigator.pop(context); },
          onInsertCard: (card) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📇 已插入卡片：${card.indexTitle ?? '未命名'}'), duration: const Duration(seconds: 2))); Navigator.pop(context); },
        ),
      ),
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
          onSubmitted: (value) { _addQuickTask(value); Navigator.pop(context); },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () { _addQuickTask(controller.text); Navigator.pop(context); },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSubtask(String taskId, String title) async {
    if (title.trim().isEmpty) return;
    final subtask = Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentTaskId: taskId,
      title: title.trim(),
    );
    await _taskService.addSubtask(subtask);
    await _loadTasks();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('步骤已添加'), duration: Duration(seconds: 1)));
  }

  Widget _buildExploreTaskCard(NotebookEntry note) {
    return ListTile(
      leading: const Icon(Icons.explore, color: Colors.purple),
      title: Text(note.title),
      subtitle: Text(
        note.inquiryQuestion ?? '探究中...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final updatedNote = await Navigator.push<NotebookEntry>(
          context,
          MaterialPageRoute(
            builder: (_) => InquiryPage(entry: note),
          ),
        );
        if (updatedNote != null) {
          await refreshTasks();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredTasks = _getFilteredTasks();

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
          _buildTaskTab(filteredTasks),
        ],
      ),
    );
  }

  Widget _buildWritingTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('📝 写作模式', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('进入全屏写作环境，调用素材库', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WritingPage(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('开始写作'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTab(List<Task> filteredTasks) {
    if (_tasks.isEmpty && _exploreNotes.isEmpty) return _buildEmptyState();
    final allDone = _tasks.every((t) => t.isDone) && _exploreNotes.isEmpty;
    if (allDone && _tasks.isNotEmpty) return _buildAllDoneState();

    final quickTasks = filteredTasks;

    return Column(
      children: [
        TaskToolbar(
          textController: _newTaskController,
          viewMode: _viewMode,
          onViewModeChanged: (mode) => setState(() => _viewMode = mode),
          urgencyFilter: _urgencyFilter,
          onUrgencyFilterChanged: (value) => setState(() => _urgencyFilter = value),
          necessityFilter: _necessityFilter,
          onNecessityFilterChanged: (value) => setState(() => _necessityFilter = value),
          onAddTask: (value) => _addQuickTask(value),
        ),
        Expanded(
          child: (quickTasks.isEmpty && _exploreNotes.isEmpty)
              ? _buildNoTasksState()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── 速通任务区块 ──────────────────────────
                        if (quickTasks.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('⚡ 速通任务', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                          ...quickTasks.map((task) => QuickTaskCard(
                            key: ValueKey('quick_${task.id}'),
                            task: task,
                            onComplete: () => _completeQuickTask(task),
                            onDelete: () => _deleteTask(task.id),
                            onSetReminder: () => _setReminder(task),
                          )),
                        ],
                        // ─── 探究任务区块 ──────────────────────────
                        if (_exploreNotes.isNotEmpty) ...[
                          if (quickTasks.isNotEmpty) const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('🔍 探究任务', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          ),
                          ..._exploreNotes.map((note) => _buildExploreTaskCard(note)),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.task_alt, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('🎯 还没有任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('在采集页输入速通任务，或前往智库创建探究任务', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showQuickAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加速通任务'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDoneState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text('🎉 所有任务已完成！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('复盘已归档到智库 → 复盘文件夹', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildNoTasksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          const Text('🎉 所有任务已完成！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}