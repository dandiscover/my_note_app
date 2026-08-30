// lib/services/cloud_data_service.dart
// 云端数据同步服务

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import 'supabase_service.dart';

class CloudDataService {
  static final CloudDataService _instance = CloudDataService._internal();
  factory CloudDataService() => _instance;
  CloudDataService._internal();

  SupabaseClient get _client => SupabaseService().client;

  // ✅ 将 getter 改为方法，避免类型推断问题
  String? _getUserId() => SupabaseService().currentUserId;
  bool get isLoggedIn => SupabaseService().isLoggedIn;

  // ─── 图书同步 ──────────────────────────────────────────────

  Future<void> syncBook(Book book) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return;
    await _client.from('books').upsert({
      'id': book.id,
      'user_id': userId,
      'title': book.title,
      'author': book.author,
      'isbn': book.isbn,
      'cover_url': book.coverUrl,
      'file_path': book.filePath,
      'file_type': book.fileType,
      'file_name': book.fileName,
      'file_size': book.fileSize,
      'status': book.status,
      'reading_progress': book.readingProgress,
      'total_pages': book.totalPages,
      'created_at': book.createdAt.toIso8601String(),
      'last_read_at': book.lastReadAt?.toIso8601String(),
    });
  }

  Future<void> syncBooks(List<Book> books) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return;
    for (var book in books) {
      await syncBook(book);
    }
  }

  Future<List<Book>> pullBooks() async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return [];
    final response = await _client
        .from('books')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((m) => Book(
      id: m['id'],
      title: m['title'],
      author: m['author'] ?? '',
      isbn: m['isbn'] ?? '',
      coverUrl: m['cover_url'] ?? '',
      filePath: m['file_path'] ?? '',
      fileType: m['file_type'] ?? 'none',
      fileName: m['file_name'] ?? '',
      fileSize: m['file_size'] ?? 0,
      status: m['status'] ?? 'want',
      readingProgress: m['reading_progress'] ?? 0,
      totalPages: m['total_pages'] ?? 0,
      createdAt: DateTime.parse(m['created_at']),
      lastReadAt: m['last_read_at'] != null
          ? DateTime.tryParse(m['last_read_at'])
          : null,
    )).toList();
  }

  Future<void> deleteBook(String bookId) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return;
    await _client.from('books').delete().eq('id', bookId);
  }

  // ─── 阅读笔记同步 ──────────────────────────────────────────

  Future<void> syncBookNote(BookNote note) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return;
    await _client.from('book_notes').upsert({
      'id': note.id,
      'user_id': userId,
      'book_id': note.bookId,
      'page_number': note.pageNumber,
      'selected_text': note.selectedText,
      'comment': note.comment,
      'color': note.color,
      'is_highlight': note.isHighlight,
      'created_at': note.createdAt.toIso8601String(),
    });
  }

  Future<void> syncBookNotes(List<BookNote> notes) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return;
    for (var note in notes) {
      await syncBookNote(note);
    }
  }

  Future<List<BookNote>> pullBookNotes(String bookId) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return [];
    final response = await _client
        .from('book_notes')
        .select()
        .eq('user_id', userId)
        .eq('book_id', bookId)
        .order('created_at', ascending: true);

    return (response as List).map((m) => BookNote(
      id: m['id'],
      bookId: m['book_id'],
      pageNumber: m['page_number'] ?? 0,
      selectedText: m['selected_text'] ?? '',
      comment: m['comment'] ?? '',
      color: m['color'] ?? '#FFD93D',
      createdAt: DateTime.parse(m['created_at']),
      isHighlight: m['is_highlight'] ?? true,
    )).toList();
  }

  Future<void> deleteBookNote(String noteId) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) return;
    await _client.from('book_notes').delete().eq('id', noteId);
  }

  // ─── 全量同步 ──────────────────────────────────────────────

  Future<void> syncAll({
    required List<Book> books,
    required List<BookNote> bookNotes,
  }) async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) throw Exception('请先登录');

    await syncBooks(books);
    await syncBookNotes(bookNotes);
  }

  Future<CloudSyncResult> pullAll() async {
    final userId = _getUserId();
    if (userId == null || !isLoggedIn) throw Exception('请先登录');

    final books = await pullBooks();

    final allNotes = <BookNote>[];
    for (var book in books) {
      final notes = await pullBookNotes(book.id);
      allNotes.addAll(notes);
    }

    return CloudSyncResult(
      books: books,
      bookNotes: allNotes,
    );
  }
}

class CloudSyncResult {
  final List<Book> books;
  final List<BookNote> bookNotes;

  CloudSyncResult({
    required this.books,
    required this.bookNotes,
  });
}