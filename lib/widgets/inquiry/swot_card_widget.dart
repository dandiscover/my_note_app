// lib/widgets/inquiry/swot_card_widget.dart
// SWOT 卡组件 — 优势、劣势、机会、威胁分析
// 流程：S（内部优势）→ W（内部劣势）→ O（外部机会）→ T（外部威胁）
//       → SO（优势+机会）→ WO（劣势+机会）→ ST（优势+威胁）→ WT（劣势+威胁）
//       → 选择一条行动 → 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';

class SwotCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const SwotCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<SwotCardWidget> createState() => _SwotCardWidgetState();
}

class _SwotCardWidgetState extends State<SwotCardWidget> {
  // ─── 状态机 ─────────────────────────────
  // 0=S, 1=W, 2=O, 3=T, 4=SO, 5=WO, 6=ST, 7=WT, 8=行动, 9=折叠展示态
  int _currentStep = 0;

  // ─── 答案存储 ─────────────────────────────
  final List<String> _answers = List.filled(8, ''); // 0-3: S/W/O/T, 4-7: SO/WO/ST/WT
  String _action = '';

  // ─── 控制器 ─────────────────────────────
  late TextEditingController _inputController;

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

  // ─── 步骤配置 ─────────────────────────────
  final List<Map<String, String>> _stepConfigs = [
    {'label': 'S · 内部优势', 'hint': '你有哪些内部优势？'},
    {'label': 'W · 内部劣势', 'hint': '你有哪些内部劣势？'},
    {'label': 'O · 外部机会', 'hint': '外部有哪些机会？'},
    {'label': 'T · 外部威胁', 'hint': '外部有哪些威胁？'},
    {'label': 'SO · 优势 + 机会', 'hint': '如何用你的优势抓住这些机会？'},
    {'label': 'WO · 劣势 + 机会', 'hint': '如何弥补劣势去抓住机会？'},
    {'label': 'ST · 优势 + 威胁', 'hint': '如何用你的优势挡住这些威胁？'},
    {'label': 'WT · 劣势 + 威胁', 'hint': '如何边补劣势边防威胁？'},
  ];

  // 用于在组合分析步骤显示对应的格子内容
  final List<List<int>> _combinationRefs = [
    [0, 2], // SO: S + O
    [1, 2], // WO: W + O
    [0, 3], // ST: S + T
    [1, 3], // WT: W + T
  ];

  // 步骤0-3的标签（用于“至少填一个”检查）
  final List<String> _swotLabels = ['S', 'W', 'O', 'T'];

  @override
  void initState() {
    super.initState();
    // 深拷贝 initialTask
    _draft = ExploreTask(
      id: widget.initialTask.id,
      scaffoldCardType: widget.initialTask.scaffoldCardType,
      scaffoldAnswers: List.from(widget.initialTask.scaffoldAnswers),
      actions: widget.initialTask.actions
          .map((a) => NoteSubtask(
                id: a.id,
                title: a.title,
                isDone: a.isDone,
                completedAt: a.completedAt,
                mood: a.mood,
                moodSummary: a.moodSummary,
                createdAt: a.createdAt,
              ))
          .toList(),
      findings: widget.initialTask.findings,
      status: widget.initialTask.status,
      createdAt: widget.initialTask.createdAt,
      updatedAt: widget.initialTask.updatedAt,
      completedAt: widget.initialTask.completedAt,
    );

    _inputController = TextEditingController();

    // 恢复已保存的数据
    if (_draft.scaffoldAnswers.isNotEmpty) {
      final answers = _draft.scaffoldAnswers;
      for (int i = 0; i < answers.length && i < 8; i++) {
        _answers[i] = answers[i]['value'] ?? '';
      }
      // 判断进度
      int lastAnsweredStep = -1;
      for (int i = 0; i < 8; i++) {
        if (_answers[i].isNotEmpty) {
          lastAnsweredStep = i;
        }
      }
      // 如果有行动，说明已到行动步骤
      if (_draft.actions.isNotEmpty) {
        _action = _draft.actions.first.title;
        _currentStep = 8;
        _inputController.text = _action;
      } else if (lastAnsweredStep >= 0) {
        _currentStep = lastAnsweredStep + 1;
        if (_currentStep > 8) _currentStep = 8;
        if (_currentStep < 8) {
          _inputController.text = _answers[_currentStep];
        }
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ─── 辅助方法 ─────────────────────────────

  bool _isSwotStep(int step) => step >= 0 && step <= 3;
  bool _isCombinationStep(int step) => step >= 4 && step <= 7;
  bool _isActionStep(int step) => step == 8;

  bool _hasAnySwotFilled() {
    for (int i = 0; i < 4; i++) {
      if (_answers[i].trim().isNotEmpty) return true;
    }
    return false;
  }

  int _filledSwotCount() {
    int count = 0;
    for (int i = 0; i < 4; i++) {
      if (_answers[i].trim().isNotEmpty) count++;
    }
    return count;
  }

  bool _hasAnyCombinationFilled() {
    for (int i = 4; i < 8; i++) {
      if (_answers[i].trim().isNotEmpty) return true;
    }
    return false;
  }

  // ─── 导航逻辑 ─────────────────────────────

  void _nextStep() {
    final text = _inputController.text.trim();

    // 如果当前是SWOT步骤（0-3），保存内容（可以为空）
    if (_isSwotStep(_currentStep)) {
      _answers[_currentStep] = text;
    } else if (_isCombinationStep(_currentStep)) {
      _answers[_currentStep] = text;
    } else if (_isActionStep(_currentStep)) {
      _action = text;
    }

    // 如果是SWOT步骤3（T），检查是否至少填了一个SWOT格子
    if (_currentStep == 3) {
      if (!_hasAnySwotFilled()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请至少填写一个 SWOT 格子（S/W/O/T）'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
      _inputController.clear();
      // 如果进入行动步骤，回显已保存的行动
      if (_currentStep == 8 && _action.isNotEmpty) {
        _inputController.text = _action;
      }
      // 如果进入组合分析步骤，可以回显已保存的内容
      if (_isCombinationStep(_currentStep) && _answers[_currentStep].isNotEmpty) {
        _inputController.text = _answers[_currentStep];
      }
    });
  }

  void _skipStep() {
    final text = _inputController.text.trim();

    // 保存当前输入（如果有）
    if (_isSwotStep(_currentStep)) {
      _answers[_currentStep] = text;
    } else if (_isCombinationStep(_currentStep)) {
      _answers[_currentStep] = text;
    }

    // 如果是SWOT步骤3（T），检查是否至少填了一个SWOT格子
    if (_currentStep == 3) {
      if (!_hasAnySwotFilled()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请至少填写一个 SWOT 格子（S/W/O/T）'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
      _inputController.clear();
      if (_currentStep == 8 && _action.isNotEmpty) {
        _inputController.text = _action;
      }
      if (_isCombinationStep(_currentStep) && _answers[_currentStep].isNotEmpty) {
        _inputController.text = _answers[_currentStep];
      }
    });
  }

  void _prevStep() {
    if (_currentStep == 0) return;

    setState(() {
      _currentStep--;
      _inputController.clear();
      if (_isSwotStep(_currentStep)) {
        _inputController.text = _answers[_currentStep];
      } else if (_isCombinationStep(_currentStep)) {
        _inputController.text = _answers[_currentStep];
      } else if (_isActionStep(_currentStep)) {
        _inputController.text = _action;
      }
    });
  }

  // ─── 确认逻辑 ─────────────────────────────

  void _confirm() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _action = text;

    // 组装 scaffoldAnswers（8步：4个格子 + 4个组合分析）
    final answers = <Map<String, String>>[];
    for (int i = 0; i < 8; i++) {
      answers.add({
        'label': _stepConfigs[i]['label']!,
        'value': _answers[i],
      });
    }

    // 组装 actions（唯一行动）
    final actions = [
      NoteSubtask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
      ),
    ];

    final confirmed = _draft.copyWith(
      scaffoldCardType: 'swot',
      scaffoldAnswers: answers,
      actions: actions,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentStep = 9;
    });

    widget.onConfirmed(confirmed);
  }

  // ─── 是否显示跳过按钮 ──────────────────────────

  bool get _showSkipButton {
    // SWOT步骤（0-3）和组合分析步骤（4-7）都显示跳过
    return _isSwotStep(_currentStep) || _isCombinationStep(_currentStep);
  }

  // ─── 组合分析上下文 ──────────────────────────

  String _getCombinationContext(int step) {
    final refs = _combinationRefs[step - 4];
    final parts = <String>[];
    for (final ref in refs) {
      final label = _stepConfigs[ref]['label']!;
      final value = _answers[ref].trim().isNotEmpty ? _answers[ref] : '（未填写）';
      parts.add('$label: $value');
    }
    return parts.join('\n');
  }

  // ─── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasText = _inputController.text.trim().isNotEmpty;
    final totalSteps = 9; // 0-8
    final isLastSwotStep = _currentStep == 3;
    final isLastCombinationStep = _currentStep == 7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 步骤进度 ──────────────────────────────
          if (_currentStep < 9) ...[
            Row(
              children: [
                Text(
                  '第 ${_currentStep + 1} 步 / 共 $totalSteps 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / $totalSteps',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentStep + 1) / totalSteps,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
          ],

          // ─── SWOT 格子 (0-3) ──────────────────────────
          if (_isSwotStep(_currentStep)) ...[
            Text(
              _stepConfigs[_currentStep]['label']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _stepConfigs[_currentStep]['hint']!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            if (_currentStep == 3) ...[
              const SizedBox(height: 4),
              Text(
                '已填写 ${_filledSwotCount()} / 4 个格子',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下你的分析...',
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _prevStep,
                    child: const Text('上一步'),
                  ),
                if (_showSkipButton) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _skipStep,
                    child: Text(
                      isLastSwotStep ? '跳过并继续' : '跳过',
                      style: TextStyle(
                        color: isLastSwotStep && !_hasAnySwotFilled()
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasText ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('下一步 →'),
                ),
              ],
            ),
          ],

          // ─── 组合分析 (4-7) ──────────────────────────
          if (_isCombinationStep(_currentStep)) ...[
            Text(
              _stepConfigs[_currentStep]['label']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _stepConfigs[_currentStep]['hint']!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            // 显示对应的 SWOT 格子内容作为上下文
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                _getCombinationContext(_currentStep),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下你的分析...',
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _prevStep,
                  child: const Text('上一步'),
                ),
                if (_showSkipButton) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _skipStep,
                    child: const Text('跳过'),
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasText ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('下一步 →'),
                ),
              ],
            ),
          ],

          // ─── 行动步骤 (8) ──────────────────────────
          if (_isActionStep(_currentStep)) ...[
            Row(
              children: [
                Text(
                  '第 ${_currentStep + 1} 步 / 共 $totalSteps 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / $totalSteps',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: 1.0,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              '🚀 选择一条行动',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '综合以上分析，你决定采取哪一条行动？',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            // 显示已填的分析摘要
            if (_hasAnySwotFilled() || _hasAnyCombinationFilled()) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 已填分析摘要',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._buildSummaryItems(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下你的具体行动...',
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _prevStep,
                  child: const Text('上一步'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _inputController.text.trim().isEmpty ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确认并折叠'),
                ),
              ],
            ),
          ],

          // ─── 折叠展示态 (9) ──────────────────────────
          if (_currentStep == 9) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '✅ 当前探究已折叠',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: widget.onCancel,
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
    );
  }

  // ─── 摘要构建 ─────────────────────────────

  List<Widget> _buildSummaryItems() {
    final items = <Widget>[];
    final labels = ['S', 'W', 'O', 'T', 'SO', 'WO', 'ST', 'WT'];
    for (int i = 0; i < 8; i++) {
      if (_answers[i].trim().isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              '• $labels[i]: ${_answers[i].trim()}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
    if (items.isEmpty) {
      items.add(
        const Text(
          '（暂无分析内容）',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      );
    }
    return items;
  }
}