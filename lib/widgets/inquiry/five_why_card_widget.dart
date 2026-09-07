// lib/widgets/inquiry/five_why_card_widget.dart
// 5 Why 卡组件 — 循环追问 → 根因总结 → 最小一步（自动成为唯一行动）→ 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';

class FiveWhyCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const FiveWhyCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<FiveWhyCardWidget> createState() => _FiveWhyCardWidgetState();
}

class _FiveWhyCardWidgetState extends State<FiveWhyCardWidget> {
  // ─── 状态机 ─────────────────────────────
  // 0~4 = 追问轮次，5 = 根因总结，6 = 最小一步输入，7 = 折叠展示态
  int _currentStep = 0;

  // ─── 5 Why 数据 ─────────────────────────────
  final List<String> _whyAnswers = [];
  int _stopAtStep = 0;
  String _whyRootCause = '';
  String _whyMinStep = '';
  late TextEditingController _inputController;

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

  // ─── 动态追问文案 ─────────────────────────────
  String get _currentPrompt {
    if (_currentStep == 0) {
      return '为什么会有这个困惑？';
    }
    final previousIndex = _currentStep - 1;
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

    // 恢复已保存的数据（如从草稿恢复）
    if (_draft.scaffoldAnswers.isNotEmpty) {
      for (final answer in _draft.scaffoldAnswers) {
        final label = answer['label'] as String? ?? '';
        final value = answer['value'] as String? ?? '';
        if (label.startsWith('第') && label.contains('层为什么')) {
          _whyAnswers.add(value);
        } else if (label == '根因总结') {
          _whyRootCause = value;
          _currentStep = 5;
        }
      }
      if (_whyRootCause.isNotEmpty && _draft.actions.isNotEmpty) {
        _whyMinStep = _draft.actions.first.title;
        _currentStep = 6;
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ─── 追问逻辑 ─────────────────────────────

  void _whyNext() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _whyAnswers.add(text);
    setState(() {
      _currentStep++;
      _inputController.clear();
    });
  }

  void _whyStop() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      _whyAnswers.add(text);
    }
    _stopAtStep = _currentStep;
    setState(() {
      _currentStep = 5;
      _inputController.clear();
    });
  }

  void _whyPrev() {
    if (_currentStep > 0 && _currentStep < 5) {
      setState(() {
        _currentStep--;
        if (_whyAnswers.isNotEmpty) {
          _whyAnswers.removeLast();
        }
        _inputController.clear();
      });
    }
  }

  // ─── 根因逻辑 ─────────────────────────────

  void _saveRootCause() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _whyRootCause = text;
      _inputController.clear();
      _currentStep = 6;
    });
  }

  void _backToStopStep() {
    setState(() {
      _currentStep = _stopAtStep;
      _inputController.clear();
      if (_stopAtStep < _whyAnswers.length) {
        _inputController.text = _whyAnswers[_stopAtStep];
      }
    });
  }

  // ─── 最小一步逻辑 ─────────────────────────────

  void _backToRootCause() {
    setState(() {
      _currentStep = 5;
      _inputController.text = _whyRootCause;
    });
  }

  void _confirm() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // 最小一步自动成为唯一行动
    final actions = [
      NoteSubtask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
      ),
    ];

    // 组装 scaffoldAnswers：所有追问答案 + 根因总结
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

    final confirmed = _draft.copyWith(
      scaffoldCardType: 'five_why',
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
                  '第 ${_currentStep + 1} 层',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
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
              color: Colors.teal,
              minHeight: 4,
            ),
            const SizedBox(height: 8),
            Text(
              _currentPrompt,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
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

          // ─── 根因总结 (5) ──────────────────────────
          if (_currentStep == 5) ...[
            Text(
              '📌 根因总结',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '综合以上回答，你认为根本原因是什么？',
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
                hintText: '写下根因总结...',
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
                  onPressed: _inputController.text.trim().isEmpty ? null : _saveRootCause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确认根因'),
                ),
              ],
            ),
          ],

          // ─── 最小一步输入 (6) ──────────────────────────
          if (_currentStep == 6) ...[
            Text(
              '🚀 最小一步',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '基于以上分析，你能做的最小一步是什么？',
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
                  onPressed: _backToRootCause,
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