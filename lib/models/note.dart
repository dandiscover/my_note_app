// lib/models/note.dart
// 笔记数据模型

class NotebookEntry {
  final String id;
  String title;
  String content;
  DateTime updatedAt;
  String status;      // raw / active / archived / deleted
  String editorMode;  // plain / markdown
  List<String> tags;
  bool isLocked;      // ✅ 新增：是否锁定（不受自动归档影响）

  NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.status = 'raw',
    this.editorMode = 'plain',
    this.tags = const [],
    this.isLocked = false,  // ✅ 默认未锁定
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'editorMode': editorMode,
      'tags': tags.join(','),
      'isLocked': isLocked ? 1 : 0,  // ✅ 存为整数
    };
  }

  factory NotebookEntry.fromMap(Map<String, dynamic> map) {
    return NotebookEntry(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      updatedAt: DateTime.parse(map['updatedAt']),
      status: map['status'] ?? 'raw',
      editorMode: map['editorMode'] ?? 'plain',
      tags: (map['tags'] ?? '').toString().split(',').where((t) => t.isNotEmpty).toList(),
      isLocked: (map['isLocked'] ?? 0) == 1,  // ✅ 从整数读取
    );
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