// lib/widgets/inquiry/second_order_card_widget.dart
// 二阶思考卡组件 — 看一个决定更长远、更连锁的后果
// 流程：直接后果 → 再接下来 → 影响谁（可选） → 还值得做吗 → 最小一步 → 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';

class SecondOrderCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const SecondOrderCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<SecondOrderCardWidget> createState() => _SecondOrderCardWidgetState();
}

class _SecondOrderCardWidgetState extends State<SecondOrderCardWidget> {
  // ─── 状态机 ─────────────────────────────
  // 0 = 直接后果，1 = 再接下来，2 = 影响谁（可选），3 = 还值得做吗，4 = 最小一步，5 = 折叠展示态
  int _currentStep = 0;

  // ─── 答案存储 ─────────────────────────────
  final List<String> _answers = List.filled(4, '');
  String _minAction = '';

  // ─── 控制器 ─────────────────────────────
  late TextEditingController _inputController;

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

  // ─── 步骤配置 ─────────────────────────────
  final List<String> _stepLabels = [
    '直接后果',
    '再接下来',
    '影响谁',
    '还值得做吗',
  ];

  final List<String> _stepHints = [
    '如果做了这个决定，马上会发生什么？',
    '然后呢？再接下来会怎样？',
    '谁会受到影响？他们会怎么做？（可选）',
    '看完这些，你现在还觉得这个决定值得做吗？',
  ];

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
      for (int i = 0; i < answers.length && i < 4; i++) {
        _answers[i] = answers[i]['value'] ?? '';
      }
      // 判断进度
      int lastAnsweredStep = -1;
      for (int i = 0; i < 4; i++) {
        if (_answers[i].isNotEmpty) {
          lastAnsweredStep = i;
        }
      }
      // 如果有行动，说明已到最小一步步骤
      if (_draft.actions.isNotEmpty) {
        _minAction = _draft.actions.first.title;
        _currentStep = 4;
        _inputController.text = _minAction;
      } else if (lastAnsweredStep >= 0) {
        _currentStep = lastAnsweredStep + 1;
        if (_currentStep > 4) _currentStep = 4;
        if (_currentStep < 4) {
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

    if (_currentStep < 4) {
      _answers[_currentStep] = text;
    } else if (_currentStep == 4) {
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
      if (_currentStep < 4) {
        _inputController.text = _answers[_currentStep];
      } else if (_currentStep == 4) {
        _inputController.text = _minAction;
      }
    });
  }

  // ─── 跳过“影响谁”步骤 ─────────────────────────

  void _skipThirdLayer() {
    // 如果当前输入框有内容，也保存；否则保持为空
    final text = _inputController.text.trim();
    if (text.isNotEmpty && _currentStep == 2) {
      _answers[2] = text;
    }

    setState(() {
      _currentStep = 3;
      _inputController.clear();
      // 回显步骤3已有答案
      if (_answers[3].isNotEmpty) {
        _inputController.text = _answers[3];
      }
    });
  }

  // ─── 确认逻辑 ─────────────────────────────

  void _confirm() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _minAction = text;

    // 组装 scaffoldAnswers（前4步）
    final answers = <Map<String, String>>[];
    for (int i = 0; i < 4; i++) {
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
      scaffoldCardType: 'second_order',
      scaffoldAnswers: answers,
      actions: actions,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentStep = 5;
    });

    widget.onConfirmed(confirmed);
  }

  // ─── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasText = _inputController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 追问轮次 (0~3) ──────────────────────────
          if (_currentStep < 4) ...[
            Row(
              children: [
                Text(
                  '第 ${_currentStep + 1} 步 / 共 5 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / 5',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey.shade200,
              color: Colors.brown,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              _stepHints[_currentStep],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _currentStep == 2
                    ? '可选，写不出可以跳过'
                    : '写下你的回答...',
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
                // 步骤2显示跳过按钮
                if (_currentStep == 2) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _skipThirdLayer,
                    child: const Text('我想不到第三层了'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasText ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('下一步 →'),
                ),
              ],
            ),
          ],

          // ─── 最小一步 (4) ──────────────────────────
          if (_currentStep == 4) ...[
            Text(
              '🚀 最小一步',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '基于以上思考，你能做的最小一步是什么？',
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
                hintText: '写下最小一步...',
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

          // ─── 折叠展示态 (5) ──────────────────────────
          if (_currentStep == 5) ...[
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