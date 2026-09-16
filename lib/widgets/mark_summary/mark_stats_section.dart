// lib/widgets/mark_summary/mark_stats_section.dart
// 标记统计区 — 第四轮批3 新增
//
// 职责：接收 List<MarkSummaryItem>，渲染两块：
//   1. 分布——按 tag 的横条列表
//   2. 趋势——最近 6 个月标记增量的月度柱状图
//
// 责任分层：
//   数据加载 → 调用方（InsightPage）
//   本组件 → 只做聚合 + 展示，不碰数据库
//
// 依据：方案 v2 §三 问2 / §五 改动 1。

import 'package:flutter/material.dart';
import 'mark_summary_item.dart';

class MarkStatsSection extends StatelessWidget {
  final List<MarkSummaryItem> items;

  const MarkStatsSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmpty();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDistribution(),
        const SizedBox(height: 12),
        _buildTrend(),
      ],
    );
  }

  Widget _buildEmpty() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.bar_chart, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Text(
              '暂无标记统计',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 分布 ──────────────────────────────

  Widget _buildDistribution() {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.tag] = (counts[item.tag] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = items.length;
    final display = sorted.take(8).toList();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🏷️ 标记分布',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '共 $total 条',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...display.map((e) => _buildDistBar(e.key, e.value, total)),
            if (sorted.length > display.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '还有 ${sorted.length - display.length} 个标记…',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistBar(String tag, int count, int total) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              tag,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 趋势 ──────────────────────────────

  Widget _buildTrend() {
    final now = DateTime.now();
    final months = <DateTime>[];
    // 当月 + 前 5 个月（滚动窗口，跨年不中断）
    for (int i = 5; i >= 0; i--) {
      months.add(DateTime(now.year, now.month - i, 1));
    }
    final counts = <String, int>{};
    for (final m in months) {
      counts[_monthKey(m)] = 0;
    }
    for (final item in items) {
      final parsed = _parseDate(item.createdAt);
      if (parsed == null) continue;
      final key = _monthKey(DateTime(parsed.year, parsed.month, 1));
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }
    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 标记趋势（近 6 月）',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: Row(
                children: months.map((m) {
                  final count = counts[_monthKey(m)] ?? 0;
                  // ✅ 比例因子（0..1）——高度交给 FractionallySizedBox 自适应，
                  //   不再按固定 60px 估算，避免与文字合计溢出。
                  final factor = maxCount == 0
                      ? 0.0
                      : (count / maxCount).clamp(0.0, 1.0).toDouble();
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: factor,
                            child: Container(
                              width: 14,
                              decoration: BoxDecoration(
                                color: Colors.purple.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.month}月',
                          style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}