// lib/models/book.dart
class Book {
  final String id;
  String title;
  String author;
  String isbn;
  String coverUrl;
  String filePath;   // 统一电子书文件路径（PDF/EPUB/MOBI等）
  String fileType;   // 'pdf' | 'epub' | 'mobi' | 'azw3' | 'cbr' | 'cbz'
  int fileSize;      // 文件大小（字节）
  String fileName;   // 原始文件名
  String status;     // 'want' | 'reading' | 'read'
  int readingProgress;
  int totalPages;
  DateTime createdAt;

  Book({
    required this.id,
    required this.title,
    this.author = '',
    this.isbn = '',
    this.coverUrl = '',
    this.filePath = '',
    this.fileType = 'none',
    this.fileSize = 0,
    this.fileName = '',
    this.status = 'want',
    this.readingProgress = 0,
    this.totalPages = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'cover_url': coverUrl,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'file_name': fileName,
      'status': status,
      'reading_progress': readingProgress,
      'total_pages': totalPages,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      coverUrl: map['cover_url'] ?? '',
      filePath: map['file_path'] ?? '',
      fileType: map['file_type'] ?? 'none',
      fileSize: map['file_size'] ?? 0,
      fileName: map['file_name'] ?? '',
      status: map['status'] ?? 'want',
      readingProgress: map['reading_progress'] ?? 0,
      totalPages: map['total_pages'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'want': return '想读';
      case 'reading': return '在读';
      case 'read': return '读完';
      default: return status;
    }
  }

  String get progressLabel => '$readingProgress%';

  // 是否有电子版
  bool get hasEbook => filePath.isNotEmpty && fileType != 'none';
}