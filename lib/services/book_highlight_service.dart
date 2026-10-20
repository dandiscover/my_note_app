// lib/services/book_highlight_service.dart
// 书籍高亮服务 —— book_highlights 表 CRUD

import '../models/book_highlight.dart';
import '../database_service.dart';

class BookHighlightService {
  final DatabaseService _db = DatabaseService();

  Future<void> addHighlights(List<BookHighlight> highlights) async {
    if (highlights.isEmpty) return;
    await _db.insertBookHighlights(
        highlights.map((h) => h.toMap()).toList());
  }

  Future<List<BookHighlight>> getByBook(String bookId) async {
    final rows = await _db.getBookHighlightsByBook(bookId);
    return rows.map((m) => BookHighlight.fromMap(m)).toList();
  }

  Future<int> countByBook(String bookId) async {
    return await _db.countBookHighlightsByBook(bookId);
  }

  Future<int> countAll() async {
    return await _db.countAllBookHighlights();
  }

  Future<void> deleteByBook(String bookId) async {
    await _db.deleteBookHighlightsByBook(bookId);
  }
}