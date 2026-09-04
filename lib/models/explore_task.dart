// lib/models/explore_task.dart
// 探究任务模型 — 多任务支持
// ✅ 一个探究笔记可以包含多个探究任务
// ✅ 每个任务包含：拐杖卡类型、三问答案、行动列表、状态

import 'note_subtask.dart';

enum ExploreTaskStatus {
  active,
  completed,
}

extension ExploreTaskStatusExt on ExploreTaskStatus {
  String get string {
    switch (this) {
      case ExploreTaskStatus.active:
        return 'active';
      case ExploreTaskStatus.completed:
        return 'completed';
    }
  }

  static ExploreTaskStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ExploreTaskStatus.active;
      case 'completed':
        return ExploreTaskStatus.completed;
      default:
        return ExploreTaskStatus.active;
    }
  }
}

class ExploreTask {
  final String id;
  final String? scaffoldCardType; // 'minimal_step', 'five_why', ...
  final List<Map<String, dynamic>> scaffoldAnswers; // [{'label': '问题', 'value': '回答'}]
  final List<NoteSubtask> actions;
  final String? findings; // 保留字段，本轮不实现，但数据模型已就位
  final ExploreTaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  ExploreTask({
    required this.id,
    this.scaffoldCardType,
    this.scaffoldAnswers = const [],
    this.actions = const [],
    this.findings,
    this.status = ExploreTaskStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'scaffoldCardType': scaffoldCardType,
    'scaffoldAnswers': scaffoldAnswers,
    'actions': actions.map((e) => e.toMap()).toList(),
    'findings': findings,
    'status': status.string,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory ExploreTask.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'active';
    final status = ExploreTaskStatusExt.fromString(statusStr);

    return ExploreTask(
      id: json['id'] as String,
      scaffoldCardType: json['scaffoldCardType'] as String?,
      scaffoldAnswers: (json['scaffoldAnswers'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
      actions: (json['actions'] as List?)
          ?.map((e) => NoteSubtask.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      findings: json['findings'] as String?,
      status: status,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  ExploreTask copyWith({
    String? id,
    String? scaffoldCardType,
    List<Map<String, dynamic>>? scaffoldAnswers,
    List<NoteSubtask>? actions,
    String? findings,
    ExploreTaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return ExploreTask(
      id: id ?? this.id,
      scaffoldCardType: scaffoldCardType ?? this.scaffoldCardType,
      scaffoldAnswers: scaffoldAnswers ?? this.scaffoldAnswers,
      actions: actions ?? this.actions,
      findings: findings ?? this.findings,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}