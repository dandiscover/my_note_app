@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database/database.dart';
import 'package:my_note_app/database_service.dart';

void main() {
  late AppDatabase db;
  late DatabaseService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = DatabaseService.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('L1-9 全流程：建笔记 → 挂书 → 搜索命中 → 软删 → 搜索不命中 → 解绑', () async {
    const noteId = 'l1n9_note_1';
    const bookId = 'l1n9_book_1';
    const linkId = 'l1n9_link_1';
    const contentMarker = 'integrationmarkerZ9';

    // 1. 建笔记（:585）
    await service.insertNote({
      'id': noteId,
      'title': 'L1-9 集成测试',
      'content': '正文包含 $contentMarker',
      'updatedAt': '2026-10-19T01:00:00.000',
    });
    final notes0 = await service.getAllNotes(includeDeleted: true);
    expect(notes0.where((m) => m['id'] == noteId).length, 1,
        reason: '建笔记后 notes 应 1 行（:585）');

    // 2. 挂书——key 为 snake_case（:1231-1243 原文）
    await service.insertNoteBookLink({
      'id': linkId,
      'note_id': noteId,
      'book_id': bookId,
      'link_type': 'manual',
      'link_text': null,
      'context': null,
      'created_at': '2026-10-19T01:00:00.000',
    });
    expect((await service.getNoteBookLinksByBook(bookId)).length, 1,
        reason: '按书查 links 应 1 行（:1259）');
    expect((await service.getNoteBookLinksByNote(noteId)).length, 1,
        reason: '按笔记查 links 应 1 行（:1271）');

    // 3. 搜索命中（:894）
    final hits0 = await service.searchIndex(contentMarker);
    expect(hits0, isNotEmpty, reason: '正文关键词应命中（:894）');
    final noteHits0 = hits0.where((r) => r['sourceId'] == noteId).toList();
    expect(noteHits0, isNotEmpty,
        reason: '_searchIndexRowToMap 的 sourceId 字段应为 noteId');

    // 4. 软删（:758-764：软删 + _clearSearchIndexForNote）
    await service.deleteNote(noteId);

    final visible = await service.getAllNotes(includeDeleted: false);
    expect(visible.where((m) => m['id'] == noteId), isEmpty,
        reason: '软删后 includeDeleted=false 查不到（:597）');
    final all = await service.getAllNotes(includeDeleted: true);
    final hit = all.firstWhere((m) => m['id'] == noteId);
    expect(hit['status'], 'deleted',
        reason: '软删后 status=deleted（:758-761）');

    // 5. 软删后搜索不命中
    final hits1 = await service.searchIndex(contentMarker);
    expect(hits1.where((r) => r['sourceId'] == noteId), isEmpty,
        reason: '软删后搜索索引应清，同 noteId 不再命中（:758-764）');

    // 6. 解绑（:1246-1250）
    await service.deleteNoteBookLink(
      noteId: noteId,
      bookId: bookId,
      linkType: 'manual',
    );
    expect(await service.getNoteBookLinksByBook(bookId), isEmpty,
        reason: '解绑后按书查空（:1259）');
    expect(await service.getNoteBookLinksByNote(noteId), isEmpty,
        reason: '解绑后按笔记查空（:1271）');
  });

  test('L1-9 变体：硬删不级联 nodes（attachNoteToNode 后 hardDeleteNote）', () async {
    const noteId = 'l1n9_note_2';
    await service.insertNote({
      'id': noteId,
      'title': 'T',
      'content': 'C',
      'updatedAt': '2026-10-19T01:00:00.000',
    });
    final node = await service.attachNoteToNode(noteId: noteId, title: 'T');
    expect((await service.getAllNodes()).where((n) => n.id == node.id).length, 1,
        reason: 'attachNoteToNode 写 nodes 1 行（:420-428）');

    await service.hardDeleteNote(noteId);

    final allNotes = await service.getAllNotes(includeDeleted: true);
    expect(allNotes.where((m) => m['id'] == noteId), isEmpty,
        reason: '硬删后 note 物理消失（:766-767）');
    expect((await service.getAllNodes()).where((n) => n.id == node.id).length, 1,
        reason: 'hardDeleteNote 不级联删 node（:766-770 只删 notes 表）');
  });
}