// lib/widgets/insight/review_stats.dart
// 复习统计栏

import 'package:flutter/material.dart';

class ReviewStats extends StatelessWidget {
  final int totalCards;
  final int dueCards;
  final int reviewedToday;
  final int remaining;

  const ReviewStats({
    super.key,
    required this.totalCards,
    required this.dueCards,
    required this.reviewedToday,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final progress = dueCards > 0 ? reviewedToday / dueCards : 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 今日复习进度',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '$reviewedToday / $dueCards',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: progress >= 0.7 ? Colors.green.shade500 : Colors.blue.shade500,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '剩余 $remaining 张待复习',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '共 $totalCards 张卡片',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}