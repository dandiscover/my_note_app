// lib/models/book_highlight.dart
// 书籍高亮模型 —— 导入批

class BookHighlight {
  final String id;
  final String bookId;
  final String? chapter;
  final String? location;
  final String text;
  final String? color;
  final String? note;
  final DateTime createdAt;
  final String source;

  BookHighlight({
    required this.id,
    required this.bookId,
    this.chapter,
    this.location,
    required this.text,
    this.color,
    this.note,
    DateTime? createdAt,
    this.source = 'local',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'book_id': bookId,
        'chapter': chapter,
        'location': location,
        'text': text,
        'color': color,
        'note': note,
        'created_at': createdAt.toIso8601String(),
        'source': source,
      };

  factory BookHighlight.fromMap(Map<String, dynamic> map) => BookHighlight(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        chapter: map['chapter'] as String?,
        location: map['location'] as String?,
        text: map['text'] as String,
        color: map['color'] as String?,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        source: (map['source'] as String?) ?? 'local',
      );

  BookHighlight copyWith({
    String? id,
    String? bookId,
    String? chapter,
    String? location,
    String? text,
    String? color,
    String? note,
    DateTime? createdAt,
    String? source,
  }) =>
      BookHighlight(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        chapter: chapter ?? this.chapter,
        location: location ?? this.location,
        text: text ?? this.text,
        color: color ?? this.color,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        source: source ?? this.source,
      );

  String get displayText =>
      text.length > 80 ? '${text.substring(0, 80)}...' : text;
}