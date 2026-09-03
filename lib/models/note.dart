// lib/models/note.dart
// 笔记模型 — 标准格式（不处理脏数据）
// ✅ 新增：inquiryQuestion（探究问题）、scaffoldSessions（拐杖记录）、subtasks（子任务列表）
// ✅ 新增：newUnderstanding（新理解）

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

class NotebookEntry {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final String status;
  final String editorMode;
  final List<String> tags;
  final bool isLocked;
  final String? inquiryQuestion;
  final String? newUnderstanding;
  final List<Map<String, dynamic>> scaffoldSessions;
  final List<NoteSubtask> subtasks;

  const NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.status = 'raw',
    this.editorMode = 'plain',
    this.tags = const [],
    this.isLocked = false,
    this.inquiryQuestion,
    this.newUnderstanding,
    this.scaffoldSessions = const [],
    this.subtasks = const [],
  });

  static final NotebookEntry empty = NotebookEntry(
    id: '',
    title: '',
    content: '',
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    status: 'deleted',
    editorMode: 'plain',
    tags: const [],
    isLocked: false,
    inquiryQuestion: null,
    newUnderstanding: null,
    scaffoldSessions: const [],
    subtasks: const [],
  );

  factory NotebookEntry.fromMap(Map<String, dynamic> map) {
    return NotebookEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      updatedAt: DateTime.parse(map['updatedAt']),
      status: map['status'] ?? 'raw',
      editorMode: map['editorMode'] ?? 'plain',
      tags: (map['tags'] as List?)?.cast<String>() ?? [],
      isLocked: (map['isLocked'] ?? 0) == 1,
      inquiryQuestion: map['inquiryQuestion'] as String?,
      newUnderstanding: map['newUnderstanding'] as String?,
      scaffoldSessions: (map['scaffoldSessions'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
      subtasks: (map['subtasks'] as List?)
          ?.map((e) => NoteSubtask.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'editorMode': editorMode,
      'isLocked': isLocked ? 1 : 0,
      'tags': tags,
      'inquiryQuestion': inquiryQuestion,
      'newUnderstanding': newUnderstanding,
      'scaffoldSessions': scaffoldSessions,
      'subtasks': subtasks,
    };
  }

  NotebookEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
    String? status,
    String? editorMode,
    List<String>? tags,
    bool? isLocked,
    String? inquiryQuestion,
    String? newUnderstanding,
    List<Map<String, dynamic>>? scaffoldSessions,
    List<NoteSubtask>? subtasks,
  }) {
    return NotebookEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      editorMode: editorMode ?? this.editorMode,
      tags: tags ?? this.tags,
      isLocked: isLocked ?? this.isLocked,
      inquiryQuestion: inquiryQuestion ?? this.inquiryQuestion,
      newUnderstanding: newUnderstanding ?? this.newUnderstanding,
      scaffoldSessions: scaffoldSessions ?? this.scaffoldSessions,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}