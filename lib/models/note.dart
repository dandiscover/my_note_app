class NotebookEntry {
  NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.status = 'raw',
    this.editorMode = 'plain',
    this.tags = const [], // ✅ 新增
  });

  final String id;
  String title;
  String content;
  DateTime updatedAt;
  String status;
  String editorMode;
  List<String> tags; // ✅ 新增

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'editorMode': editorMode,
      'tags': tags.join(','), // ✅ 存为逗号分隔字符串
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
      tags: (map['tags'] ?? '').toString().split(',').where((t) => t.isNotEmpty).toList(), // ✅ 从字符串解析
    );
  }
}