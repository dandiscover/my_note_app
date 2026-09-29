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
  // ─── [[笔记标题]] 扫描（笔记保存时调用）──────────────

  /// 重扫笔记↔笔记链接：先删旧，再按 content 重建
  /// 锚定靠 note_id —— 标题匹配只用于定位目标
  /// 多命中：全记（用户自判）
  /// ⚡ 性能：notes 全表只查一次（移出 [[X]] 循环外）
  Future<void> rebuildNoteNoteLinks({
    required String noteId,
    required String content,
  }) async {
    final db = await _db.database;

    // 1. 删旧
    await db.delete(
      'note_note_links',
      where: 'source_note_id = ? AND link_type = ?',
      whereArgs: [noteId, linkTypeWikilink],
    );

    // 2. 扫 content
    final regex = RegExp(r'\[\[([^\]\n]+)\]\]');
    final matches = regex.allMatches(content).toList();
    if (matches.isEmpty) return;

    // 3. 一次性查 notes —— 移出循环
    final allNotes = await db.query(
      'notes',
      columns: ['id', 'title', 'content'],
      where: 'status != ?',
      whereArgs: ['deleted'],
    );

    // 4. 建 title → List<noteId> 索引
    final byTitle = <String, List<String>>{};
    for (final row in allNotes) {
      final rowId = row['id'] as String;
      if (rowId == noteId) continue;
      final rawTitle = (row['title'] as String? ?? '').trim();
      final displayTitle = rawTitle.isNotEmpty
          ? rawTitle
          : _virtualTitle(row['content'] as String? ?? '');
      byTitle.putIfAbsent(displayTitle, () => []).add(rowId);
    }

    // 5. 逐 [[X]] 匹配 —— O(1) 查索引
    int counter = 0;
    for (final m in matches) {
      final title = m.group(1)?.trim() ?? '';
      if (title.isEmpty) continue;
      final targets = byTitle[title];
      if (targets == null || targets.isEmpty) continue;

      for (final targetId in targets) {
        await db.insert(
          'note_note_links',
          {
            'id':
                '${DateTime.now().microsecondsSinceEpoch}_${counter++}',
            'source_note_id': noteId,
            'target_note_id': targetId,
            'link_type': linkTypeWikilink,
            'link_text': title,
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// 反查：哪些笔记引用了 noteId
  Future<List<Map<String, dynamic>>> getBacklinks(String noteId) async {
    final db = await _db.database;
    return db.query(
      'note_note_links',
      where: 'target_note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );
  }

  /// 前查：noteId 引用了哪些笔记
  Future<List<Map<String, dynamic>>> getOutboundLinks(String noteId) async {
    final db = await _db.database;
    return db.query(
      'note_note_links',
      where: 'source_note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );
  }
  Future<List<Map<String, dynamic>>> getOutboundLinksByText(
    String sourceNoteId,
    String linkText,
  ) async {
    final db = await _db.database;
    return db.query(
      'note_note_links',
      where: 'source_note_id = ? AND link_text = ?',
      whereArgs: [sourceNoteId, linkText],
    );
  }
  static String _virtualTitle(String content) {
    final c = content.trim().replaceAll('\n', ' ');
    if (c.isEmpty) return '无标题';
    return c.length > 20 ? '${c.substring(0, 20)}…' : c;
  }
  // ─── 内部工具 ──────────────────────────────────────────

  static String _extractContext(String content, int start, int end) {
    final s = (start - _contextRadius).clamp(0, content.length);
    final e = (end + _contextRadius).clamp(0, content.length);
    return content.substring(s, e);
  }
}