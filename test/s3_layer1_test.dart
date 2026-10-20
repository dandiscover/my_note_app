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

  // ═══════════ L1-1 笔记树：多层级父子关系 ═══════════
  test('L1-1 笔记树：多层级父子关系经 parentId 正确存取', () async {
    await service.insertNode({'id': 'root', 'title': 'root', 'parentId': null, 'sortOrder': 0});
    await service.insertNode({'id': 'child1', 'title': 'c1', 'parentId': 'root', 'sortOrder': 1});
    await service.insertNode({'id': 'child2', 'title': 'c2', 'parentId': 'root', 'sortOrder': 2});
    await service.insertNode({'id': 'grand', 'title': 'g', 'parentId': 'child1', 'sortOrder': 1});

    final nodes = await service.getAllNodes();
    expect(nodes.length, 4);

    final byParent = <String?, List<String>>{};
    for (final n in nodes) {
      byParent.putIfAbsent(n.parentId, () => []).add(n.id);
    }
    expect(byParent[null], ['root'], reason: '顶层只有 root');
    expect(byParent['root'], ['child1', 'child2'], reason: 'root 下两子，按 sortOrder 升序');
    expect(byParent['child1'], ['grand'], reason: 'child1 下挂 grand');
  });

  // ═══════════ L1-3 画布：多视图隔离 + 幂等替换 ═══════════
  test('L1-3 画布：多视图隔离，A 视图替换不影响 B 视图', () async {
    await service.upsertBoardView({'id': 'vA', 'name': 'A', 'type': 'board'});
    await service.upsertBoardView({'id': 'vB', 'name': 'B', 'type': 'board'});
    await service.replaceBoardNodes('vA', [
      {'id': 'a1', 'viewId': 'vA', 'type': 'card', 'x': 1.0, 'y': 2.0},
    ]);
    await service.replaceBoardNodes('vB', [
      {'id': 'b1', 'viewId': 'vB', 'type': 'card', 'x': 3.0, 'y': 4.0},
    ]);

    await service.replaceBoardNodes('vA', [
      {'id': 'a2', 'viewId': 'vA', 'type': 'card', 'x': 5.0, 'y': 6.0},
    ]);

    final a = await service.getBoardNodes('vA');
    final b = await service.getBoardNodes('vB');
    expect(a.map((n) => n['id']).toList(), ['a2'], reason: 'A 视图只剩新节点');
    expect(b.map((n) => n['id']).toList(), ['b1'], reason: 'B 视图不受 A 影响');
  });

  test('L1-3 画布：同视图重复 replaceBoardNodes 幂等，无残留', () async {
    await service.replaceBoardNodes('v1', [
      {'id': 'n_old', 'viewId': 'v1', 'type': 'card', 'x': 1.0, 'y': 2.0},
    ]);
    await service.replaceBoardNodes('v1', [
      {'id': 'n_new', 'viewId': 'v1', 'type': 'card', 'x': 3.0, 'y': 4.0},
    ]);
    final nodes = await service.getBoardNodes('v1');
    expect(nodes, hasLength(1), reason: 'replace 先删后写，旧节点应被清');
    expect(nodes.first['id'], 'n_new');
  });

  // ═══════════ L1-6 搜索：limit 参数 ═══════════
  test('L1-6 搜索：limit 参数限制返回数量', () async {
    for (var i = 0; i < 10; i++) {
      await service.insertNote({
        'id': 'lim_n$i',
        'title': 'lim',
        'content': 'common keyword limitmarker$i',
        'updatedAt': '2026-10-19T0$i:00:00.000',
      });
    }

    final all = await service.searchIndex('limitmarker');
    expect(all.length, 10, reason: '10 条笔记内容都含 limitmarker，应全返回');

    final limited = await service.searchIndex('limitmarker', limit: 3);
    expect(limited.length, 3, reason: 'limit=3 应截断到 3 条');
  });

  // ═══════════ L1-7 超大字段：content / exploreTasks ═══════════
  test('L1-7 超大字段：100KB content 往返逐字一致', () async {
    final largeContent = 'A' * 100000; // 100KB
    await service.insertNote({
      'id': 'big_n1',
      'title': 'big',
      'content': largeContent,
      'updatedAt': '2026-10-19T01:00:00.000',
    });
    final rows = await service.getAllNotes(includeDeleted: true);
    final row = rows.firstWhere((m) => m['id'] == 'big_n1');
    expect((row['content'] as String).length, 100000);
    expect(row['content'], largeContent, reason: '逐字一致');
  });

  test('L1-7 超大字段：100 条 exploreTasks JSON 往返', () async {
    final tasks = List.generate(100, (i) => {'id': 't$i', 'question': 'q$i'});
    await service.insertNote({
      'id': 'big_n2',
      'title': 'big2',
      'content': 'x',
      'exploreTasks': tasks,
      'updatedAt': '2026-10-19T01:00:00.000',
    });
    final rows = await service.getAllNotes(includeDeleted: true);
    final row = rows.firstWhere((m) => m['id'] == 'big_n2');
    expect((row['exploreTasks'] as List).length, 100,
        reason: '_noteMapToCompanion jsonEncode，_noteRowToMap jsonDecode，往返 100 条');
  });
}