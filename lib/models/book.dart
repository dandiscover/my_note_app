// lib/models/book.dart
// 图书数据模型（添加 fileTypeLabel getter）

class Book {
  final String id;
  String title;
  String author;
  String isbn;
  String coverUrl;
  String filePath;
  String fileType;
  int fileSize;
  String fileName;
  String status;
  int readingProgress;
  int totalPages;
  DateTime createdAt;
  DateTime? lastReadAt;

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
    this.lastReadAt,
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
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
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
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      lastReadAt: map['last_read_at'] != null
          ? DateTime.tryParse(map['last_read_at'])
          : null,
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    String? filePath,
    String? fileType,
    int? fileSize,
    String? fileName,
    String? status,
    int? readingProgress,
    int? totalPages,
    DateTime? createdAt,
    DateTime? lastReadAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      readingProgress: readingProgress ?? this.readingProgress,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
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
  bool get hasEbook => filePath.isNotEmpty && fileType != 'none';

  // ✅ 新增：文件类型标签（大写）
  String get fileTypeLabel => fileType.toUpperCase();
}