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

  // ═══════════ 1 · 时间格式：ISO8601 字符串往返一致 ═══════════
  test('时间格式：updatedAt 写入→读出字符串完全一致', () async {
    final iso = '2026-10-19T12:34:56.789';
    await service.insertNote({
      'id': 't1',
      'title': 't1',
      'updatedAt': iso,
    });
    final rows = await service.getAllNotes(includeDeleted: true);
    final row = rows.firstWhere((m) => m['id'] == 't1');
    expect(row['updatedAt'], iso, reason: '写入 ISO 字符串，读出应逐字相同');
  });

  // ═══════════ 2 · 单字段排序：updatedAt DESC ═══════════
  test('排序（单字段）：getAllNotes 默认 updatedAt DESC', () async {
    await service.insertNote({'id': 's1', 'title': 's1', 'updatedAt': '2026-10-19T01:00:00.000'});
    await service.insertNote({'id': 's2', 'title': 's2', 'updatedAt': '2026-10-19T03:00:00.000'});
    await service.insertNote({'id': 's3', 'title': 's3', 'updatedAt': '2026-10-19T02:00:00.000'});
    final rows = await service.getAllNotes();
    final ids = rows.map((m) => m['id']).toList();
    expect(ids, ['s2', 's3', 's1'], reason: 'updatedAt 降序');
  });

  // ═══════════ 3 · 多字段排序：sortOrder ASC → createdAt ASC ═══════════
  test('排序（多字段）：getAllNodes 按 sortOrder 升序，同值时按 createdAt 升序', () async {
    await service.insertNode({'id': 'n_a', 'title': 'a', 'sortOrder': 5, 'createdAt': '2026-10-19T03:00:00.000'});
    await service.insertNode({'id': 'n_b', 'title': 'b', 'sortOrder': 5, 'createdAt': '2026-10-19T01:00:00.000'});
    await service.insertNode({'id': 'n_c', 'title': 'c', 'sortOrder': 5, 'createdAt': '2026-10-19T02:00:00.000'});
    final nodes = await service.getAllNodes();
    final ids = nodes.map((n) => n.id).toList();
    expect(ids, ['n_b', 'n_c', 'n_a'], reason: 'sortOrder 同值时按 createdAt 升序');
  });

  // ═══════════ 4 · 空值：'' / 'null' → null，真实值保留 ═══════════
  test('空值：parentId 空串或 "null" 转 null，真实值保留', () async {
    await service.insertNode({'id': 'e1', 'title': 'e1', 'parentId': ''});
    await service.insertNode({'id': 'e2', 'title': 'e2', 'parentId': 'null'});
    await service.insertNode({'id': 'e3', 'title': 'e3', 'parentId': 'real_parent'});
    final nodes = await service.getAllNodes();
    expect(nodes.firstWhere((n) => n.id == 'e1').parentId, null);
    expect(nodes.firstWhere((n) => n.id == 'e2').parentId, null);
    expect(nodes.firstWhere((n) => n.id == 'e3').parentId, 'real_parent');
  });

  // ═══════════ 5 · 事务回滚 × 4 ═══════════
  test('事务回滚：insertBookHighlights 第二条失败，整批回滚', () async {
    await db.customStatement('''
      CREATE TRIGGER tx_fail_highlights BEFORE INSERT ON book_highlights
      WHEN NEW.id = 'fail_id' BEGIN SELECT RAISE(ABORT, 'simulated'); END;
    ''');
    final hs = [
      {'id': 'ok_id', 'book_id': 'b1', 'created_at': '2026-10-19T01:00:00.000'},
      {'id': 'fail_id', 'book_id': 'b1', 'created_at': '2026-10-19T02:00:00.000'},
    ];
    await expectLater(() => service.insertBookHighlights(hs), throwsA(anything));
    final rows = await db.select(db.bookHighlights).get();
    expect(rows.where((r) => r.bookId == 'b1'), isEmpty, reason: '整批回滚，ok_id 也不应残留');
  });

  test('事务回滚：replaceBoardNodes 插入失败，旧节点保留', () async {
    await service.replaceBoardNodes('v1', [
      {'id': 'old_n1', 'viewId': 'v1', 'x': 1.0, 'y': 2.0},
    ]);
    await db.customStatement('''
      CREATE TRIGGER tx_fail_board_nodes BEFORE INSERT ON board_nodes
      WHEN NEW.id = 'fail_n1' BEGIN SELECT RAISE(ABORT, 'simulated'); END;
    ''');
    await expectLater(
      () => service.replaceBoardNodes('v1', [
        {'id': 'fail_n1', 'viewId': 'v1', 'x': 3.0, 'y': 4.0},
      ]),
      throwsA(anything),
    );
    final after = await service.getBoardNodes('v1');
    expect(after, hasLength(1), reason: '删除已回滚，旧节点应保留');
    expect(after.first['id'], 'old_n1');
  });

  test('事务回滚：replaceBoardEdges 插入失败，旧边保留', () async {
    await service.replaceBoardEdges('v1', [
      {'id': 'old_e1', 'viewId': 'v1', 'sourceNodeId': 'a', 'targetNodeId': 'b'},
    ]);
    await db.customStatement('''
      CREATE TRIGGER tx_fail_board_edges BEFORE INSERT ON board_edges
      WHEN NEW.id = 'fail_e1' BEGIN SELECT RAISE(ABORT, 'simulated'); END;
    ''');
    await expectLater(
      () => service.replaceBoardEdges('v1', [
        {'id': 'fail_e1', 'viewId': 'v1', 'sourceNodeId': 'c', 'targetNodeId': 'd'},
      ]),
      throwsA(anything),
    );
    final after = await service.getBoardEdges('v1');
    expect(after, hasLength(1), reason: '删除已回滚，旧边应保留');
    expect(after.first['id'], 'old_e1');
  });

  test('事务回滚：saveNodeAnnotation 插入失败，旧标注保留', () async {
    await service.saveNodeAnnotation('node1', [{'stroke': 'old'}]);
    await db.customStatement('''
      CREATE TRIGGER tx_fail_annotations BEFORE INSERT ON node_annotations
      WHEN NEW.id = 'na_node1' BEGIN SELECT RAISE(ABORT, 'simulated'); END;
    ''');
    await expectLater(
      () => service.saveNodeAnnotation('node1', [{'stroke': 'new'}]),
      throwsA(anything),
    );
    final after = await db.select(db.nodeAnnotations).get();
    expect(after.where((r) => r.nodeId == 'node1'), hasLength(1),
        reason: '删除已回滚，旧标注应保留');
  });

  // ═══════════ 6 · 批量写 ═══════════
  test('批量写：insertBookHighlights 一次插入 5 条，结果一致', () async {
    final hs = List.generate(5, (i) => {
      'id': 'batch_h$i',
      'book_id': 'b1',
      'created_at': '2026-10-19T0${i}:00:00.000',
    });
    await service.insertBookHighlights(hs);
    final rows = await db.select(db.bookHighlights).get();
    expect(rows.where((r) => r.bookId == 'b1').length, 5);
  });

  // ═══════════ 7 · 模糊搜索 ═══════════
  test('模糊搜索：正文关键词命中；标题不命中（代-账-001）', () async {
    await service.insertNote({
      'id': 'f1',
      'title': '标题uniqueTitleX',
      'content': '正文uniqueContentY',
      'updatedAt': '2026-10-19T01:00:00.000',
    });
    expect(await service.searchIndex('uniqueContentY'), isNotEmpty,
        reason: '正文关键词应命中');
    expect(await service.searchIndex('uniqueTitleX'), isEmpty,
        reason: '标题不参与索引——代-账-001，非本批修');
    expect(await service.searchIndex('   '), isEmpty, reason: '空关键词不返回');
  });

  // ═══════════ 8 · 事务嵌套：仅审查，不出代码 ═══════════

  // ═══════════ 9 · 隔离级别（单端顺序一致） ═══════════
  test('单端顺序一致：顺序插入后两次读取顺序完全一致', () async {
    for (var i = 0; i < 5; i++) {
      await service.insertNote({
        'id': 'seq_$i',
        'title': 'seq $i',
        'updatedAt': '2026-10-19T0$i:00:00.000',
      });
    }
    final a = await service.getAllNotes();
    final b = await service.getAllNotes();
    expect(a.map((m) => m['id']).toList(), b.map((m) => m['id']).toList(),
        reason: '单端顺序读取，两次结果顺序应一致');
    expect(a.length, 5);
  });
}