// lib/services/book_highlight_service.dart
// 书籍高亮服务 —— book_highlights 表 CRUD

import 'package:sqflite/sqflite.dart';
import '../models/book_highlight.dart';
import '../database_service.dart';

class BookHighlightService {
  final DatabaseService _db = DatabaseService();

  Future<void> addHighlights(List<BookHighlight> highlights) async {
    if (highlights.isEmpty) return;
    final db = await _db.database;
    final batch = db.batch();
    for (final h in highlights) {
      batch.insert(
        'book_highlights',
        h.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<BookHighlight>> getByBook(String bookId) async {
    final db = await _db.database;
    final rows = await db.query(
      'book_highlights',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at ASC',
    );
    return rows.map((m) => BookHighlight.fromMap(m)).toList();
  }

  Future<int> countByBook(String bookId) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM book_highlights WHERE book_id = ?',
      [bookId],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> countAll() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM book_highlights');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> deleteByBook(String bookId) async {
    final db = await _db.database;
    await db.delete(
      'book_highlights',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }
}