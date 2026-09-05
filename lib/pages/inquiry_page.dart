// lib/pages/inquiry_page.dart
// 深度笔记 — 多任务探究
// ✅ 多任务状态管理：_exploreTasks + _currentTaskIndex
// ✅ 新理解按钮常驻，绑定主问题
// ✅ newUnderstanding != null 时隐藏"新增拐杖卡"
// ✅ 最小一步卡展开（三问 + 存 scaffoldAnswers）
// ✅ 行动区跟随当前任务
// ✅ 新理解保存时立即持久化
// ✅ 新理解编辑时保持文案同步
// ✅ 当前编辑的空任务在任务列表中可见
// ✅ _switchTask 用 id 定位，避免越界
// ✅ 新增 isDialog 模式：弹窗内逐步展开三问，行动添加，折叠任务，再探究，完成回传
// ✅ 弹窗模式：已有任务只读展示，新建任务独立维护，三问初始为空
// ✅ 弹窗模式：确认后进入折叠展示态（步骤4），不显示行动输入区
// ✅ 弹窗模式：完成探究时检查未确认草稿，给出放弃提示（异步确认）
// ✅ 弹窗模式：底部按钮有任务时"完成探究"，无任务时"关闭"（始终可点）
// ✅ 弹窗模式：三问输入框 onChanged 触发 setState，按钮实时启用

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/note_subtask.dart';
import '../models/explore_task.dart';

class InquiryPage extends StatefulWidget {
  final NotebookEntry entry;
  final bool isDialog;

  const InquiryPage({
    super.key,
    required this.entry,
    this.isDialog = false,
  });

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();

  // ─── 多任务状态（全屏模式） ──────────────────
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

  // ─── 弹窗模式专用状态 ──────────────────────
  late List<ExploreTask> _existingTasks; // 已有任务（只读展示）
  List<ExploreTask> _newConfirmedTasks = []; // 本轮新确认的任务
  int _currentStep = 0; // 0=第一问, 1=第二问, 2=第三问, 3=过渡/行动区, 4=折叠展示态

  // ─── 计算属性 ──────────────────────────────
  bool get _isCompleted => _newUnderstanding != null;

  String get _currentQuestionText =>
      _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : (widget.entry.inquiryQuestion ?? '这个探究问题');

  // 弹窗模式下所有已完成任务（已有 + 本轮新增）
  List<ExploreTask> get _allConfirmedTasks => [..._existingTasks, ..._newConfirmedTasks];

  // 当前草稿任务（弹窗模式下始终是 _exploreTasks[0]）
  ExploreTask get _currentDraft => _exploreTasks[_currentTaskIndex];

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.entry.inquiryQuestion ?? '';
    _newUnderstanding = widget.entry.newUnderstanding;
    _understandingController = TextEditingController(text: _newUnderstanding ?? '');

    _q1Controller = TextEditingController();
    _q2Controller = TextEditingController();
    _q3Controller = TextEditingController();

    if (widget.isDialog) {
      // ─── 弹窗模式 ──────────────────────────────
      _existingTasks = List.from(widget.entry.exploreTasks);
      // 只创建一个新任务作为草稿
      _exploreTasks = [ExploreTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      )];
      _currentTaskIndex = 0;
      _currentStep = 0;
      // 三问保持为空，不加载已有答案
    } else {
      // ─── 全屏模式 ──────────────────────────────
      _existingTasks = [];
      _exploreTasks = List.from(widget.entry.exploreTasks);
      if (_exploreTasks.isEmpty) {
        _exploreTasks.add(ExploreTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        ));
      }
      _currentTaskIndex = _exploreTasks.length - 1;
      _loadScaffoldAnswers();
    }
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

  // ─── 三问同步（全屏模式） ──────────────────

  void _loadScaffoldAnswers() {
    final answers = _exploreTasks[_currentTaskIndex].scaffoldAnswers;
    _q1Controller.text = answers.length > 0 ? answers[0]['value'] ?? '' : '';
    _q2Controller.text = answers.length > 1 ? answers[1]['value'] ?? '' : '';
    _q3Controller.text = answers.length > 2 ? answers[2]['value'] ?? '' : '';
  }

  void _switchTask(int index) {
    final targetId = _exploreTasks[index].id;

    if (_isScaffoldEditing) {
      _cancelScaffoldEditingInternal();
    }

    final newIndex = _exploreTasks.indexWhere((t) => t.id == targetId);
    if (newIndex == -1) {
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

  // ─── 新增拐杖卡（全屏模式） ────────────────

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

  // ─── 行动区（全屏 + 弹窗共用） ──────────────

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

  // ─── 新理解（全屏模式） ─────────────────────

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

  // ─── 保存（全屏模式） ──────────────────────

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

  // ─── 弹窗模式专用方法 ──────────────────────

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  // 确认当前任务（三问+行动）并折叠，进入折叠展示态（步骤4）
  void _confirmTask() {
    final draft = _currentDraft;
    final answers = [
      {'label': '现在最困扰我的是什么？', 'value': _q1Controller.text.trim()},
      {'label': '我能做的最小一步是什么？', 'value': _q2Controller.text.trim()},
      {'label': '做完这一步会怎样？', 'value': _q3Controller.text.trim()},
    ];
    // 组装完整任务
    final confirmedTask = draft.copyWith(
      scaffoldCardType: 'minimal_step',
      scaffoldAnswers: answers,
      updatedAt: DateTime.now(),
    );
    // 加入已确认列表
    _newConfirmedTasks.add(confirmedTask);
    // 重置草稿（新建空任务）
    _exploreTasks[_currentTaskIndex] = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    // 清空输入
    _q1Controller.clear();
    _q2Controller.clear();
    _q3Controller.clear();
    _subtaskController.clear();
    // 进入折叠展示态（步骤4）
    setState(() {
      _currentStep = 4;
    });
  }

  // 重置并开始新一轮探究
  void _resetForNewTask() {
    // 重置草稿
    _exploreTasks[_currentTaskIndex] = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _q1Controller.clear();
    _q2Controller.clear();
    _q3Controller.clear();
    _subtaskController.clear();
    setState(() {
      _currentStep = 0;
    });
  }

  // 完成弹窗，返回合并后的任务列表，如有未确认草稿则提示
  Future<void> _completeAndReturn() async {
    // 检查草稿是否有内容
    final draft = _currentDraft;
    final hasDraftContent = _q1Controller.text.trim().isNotEmpty ||
        _q2Controller.text.trim().isNotEmpty ||
        _q3Controller.text.trim().isNotEmpty ||
        draft.actions.isNotEmpty;

    // 如果没有草稿内容，直接返回
    if (!hasDraftContent) {
      final allTasks = [..._existingTasks, ..._newConfirmedTasks];
      if (mounted) {
        Navigator.pop(context, allTasks);
      }
      return;
    }

    // 有草稿内容，弹出确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃当前任务？'),
        content: const Text('当前任务还没确认，确定要放弃吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );

    // 用户确认放弃才返回
    if (confirmed == true) {
      final allTasks = [..._existingTasks, ..._newConfirmedTasks];
      if (mounted) {
        Navigator.pop(context, allTasks);
      }
    }
    // 否则（取消或对话框关闭）停留在弹窗
  }

  // ─── UI 入口 ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogContent();
    } else {
      return _buildFullscreenContent();
    }
  }

  // ─── 全屏模式 UI ──────────────────────────

  Widget _buildFullscreenContent() {
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

  // ─── 弹窗模式 UI ──────────────────────────

  Widget _buildDialogContent() {
    final hasAnyConfirmed = _allConfirmedTasks.isNotEmpty;
    final currentDraft = _currentDraft;

    return Card(
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 顶部栏 ──────────────────────────────
            Row(
              children: [
                const Text(
                  '🧭 深入探究',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, null),
                  tooltip: '关闭',
                ),
              ],
            ),
            const Divider(height: 16),

            // ─── 主问题展示 ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                '🎯 $_currentQuestionText',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 已生成任务列表（折叠展示） ──────────
            if (hasAnyConfirmed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '已生成的探究：',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  ..._allConfirmedTasks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final task = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: Colors.purple, size: 10),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '任务 ${idx + 1}  ${task.actions.isNotEmpty ? "${task.actions.length} 个行动" : "已折叠"}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),

            // ─── 当前步骤内容 ──────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 步骤0: 第一问
                    if (_currentStep == 0) ...[
                      const Text(
                        '第一步：明确困扰',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '现在最困扰我的是什么？',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _q1Controller,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '写下你的回答...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: _q1Controller.text.trim().isEmpty ? null : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('下一步 →'),
                          ),
                        ],
                      ),
                    ],
                    // 步骤1: 第二问
                    if (_currentStep == 1) ...[
                      const Text(
                        '第二步：最小一步',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '我能做的最小一步是什么？',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _q2Controller,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '写下你的回答...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = 0;
                              });
                            },
                            child: const Text('上一步'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _q2Controller.text.trim().isEmpty ? null : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('下一步 →'),
                          ),
                        ],
                      ),
                    ],
                    // 步骤2: 第三问
                    if (_currentStep == 2) ...[
                      const Text(
                        '第三步：预见结果',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '做完这一步会怎样？',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _q3Controller,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '写下你的回答...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = 1;
                              });
                            },
                            child: const Text('上一步'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _q3Controller.text.trim().isEmpty ? null : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('完成三问 →'),
                          ),
                        ],
                      ),
                    ],
                    // 步骤3: 过渡 + 行动区
                    if (_currentStep == 3) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Text(
                          '✨ 那我们计划行动',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 行动输入
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              decoration: InputDecoration(
                                hintText: '输入具体行动...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      // 行动列表
                      if (currentDraft.actions.isNotEmpty)
                        ...currentDraft.actions.map((action) => _buildActionItem(action)),
                      if (currentDraft.actions.isEmpty)
                        const Text(
                          '还没有行动，添加一条吧',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentStep = 2;
                              });
                            },
                            child: const Text('上一步'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: currentDraft.actions.isEmpty ? null : _confirmTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('确认并折叠'),
                          ),
                        ],
                      ),
                      // 如果已经至少完成一个任务，显示"再探究一个"
                      if (hasAnyConfirmed) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _resetForNewTask,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('＋ 再探究一个问题'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                    // 步骤4: 折叠展示态（仅显示再探究按钮）
                    if (_currentStep == 4) ...[
                      if (hasAnyConfirmed) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _resetForNewTask,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('＋ 再探究一个问题'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.purple,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          '没有已生成的探究，请先完成一个任务。',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // ─── 底部按钮 ──────────────────────────
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // 有任务 → 返回列表；无任务 → 返回 null（关闭弹窗）
                    if (hasAnyConfirmed) {
                      _completeAndReturn();
                    } else {
                      Navigator.pop(context, null);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(hasAnyConfirmed ? '生成探究' : '关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 子组件（全屏 + 弹窗共用） ──────────────

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
          onChanged: (_) => setState(() {}),
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
              action.isDone ? Icons.check_circle : Icons.subdirectory_arrow_right,
              color: action.isDone ? Colors.green : Colors.grey.shade500,
              size: action.isDone ? 22 : 16,
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