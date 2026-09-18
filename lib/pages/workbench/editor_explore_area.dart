import 'package:flutter/material.dart';
import '../../models/explore_task.dart';
import '../../models/note.dart';

/// 探究缩略区——工作台零件 · 丁方案第 2 步
///
/// 原 _buildExploreSummaryTile——三处调用合一
/// 点卡片 → 回调打开只读概览弹窗（ExploreTaskSummaryDialog）
class EditorExploreArea extends StatelessWidget {
  final NotebookEntry entry;
  final VoidCallback onTap;

  const EditorExploreArea({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = entry.exploreTasks.length;
    final done = entry.exploreTasks
        .where((t) => t.status == ExploreTaskStatus.completed)
        .length;
    final question = entry.inquiryQuestion ?? '未设置主问题';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.purple.shade200, width: 0.5),
      ),
      color: Colors.purple.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.explore, color: Colors.purple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '共 $total 个行动 · 已完成 $done / $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}