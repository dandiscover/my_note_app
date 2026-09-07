// lib/pages/inquiry_page.dart
// 深度笔记 — 多任务探究
// ✅ 三阶段状态机：选卡 → 问答 → 列表
// ✅ 支持两种卡片类型：最小一步卡 / 5 Why 卡
// ✅ 跨卡切换时彻底清理对方状态，不留脏数据
// ✅ 5 Why 的 _whyMinStep 直接进行动列表，不作为输入框预填
// ✅ 5 Why 任意轮次“我挖够了”空输入也有效，直接跳转到根因总结
// ✅ 返回层级：question → selectCard → list
// ✅ 默认打开显示 list（已有探究列表），空列表时显示引导文案
// ✅ 5 Why 问题文案动态生成：首轮固定，后续嵌入上一轮答案（截断20字）
// ✅ 已完成探究列表：紫色圆点图标，文本不带对勾
// ✅ 5 Why 停止位置记录，根因步骤“上一步”回到停止位置并回显答案
// ✅ 最小一步步骤“上一步”回到根因步骤并回显根因内容
// ✅ 空状态仅显示引导文案，不显示新理解区域
// ✅ 已有探究任务时才显示新理解相关区域
// ✅ 关闭弹窗时，若有已确认任务返回任务列表，否则返回 null
// ✅ 行动项只读，不可勾选完成；行动列表上方提示去任务页完成
// ✅ 探究页移除新理解区域，改为轻提示

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/note_subtask.dart';
import '../models/explore_task.dart';

enum InquiryCardType { minimalStep, fiveWhy }

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

  // ─── 多任务状态 ─────────────────────────────
  List<ExploreTask> _exploreTasks = [];
  int _currentTaskIndex = 0;

  // ─── 三阶段状态机 ─────────────────────────────
  static const String _phaseList = 'list';
  static const String _phaseSelectCard = 'selectCard';
  static const String _phaseQuestion = 'question';
  String _phase = _phaseList;

  InquiryCardType? _cardType;

  // ─── 最小一步卡状态 ─────────────────────────────
  int _minimalStep = 0;
  late TextEditingController _q1Controller;
  late TextEditingController _q2Controller;
  late TextEditingController _q3Controller;

  // ─── 5 Why 卡状态 ─────────────────────────────
  int _whyStep = 0;
  int _stopAtStep = 0;
  final List<String> _whyAnswers = [];
  String _whyRootCause = '';
  String _whyMinStep = '';
  late TextEditingController _whyController;

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

  bool get _hasAnyConfirmedTask {
    return _exploreTasks.any((t) => t.scaffoldCardType != null || t.actions.isNotEmpty);
  }

  ExploreTask get _currentDraft => _exploreTasks[_currentTaskIndex];

  /// 5 Why 当前轮次的提示文案（动态生成）
  String get _currentWhyPrompt {
    if (_whyStep == 0) {
      return '为什么会有这个困惑？';
    }
    final previousIndex = _whyStep - 1;
    if (previousIndex < _whyAnswers.length) {
      final previousAnswer = _whyAnswers[previousIndex];
      if (previousAnswer.isNotEmpty) {
        String truncated = previousAnswer.length > 20
            ? '${previousAnswer.substring(0, 20)}……'
            : previousAnswer;
        return '为什么「$truncated」？';
      }
    }
    return '为什么？';
  }

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.entry.inquiryQuestion ?? '';
    _newUnderstanding = widget.entry.newUnderstanding;
    _understandingController = TextEditingController(text: _newUnderstanding ?? '');

    _q1Controller = TextEditingController();
    _q2Controller = TextEditingController();
    _q3Controller = TextEditingController();
    _whyController = TextEditingController();

    _exploreTasks = List.from(widget.entry.exploreTasks);
    if (_exploreTasks.isEmpty) {
      _exploreTasks.add(ExploreTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    }
    _currentTaskIndex = _exploreTasks.length - 1;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _subtaskController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    _whyController.dispose();
    _understandingController.dispose();
    super.dispose();
  }

  // ─── 卡片类型选择 ─────────────────────────────

  void _selectCardType(InquiryCardType type) {
    if (_cardType == InquiryCardType.fiveWhy && type != InquiryCardType.fiveWhy) {
      _resetFiveWhyState();
    } else if (_cardType == InquiryCardType.minimalStep && type != InquiryCardType.minimalStep) {
      _resetMinimalStepState();
    }

    setState(() {
      _cardType = type;
      _phase = _phaseQuestion;
      if (type == InquiryCardType.minimalStep) {
        _minimalStep = 0;
        _q1Controller.clear();
        _q2Controller.clear();
        _q3Controller.clear();
      } else if (type == InquiryCardType.fiveWhy) {
        _whyStep = 0;
        _stopAtStep = 0;
        _whyAnswers.clear();
        _whyRootCause = '';
        _whyMinStep = '';
        _whyController.clear();
      }
      _subtaskController.clear();
    });
  }

  void _resetMinimalStepState() {
    _minimalStep = 0;
    _q1Controller.clear();
    _q2Controller.clear();
    _q3Controller.clear();
  }

  void _resetFiveWhyState() {
    _whyStep = 0;
    _stopAtStep = 0;
    _whyAnswers.clear();
    _whyRootCause = '';
    _whyMinStep = '';
    _whyController.clear();
  }

  // ─── 返回层级 ─────────────────────────────
  void _goBack() {
    if (_phase == _phaseQuestion) {
      setState(() {
        _phase = _phaseSelectCard;
        if (_cardType == InquiryCardType.minimalStep) {
          _resetMinimalStepState();
        } else if (_cardType == InquiryCardType.fiveWhy) {
          _resetFiveWhyState();
        }
        _cardType = null;
        _subtaskController.clear();
      });
    }
  }

  // ─── 新增探究：从列表进入选卡 ──────────────
  void _startNewExplore() {
    setState(() {
      _phase = _phaseSelectCard;
      _cardType = null;
      _resetMinimalStepState();
      _resetFiveWhyState();
      _subtaskController.clear();
    });
  }

  // ─── 最小一步卡逻辑 ─────────────────────────────

  void _minimalNextStep() {
    setState(() {
      _minimalStep++;
    });
  }

  void _minimalPrevStep() {
    setState(() {
      _minimalStep--;
    });
  }

  void _confirmMinimalTask() {
    final answers = [
      {'label': '现在最困扰我的是什么？', 'value': _q1Controller.text.trim()},
      {'label': '我能做的最小一步是什么？', 'value': _q2Controller.text.trim()},
      {'label': '做完这一步会怎样？', 'value': _q3Controller.text.trim()},
    ];

    final draft = _currentDraft;
    final confirmedTask = draft.copyWith(
      scaffoldCardType: 'minimal_step',
      scaffoldAnswers: answers,
      updatedAt: DateTime.now(),
    );

    _exploreTasks[_currentTaskIndex] = confirmedTask;

    final newTask = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _exploreTasks.add(newTask);
    _currentTaskIndex = _exploreTasks.length - 1;

    _q1Controller.clear();
    _q2Controller.clear();
    _q3Controller.clear();
    _subtaskController.clear();

    setState(() {
      _phase = _phaseList;
      _minimalStep = 4;
    });
  }

  // ─── 5 Why 逻辑 ─────────────────────────────
  void _whyNext() {
    final text = _whyController.text.trim();
    if (text.isEmpty) return;
    _whyAnswers.add(text);
    setState(() {
      _whyStep++;
      _whyController.clear();
    });
    if (_whyStep == 5) {
      _stopAtStep = 4;
    }
  }

  void _whyStop() {
    final text = _whyController.text.trim();
    if (text.isNotEmpty) {
      _whyAnswers.add(text);
    }
    _stopAtStep = _whyStep;
    setState(() {
      _whyStep = 5;
      _whyController.clear();
    });
  }

  void _whyPrev() {
    if (_whyStep > 0) {
      setState(() {
        _whyStep--;
        if (_whyAnswers.isNotEmpty) {
          _whyAnswers.removeLast();
        }
        _whyController.clear();
      });
    }
  }

  void _saveWhyRootCause() {
    final rootCause = _whyController.text.trim();
    if (rootCause.isEmpty) return;

    setState(() {
      _whyRootCause = rootCause;
      _whyController.clear();
      _whyStep = 6;
    });
  }

  void _saveWhyMinStep() {
    final minStep = _whyController.text.trim();
    if (minStep.isEmpty) return;

    setState(() {
      _whyMinStep = minStep;
      _whyController.clear();
    });

    _addActionDirect(minStep);
    _confirmFiveWhyTask();
  }

  void _addActionDirect(String title) {
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
  }

  void _confirmFiveWhyTask() {
    final answers = <Map<String, String>>[];
    for (int i = 0; i < _whyAnswers.length; i++) {
      answers.add({
        'label': '第${i + 1}层为什么',
        'value': _whyAnswers[i],
      });
    }
    if (_whyRootCause.isNotEmpty) {
      answers.add({
        'label': '根因总结',
        'value': _whyRootCause,
      });
    }

    final draft = _currentDraft;
    final confirmedTask = draft.copyWith(
      scaffoldCardType: 'five_why',
      scaffoldAnswers: answers,
      updatedAt: DateTime.now(),
    );

    _exploreTasks[_currentTaskIndex] = confirmedTask;

    final newTask = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _exploreTasks.add(newTask);
    _currentTaskIndex = _exploreTasks.length - 1;

    _resetFiveWhyState();
    setState(() {
      _phase = _phaseList;
    });
  }

  // ─── 行动区（共用） ─────────────────────────────

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

  void _deleteAction(String id) {
    final current = _exploreTasks[_currentTaskIndex];
    final actions = current.actions.where((a) => a.id != id).toList();
    _exploreTasks[_currentTaskIndex] = current.copyWith(
      actions: actions,
      updatedAt: DateTime.now(),
    );
    setState(() {});
  }

  // ─── 重置再探究 ─────────────────────────────

  void _resetForNewTask() {
    final newTask = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _exploreTasks.add(newTask);
    _currentTaskIndex = _exploreTasks.length - 1;
    _cardType = null;
    _resetMinimalStepState();
    _resetFiveWhyState();
    _q1Controller.clear();
    _q2Controller.clear();
    _q3Controller.clear();
    _whyController.clear();
    _subtaskController.clear();
    setState(() {
      _phase = _phaseSelectCard;
    });
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

  // ─── 弹窗模式：关闭弹窗 ──────────────────────

  /// 关闭弹窗时，如果有已确认的探究任务，返回过滤后的任务列表；
  /// 否则返回 null。
  void _closeDialog() {
    final hasConfirmed = _hasAnyConfirmedTask;
    final tasks = _filterEmptyTasks(_exploreTasks);
    Navigator.pop(context, hasConfirmed ? tasks : null);
  }

  // ─── 弹窗模式：完成并返回 ──────────────────────

  Future<void> _completeAndReturn() async {
    final draft = _currentDraft;
    final hasDraftContent = _cardType != null &&
        (_cardType == InquiryCardType.minimalStep
            ? (_q1Controller.text.trim().isNotEmpty ||
                _q2Controller.text.trim().isNotEmpty ||
                _q3Controller.text.trim().isNotEmpty ||
                draft.actions.isNotEmpty)
            : (_whyController.text.trim().isNotEmpty ||
                _whyAnswers.isNotEmpty ||
                _whyRootCause.isNotEmpty ||
                draft.actions.isNotEmpty));

    if (!hasDraftContent) {
      final allTasks = _filterEmptyTasks(_exploreTasks);
      if (mounted) {
        Navigator.pop(context, allTasks);
      }
      return;
    }

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

    if (confirmed == true) {
      final allTasks = _filterEmptyTasks(_exploreTasks);
      if (mounted) {
        Navigator.pop(context, allTasks);
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 深度笔记'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildContent(context),
      ),
    );
  }

  // ─── 弹窗模式 UI ──────────────────────────

  Widget _buildDialogContent() {
    return Card(
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: _buildContent(context),
      ),
    );
  }

  // ─── 核心内容 ─────────────────────────────

  Widget _buildContent(BuildContext context) {
    final hasAnyConfirmed = _hasAnyConfirmedTask;

    return Column(
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
            if (widget.isDialog)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _closeDialog,
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

        // ─── 已完成任务列表 ──────────────────────────
        if (hasAnyConfirmed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '已生成的探究：',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              ..._exploreTasks
                  .where((t) => t.scaffoldCardType != null || t.actions.isNotEmpty)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final idx = entry.key + 1;
                final task = entry.value;
                final label = task.scaffoldCardType == 'five_why' ? '5 Why' : '最小一步';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.purple, size: 10),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '任务 $idx ($label)  ${task.actions.isNotEmpty ? "${task.actions.length} 个行动" : "已折叠"}',
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

        // ─── 三阶段状态机 ──────────────────────────
        if (_phase == _phaseSelectCard)
          _buildCardSelectPanel()
        else if (_phase == _phaseQuestion)
          _buildQuestionPanel()
        else
          _buildListPanel(hasAnyConfirmed),

        // ─── 底部按钮 ──────────────────────────────
        if (widget.isDialog) ...[
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_phase == _phaseList) ...[
                TextButton(
                  onPressed: _closeDialog,
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _startNewExplore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('＋ 新增探究'),
                ),
              ],
              if (_phase == _phaseQuestion) ...[
                TextButton(
                  onPressed: _goBack,
                  child: const Text('返回'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ─── 选卡面板 ─────────────────────────────

  Widget _buildCardSelectPanel() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '选择探究方式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // 可用卡
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardTypeButton(
                  icon: Icons.looks_one,
                  label: '最小一步卡',
                  desc: '三问引导，聚焦行动',
                  color: Colors.purple,
                  enabled: true,
                  onTap: () => _selectCardType(InquiryCardType.minimalStep),
                ),
                const SizedBox(width: 16),
                _buildCardTypeButton(
                  icon: Icons.psychology,
                  label: '5 Why 卡',
                  desc: '深度挖掘根因',
                  color: Colors.teal,
                  enabled: true,
                  onTap: () => _selectCardType(InquiryCardType.fiveWhy),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '更多卡片类型即将开放',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildDisabledCard('🪞 苏格拉底卡', '通过提问检验信念'),
                _buildDisabledCard('🔄 逆向思维卡', '从反面寻找突破口'),
                _buildDisabledCard('🧠 二阶思考卡', '思考的思考，追因再追因'),
                _buildDisabledCard('💭 CBT 卡', '识别并重构认知模式'),
                _buildDisabledCard('⚖️ 价值澄清卡', '明确什么是真正重要的'),
                _buildDisabledCard('🧊 SWOT 卡', '优势、劣势、机会、威胁'),
                _buildDisabledCard('🎩 六顶思考帽卡', '多视角全方位审视问题'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeButton({
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: enabled ? color : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? color : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledCard(String label, String desc) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            '🔒',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '即将开放',
              style: TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 问答面板 ─────────────────────────────

  Widget _buildQuestionPanel() {
    if (_cardType == InquiryCardType.minimalStep) {
      return _buildMinimalStepQuestionPanel();
    } else if (_cardType == InquiryCardType.fiveWhy) {
      return _buildFiveWhyQuestionPanel();
    }
    return const SizedBox.shrink();
  }

  // ─── 最小一步卡问答 ─────────────────────────────

  Widget _buildMinimalStepQuestionPanel() {
    final stepLabels = [
      '第一步：明确困扰',
      '第二步：最小一步',
      '第三步：预见结果',
    ];
    final stepQuestions = [
      '现在最困扰我的是什么？',
      '我能做的最小一步是什么？',
      '做完这一步会怎样？',
    ];
    final controllers = [_q1Controller, _q2Controller, _q3Controller];

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_minimalStep < 3) ...[
              Text(
                stepLabels[_minimalStep],
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
              ),
              const SizedBox(height: 4),
              Text(
                stepQuestions[_minimalStep],
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controllers[_minimalStep],
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
                  if (_minimalStep > 0)
                    TextButton(
                      onPressed: _minimalPrevStep,
                      child: const Text('上一步'),
                    ),
                  if (_minimalStep < 2) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: controllers[_minimalStep].text.trim().isEmpty ? null : _minimalNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('下一步 →'),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: controllers[_minimalStep].text.trim().isEmpty ? null : _minimalNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('完成三问 →'),
                    ),
                  ],
                ],
              ),
            ],
            if (_minimalStep == 3) ...[
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
              _buildActionInputRow(),
              const SizedBox(height: 8),
              // ✅ 行动列表上方提示
              if (_currentDraft.actions.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '行动已生成，去任务页完成',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              if (_currentDraft.actions.isNotEmpty)
                ..._currentDraft.actions.map((action) => _buildActionItem(action)),
              if (_currentDraft.actions.isEmpty)
                const Text(
                  '还没有行动，添加一条吧',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _minimalPrevStep,
                    child: const Text('上一步'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _currentDraft.actions.isEmpty ? null : _confirmMinimalTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认并折叠'),
                  ),
                ],
              ),
            ],
            if (_minimalStep == 4) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '✅ 当前探究已折叠',
                  style: TextStyle(fontSize: 14, color: Colors.green.shade700),
                ),
              ),
              const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  // ─── 5 Why 问答 ─────────────────────────────

  Widget _buildFiveWhyQuestionPanel() {
    final isRootCauseStep = _whyStep == 5;
    final isMinStepStep = _whyStep == 6;
    final hasText = _whyController.text.trim().isNotEmpty;

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_whyStep < 5) ...[
              Row(
                children: [
                  Text(
                    '第 ${_whyStep + 1} 层',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_whyStep + 1} / 5',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (_whyStep + 1) / 5,
                backgroundColor: Colors.grey.shade200,
                color: Colors.teal,
                minHeight: 4,
              ),
              const SizedBox(height: 8),
              Text(
                _currentWhyPrompt,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.teal.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _whyController,
                maxLines: 3,
                autofocus: true,
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
                  if (_whyStep > 0)
                    TextButton(
                      onPressed: _whyPrev,
                      child: const Text('上一步'),
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _whyStop,
                    child: const Text('我挖够了'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: hasText ? _whyNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Text('继续挖 →'),
                  ),
                ],
              ),
            ],
            if (isRootCauseStep) ...[
              const Text(
                '📌 根因总结',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal),
              ),
              const SizedBox(height: 4),
              Text(
                '综合以上回答，你认为根本原因是什么？',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _whyController,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '写下根因总结...',
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
                        _whyStep = _stopAtStep;
                        _whyController.clear();
                        if (_stopAtStep < _whyAnswers.length) {
                          _whyController.text = _whyAnswers[_stopAtStep];
                        }
                      });
                    },
                    child: const Text('上一步'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _whyController.text.trim().isEmpty ? null : _saveWhyRootCause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认根因'),
                  ),
                ],
              ),
            ],
            if (isMinStepStep) ...[
              const Text(
                '🚀 最小一步',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.teal),
              ),
              const SizedBox(height: 4),
              Text(
                '基于以上分析，你能做的最小一步是什么？',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _whyController,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '写下最小一步...',
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
                        _whyStep = 5;
                        _whyController.text = _whyRootCause;
                      });
                    },
                    child: const Text('上一步'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _whyController.text.trim().isEmpty ? null : _saveWhyMinStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认并折叠'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 行动输入行 ─────────────────────────────

  Widget _buildActionInputRow() {
    return Row(
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
    );
  }

  // ─── 列表面板 ─────────────────────────────

  Widget _buildListPanel(bool hasAnyConfirmed) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 空状态引导 ──────────────────────────
            if (!hasAnyConfirmed) ...[
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.explore, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      '你想探究什么问题？',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击「＋ 新增探究」开始',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
            // ─── 已有探究任务时显示轻提示 ──────────
            if (hasAnyConfirmed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已生成 ${_exploreTasks.where((t) => t.scaffoldCardType != null || t.actions.isNotEmpty).length} 个探究任务，行动已添加到任务页，去那里完成',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 行动项 ─────────────────────────────

  Widget _buildActionItem(NoteSubtask action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right, color: Colors.grey.shade500, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action.title,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
}