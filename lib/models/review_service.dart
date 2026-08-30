// lib/models/review_card.dart
// 复习卡片模型 — SM-2算法


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

  ReviewCard review({required int quality}) {
    // quality: 0=忘记, 1=困难, 2=模糊, 3=一般, 4=记得, 5=轻松
    final mappedQuality = quality.clamp(0, 5);

    // 计算新的 easeFactor
    double newEase = easeFactor +
        (0.1 - (5 - mappedQuality) * (0.08 + (5 - mappedQuality) * 0.02));

    if (newEase < 1.3) newEase = 1.3;
    if (newEase > 2.5) newEase = 2.5;

    // 修复浮点精度问题：高质量时确保增加
    if (mappedQuality >= 4 && newEase <= easeFactor) {
      newEase = (easeFactor + 0.01).clamp(1.3, 2.5);
    }

    int newInterval;
    if (mappedQuality < 3) {
      // 忘记 -> 重置为1天
      newInterval = 1;
    } else if (repetitions == 0) {
      newInterval = 1;
    } else if (repetitions == 1) {
      newInterval = 6;
    } else {
      newInterval = (interval * newEase).round();
    }
    if (newInterval < 1) newInterval = 1;

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