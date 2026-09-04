// lib/models/note_subtask.dart
// 子任务模型 — 被 Note 和 ExploreTask 复用

class NoteSubtask {
  final String id;
  final String title;
  final bool isDone;
  final DateTime? completedAt;
  final DateTime createdAt;

  NoteSubtask({
    required this.id,
    required this.title,
    this.isDone = false,
    this.completedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NoteSubtask.fromMap(Map<String, dynamic> map) {
    return NoteSubtask(
      id: map['id'] as String,
      title: map['title'] as String,
      isDone: map['isDone'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NoteSubtask copyWith({
    String? id,
    String? title,
    bool? isDone,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return NoteSubtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}