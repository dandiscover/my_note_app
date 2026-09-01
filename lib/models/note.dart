// lib/models/note.dart
// 笔记模型 — 标准格式（不处理脏数据）

class NotebookEntry {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final String status;
  final String editorMode;
  final List<String> tags;
  final bool isLocked;

  const NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.status = 'raw',
    this.editorMode = 'plain',
    this.tags = const [],
    this.isLocked = false,
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
    );
  }
}