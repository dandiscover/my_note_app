// lib/models/book_note.dart
// 书籍阅读笔记模型


class BookNote {
  final String id;
  final String bookId;
  final int pageNumber;      // 页码（PDF）或位置（EPUB）
  final String? location;    // EPUB 位置标识
  final String selectedText; // 选中的原文
  final String comment;      // 用户批注
  final String color;        // 高亮颜色 (hex)
  final DateTime createdAt;
  final bool isHighlight;    // true=高亮, false=普通笔记

  BookNote({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    this.location,
    required this.selectedText,
    this.comment = '',
    this.color = '#FFD93D',  // 默认黄色
    DateTime? createdAt,
    this.isHighlight = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookId': bookId,
    'pageNumber': pageNumber,
    'location': location,
    'selectedText': selectedText,
    'comment': comment,
    'color': color,
    'createdAt': createdAt.toIso8601String(),
    'isHighlight': isHighlight ? 1 : 0,
  };

  factory BookNote.fromMap(Map<String, dynamic> map) => BookNote(
    id: map['id'],
    bookId: map['bookId'],
    pageNumber: map['pageNumber'],
    location: map['location'],
    selectedText: map['selectedText'],
    comment: map['comment'] ?? '',
    color: map['color'] ?? '#FFD93D',
    createdAt: DateTime.parse(map['createdAt']),
    isHighlight: (map['isHighlight'] ?? 1) == 1,
  );

  String get displayText => selectedText.length > 80
      ? '${selectedText.substring(0, 80)}...'
      : selectedText;
}