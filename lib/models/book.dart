class Book {
  final String id;
  String title;
  String author;
  String isbn;
  String coverUrl;        // 对应数据库列: cover_image
  String filePath;        // 对应数据库列: pdf_path
  String fileType;        // 对应数据库列: file_type
  int fileSize;           // 仅内存使用，不存数据库
  String fileName;        // 仅内存使用，不存数据库
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
      'cover_image': coverUrl,
      'pdf_path': filePath,
      'file_type': fileType,
      // fileSize 和 fileName 不写入数据库
      'status': status,
      'reading_progress': readingProgress,
      'total_pages': totalPages,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      coverUrl: map['cover_image'] ?? '',
      filePath: map['pdf_path'] ?? '',
      fileType: map['file_type'] ?? 'none',
      fileSize: map['file_size'] ?? 0,      // 如果数据库有就读取，没有就用默认值
      fileName: map['file_name'] ?? '',     // 同上
      status: map['status'] ?? 'want',
      readingProgress: map['reading_progress'] ?? 0,
      totalPages: map['total_pages'] ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
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
    );
  }

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
}