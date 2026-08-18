// lib/models/card.dart
// 卡片数据模型 — 支持多种类型

import 'package:flutter/material.dart';

enum CardType {
  review,      // 复习卡（正面/背面）
  indexCard,   // 索引卡（标题/作者/高光句）
  qa,          // 问答卡
  fill,        // 填空卡
  choice,      // 选择题
  truefalse,   // 判断题
}

enum Importance {
  low,
  medium,
  high,
  critical,
}

extension CardTypeExt on CardType {
  String get label {
    switch (this) {
      case CardType.review:
        return '复习卡';
      case CardType.indexCard:
        return '索引卡';
      case CardType.qa:
        return '问答卡';
      case CardType.fill:
        return '填空卡';
      case CardType.choice:
        return '选择题';
      case CardType.truefalse:
        return '判断题';
    }
  }

  String get icon {
    switch (this) {
      case CardType.review:
        return '📄';
      case CardType.indexCard:
        return '📚';
      case CardType.qa:
        return '❓';
      case CardType.fill:
        return '✏️';
      case CardType.choice:
        return '🔘';
      case CardType.truefalse:
        return '⚖️';
    }
  }

  Color get color {
    switch (this) {
      case CardType.review:
        return Colors.purple;
      case CardType.indexCard:
        return Colors.teal;
      case CardType.qa:
        return Colors.blue;
      case CardType.fill:
        return Colors.orange;
      case CardType.choice:
        return Colors.green;
      case CardType.truefalse:
        return Colors.red;
    }
  }
}

class CardModel {
  final String id;
  final CardType cardType;
  final String sourceType;
  final String sourceId;
  final String? sourceTitle;
  final List<String> tags;
  final DateTime createdAt;
  DateTime updatedAt;

  final String? front;
  final String? back;
  final String? indexTitle;
  final String? author;
  final String? highlight;
  final String? question;
  final String? answer;
  final String? fillQuestion;
  final String? fillAnswer;
  final String? choiceQuestion;
  final List<String>? choiceOptions;
  final int? choiceCorrectIndex;
  final String? tfStatement;
  final bool? tfIsTrue;

  final Importance importance;
  double memoryLevel;
  final List<String> relatedIds;

  int stage;
  bool mastered;
  DateTime? lastReviewDate;
  DateTime? nextReviewDate;
  int totalReviews;
  int failedCount;

  CardModel({
    required this.id,
    required this.cardType,
    required this.sourceType,
    required this.sourceId,
    this.sourceTitle,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.front,
    this.back,
    this.indexTitle,
    this.author,
    this.highlight,
    this.question,
    this.answer,
    this.fillQuestion,
    this.fillAnswer,
    this.choiceQuestion,
    this.choiceOptions,
    this.choiceCorrectIndex,
    this.tfStatement,
    this.tfIsTrue,
    this.importance = Importance.medium,
    this.memoryLevel = 0.5,
    this.relatedIds = const [],
    this.stage = 0,
    this.mastered = false,
    this.lastReviewDate,
    this.nextReviewDate,
    this.totalReviews = 0,
    this.failedCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayFront {
    switch (cardType) {
      case CardType.review:
        return front ?? '无正面内容';
      case CardType.indexCard:
        return '${indexTitle ?? ''}\n${author ?? ''}\n${highlight ?? ''}';
      case CardType.qa:
        return question ?? '无问题';
      case CardType.fill:
        return fillQuestion ?? '无题目';
      case CardType.choice:
        return choiceQuestion ?? '无题目';
      case CardType.truefalse:
        return tfStatement ?? '无陈述';
    }
  }

  String get displayBack {
    switch (cardType) {
      case CardType.review:
        return back ?? '无背面内容';
      case CardType.indexCard:
        return '📖 索引卡\n标题：${indexTitle ?? ''}\n作者：${author ?? ''}\n高光：${highlight ?? ''}';
      case CardType.qa:
        return '答案：${answer ?? ''}';
      case CardType.fill:
        return '答案：${fillAnswer ?? ''}';
      case CardType.choice:
        final options = choiceOptions ?? [];
        final correct = choiceCorrectIndex ?? -1;
        return '选项：\n${options.asMap().map((i, o) => MapEntry(i, '  ${i + 1}. $o${i == correct ? ' ✅' : ''}'))}\n正确答案：${correct >= 0 ? options[correct] : '未设置'}';
      case CardType.truefalse:
        return tfIsTrue == true ? '✅ 正确' : '❌ 错误';
    }
  }

  String get typeLabel => cardType.label;
  String get typeIcon => cardType.icon;
  Color get typeColor => cardType.color;

  String get importanceLabel {
    switch (importance) {
      case Importance.low:
        return '⭐ 低';
      case Importance.medium:
        return '⭐⭐ 中';
      case Importance.high:
        return '⭐⭐⭐ 高';
      case Importance.critical:
        return '⭐⭐⭐⭐ 极高';
    }
  }

  String get stageLabel {
    if (mastered) return '✅ 已掌握';
    switch (stage) {
      case 0:
        return '🌱 初始';
      case 1:
        return '🌿 学习1';
      case 2:
        return '🌿 学习2';
      case 3:
        return '🌳 巩固1';
      case 4:
        return '🌳 巩固2';
      case 5:
        return '🌲 复习1';
      case 6:
        return '🌲 复习2';
      case 7:
        return '🏆 掌握';
      default:
        return '未知';
    }
  }

  static const List<Duration> ebbinghausIntervals = [
    Duration(minutes: 20),
    Duration(hours: 1),
    Duration(hours: 9),
    Duration(days: 1),
    Duration(days: 2),
    Duration(days: 6),
    Duration(days: 31),
    Duration(days: 180),
  ];

  DateTime calculateNextReviewDate(DateTime now) {
    if (mastered) return now.add(const Duration(days: 180));
    final index = stage.clamp(0, 7);
    final interval = ebbinghausIntervals[index];
    return now.add(interval);
  }

  CardModel rateRemembered() {
    final now = DateTime.now();
    int newStage = stage + 1;
    bool newMastered = newStage >= 7;
    if (newMastered) newStage = 7;

    return copyWith(
      stage: newStage,
      mastered: newMastered,
      lastReviewDate: now,
      nextReviewDate: calculateNextReviewDate(now),
      totalReviews: totalReviews + 1,
      memoryLevel: (memoryLevel + 0.1).clamp(0.0, 1.0),
      updatedAt: now,
    );
  }

  CardModel rateForgotten() {
    final now = DateTime.now();
    return copyWith(
      stage: 0,
      mastered: false,
      lastReviewDate: now,
      nextReviewDate: now.add(Duration(minutes: 20)),
      totalReviews: totalReviews + 1,
      failedCount: failedCount + 1,
      memoryLevel: (memoryLevel - 0.2).clamp(0.0, 1.0),
      updatedAt: now,
    );
  }

  bool get isDue {
    if (mastered) return false;
    if (nextReviewDate == null) return true;
    return nextReviewDate!.isBefore(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardType': cardType.toString().split('.').last,
    'sourceType': sourceType,
    'sourceId': sourceId,
    'sourceTitle': sourceTitle,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'front': front,
    'back': back,
    'indexTitle': indexTitle,
    'author': author,
    'highlight': highlight,
    'question': question,
    'answer': answer,
    'fillQuestion': fillQuestion,
    'fillAnswer': fillAnswer,
    'choiceQuestion': choiceQuestion,
    'choiceOptions': choiceOptions,
    'choiceCorrectIndex': choiceCorrectIndex,
    'tfStatement': tfStatement,
    'tfIsTrue': tfIsTrue,
    'importance': importance.toString().split('.').last,
    'memoryLevel': memoryLevel,
    'relatedIds': relatedIds,
    'stage': stage,
    'mastered': mastered,
    'lastReviewDate': lastReviewDate?.toIso8601String(),
    'nextReviewDate': nextReviewDate?.toIso8601String(),
    'totalReviews': totalReviews,
    'failedCount': failedCount,
  };

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id: json['id'] as String,
    cardType: _parseCardType(json['cardType'] as String?),
    sourceType: json['sourceType'] as String,
    sourceId: json['sourceId'] as String,
    sourceTitle: json['sourceTitle'] as String?,
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    front: json['front'] as String?,
    back: json['back'] as String?,
    indexTitle: json['indexTitle'] as String?,
    author: json['author'] as String?,
    highlight: json['highlight'] as String?,
    question: json['question'] as String?,
    answer: json['answer'] as String?,
    fillQuestion: json['fillQuestion'] as String?,
    fillAnswer: json['fillAnswer'] as String?,
    choiceQuestion: json['choiceQuestion'] as String?,
    choiceOptions: (json['choiceOptions'] as List?)?.map((e) => e as String).toList(),
    choiceCorrectIndex: json['choiceCorrectIndex'] as int?,
    tfStatement: json['tfStatement'] as String?,
    tfIsTrue: json['tfIsTrue'] as bool?,
    importance: _parseImportance(json['importance'] as String?),
    memoryLevel: json['memoryLevel'] as double? ?? 0.5,
    relatedIds: (json['relatedIds'] as List?)?.map((e) => e as String).toList() ?? [],
    stage: json['stage'] as int? ?? 0,
    mastered: json['mastered'] as bool? ?? false,
    lastReviewDate: json['lastReviewDate'] != null ? DateTime.parse(json['lastReviewDate'] as String) : null,
    nextReviewDate: json['nextReviewDate'] != null ? DateTime.parse(json['nextReviewDate'] as String) : null,
    totalReviews: json['totalReviews'] as int? ?? 0,
    failedCount: json['failedCount'] as int? ?? 0,
  );

  static CardType _parseCardType(String? value) {
    switch (value) {
      case 'review':
        return CardType.review;
      case 'indexCard':
        return CardType.indexCard;
      case 'qa':
        return CardType.qa;
      case 'fill':
        return CardType.fill;
      case 'choice':
        return CardType.choice;
      case 'truefalse':
        return CardType.truefalse;
      default:
        return CardType.review;
    }
  }

  static Importance _parseImportance(String? value) {
    switch (value) {
      case 'low':
        return Importance.low;
      case 'medium':
        return Importance.medium;
      case 'high':
        return Importance.high;
      case 'critical':
        return Importance.critical;
      default:
        return Importance.medium;
    }
  }

  CardModel copyWith({
    String? id,
    CardType? cardType,
    String? sourceType,
    String? sourceId,
    String? sourceTitle,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? front,
    String? back,
    String? indexTitle,
    String? author,
    String? highlight,
    String? question,
    String? answer,
    String? fillQuestion,
    String? fillAnswer,
    String? choiceQuestion,
    List<String>? choiceOptions,
    int? choiceCorrectIndex,
    String? tfStatement,
    bool? tfIsTrue,
    Importance? importance,
    double? memoryLevel,
    List<String>? relatedIds,
    int? stage,
    bool? mastered,
    DateTime? lastReviewDate,
    DateTime? nextReviewDate,
    int? totalReviews,
    int? failedCount,
  }) => CardModel(
    id: id ?? this.id,
    cardType: cardType ?? this.cardType,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId ?? this.sourceId,
    sourceTitle: sourceTitle ?? this.sourceTitle,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    front: front ?? this.front,
    back: back ?? this.back,
    indexTitle: indexTitle ?? this.indexTitle,
    author: author ?? this.author,
    highlight: highlight ?? this.highlight,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    fillQuestion: fillQuestion ?? this.fillQuestion,
    fillAnswer: fillAnswer ?? this.fillAnswer,
    choiceQuestion: choiceQuestion ?? this.choiceQuestion,
    choiceOptions: choiceOptions ?? this.choiceOptions,
    choiceCorrectIndex: choiceCorrectIndex ?? this.choiceCorrectIndex,
    tfStatement: tfStatement ?? this.tfStatement,
    tfIsTrue: tfIsTrue ?? this.tfIsTrue,
    importance: importance ?? this.importance,
    memoryLevel: memoryLevel ?? this.memoryLevel,
    relatedIds: relatedIds ?? this.relatedIds,
    stage: stage ?? this.stage,
    mastered: mastered ?? this.mastered,
    lastReviewDate: lastReviewDate ?? this.lastReviewDate,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    totalReviews: totalReviews ?? this.totalReviews,
    failedCount: failedCount ?? this.failedCount,
  );
}