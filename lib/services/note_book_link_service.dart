// lib/services/note_book_link_service.dart
// 笔记↔书 关联服务
// 批 1a —— 写边 / 反查 / [[书名]] 扫描

import 'package:sqflite/sqflite.dart';
import '../database_service.dart';

class NoteBookLinkService {
  final DatabaseService _db = DatabaseService();

  // ─── 常量 ──────────────────────────────────────────────
  static const String linkTypeManual = 'manual';
  static const String linkTypeReading = 'reading';
  static const String linkTypeWikilink = 'wikilink';
  static const String linkTypeInherited = 'inherited';
  static const String linkTypeImport = 'import';   // 导入批

  /// [[书名]] 前后文截取半径
  static const int _contextRadius = 30;

  // ─── 写边 ──────────────────────────────────────────────

  /// 幂等写边——已存在 (note_id, book_id, link_type) 则忽略
  Future<void> addLink({
    required String noteId,
    required String bookId,
    required String linkType,
    String? context,
  }) async {
    final db = await _db.database;
    await db.insert(
      'note_book_links',
      {
        'id': '${DateTime.now().microsecondsSinceEpoch}_${noteId}_${bookId}',
        'note_id': noteId,
        'book_id': bookId,
        'link_type': linkType,
        'context': context,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeLink({
    required String noteId,
    required String bookId,
    required String linkType,
  }) async {
    final db = await _db.database;
    await db.delete(
      'note_book_links',
      where: 'note_id = ? AND book_id = ? AND link_type = ?',
      whereArgs: [noteId, bookId, linkType],
    );
  }

  // ─── 反查 ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLinksByBook(String bookId) async {
    final db = await _db.database;
    return db.query(
      'note_book_links',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getLinksByNote(String noteId) async {
    final db = await _db.database;
    return db.query(
      'note_book_links',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );
  }

  // ─── [[书名]] 扫描（笔记保存时调用） ────────────────────

  /// 重扫：先删旧 wikilink 边，再按 content 重建
  /// B2 裁：标题匹配 + 固化 id
  /// B3 裁：多命中不取
  /// B4 裁：目标删了保留悬空（不建边）
  /// 幂等：同一笔记同一书多次 [[书名]] 只留第一次（UNIQUE + ignore）
  Future<void> rebuildWikiLinks({
    required String noteId,
    required String content,
  }) async {
    final db = await _db.database;

    // 1. 删旧
    await db.delete(
      'note_book_links',
      where: 'note_id = ? AND link_type = ?',
      whereArgs: [noteId, linkTypeWikilink],
    );

    // 2. 扫 content
    final regex = RegExp(r'\[\[([^\]\n]+)\]\]');
    final matches = regex.allMatches(content).toList();
    if (matches.isEmpty) return;

    // 3. 逐条匹配
    int counter = 0;
    for (final m in matches) {
      final title = m.group(1)?.trim() ?? '';
      if (title.isEmpty) continue;

      final rows = await db.query(
        'books',
        columns: ['id'],
        where: 'title = ?',
        whereArgs: [title],
        limit: 2,
      );

      // B3：多命中不取
      if (rows.length != 1) continue;

      final bookId = rows.first['id'] as String;
      final context = _extractContext(content, m.start, m.end);

      await db.insert(
        'note_book_links',
        {
          // 后缀 counter：同微秒多次匹配不撞主键
          'id': '${DateTime.now().microsecondsSinceEpoch}_${counter++}',
          'note_id': noteId,
          'book_id': bookId,
          'link_type': linkTypeWikilink,
          'context': context,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ─── 内部工具 ──────────────────────────────────────────

  static String _extractContext(String content, int start, int end) {
    final s = (start - _contextRadius).clamp(0, content.length);
    final e = (end + _contextRadius).clamp(0, content.length);
    return content.substring(s, e);
  }
}