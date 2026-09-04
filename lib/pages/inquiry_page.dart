// lib/pages/inquiry_page.dart
// 深度笔记 — 多任务探究
// ✅ 多任务状态管理：_exploreTasks + _currentTaskIndex
// ✅ 新理解按钮常驻，绑定主问题
// ✅ newUnderstanding != null 时隐藏“新增拐杖卡”
// ✅ 最小一步卡展开（三问 + 存 scaffoldAnswers）
// ✅ 行动区跟随当前任务
// ✅ 新理解保存时立即持久化
// ✅ 新理解编辑时保持文案同步
// ✅ 当前编辑的空任务在任务列表中可见
// ✅ _switchTask 用 id 定位，避免越界

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/note_subtask.dart';
import '../models/explore_task.dart';

class InquiryPage extends StatefulWidget {
  final NotebookEntry entry;

  const InquiryPage({
    super.key,
    required this.entry,
  });

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();

  // ─── 多任务状态 ─────────────────────────────
  List<ExploreTask> _exploreTasks = [];
  int _currentTaskIndex = 0;

  // ─── 最小一步卡三问 ─────────────────────────
  bool _isScaffoldEditing = false;
  late TextEditingController _q1Controller;
  late TextEditingController _q2Controller;
  late TextEditingController _q3Controller;

  // ─── 新理解 ─────────────────────────────────
  bool _isNewUnderstandingEditing = false;
  String? _newUnderstanding;
  late TextEditingController _understandingController;

  // ─── 计算属性 ──────────────────────────────
  bool get _isCompleted => _newUnderstanding != null;

  String get _currentQuestionText =>
      _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : (widget.entry.inquiryQuestion ?? '这个探究问题');

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.entry.inquiryQuestion ?? '';
    _newUnderstanding = widget.entry.newUnderstanding;
    _understandingController = TextEditingController(text: _newUnderstanding ?? '');

    _q1Controller = TextEditingController();
    _q2Controller = TextEditingController();
    _q3Controller = TextEditingController();

    _exploreTasks = List.from(widget.entry.exploreTasks);
    if (_exploreTasks.isEmpty) {
      _exploreTasks.add(ExploreTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    }
    _currentTaskIndex = _exploreTasks.length - 1;
    _loadScaffoldAnswers();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _subtaskController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    _understandingController.dispose();
    super.dispose();
  }

  // ─── 三问同步 ──────────────────────────────

  void _loadScaffoldAnswers() {
    final answers = _exploreTasks[_currentTaskIndex].scaffoldAnswers;
    _q1Controller.text = answers.length > 0 ? answers[0]['value'] ?? '' : '';
    _q2Controller.text = answers.length > 1 ? answers[1]['value'] ?? '' : '';
    _q3Controller.text = answers.length > 2 ? answers[2]['value'] ?? '' : '';
  }

  void _switchTask(int index) {
    // ✅ 保存目标任务的 id，避免删除空任务后索引变化导致越界
    final targetId = _exploreTasks[index].id;

    // 如果正在编辑，先处理取消（可能删除空任务）
    if (_isScaffoldEditing) {
      _cancelScaffoldEditingInternal();
    }

    // 在更新后的列表中按 id 查找目标
    final newIndex = _exploreTasks.indexWhere((t) => t.id == targetId);
    if (newIndex == -1) {
      // 兜底：理论上不会发生
      setState(() {
        _currentTaskIndex = _exploreTasks.length - 1;
        _loadScaffoldAnswers();
        _isScaffoldEditing = false;
      });
      return;
    }

    setState(() {
      _currentTaskIndex = newIndex;
      _loadScaffoldAnswers();
      _isScaffoldEditing = false;
    });
  }

  // ─── 新增拐杖卡 ─────────────────────────────

  void _addScaffoldCard() {
    final newTask = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    setState(() {
      _exploreTasks.add(newTask);
      _currentTaskIndex = _exploreTasks.length - 1;
      _q1Controller.clear();
      _q2Controller.clear();
      _q3Controller.clear();
      _isScaffoldEditing = true;
    });
  }

  void _saveScaffoldAnswers() {
    final current = _exploreTasks[_currentTaskIndex];
    final answers = [
      {'label': '现在最困扰我的是什么？', 'value': _q1Controller.text.trim()},
      {'label': '我能做的最小一步是什么？', 'value': _q2Controller.text.trim()},
      {'label': '做完这一步会怎样？', 'value': _q3Controller.text.trim()},
    ];
    _exploreTasks[_currentTaskIndex] = current.copyWith(
      scaffoldCardType: current.scaffoldCardType ?? 'minimal_step',
      scaffoldAnswers: answers,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _isScaffoldEditing = false;
    });
  }

  void _cancelScaffoldEditing() {
    _cancelScaffoldEditingInternal();
    setState(() {});
  }

  void _cancelScaffoldEditingInternal() {
    final current = _exploreTasks[_currentTaskIndex];
    if (current.scaffoldCardType == null && current.actions.isEmpty) {
      _exploreTasks.removeAt(_currentTaskIndex);
      if (_exploreTasks.isEmpty) {
        _exploreTasks.add(ExploreTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        ));
      }
      _currentTaskIndex = _exploreTasks.length - 1;
      _loadScaffoldAnswers();
    } else {
      _loadScaffoldAnswers();
    }
    _isScaffoldEditing = false;
  }

  // ─── 行动区 ─────────────────────────────────

  void _addAction() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    final current = _exploreTasks[_currentTaskIndex];
    final newAction = NoteSubtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    _exploreTasks[_currentTaskIndex] = current.copyWith(
      actions: [...current.actions, newAction],
      updatedAt: DateTime.now(),
    );
    _subtaskController.clear();
    setState(() {});
  }

  void _toggleAction(String id) {
    final current = _exploreTasks[_currentTaskIndex];
    final actions = current.actions.map((a) {
      if (a.id == id) {
        return a.copyWith(
          isDone: !a.isDone,
          completedAt: a.isDone ? null : DateTime.now(),
        );
      }
      return a;
    }).toList();
    _exploreTasks[_currentTaskIndex] = current.copyWith(
      actions: actions,
      updatedAt: DateTime.now(),
    );
    setState(() {});
  }

  void _deleteAction(String id) {
    final current = _exploreTasks[_currentTaskIndex];
    final actions = current.actions.where((a) => a.id != id).toList();
    _exploreTasks[_currentTaskIndex] = current.copyWith(
      actions: actions,
      updatedAt: DateTime.now(),
    );
    setState(() {});
  }

  // ─── 新理解 ─────────────────────────────────

  void _toggleNewUnderstandingEditing() {
    if (_isNewUnderstandingEditing) {
      _understandingController.text = _newUnderstanding ?? '';
      setState(() {
        _isNewUnderstandingEditing = false;
      });
    } else {
      setState(() {
        _isNewUnderstandingEditing = true;
      });
    }
  }

  void _saveNewUnderstanding() async {
    final text = _understandingController.text.trim();
    if (text.isEmpty) return;

    final filteredTasks = _filterEmptyTasks(_exploreTasks);
    final updated = widget.entry.copyWith(
      inquiryQuestion: _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : null,
      newUnderstanding: text,
      exploreTasks: filteredTasks,
      updatedAt: DateTime.now(),
    );
    await _db.updateNote(updated.toMap());

    setState(() {
      _newUnderstanding = text;
      _isNewUnderstandingEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 新理解已保存，探究结束')),
      );
    }
  }

  // ─── 保存 ─────────────────────────────────

  List<ExploreTask> _filterEmptyTasks(List<ExploreTask> tasks) {
    return tasks.where((task) {
      return task.scaffoldCardType != null || task.actions.isNotEmpty;
    }).toList();
  }

  Future<void> _saveAndReturn() async {
    final filteredTasks = _filterEmptyTasks(_exploreTasks);
    final updated = widget.entry.copyWith(
      inquiryQuestion: _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : null,
      newUnderstanding: _newUnderstanding,
      exploreTasks: filteredTasks,
      updatedAt: DateTime.now(),
    );
    await _db.updateNote(updated.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 已保存')),
      );
      Navigator.pop(context, updated);
    }
  }

  // ─── UI ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentTask = _exploreTasks[_currentTaskIndex];
    final hasTasks = _exploreTasks.any((t) => t.scaffoldCardType != null || t.actions.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 深度笔记'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 探究问题 ────────────────────────────
              const Text(
                '🎯 探究问题',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '现在最困扰我的是什么？',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // ─── 最小一步卡（展开/编辑） ────────────
              _buildScaffoldCard(currentTask),

              const SizedBox(height: 16),

              // ─── 行动区（仅当任务有拐杖卡类型时显示） ──
              if (currentTask.scaffoldCardType != null) ...[
                Row(
                  children: [
                    const Text(
                      '🚀 行动',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${currentTask.actions.length} 步',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: InputDecoration(
                          hintText: '输入行动...',
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
                ...currentTask.actions.map((action) => _buildActionItem(action)),
                const SizedBox(height: 12),
              ],

              // ─── 任务列表 ──────────────────────────────
              if (hasTasks || _exploreTasks.isNotEmpty) ...[
                const Text(
                  '📦 探究任务',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ..._exploreTasks
                    .asMap()
                    .entries
                    .where((entry) =>
                        entry.value.scaffoldCardType != null ||
                        entry.value.actions.isNotEmpty ||
                        entry.key == _currentTaskIndex)
                    .map((entry) => _buildTaskItem(entry.value, entry.key)),
                const SizedBox(height: 12),
              ],

              // ─── 新增拐杖卡按钮 ──────────────────────
              if (!_isCompleted) ...[
                TextButton.icon(
                  onPressed: _addScaffoldCard,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('＋ 新增拐杖卡'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── 新理解 ──────────────────────────────
              const Divider(height: 24),
              if (_isNewUnderstandingEditing) ...[
                Text(
                  '💡 现在，你怎么理解「$_currentQuestionText」？',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _understandingController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '写下你的新理解...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _toggleNewUnderstandingEditing,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveNewUnderstanding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('保存新理解'),
                    ),
                  ],
                ),
              ] else if (_newUnderstanding != null) ...[
                // 已完成状态（只读）
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _newUnderstanding!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          _understandingController.text = _newUnderstanding ?? '';
                          setState(() {
                            _isNewUnderstandingEditing = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 未完成：显示点击入口
                Text(
                  '💡 现在，你怎么理解「$_currentQuestionText」？',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _toggleNewUnderstandingEditing,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text(
                        '✍️ 点击写下新理解',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndReturn,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─── 子组件 ─────────────────────────────────

  Widget _buildScaffoldCard(ExploreTask task) {
    final hasAnswers = task.scaffoldAnswers.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200, width: 0.5),
      ),
      child: _isScaffoldEditing
          ? _buildScaffoldEditor()
          : _buildScaffoldCardContent(task, hasAnswers),
    );
  }

  Widget _buildScaffoldCardContent(ExploreTask task, bool hasAnswers) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loadScaffoldAnswers();
          _isScaffoldEditing = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text('🧭 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最小一步卡',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                  if (hasAnswers) ...[
                    const SizedBox(height: 4),
                    Text(
                      '✅ 已回答',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      '💡 点我开始',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffoldEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧭 最小一步卡 — 三问',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuestionInput(
            label: '1. 现在最困扰我的是什么？',
            controller: _q1Controller,
          ),
          const SizedBox(height: 8),
          _buildQuestionInput(
            label: '2. 我能做的最小一步是什么？',
            controller: _q2Controller,
          ),
          const SizedBox(height: 8),
          _buildQuestionInput(
            label: '3. 做完这一步会怎样？',
            controller: _q3Controller,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelScaffoldEditing,
                child: const Text('取消', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveScaffoldAnswers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('保存', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActionItem(NoteSubtask action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: action.isDone ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: action.isDone ? Colors.green.shade200 : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleAction(action.id),
            child: Icon(
              action.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: action.isDone ? Colors.green : Colors.grey.shade500,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action.title,
              style: TextStyle(
                fontSize: 14,
                decoration: action.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                color: action.isDone ? Colors.grey.shade500 : Colors.black87,
              ),
            ),
          ),
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

  Widget _buildTaskItem(ExploreTask task, int index) {
    final isActive = index == _currentTaskIndex;
    final actionCount = task.actions.length;
    final cardType = task.scaffoldCardType ?? '编辑中...';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.purple.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.purple.shade200 : Colors.grey.shade200,
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: GestureDetector(
        onTap: () => _switchTask(index),
        child: Row(
          children: [
            const Icon(Icons.task, size: 16, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardType,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? Colors.purple : Colors.black87,
                    ),
                  ),
                  Text(
                    actionCount > 0 ? '$actionCount 个行动' : '编辑中...',
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.purple.shade600 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (task.status == ExploreTaskStatus.completed) ...[
              const Text('✅', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}