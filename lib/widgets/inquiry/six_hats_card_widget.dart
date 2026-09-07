// lib/widgets/inquiry/six_hats_card_widget.dart
// 六顶思考帽卡组件 — 多视角全方位审视问题
// 流程：白帽（事实）→ 红帽（感觉）→ 黑帽（风险）→ 黄帽（收益）→ 绿帽（创意）→ 蓝帽（决策）→ 最小一步 → 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';

class SixHatsCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const SixHatsCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<SixHatsCardWidget> createState() => _SixHatsCardWidgetState();
}

class _SixHatsCardWidgetState extends State<SixHatsCardWidget> {
  // ─── 状态机 ─────────────────────────────
  // 0~5 = 六顶帽子，6 = 最小一步，7 = 折叠展示态
  int _currentStep = 0;

  // ─── 答案存储 ─────────────────────────────
  final List<String> _answers = List.filled(6, '');
  String _minAction = '';

  // ─── 控制器 ─────────────────────────────
  late TextEditingController _inputController;

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

  // ─── 步骤配置 ─────────────────────────────
  final List<String> _stepLabels = [
    '白帽 — 事实',
    '红帽 — 感觉',
    '黑帽 — 风险',
    '黄帽 — 收益',
    '绿帽 — 创意',
    '蓝帽 — 决策',
  ];

  final List<String> _stepHints = [
    '关于这件事，我们确切知道什么？',
    '你现在的第一感觉是什么？',
    '如果事情不顺利，最坏的结果是什么？',
    '如果顺利，最好的可能是什么？',
    '有没有更大胆、更突破常规的想法？',
    '综合所有角度，现在该做什么？',
  ];

  // ✅ 白帽和红帽特殊提示
  final Map<int, String?> _stepExtraHints = {
    0: '只说事实，不评价。',
    1: '直接说感觉，不用讲道理。',
  };

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
      for (int i = 0; i < answers.length && i < 6; i++) {
        _answers[i] = answers[i]['value'] ?? '';
      }
      // 判断进度
      int lastAnsweredStep = -1;
      for (int i = 0; i < 6; i++) {
        if (_answers[i].isNotEmpty) {
          lastAnsweredStep = i;
        }
      }
      // 如果有行动，说明已到最小一步步骤
      if (_draft.actions.isNotEmpty) {
        _minAction = _draft.actions.first.title;
        _currentStep = 6;
        _inputController.text = _minAction;
      } else if (lastAnsweredStep >= 0) {
        _currentStep = lastAnsweredStep + 1;
        if (_currentStep > 6) _currentStep = 6;
        if (_currentStep < 6) {
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

  // ─── 导航逻辑 ─────────────────────────────

  void _nextStep() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (_currentStep < 6) {
      _answers[_currentStep] = text;
    } else if (_currentStep == 6) {
      _minAction = text;
    }

    setState(() {
      _currentStep++;
      _inputController.clear();
    });
  }

  void _prevStep() {
    if (_currentStep == 0) return;

    setState(() {
      _currentStep--;
      _inputController.clear();
      if (_currentStep < 6) {
        _inputController.text = _answers[_currentStep];
      } else if (_currentStep == 6) {
        _inputController.text = _minAction;
      }
    });
  }

  // ─── 确认逻辑 ─────────────────────────────

  void _confirm() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _minAction = text;

    // 组装 scaffoldAnswers（6顶帽子）
    final answers = <Map<String, String>>[];
    for (int i = 0; i < 6; i++) {
      answers.add({
        'label': _stepLabels[i],
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
      scaffoldCardType: 'six_hats',
      scaffoldAnswers: answers,
      actions: actions,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentStep = 7;
    });

    widget.onConfirmed(confirmed);
  }

  // ─── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasText = _inputController.text.trim().isNotEmpty;
    final extraHint = _stepExtraHints[_currentStep];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 六顶帽子轮次 (0~5) ──────────────────────────
          if (_currentStep < 6) ...[
            Row(
              children: [
                Text(
                  '第 ${_currentStep + 1} 步 / 共 7 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / 7',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 7,
              backgroundColor: Colors.grey.shade200,
              color: Colors.purple,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              _stepHints[_currentStep],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
            // ✅ 白帽和红帽特殊提示
            if (extraHint != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '💡 $extraHint',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下你的回答...',
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
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasText ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('下一步 →'),
                ),
              ],
            ),
          ],

          // ─── 最小一步 (6) ──────────────────────────
          if (_currentStep == 6) ...[
            Text(
              '🚀 把它变成一个具体的小行动',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '基于蓝帽决策，你具体要做的第一步是什么？',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下具体行动...',
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

          // ─── 折叠展示态 (7) ──────────────────────────
          if (_currentStep == 7) ...[
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
}