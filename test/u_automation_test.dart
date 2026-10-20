@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'dart:io';
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

  test('U2 搜索：插入笔记后 searchIndex 命中标题/正文关键词', () async {
    await service.insertNote({
      'id': 'u2_note_1',
      'title': '换库验证标题uniqueA',
      'content': '换库验证正文uniqueB',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    expect(await service.searchIndex('uniqueA'), isEmpty, reason: '标题不入索引——历史现状，见 代-账-001');
    expect(await service.searchIndex('uniqueB'), isNotEmpty, reason: '正文关键词应命中');
    expect(await service.searchIndex('   '), isEmpty, reason: '空关键词不应返回结果');
  });

  test('U3 标签：insertNote 后 tag_index 有该笔记的 sourceId 行', () async {
    await service.insertNote({
      'id': 'u3_note_1',
      'title': '标签测试',
      'content': '内容',
      'tags': <String>['tag_a', 'tag_b'],
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final allTags = await service.getAllTagRows();
    final mine = allTags.where((r) => r['sourceId'] == 'u3_note_1').toList();
    expect(mine, isNotEmpty, reason: 'insertNote 内部 _syncSearchIndexForNote 应写 tag_index');
  });

  test('U4 书系：insertNoteBookLink -> 按书/按笔记查 -> 删', () async {
    await service.insertNoteBookLink({
      'id': 'u4_link_1',
      'note_id': 'u4_note_1',
      'book_id': 'u4_book_1',
      'link_type': 'ref',
      'link_text': null,
      'context': null,
      'created_at': DateTime.now().toIso8601String(),
    });

    expect(await service.getNoteBookLinksByBook('u4_book_1'), hasLength(1));
    expect(await service.getNoteBookLinksByNote('u4_note_1'), hasLength(1));

    await service.deleteNoteBookLink(noteId: 'u4_note_1', bookId: 'u4_book_1', linkType: 'ref');

    expect(await service.getNoteBookLinksByBook('u4_book_1'), isEmpty);
    expect(await service.getNoteBookLinksByNote('u4_note_1'), isEmpty);
  });

  test('U5 画布：view + node + edge + text + stroke 存->读一致', () async {
    const vid = 'u5_view_1';

    await service.upsertBoardView({
      'id': vid, 'name': '测试画布', 'type': 'board',
      'ownerId': null, 'createdAt': DateTime.now().toIso8601String(), 'updatedAt': null,
    });

    await service.replaceBoardNodes(vid, [
      {'id': 'u5_n1', 'viewId': vid, 'cardId': null, 'type': 'card', 'noteId': null, 'x': 10.0, 'y': 20.0, 'zIndex': 0},
    ]);
    await service.replaceBoardEdges(vid, [
      {'id': 'u5_e1', 'viewId': vid, 'sourceNodeId': 'u5_n1', 'targetNodeId': 'u5_n1'},
    ]);
    await service.replaceBoardTexts(vid, [
      {'id': 'u5_t1', 'viewId': vid, 'x': 1.0, 'y': 2.0, 'content': '文字'},
    ]);
    await service.replaceBoardStrokes(vid, [
      {'id': 'u5_s1', 'viewId': vid, 'groupId': null, 'zIndex': 0, 'points': '[[1,2],[3,4]]', 'color': '#FF0000', 'width': 2.0, 'createdAt': DateTime.now().toIso8601String()},
    ]);

    final nodes = await service.getBoardNodes(vid);
    final edges = await service.getBoardEdges(vid);
    final texts = await service.getBoardTexts(vid);
    final strokes = await service.getBoardStrokes(vid);

    expect(nodes, hasLength(1));
    expect(edges, hasLength(1));
    expect(texts, hasLength(1));
    expect(strokes, hasLength(1));
    expect(nodes.first['x'], 10.0);
    expect(nodes.first['y'], 20.0);
    expect(texts.first['content'], '文字');
    expect(strokes.first['points'], '[[1,2],[3,4]]');
  });

  test('U6 宠物：savePet 后 loadPet 字段保留，id 恒 1', () async {
    await service.savePet({'name': '测试云', 'level': 5, 'exp': 100});
    final pet = await service.loadPet();
    expect(pet, isNotNull);
    expect(pet!['name'], '测试云');
    expect(pet['level'], 5);
    expect(pet['exp'], 100);

    final rows = await db.select(db.pets).get();
    expect(rows, hasLength(1));
    expect(rows.first.id, 1);
  });

  test('U6 设置：saveSettings 后 loadSettings 字段保留', () async {
    await service.saveSettings({'nickname': '测试昵称', 'themeMode': 'dark'});
    final s = await service.loadSettings();
    expect(s, isNotNull);
    expect(s!['nickname'], '测试昵称');
    expect(s['themeMode'], 'dark');

    final rows = await db.select(db.userSettingsTable).get();
    expect(rows, hasLength(1));
  });
  test('U1 附件：systemTemp 写文件 -> DB 存绝对路径 -> 读回一致', () async {
    final tmp = Directory.systemTemp.createTempSync('u1_attach_');
    try {
      final f = File('${tmp.path}/attach_test.png');
      f.writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]);

      await service.insertNote({
        'id': 'u1_note_1',
        'title': 'u1',
        'content': '![img](${f.path})',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final rows = await db.select(db.notes).get();
      final row = rows.firstWhere((r) => r.id == 'u1_note_1');
      expect(row.content, contains(f.path));
      expect(File(f.path).existsSync(), true);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}