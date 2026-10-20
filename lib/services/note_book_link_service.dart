// lib/services/note_book_link_service.dart
// 笔记↔书 关联服务
// 批 1a —— 写边 / 反查 / [[书名]] 扫描

import '../database_service.dart';

class NoteBookLinkService {
  final DatabaseService _db = DatabaseService();

  // ─── 常量 ──────────────────────────────────────────────
  static const String linkTypeManual = 'manual';
  static const String linkTypeReading = 'reading';
  static const String linkTypeWikilink = 'wikilink';
  static const String linkTypeInherited = 'inherited';
  static const String linkTypeImport = 'import';   // 导入批

  // ─── 写边 ──────────────────────────────────────────────

  /// 幂等写边——已存在 (note_id, book_id, link_type) 则忽略
  Future<void> addLink({
    required String noteId,
    required String bookId,
    required String linkType,
    String? context,
  }) async {
    await _db.insertNoteBookLink({
      'id': '${DateTime.now().microsecondsSinceEpoch}_${noteId}_${bookId}',
      'note_id': noteId,
      'book_id': bookId,
      'link_type': linkType,
      'link_text': null,
      'context': context,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeLink({
    required String noteId,
    required String bookId,
    required String linkType,
  }) async {
    await _db.deleteNoteBookLink(
        noteId: noteId, bookId: bookId, linkType: linkType);
  }

  // ─── 反查 ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLinksByBook(String bookId) async {
    return _db.getNoteBookLinksByBook(bookId);
  }

  Future<List<Map<String, dynamic>>> getLinksByNote(String noteId) async {
    return _db.getNoteBookLinksByNote(noteId);
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
    await _db.rebuildWikiLinks(noteId: noteId, content: content);
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
    await _db.rebuildNoteNoteLinks(noteId: noteId, content: content);
  }

  /// 反查：哪些笔记引用了 noteId
  Future<List<Map<String, dynamic>>> getBacklinks(String noteId) async {
    return _db.getBacklinks(noteId);
  }

  /// 前查：noteId 引用了哪些笔记
  Future<List<Map<String, dynamic>>> getOutboundNoteLinks(String noteId) async {
    return _db.getOutboundNoteLinks(noteId);
  }

  Future<List<Map<String, dynamic>>> getOutboundNoteLinksByText(
    String sourceNoteId,
    String linkText,
  ) async {
    return _db.getOutboundNoteLinksByText(sourceNoteId, linkText);
  }

  /// B5 补：按 note + link_text 查书边
  Future<List<Map<String, dynamic>>> getOutboundBookLinksByText(
    String sourceNoteId,
    String linkText,
  ) async {
    return _db.getOutboundBookLinksByText(sourceNoteId, linkText);
  }
}