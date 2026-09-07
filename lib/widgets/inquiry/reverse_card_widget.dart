// lib/widgets/inquiry/reverse_card_widget.dart
// 逆向思维卡组件 — 从反面寻找突破口
// 流程：当前想法 → 相反观点 → 反向行动预测 → 最小反向行动 → 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';

class ReverseCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const ReverseCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<ReverseCardWidget> createState() => _ReverseCardWidgetState();
}

class _ReverseCardWidgetState extends State<ReverseCardWidget> {
  // ─── 状态机 ─────────────────────────────
  // 0 = 当前想法，1 = 相反观点，2 = 反向行动预测，3 = 最小反向行动，4 = 折叠展示态
  int _currentStep = 0;
  int _stopAtStep = -1;

  // ─── 答案存储 ─────────────────────────────
  final List<String> _answers = List.filled(3, '');
  String _minAction = '';

  // ─── 控制器 ─────────────────────────────
  late TextEditingController _inputController;

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

  // ─── 步骤配置 ─────────────────────────────
  final List<String> _stepLabels = [
    '当前想法',
    '相反观点',
    '反向行动预测',
  ];

  final List<String> _stepHints = [
    '写下你当前的想法或判断...',
    '反过来想，完全相反的观点是什么？',
    '如果按相反观点行动，可能会发生什么？',
  ];

  // ✅ 每个示例文案末尾补充明确提示
  final List<String> _stepExamples = [
    '例：我觉得应该先做完所有准备再开始（这是例子，写你自己的）',
    '例：先不准备，直接开始做会怎样？（这是例子，写你自己的）',
    '例：直接开始可能会失败，但也可能更快得到反馈（这是例子，写你自己的）',
  ];

  @override
  void initState() {
    super.initState();
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

    if (_draft.scaffoldAnswers.isNotEmpty) {
      final answers = _draft.scaffoldAnswers;
      for (int i = 0; i < answers.length && i < 3; i++) {
        _answers[i] = answers[i]['value'] ?? '';
      }
      int lastAnsweredStep = -1;
      for (int i = 0; i < 3; i++) {
        if (_answers[i].isNotEmpty) {
          lastAnsweredStep = i;
        }
      }
      if (_draft.actions.isNotEmpty) {
        _minAction = _draft.actions.first.title;
        _currentStep = 3;
        _inputController.text = _minAction;
      } else if (lastAnsweredStep >= 0) {
        _currentStep = lastAnsweredStep + 1;
        if (_currentStep > 3) _currentStep = 3;
        if (_currentStep < 3) {
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

  void _nextStep() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    if (_currentStep < 3) {
      _answers[_currentStep] = text;
    } else if (_currentStep == 3) {
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
      if (_currentStep < 3) {
        _inputController.text = _answers[_currentStep];
      } else if (_currentStep == 3) {
        _inputController.text = _minAction;
      }
    });
  }

  void _stopAndJump() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty && _currentStep < 3) {
      _answers[_currentStep] = text;
    }

    _stopAtStep = _currentStep;

    setState(() {
      _currentStep = 3;
      _inputController.clear();
      if (_minAction.isNotEmpty) {
        _inputController.text = _minAction;
      }
    });
  }

  void _backToStopStep() {
    if (_stopAtStep < 0) {
      setState(() {
        _currentStep = 2;
        _inputController.clear();
        _inputController.text = _answers[2];
      });
      return;
    }

    setState(() {
      _currentStep = _stopAtStep;
      _inputController.clear();
      _inputController.text = _answers[_stopAtStep];
    });
  }

  void _backToPrediction() {
    setState(() {
      _currentStep = 2;
      _inputController.clear();
      _inputController.text = _answers[2];
    });
  }

  void _confirm() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _minAction = text;

    final answers = <Map<String, String>>[];
    for (int i = 0; i < 3; i++) {
      answers.add({
        'label': _stepLabels[i],
        'value': _answers[i],
      });
    }

    final actions = [
      NoteSubtask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
      ),
    ];

    final confirmed = _draft.copyWith(
      scaffoldCardType: 'reverse',
      scaffoldAnswers: answers,
      actions: actions,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentStep = 4;
    });

    widget.onConfirmed(confirmed);
  }

  bool get _showStopButton {
    return _currentStep >= 1 && _currentStep <= 2;
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _inputController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 追问轮次 (0~2) ──────────────────────────
          if (_currentStep < 3) ...[
            Row(
              children: [
                Text(
                  '第 ${_currentStep + 1} 步 / 共 4 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / 4',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              backgroundColor: Colors.grey.shade200,
              color: Colors.deepOrange,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              _stepHints[_currentStep],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange.shade700,
              ),
            ),
            const SizedBox(height: 4),
            // ✅ 极轻示例文案，末尾包含明确提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💡 ${_stepExamples[_currentStep]}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.deepOrange.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
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
                if (_showStopButton) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _stopAndJump,
                    child: const Text('我答够了'),
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasText ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('下一步 →'),
                ),
              ],
            ),
          ],

          // ─── 最小反向行动 (3) ──────────────────────────
          if (_currentStep == 3) ...[
            Text(
              '🚀 最小反向行动',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '你能尝试的最小的反向行动是什么？',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            // ✅ 最小反向行动示例也包含明确提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '💡 例：今天先直接开始做 5 分钟，不准备（这是例子，写你自己的）',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.deepOrange.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '写下最小反向行动...',
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
                  onPressed: _backToStopStep,
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

          // ─── 折叠展示态 (4) ──────────────────────────
          if (_currentStep == 4) ...[
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