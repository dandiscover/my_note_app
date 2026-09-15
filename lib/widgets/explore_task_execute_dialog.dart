// lib/widgets/explore_task_execute_dialog.dart
// 探究任务执行弹窗 — 任务页点击探究卡片后弹出

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/explore_task.dart';
import '../models/note_subtask.dart';

class ExploreTaskExecuteDialog extends StatefulWidget {
  final NotebookEntry entry;

  const ExploreTaskExecuteDialog({
    super.key,
    required this.entry,
  });

  @override
  State<ExploreTaskExecuteDialog> createState() =>
      _ExploreTaskExecuteDialogState();
}

class _ExploreTaskExecuteDialogState
    extends State<ExploreTaskExecuteDialog> {
  late NotebookEntry _entry;
  final Set<String> _expandedTaskIds = {};
  final Set<String> _expandedAnswerIds = {}; // ✅ 新增：问答记录折叠状态
  String? _completingTaskId;
  final TextEditingController _findingController = TextEditingController();
  final TextEditingController _inquiryConclusionController =
      TextEditingController();
  bool _isSaving = false;
  bool _inquiryConclusionSaved = false;

  @override
  void initState() {
    super.initState();
    _entry = _deepCopyEntry(widget.entry);
    _inquiryConclusionController.text = _entry.inquiryConclusion ?? '';
    _inquiryConclusionSaved = _entry.inquiryConclusion != null;
  }

  @override
  void dispose() {
    _findingController.dispose();
    _inquiryConclusionController.dispose();
    super.dispose();
  }

  NotebookEntry _deepCopyEntry(NotebookEntry source) {
    return NotebookEntry(
      id: source.id,
      title: source.title,
      content: source.content,
      updatedAt: source.updatedAt,
      status: source.status,
      editorMode: source.editorMode,
      tags: List.from(source.tags),
      isLocked: source.isLocked,
      inquiryQuestion: source.inquiryQuestion,
      inquiryConclusion: source.inquiryConclusion,
      exploreTasks: source.exploreTasks.map((task) => ExploreTask(
        id: task.id,
        scaffoldCardType: task.scaffoldCardType,
        scaffoldAnswers: List.from(task.scaffoldAnswers),
        actions: task.actions.map((sub) => NoteSubtask(
          id: sub.id,
          title: sub.title,
          isDone: sub.isDone,
          completedAt: sub.completedAt,
          mood: sub.mood,
          moodSummary: sub.moodSummary,
          createdAt: sub.createdAt,
        )).toList(),
        findings: task.findings,
        status: task.status,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        completedAt: task.completedAt,
      )).toList(),
      contentFormat: source.contentFormat,   // ← 加这行
    );
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      _entry = _entry.copyWith(updatedAt: DateTime.now());
      await DatabaseService().updateNote(_entry.toMap());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _closeAndReturn() {
    Navigator.pop(context, _entry);
  }

  void _toggleExpand(String taskId) {
    setState(() {
      if (_expandedTaskIds.contains(taskId)) {
        _expandedTaskIds.remove(taskId);
      } else {
        _expandedTaskIds.add(taskId);
      }
    });
  }

  void _toggleAnswerExpand(String taskId) {
    setState(() {
      if (_expandedAnswerIds.contains(taskId)) {
        _expandedAnswerIds.remove(taskId);
      } else {
        _expandedAnswerIds.add(taskId);
      }
    });
  }

  bool _allSubtasksDone(List<NoteSubtask> actions) {
    if (actions.isEmpty) return false;
    return actions.every((a) => a.isDone);
  }

  int _doneCount(List<NoteSubtask> actions) {
    return actions.where((a) => a.isDone).length;
  }

  // ✅ 新增：计算剩余未完成行动数
  int get _remainingIncompleteActions {
    int count = 0;
    for (final task in _entry.exploreTasks) {
      if (task.status == ExploreTaskStatus.completed) continue;
      for (final action in task.actions) {
        if (!action.isDone) count++;
      }
    }
    return count;
  }

  // ✅ 新增：是否应简化复盘流程（剩余未完成行动数为 1 时）
  bool get _shouldSimplifyReview => _remainingIncompleteActions == 1;

  Future<void> _onSubtaskTap(ExploreTask parentTask, NoteSubtask subtask) async {
    if (subtask.isDone) return;
    if (_isSaving) return;

    // ✅ 在状态改变前记录简化状态
    final shouldSimplify = _shouldSimplifyReview;

    final result = await _showMoodDialog(context);
    if (result == null) return;

    final updatedActions = parentTask.actions.map((a) {
      if (a.id == subtask.id) {
        return a.copyWith(
          isDone: true,
          completedAt: DateTime.now(),
          mood: result['emoji'],
          moodSummary: result['summary'],
        );
      }
      return a;
    }).toList();

    var updatedTasks = _entry.exploreTasks.map((t) {
      if (t.id == parentTask.id) {
        return t.copyWith(actions: updatedActions, updatedAt: DateTime.now());
      }
      return t;
    }).toList();

    // ✅ 如果此前判定为简化复盘，完成最后一个行动后自动完成所属任务
    if (shouldSimplify) {
      updatedTasks = updatedTasks.map((t) {
        if (t.id == parentTask.id) {
          return t.copyWith(
            status: ExploreTaskStatus.completed,
            completedAt: DateTime.now(),
            updatedAt: DateTime.now(),
            findings: null, // 留空
          );
        }
        return t;
      }).toList();
    }

    setState(() {
      _entry = _entry.copyWith(exploreTasks: updatedTasks);
    });
    await _saveEntry();
  }

  Future<Map<String, String>?> _showMoodDialog(BuildContext context) async {
    String? selectedEmoji;
    final summaryController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hasSelected = selectedEmoji != null;
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.sentiment_satisfied, color: Colors.orange),
                SizedBox(width: 8),
                Text('心情复盘'),
              ],
            ),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('完成这个子任务，感觉如何？',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: '一句话总结（可选）',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: hasSelected
                    ? () {
                        Navigator.pop(dialogContext, {
                          'emoji': selectedEmoji!,
                          'summary': summaryController.text.trim(),
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSelected ? Colors.purple : Colors.grey.shade300,
                  foregroundColor: hasSelected ? Colors.white : Colors.grey.shade600,
                ),
                child: const Text('确认'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmojiButton(
    String emoji,
    String? selected,
    void Function(String) onTap,
  ) {
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

  void _startCompletingTask(String taskId) {
    setState(() {
      _completingTaskId = taskId;
      _findingController.clear();
    });
  }

  void _cancelCompletingTask() {
    setState(() {
      _completingTaskId = null;
      _findingController.clear();
    });
  }

  Future<void> _saveFinding(String taskId) async {
    final text = _findingController.text.trim();
    if (text.isEmpty) return;

    final updatedTasks = _entry.exploreTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          findings: text,
          status: ExploreTaskStatus.completed,
          completedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return t;
    }).toList();

    setState(() {
      _entry = _entry.copyWith(exploreTasks: updatedTasks);
      _completingTaskId = null;
      _findingController.clear();
    });
    await _saveEntry();
  }

  Future<void> _saveInquiryConclusion() async {
    final text = _inquiryConclusionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _entry = _entry.copyWith(
        inquiryConclusion: text,
        updatedAt: DateTime.now(),
      );
      _inquiryConclusionSaved = true;
    });
    await _saveEntry();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 探究结论已保存，探究完成'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _allTasksCompleted() {
    if (_entry.exploreTasks.isEmpty) return false;
    return _entry.exploreTasks.every((t) =>
        t.status == ExploreTaskStatus.completed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 标题栏 ──────────────────────────────
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.purple, size: 22),
                const SizedBox(width: 8),
                const Text(
                  '🔍 探究执行',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeAndReturn,
                  tooltip: '关闭',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 16),

            // ─── 主问题 ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                '🎯 ${_entry.inquiryQuestion ?? "未设置主问题"}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 任务列表 ──────────────────────────────
            Expanded(
              child: _entry.exploreTasks.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无探究任务',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: _entry.exploreTasks.asMap().entries.map(
                          (entry) {
                            final idx = entry.key;
                            final task = entry.value;
                            return _buildTaskCard(task, idx);
                          },
                        ).toList(),
                      ),
                    ),
            ),

            // ─── 探究结论区域（所有任务完成后显示） ────
            if (_allTasksCompleted()) ...[
              const Divider(height: 16),
              _buildInquiryConclusionArea(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(ExploreTask task, int index) {
    final isExpanded = _expandedTaskIds.contains(task.id);
    final doneCount = _doneCount(task.actions);
    final totalCount = task.actions.length;
    final allDone = _allSubtasksDone(task.actions);
    final isCompleted = task.status == ExploreTaskStatus.completed;
    final isCompleting = _completingTaskId == task.id;
    final taskName = task.scaffoldCardType ?? '任务 ${index + 1}';
    final isAnswerExpanded = _expandedAnswerIds.contains(task.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          width: isCompleted ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 卡片头部 ──────────────────────────────
          InkWell(
            onTap: () => _toggleExpand(task.id),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.chevron_right,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              taskName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? Colors.green.shade700 : Colors.black87,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '已完成',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (totalCount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$doneCount / $totalCount 个子任务',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted ? Colors.green.shade600 : Colors.grey.shade600,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            '暂无子任务',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        if (isCompleted && task.completedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '完成于 ${_formatDate(task.completedAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isCompleted && task.findings != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.note, color: Colors.grey.shade400, size: 16),
                    ),
                ],
              ),
            ),
          ),

          // ─── 展开内容 ──────────────────────────────
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 子任务列表
                  if (task.actions.isNotEmpty)
                    ...task.actions.map((subtask) =>
                        _buildSubtaskItem(subtask, task)),
                  if (task.actions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '暂无子任务',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  // ✅ 问答记录折叠展示
                  if (task.scaffoldAnswers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _toggleAnswerExpand(task.id),
                      child: Row(
                        children: [
                          Icon(
                            isAnswerExpanded
                                ? Icons.expand_less
                                : Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '问答记录',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAnswerExpanded)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: task.scaffoldAnswers.map((answer) {
                            final label = answer['label']?.toString() ?? '';
                            final value = answer['value']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    value,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],

                  // 已完成任务的发现展示
                  if (isCompleted && task.findings != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💡 发现',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.findings!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 完成行动区域（仅当所有子任务完成且任务未完成时）
                  // ✅ 修正：不再受简化流程影响，避免多任务死锁
                  if (allDone && !isCompleted) ...[
                    const SizedBox(height: 10),
                    if (isCompleting) ...[
                      _buildFindingInputArea(task.id),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _startCompletingTask(task.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('✅ 完成行动'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(NoteSubtask subtask, ExploreTask parentTask) {
    final isDone = subtask.isDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: isDone ? null : () => _onSubtaskTap(parentTask, subtask),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: isDone ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey.shade500 : Colors.black87,
                  ),
                ),
                if (isDone && subtask.moodSummary != null) ...[
                  Text(
                    '💭 ${subtask.moodSummary}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDone && subtask.mood != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                subtask.mood!,
                style: const TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFindingInputArea(String taskId) {
    final hasText = _findingController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 写下你的发现',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _findingController,
          maxLines: 2,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '这个行动给你带来了什么启发？',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelCompletingTask,
              child: const Text('取消'),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: hasText ? () => _saveFinding(taskId) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasText ? Colors.purple : Colors.grey.shade300,
                foregroundColor: hasText ? Colors.white : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
              child: const Text('保存发现'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInquiryConclusionArea() {
    final hasText = _inquiryConclusionController.text.trim().isNotEmpty;
    final isReadOnly = _inquiryConclusionSaved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 探究结论',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _inquiryConclusionController,
          maxLines: 3,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            hintText: isReadOnly ? '' : '写下你的探究结论...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: isReadOnly ? Colors.green.shade50 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(12),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (!isReadOnly) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: hasText ? _saveInquiryConclusion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasText ? Colors.purple : Colors.grey.shade300,
                  foregroundColor: hasText ? Colors.white : Colors.grey.shade600,
                ),
                child: const Text('保存探究结论'),
              ),
            ],
          ),
        ],
        if (isReadOnly) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '✅ 已保存',
              style: TextStyle(fontSize: 11, color: Colors.green),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}