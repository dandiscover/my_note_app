class NotebookEntry {
  NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.status = 'raw', // 'raw' | 'active' | 'archived' | 'task'
  });

  final String id;
  String title;
  String content;
  DateTime updatedAt;
  String status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
    };
  }

  factory NotebookEntry.fromMap(Map<String, dynamic> map) {
    return NotebookEntry(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      updatedAt: DateTime.parse(map['updatedAt']),
      status: map['status'] ?? 'raw',
    );
  }
}