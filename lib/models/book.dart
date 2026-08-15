import 'dart:convert';

class Book {
  final String id;
  String title;
  String author;
  String isbn;
  String coverUrl;        // 对应数据库列: cover_image
  String filePath;        // 对应数据库列: pdf_path
  String fileType;        // 对应数据库列: file_type
  String status;          // want / reading / read
  int readingProgress;    // 对应数据库列: reading_progress
  int totalPages;         // 对应数据库列: total_pages
  DateTime createdAt;     // 对应数据库列: created_at

  Book({
    required this.id,
    required this.title,
    this.author = '',
    this.isbn = '',
    this.coverUrl = '',
    this.filePath = '',
    this.fileType = 'none',
    this.status = 'want',
    this.readingProgress = 0,
    this.totalPages = 0,
    required this.createdAt,
  });

  // 转换为数据库 Map（键名必须与表列名完全一致）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'cover_image': coverUrl,      // ✅ 修复：cover_url → cover_image
      'pdf_path': filePath,         // ✅ 修复：file_path → pdf_path
      'file_type': fileType,
      'status': status,
      'reading_progress': readingProgress,
      'total_pages': totalPages,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 从数据库 Map 读取（键名必须与表列名完全一致）
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      coverUrl: map['cover_image'] ?? '',   // ✅ 修复：cover_url → cover_image
      filePath: map['pdf_path'] ?? '',      // ✅ 修复：file_path → pdf_path
      fileType: map['file_type'] ?? 'none',
      status: map['status'] ?? 'want',
      readingProgress: map['reading_progress'] ?? 0,
      totalPages: map['total_pages'] ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // 方便复制的辅助方法
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    String? filePath,
    String? fileType,
    String? status,
    int? readingProgress,
    int? totalPages,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      status: status ?? this.status,
      readingProgress: readingProgress ?? this.readingProgress,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 辅助属性（仅用于 UI，不存入数据库）
  String get statusLabel {
    switch (status) {
      case 'want':
        return '想读';
      case 'reading':
        return '在读';
      case 'read':
        return '读完';
      default:
        return status;
    }
  }

  String get progressLabel => '$readingProgress%';
  bool get hasEbook => filePath.isNotEmpty && fileType != 'none';

  // JSON 序列化（用于网络传输，可选）
  Map<String, dynamic> toJson() => toMap();
  factory Book.fromJson(Map<String, dynamic> json) => Book.fromMap(json);
}