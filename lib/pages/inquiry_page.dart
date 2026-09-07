// lib/pages/inquiry_page.dart
// 深度笔记 — 多任务探究
// ✅ 三阶段状态机：list → selectCard → question
// ✅ 卡片组件注册模式：7 种卡片类型
// ✅ 卡片切换时使用 ValueKey 强制重建，状态自动重置
// ✅ 卡片组件独立管理各自的状态和交互
// ✅ 选卡面板：可翻转卡片，正面小尺寸，点击翻面，独立“使用”按钮

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/explore_task.dart';
import '../widgets/inquiry/minimal_step_card_widget.dart';
import '../widgets/inquiry/five_why_card_widget.dart';
import '../widgets/inquiry/socratic_card_widget.dart';
import '../widgets/inquiry/reverse_card_widget.dart';
import '../widgets/inquiry/second_order_card_widget.dart';
import '../widgets/inquiry/six_hats_card_widget.dart';
import '../widgets/inquiry/swot_card_widget.dart';
enum InquiryCardType {
  minimalStep,
  fiveWhy,
  socratic,
  reverse,
  secondOrder,
  sixHats,
  swot,
}

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

  // ─── 多任务状态 ─────────────────────────────
  List<ExploreTask> _exploreTasks = [];
  int _currentTaskIndex = 0;

  // ─── 三阶段状态机 ─────────────────────────────
  static const String _phaseList = 'list';
  static const String _phaseSelectCard = 'selectCard';
  static const String _phaseQuestion = 'question';
  String _phase = _phaseList;

  InquiryCardType? _cardType;

  // ─── 新理解（仅保留字段，UI 已迁移） ──────────
  String? _newUnderstanding;

  // ─── 计算属性 ──────────────────────────────
  String get _currentQuestionText =>
      _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : (widget.entry.inquiryQuestion ?? '这个探究问题');

  bool get _hasAnyConfirmedTask {
    return _exploreTasks.any((t) => t.scaffoldCardType != null || t.actions.isNotEmpty);
  }

  ExploreTask get _currentDraft => _exploreTasks[_currentTaskIndex];

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.entry.inquiryQuestion ?? '';
    _newUnderstanding = widget.entry.newUnderstanding;

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
    super.dispose();
  }

  // ─── 卡片类型选择 ─────────────────────────────

  void _selectCardType(InquiryCardType type) {
    setState(() {
      _cardType = type;
      _phase = _phaseQuestion;
    });
  }

  // ─── 返回层级 ─────────────────────────────
  void _goBack() {
    if (_phase == _phaseQuestion) {
      setState(() {
        _phase = _phaseSelectCard;
        _cardType = null;
      });
    }
  }

  // ─── 新增探究：从列表进入选卡 ──────────────
  void _startNewExplore() {
    setState(() {
      _phase = _phaseSelectCard;
      _cardType = null;
    });
  }

  // ─── 卡片确认回调 ─────────────────────────────
  void _onCardConfirmed(ExploreTask confirmedTask) {
    _exploreTasks[_currentTaskIndex] = confirmedTask;

    final newTask = ExploreTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _exploreTasks.add(newTask);
    _currentTaskIndex = _exploreTasks.length - 1;

    setState(() {
      _phase = _phaseList;
      _cardType = null;
    });

    _saveEntry();
  }

  void _onCardCancel() {
    setState(() {
      _phase = _phaseSelectCard;
      _cardType = null;
    });
  }

  // ─── 保存 ──────────────────────────────────

  List<ExploreTask> _filterEmptyTasks(List<ExploreTask> tasks) {
    return tasks.where((task) {
      return task.scaffoldCardType != null || task.actions.isNotEmpty;
    }).toList();
  }

  Future<void> _saveEntry() async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── 弹窗模式：关闭弹窗 ──────────────────────

  void _closeDialog() {
    final hasConfirmed = _hasAnyConfirmedTask;
    final tasks = _filterEmptyTasks(_exploreTasks);
    Navigator.pop(context, hasConfirmed ? tasks : null);
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
                final label = _getCardLabel(task.scaffoldCardType);
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

  String _getCardLabel(String? cardType) {
    switch (cardType) {
      case 'minimal_step':
        return '最小一步';
      case 'five_why':
        return '5 Why';
      case 'socratic':
        return '苏格拉底';
      case 'reverse':
        return '逆向思维';
      case 'second_order':
        return '二阶思考';
      case 'six_hats':
        return '六顶思考帽';
      case 'swot':
        return 'SWOT';
      default:
        return '未知';
    }
  }

  // ─── 选卡面板 ─────────────────────────────

  Widget _buildCardSelectPanel() {
    return Expanded(
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            // 计算弹性宽度：每行最多3张卡，间距6
            final spacing = 6.0;
            final cardCountPerRow = 3;
            final collapsedWidth = (maxWidth - spacing * (cardCountPerRow - 1)) / cardCountPerRow;
            final expandedWidth = maxWidth;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择探究方式',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                // 可用卡（七张）
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _FlippableCard(
                      icon: Icons.looks_one,
                      title: '最小一步卡',
                      desc: '三问引导，聚焦行动',
                      color: Colors.purple,
                      onUse: () => _selectCardType(InquiryCardType.minimalStep),
                      backContent: _buildMinimalStepBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
                    ),
                    _FlippableCard(
                      icon: Icons.psychology,
                      title: '5 Why 卡',
                      desc: '深度挖掘根因',
                      color: Colors.teal,
                      onUse: () => _selectCardType(InquiryCardType.fiveWhy),
                      backContent: _buildFiveWhyBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
                    ),
                    _FlippableCard(
                      icon: Icons.help_outline,
                      title: '苏格拉底卡',
                      desc: '通过提问检验信念',
                      color: Colors.indigo,
                      onUse: () => _selectCardType(InquiryCardType.socratic),
                      backContent: _buildSocraticBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
                    ),
                    _FlippableCard(
                      icon: Icons.compare_arrows,
                      title: '逆向思维卡',
                      desc: '从反面寻找突破口',
                      color: Colors.deepOrange,
                      onUse: () => _selectCardType(InquiryCardType.reverse),
                      backContent: _buildReverseBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
                    ),
                    _FlippableCard(
                      icon: Icons.timeline,
                      title: '二阶思考卡',
                      desc: '看一个决定更长远、更连锁的后果',
                      color: Colors.brown,
                      onUse: () => _selectCardType(InquiryCardType.secondOrder),
                      backContent: _buildSecondOrderBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
                    ),
                    _FlippableCard(
                      icon: Icons.style,
                      title: '六顶思考帽卡',
                      desc: '多视角全方位审视问题',
                      color: Colors.purple.shade700,
                      onUse: () => _selectCardType(InquiryCardType.sixHats),
                      backContent: _buildSixHatsBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
                    ),
                    _FlippableCard(
                      icon: Icons.assessment,
                      title: 'SWOT 卡',
                      desc: '优势、劣势、机会、威胁',
                      color: Colors.green,
                      onUse: () => _selectCardType(InquiryCardType.swot),
                      backContent: _buildSwotBackContent(),
                      collapsedWidth: collapsedWidth,
                      expandedWidth: expandedWidth,
                      cardHeight: 140,
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
                  children: [
                    _buildDisabledCard('💭 CBT 卡', '识别并重构认知模式'),
                    _buildDisabledCard('⚖️ 价值澄清卡', '明确什么是真正重要的'),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── 卡片背面内容构建 ──────────────────────────

  Widget _buildMinimalStepBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '按顺序回答三个问题，最后添加一条最小行动。'),
        ('来源', '基于最小行动原则设计。'),
        ('背景', '人常被模糊问题困住，不知从何下手。'),
        ('使用契机', '你知道问题是什么，但不知道第一步怎么走。'),
      ],
    );
  }

  Widget _buildFiveWhyBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '从困惑出发，连续追问“为什么”，挖到根因后总结最小一步。'),
        ('来源', '丰田生产系统中的根因分析方法。'),
        ('背景', '表面原因往往掩盖真正的根因。'),
        ('使用契机', '同一个问题反复出现，你觉得没找到真正原因。'),
      ],
    );
  }

  Widget _buildSocraticBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '检验一个想法：证据→反例→默认前提→相反观点→完整性判断。'),
        ('来源', '苏格拉底的反诘法。'),
        ('背景', '我们常持有未经检验的信念。'),
        ('使用契机', '你对某个判断有疑问，想深入检验它。'),
      ],
    );
  }

  Widget _buildReverseBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '从当前想法出发，找到相反观点，预测反向行动结果。'),
        ('来源', '逆向思维策略。'),
        ('背景', '常规思路容易陷入死胡同。'),
        ('使用契机', '当你觉得常规解法不奏效时。'),
      ],
    );
  }

  Widget _buildSecondOrderBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '思考直接后果→再接下来的连锁反应→影响谁→判断价值。'),
        ('来源', '二阶思维概念。'),
        ('背景', '只考虑第一层后果往往导致短视。'),
        ('使用契机', '需要做长远决策时。'),
      ],
    );
  }

  Widget _buildSixHatsBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '依次戴上白(事实)、红(感觉)、黑(风险)、黄(收益)、绿(创意)、蓝(决策)六顶帽子。'),
        ('来源', '爱德华·德·波诺的六顶思考帽。'),
        ('背景', '从单一视角看问题容易片面。'),
        ('使用契机', '需要全面审视复杂问题时。'),
      ],
    );
  }

  Widget _buildSwotBackContent() {
    return _CardBackContent(
      sections: [
        ('使用方法', '分析内部优势/劣势，外部机会/威胁，再组合分析制定行动。'),
        ('来源', 'SWOT 分析法。'),
        ('背景', '决策前需要系统评估内外环境。'),
        ('使用契机', '需要制定策略或评估方案时。'),
      ],
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

  // ─── 问答面板（注册模式） ─────────────────────────────

  Widget _buildQuestionPanel() {
    if (_cardType == null) {
      return const SizedBox.shrink();
    }
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildCardWidget(_cardType!),
        ),
      ),
    );
  }

  Widget _buildCardWidget(InquiryCardType type) {
    final key = ValueKey(type);
    final draft = _currentDraft;

    switch (type) {
      case InquiryCardType.minimalStep:
        return MinimalStepCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
      case InquiryCardType.fiveWhy:
        return FiveWhyCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
      case InquiryCardType.socratic:
        return SocraticCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
      case InquiryCardType.reverse:
        return ReverseCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
      case InquiryCardType.secondOrder:
        return SecondOrderCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
      case InquiryCardType.sixHats:
        return SixHatsCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
      case InquiryCardType.swot:
        return SwotCardWidget(
          key: key,
          initialTask: draft,
          onConfirmed: _onCardConfirmed,
          onCancel: _onCardCancel,
        );
    }
  }

  // ─── 列表面板 ─────────────────────────────

  Widget _buildListPanel(bool hasAnyConfirmed) {
    final filteredTasks = _filterEmptyTasks(_exploreTasks);

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (hasAnyConfirmed) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已生成 ${filteredTasks.length} 个探究任务，行动已添加到任务页，去那里完成',
                        style: const TextStyle(fontSize: 13, color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '已生成的探究：',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              ...filteredTasks.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final task = entry.value;
                final label = _getCardLabel(task.scaffoldCardType);
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
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 私有组件：可翻转卡片
// ═══════════════════════════════════════════════════════

class _FlippableCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onUse;
  final Widget backContent;
  final double collapsedWidth;
  final double expandedWidth;
  final double cardHeight;

  const _FlippableCard({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onUse,
    required this.backContent,
    required this.collapsedWidth,
    required this.expandedWidth,
    required this.cardHeight,
  });

  @override
  State<_FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<_FlippableCard> {
  bool _isFlipped = false;

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topLeft,
      child: Stack(
        children: [
          // 卡片主体（点击翻面）
          GestureDetector(
            onTap: _toggleFlip,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _isFlipped
                  ? Container(
                      key: const ValueKey('back'),
                      width: widget.expandedWidth,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.color.withOpacity(0.3)),
                      ),
                      child: widget.backContent,
                    )
                  : Container(
                      key: const ValueKey('front'),
                      width: widget.collapsedWidth,
                      height: widget.cardHeight,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 36),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 28, color: widget.color),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.color,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.desc,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // 独立“使用”按钮
          Positioned(
            right: 6,
            bottom: 6,
            child: SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: widget.onUse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  textStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('使用'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBackContent extends StatelessWidget {
  final List<(String, String)> sections;

  const _CardBackContent({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.$1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.$2,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}