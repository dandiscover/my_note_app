// lib/widgets/inquiry/minimal_step_card_widget.dart
// 最小一步卡组件 — 三问逐步展开 + 行动列表编辑 + 确认折叠
// 接口：initialTask（草稿）→ onConfirmed（回传完整任务）→ onCancel（取消返回）

import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note_subtask.dart';
import 'action_list_editor.dart';

class MinimalStepCardWidget extends StatefulWidget {
  final ExploreTask initialTask;
  final void Function(ExploreTask) onConfirmed;
  final VoidCallback onCancel;

  const MinimalStepCardWidget({
    super.key,
    required this.initialTask,
    required this.onConfirmed,
    required this.onCancel,
  });

  @override
  State<MinimalStepCardWidget> createState() => _MinimalStepCardWidgetState();
}

class _MinimalStepCardWidgetState extends State<MinimalStepCardWidget> {
  // ─── 状态机 ─────────────────────────────
  int _currentStep = 0; // 0,1,2 = 三问，3 = 行动区，4 = 折叠展示态

  // ─── 三问控制器 ─────────────────────────────
  late TextEditingController _q1Controller;
  late TextEditingController _q2Controller;
  late TextEditingController _q3Controller;

  // ─── 行动列表 ─────────────────────────────
  List<NoteSubtask> _actions = [];

  // ─── 深拷贝 ─────────────────────────────
  late ExploreTask _draft;

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

    _q1Controller = TextEditingController();
    _q2Controller = TextEditingController();
    _q3Controller = TextEditingController();

    // 如果草稿已有三问答案，恢复显示
    if (_draft.scaffoldAnswers.isNotEmpty) {
      final answers = _draft.scaffoldAnswers;
      if (answers.length > 0) _q1Controller.text = answers[0]['value'] ?? '';
      if (answers.length > 1) _q2Controller.text = answers[1]['value'] ?? '';
      if (answers.length > 2) _q3Controller.text = answers[2]['value'] ?? '';
    }

    // 恢复行动列表
    _actions = _draft.actions
        .map((a) => NoteSubtask(
              id: a.id,
              title: a.title,
              isDone: a.isDone,
              completedAt: a.completedAt,
              mood: a.mood,
              moodSummary: a.moodSummary,
              createdAt: a.createdAt,
            ))
        .toList();
  }

  @override
  void dispose() {
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  void _onActionsChanged(List<NoteSubtask> actions) {
    setState(() {
      _actions = actions
          .map((a) => NoteSubtask(
                id: a.id,
                title: a.title,
                isDone: a.isDone,
                completedAt: a.completedAt,
                mood: a.mood,
                moodSummary: a.moodSummary,
                createdAt: a.createdAt,
              ))
          .toList();
    });
  }

  void _confirm() {
    // 组装三问答案
    final answers = [
      {'label': '现在最困扰我的是什么？', 'value': _q1Controller.text.trim()},
      {'label': '我能做的最小一步是什么？', 'value': _q2Controller.text.trim()},
      {'label': '做完这一步会怎样？', 'value': _q3Controller.text.trim()},
    ];

    final confirmed = _draft.copyWith(
      scaffoldCardType: 'minimal_step',
      scaffoldAnswers: answers,
      actions: _actions
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
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentStep = 4;
    });

    widget.onConfirmed(confirmed);
  }

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 步骤 0-2：三问 ──────────────────────────
          if (_currentStep < 3) ...[
            Text(
              stepLabels[_currentStep],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stepQuestions[_currentStep],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controllers[_currentStep],
              maxLines: 3,
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
                if (_currentStep < 2) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controllers[_currentStep].text.trim().isEmpty
                        ? null
                        : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('下一步 →'),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controllers[_currentStep].text.trim().isEmpty
                        ? null
                        : _nextStep,
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

          // ─── 步骤 3：行动区 ──────────────────────────
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
            const SizedBox(height: 8),
            // ─── 提示：行动已生成，去任务页完成 ──────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '行动已生成，去任务页完成',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActionListEditor(
              initialActions: _actions,
              onActionsChanged: _onActionsChanged,
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
                  onPressed: _actions.isEmpty ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确认并折叠'),
                ),
              ],
            ),
          ],

          // ─── 步骤 4：折叠展示态 ──────────────────────
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