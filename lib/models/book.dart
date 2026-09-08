// lib/models/book.dart
// 图书模型
// ✅ 新增 source 字段：记录图书来源（import / scan / manual）

class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String coverUrl;
  final String filePath;
  final String fileType;
  final String fileName;
  final int fileSize;
  final String status;
  final int readingProgress;
  final int totalPages;
  final DateTime createdAt;
  final DateTime? lastReadAt;
  final String source; // ✅ 新增：来源（import / scan / manual）

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn = '',
    this.coverUrl = '',
    this.filePath = '',
    this.fileType = 'none',
    this.fileName = '',
    this.fileSize = 0,
    this.status = 'want',
    this.readingProgress = 0,
    this.totalPages = 0,
    required this.createdAt,
    this.lastReadAt,
    this.source = '', // ✅ 新增，默认空字符串
  });

  /// ✅ 空对象（用于 orElse 安全返回）
  static final Book empty = Book(
    id: '',
    title: '',
    author: '',
    isbn: '',
    coverUrl: '',
    filePath: '',
    fileType: 'none',
    fileName: '',
    fileSize: 0,
    status: 'want',
    readingProgress: 0,
    totalPages: 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    lastReadAt: null,
    source: '', // ✅ 新增
  );

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      filePath: map['filePath'] ?? '',
      fileType: map['fileType'] ?? 'none',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      status: map['status'] ?? 'want',
      readingProgress: map['readingProgress'] ?? 0,
      totalPages: map['totalPages'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      lastReadAt: map['lastReadAt'] != null ? DateTime.parse(map['lastReadAt']) : null,
      source: map['source'] ?? '', // ✅ 新增
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'coverUrl': coverUrl,
      'filePath': filePath,
      'fileType': fileType,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status,
      'readingProgress': readingProgress,
      'totalPages': totalPages,
      'createdAt': createdAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'source': source, // ✅ 新增
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? coverUrl,
    String? filePath,
    String? fileType,
    String? fileName,
    int? fileSize,
    String? status,
    int? readingProgress,
    int? totalPages,
    DateTime? createdAt,
    DateTime? lastReadAt,
    String? source, // ✅ 新增
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      readingProgress: readingProgress ?? this.readingProgress,
      totalPages: totalPages ?? this.totalPages,
      createdAt: createdAt ?? this.createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      source: source ?? this.source, // ✅ 新增
    );
  }

  bool get hasEbook => fileType != 'none' && filePath.isNotEmpty;

  String get statusLabel {
    switch (status) {
      case 'want':
        return '想读';
      case 'reading':
        return '在读';
      case 'read':
        return '读完';
      default:
        return '未知';
    }
  }

  String get fileTypeLabel {
    switch (fileType) {
      case 'pdf':
        return 'PDF';
      case 'epub':
        return 'EPUB';
      case 'mobi':
        return 'MOBI';
      case 'azw3':
        return 'AZW3';
      default:
        return fileType.toUpperCase();
    }
  }
}