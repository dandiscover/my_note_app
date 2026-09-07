// lib/widgets/explore_task_summary_dialog.dart
// 探究概览弹窗 — 笔记详情页点击缩略图后弹出（只读）
// ✅ 改为 StatefulWidget，构造函数签名保持不变
// ✅ 新增问答记录折叠展示，默认折叠

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/explore_task.dart';

class ExploreTaskSummaryDialog extends StatefulWidget {
  final NotebookEntry entry;

  const ExploreTaskSummaryDialog({
    super.key,
    required this.entry,
  });

  @override
  State<ExploreTaskSummaryDialog> createState() =>
      _ExploreTaskSummaryDialogState();
}

class _ExploreTaskSummaryDialogState
    extends State<ExploreTaskSummaryDialog> {
  final Set<String> _expandedAnswerIds = {};

  void _toggleAnswerExpand(String taskId) {
    setState(() {
      if (_expandedAnswerIds.contains(taskId)) {
        _expandedAnswerIds.remove(taskId);
      } else {
        _expandedAnswerIds.add(taskId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 标题栏 ──────────────────────────────
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.purple, size: 22),
                const SizedBox(width: 8),
                const Text(
                  '📊 探究概览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: '关闭',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 16),

            // ─── 主问题 ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                '🎯 ${entry.inquiryQuestion ?? "未设置主问题"}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 任务列表 ──────────────────────────────
            Expanded(
              child: entry.exploreTasks.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无探究任务',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: entry.exploreTasks.asMap().entries.map(
                          (entry) {
                            final idx = entry.key;
                            final task = entry.value;
                            return _buildTaskCard(task, idx);
                          },
                        ).toList(),
                      ),
                    ),
            ),

            // ─── 新理解区域（如有） ──────────────────
            if (entry.newUnderstanding != null &&
                entry.newUnderstanding!.isNotEmpty) ...[
              const Divider(height: 16),
              _buildNewUnderstandingArea(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(ExploreTask task, int index) {
    final isCompleted = task.status == ExploreTaskStatus.completed;
    final doneCount = task.actions.where((a) => a.isDone).length;
    final totalCount = task.actions.length;
    final taskName = task.scaffoldCardType ?? '任务 ${index + 1}';
    final isAnswerExpanded = _expandedAnswerIds.contains(task.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          width: isCompleted ? 1.5 : 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 标题行 ──────────────────────────────
            Row(
              children: [
                Text(
                  taskName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCompleted ? '✅' : '🔄',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompleted ? '已完成' : '进行中',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCompleted
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ─── 子任务完成数 ──────────────────────────
            if (totalCount > 0) ...[
              Text(
                '子任务: $doneCount / $totalCount',
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.green.shade600 : Colors.grey.shade600,
                ),
              ),
            ] else ...[
              Text(
                '暂无子任务',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],

            // ─── 完成时间 ──────────────────────────────
            if (isCompleted && task.completedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                '完成于 ${_formatDate(task.completedAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],

            // ─── 问答记录折叠展示 ──────────────────────
            if (task.scaffoldAnswers.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _toggleAnswerExpand(task.id),
                child: Row(
                  children: [
                    Icon(
                      isAnswerExpanded
                          ? Icons.expand_less
                          : Icons.chevron_right,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '问答记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAnswerExpanded)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: task.scaffoldAnswers.map((answer) {
                      final label = answer['label']?.toString() ?? '';
                      final value = answer['value']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],

            // ─── 发现内容 ──────────────────────────────
            if (task.findings != null && task.findings!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 发现',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.findings!,
                      style: const TextStyle(fontSize: 13),
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

  Widget _buildNewUnderstandingArea() {
    final entry = widget.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 新理解',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Text(
            entry.newUnderstanding!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}