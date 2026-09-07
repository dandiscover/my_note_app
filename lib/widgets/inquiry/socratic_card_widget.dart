// lib/widgets/inquiry/socratic_card_widget.dart
// 苏格拉底卡组件 — 通过追问检验信念/想法
// 流程：想法 → 证据 → 反例 → 默认前提 → 相反观点 → 完整性判断 → 最小一步 → 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';

class SocraticCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const SocraticCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<SocraticCardWidget> createState() => _SocraticCardWidgetState();
}

class _SocraticCardWidgetState extends State<SocraticCardWidget> {
  // ─── 状态机 ─────────────────────────────
  // 0~5 = 追问，6 = 最小一步，7 = 折叠展示态
  int _currentStep = 0;
  int _stopAtStep = -1; // -1 表示未使用“我答够了”

  // ─── 答案存储 ─────────────────────────────
  final List<String> _answers = List.filled(6, '');
  String _minStep = '';

  // ─── 控制器 ─────────────────────────────
  late TextEditingController _inputController;

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

  // ─── 步骤配置 ─────────────────────────────
  final List<String> _stepLabels = [
    '待检验的想法',
    '证据支持',
    '反例',
    '默认前提',
    '相反观点',
    '完整性判断',
  ];

  final List<String> _stepHints = [
    '写下你想检验的判断或想法...',
    '你有什么证据支持这个判断？',
    '有没有一次，事情不是这样的？',
    '这个结论背后，你默认了什么？',
    '如果换一个完全相反的人，他会怎么说？',
    '你现在还觉得原来的想法完整吗？',
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
      for (int i = 0; i < answers.length && i < 6; i++) {
        _answers[i] = answers[i]['value'] ?? '';
      }
      // 判断哪些步骤已有答案，用于恢复进度
      int lastAnsweredStep = -1;
      for (int i = 0; i < 6; i++) {
        if (_answers[i].isNotEmpty) {
          lastAnsweredStep = i;
        }
      }
      if (lastAnsweredStep >= 0) {
        _currentStep = lastAnsweredStep + 1;
        if (_currentStep > 6) _currentStep = 6;
        // 如果最后一步是步骤6，说明已进入最小一步
        if (_currentStep == 6 && _draft.actions.isNotEmpty) {
          _minStep = _draft.actions.first.title;
        }
        // 回显当前步骤的答案
        if (_currentStep < 6) {
          _inputController.text = _answers[_currentStep];
        } else if (_currentStep == 6) {
          _inputController.text = _minStep;
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
      _minStep = text;
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
      // 回显对应步骤的答案
      if (_currentStep < 6) {
        _inputController.text = _answers[_currentStep];
      } else if (_currentStep == 6) {
        _inputController.text = _minStep;
      }
    });
  }

  void _stopAndJump() {
    // 保存当前输入（如果有）
    final text = _inputController.text.trim();
    if (text.isNotEmpty && _currentStep < 6) {
      _answers[_currentStep] = text;
    }

    // 记录停止位置
    _stopAtStep = _currentStep;

    setState(() {
      _currentStep = 5; // 跳到完整性判断
      _inputController.clear();
      // 如果步骤5已有答案，回显
      if (_answers[5].isNotEmpty) {
        _inputController.text = _answers[5];
      }
    });
  }

  void _backToStopStep() {
    if (_stopAtStep < 0) {
      // 没有“我答够了”记录，回到步骤4
      setState(() {
        _currentStep = 4;
        _inputController.clear();
        _inputController.text = _answers[4];
      });
      return;
    }

    setState(() {
      _currentStep = _stopAtStep;
      _inputController.clear();
      _inputController.text = _answers[_stopAtStep];
    });
  }

  void _backToIntegrity() {
    setState(() {
      _currentStep = 5;
      _inputController.clear();
      _inputController.text = _answers[5];
    });
  }

  // ─── 确认逻辑 ─────────────────────────────

  void _confirm() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // 保存最小一步
    _minStep = text;

    // 组装 scaffoldAnswers（前6步）
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
      scaffoldCardType: 'socratic',
      scaffoldAnswers: answers,
      actions: actions,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentStep = 7;
    });

    widget.onConfirmed(confirmed);
  }

  // ─── 是否显示“我答够了”按钮 ──────────────────

  bool get _showStopButton {
    // 步骤0不显示，步骤1~4显示
    return _currentStep >= 1 && _currentStep <= 4;
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
          // ─── 追问轮次 (0~4) ──────────────────────────
          if (_currentStep < 5) ...[
            Row(
              children: [
                Text(
                  '第 ${_currentStep + 1} 步 / 共 6 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / 6',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              backgroundColor: Colors.grey.shade200,
              color: Colors.indigo,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              _stepHints[_currentStep],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _stepHints[_currentStep],
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
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('下一步 →'),
                ),
              ],
            ),
          ],

          // ─── 完整性判断 (5) ──────────────────────────
          if (_currentStep == 5) ...[
            Row(
              children: [
                Text(
                  '第 6 步 / 共 6 步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                Text(
                  '6 / 6',
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
              color: Colors.indigo,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              _stepHints[5],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _inputController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _stepHints[5],
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
                  onPressed: _inputController.text.trim().isEmpty ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('确认 →'),
                ),
              ],
            ),
          ],

          // ─── 最小一步 (6) ──────────────────────────
          if (_currentStep == 6) ...[
            Text(
              '🚀 最小一步',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '为了验证这个想法，你能做的最小一步是什么？',
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
                  onPressed: _backToIntegrity,
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