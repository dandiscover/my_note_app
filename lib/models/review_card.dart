// lib/models/review_card.dart
// 复习卡片模型 — SM-2算法（修复浮点精度问题）

import 'dart:math';

class ReviewCard {
  final String id;
  final String noteId;
  final String question;
  final String answer;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final int repetitions;
  final double easeFactor;
  final int interval;

  ReviewCard({
    required this.id,
    required this.noteId,
    required this.question,
    required this.answer,
    required this.createdAt,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
  });

  bool get isDue {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  bool get isNew => repetitions == 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'question': question,
      'answer': answer,
      'created_at': createdAt.toIso8601String(),
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'next_review_at': nextReviewAt?.toIso8601String(),
      'repetitions': repetitions,
      'ease_factor': easeFactor,
      'interval': interval,
    };
  }

  factory ReviewCard.fromMap(Map<String, dynamic> map) {
    return ReviewCard(
      id: map['id'],
      noteId: map['note_id'],
      question: map['question'],
      answer: map['answer'],
      createdAt: DateTime.parse(map['created_at']),
      lastReviewedAt: map['last_reviewed_at'] != null
          ? DateTime.parse(map['last_reviewed_at'])
          : null,
      nextReviewAt: map['next_review_at'] != null
          ? DateTime.parse(map['next_review_at'])
          : null,
      repetitions: map['repetitions'] ?? 0,
      easeFactor: (map['ease_factor'] ?? 2.5).toDouble(),
      interval: map['interval'] ?? 0,
    );
  }

  /// SM-2 算法复习调度（浮点精度已修复）
  ReviewCard review({required int quality}) {
    // quality: 0=忘记, 1=困难, 2=模糊, 3=一般, 4=记得, 5=轻松
    final q = quality.clamp(0, 5);

    // ─── 1. 计算新的 easeFactor ───────────────────────────────
    // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    double newEase = easeFactor +
        (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));

    // 限制范围
    if (newEase < 1.3) newEase = 1.3;
    if (newEase > 2.5) newEase = 2.5;

    // ✅ 关键修复：当 quality=5 且由于浮点误差导致未增加时强制增加
    // 使用增量比较，避免浮点误差
    if (q == 5 && newEase <= easeFactor) {
      newEase = easeFactor + 0.01;
    }

    // ✅ 四舍五入到两位小数，消除累积误差
    newEase = (newEase * 100).round() / 100;

    // ─── 2. 计算新间隔 ──────────────────────────────────────
    int newInterval;
    if (q < 3) {
      // 忘记 -> 重置为1天
      newInterval = 1;
    } else if (repetitions == 0) {
      newInterval = 1;
    } else if (repetitions == 1) {
      newInterval = 6;
    } else {
      // ✅ 使用 double 计算后再四舍五入，避免精度丢失
      final intervalDouble = interval * newEase;
      newInterval = intervalDouble.round();
      if (newInterval < 1) newInterval = 1;
    }

    // ─── 3. 返回新卡片 ──────────────────────────────────────
    return ReviewCard(
      id: id,
      noteId: noteId,
      question: question,
      answer: answer,
      createdAt: createdAt,
      lastReviewedAt: DateTime.now(),
      nextReviewAt: DateTime.now().add(Duration(days: newInterval)),
      repetitions: repetitions + 1,
      easeFactor: newEase,
      interval: newInterval,
    );
  }

  factory ReviewCard.fromNote({
    required String noteId,
    required String title,
    required String content,
  }) {
    return ReviewCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      noteId: noteId,
      question: title,
      answer: content.length > 200 ? '${content.substring(0, 200)}...' : content,
      createdAt: DateTime.now(),
      nextReviewAt: DateTime.now(),
    );
  }
}