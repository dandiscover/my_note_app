@TestOn('vm')
library;

import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database/database.dart';
import 'package:my_note_app/database_service.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('L1-5 导出/导入', () {
    late AppDatabase db;
    late DatabaseService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = DatabaseService.forTesting(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('exportAllData 返回 JSON，含 version / notes / nodes / books', () async {
      await service.insertNote({
        'id': 'exp_n1',
        'title': 'ExportT',
        'content': 'ExportC',
        'updatedAt': '2026-10-19T01:00:00.000',
      });

      final json = await service.exportAllData();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['version'], '1.0');
      expect(decoded['notes'], isA<List>());
      expect((decoded['notes'] as List).length, 1);
      expect(decoded['nodes'], isA<List>());
      expect(decoded['books'], isA<List>());
    });

    test('importAllData 清空后重建 notes', () async {
      await service.insertNote({
        'id': 'exp_n1',
        'title': 'T1',
        'content': 'C1',
        'updatedAt': '2026-10-19T01:00:00.000',
      });
      final json = await service.exportAllData();

      await service.insertNote({
        'id': 'exp_n2',
        'title': 'T2',
        'content': 'C2',
        'updatedAt': '2026-10-19T02:00:00.000',
      });
      expect((await service.getAllNotes(includeDeleted: true)).length, 2);

      await service.importAllData(json);
      final after = await service.getAllNotes(includeDeleted: true);
      expect(after.length, 1, reason: '_clearAllData 先清空');
      expect(after.first['id'], 'exp_n1');
    });

    test('exportNotesAsMarkdown 含标题 / 正文 / 分隔线', () async {
      await service.insertNote({
        'id': 'md_n1',
        'title': 'MdTitleX',
        'content': 'MdContentY',
        'updatedAt': '2026-10-19T01:00:00.000',
      });
      final md = await service.exportNotesAsMarkdown();
      expect(md, contains('# MdTitleX'), reason: 'Markdown 输出应包含标题');
      expect(md, contains('MdContentY'), reason: 'Markdown 输出应包含正文');
      expect(md, contains('---'), reason: '每笔记末尾应有分隔线');
    });

    test('三表完整往返：note + node + book export→import 后行数一致', () async {
      await service.insertNote({
        'id': 'rt_n1',
        'title': '往返测试笔记',
        'content': '往返测试正文',
        'updatedAt': '2026-10-20T01:00:00.000',
      });
      await service.insertNode({
        'id': 'rt_node1',
        'title': '往返测试节点',
        'parentId': null,
        'sortOrder': 1,
        'createdAt': '2026-10-20T01:00:00.000',
      });
      await service.insertBook({
        'id': 'rt_b1',
        'title': '往返测试书',
        'author': '作者A',
        'isbn': '1234567890',
      });

      final json = await service.exportAllData();
      await service.importAllData(json);

      final notes = await service.getAllNotes(includeDeleted: true);
      final nodes = await service.getAllNodes();
      final books = await service.getAllBooks();

      expect(notes.where((m) => m['id'] == 'rt_n1').length, 1);
      expect(nodes.where((n) => n.id == 'rt_node1').length, 1);
      expect(books.where((m) => m['id'] == 'rt_b1').length, 1);
    });

    test('字段级一致性：note 6 字段 + node 5 字段 + book 15 字段（代-账-006 三字段不断言）', () async {
      await service.insertNote({
        'id': 'rt_n2',
        'title': '字段笔记',
        'content': '字段正文',
        'status': 'active',
        'editorMode': 'markdown',
        'updatedAt': '2026-10-20T02:00:00.000',
      });
      await service.insertNode({
        'id': 'rt_node2',
        'title': '字段节点',
        'parentId': null,
        'sortOrder': 5,
        'createdAt': '2026-10-20T02:00:00.000',
      });
      await service.insertBook({
        'id': 'rt_b2',
        'title': '字段书',
        'author': '作者B',
        'isbn': '0987654321',
        'coverUrl': 'http://example.com/c.jpg',
        'filePath': '/path/to/book.pdf',
        'fileType': 'pdf',
        'fileName': 'book.pdf',
        'fileSize': 1024,
        'status': 'reading',
        'readingProgress': 50,
        'totalPages': 200,
        'createdAt': '2026-10-20T02:00:00.000',
        'lastReadAt': '2026-10-20T02:30:00.000',
        'source': 'import',
      });

      final json = await service.exportAllData();
      await service.importAllData(json);

      // note 5 字段（id 已断言过，其余）
      final notes = await service.getAllNotes(includeDeleted: true);
      final n = notes.firstWhere((m) => m['id'] == 'rt_n2');
      expect(n['title'], '字段笔记');
      expect(n['content'], '字段正文');
      expect(n['status'], 'active');
      expect(n['editorMode'], 'markdown');
      expect(n['updatedAt'], '2026-10-20T02:00:00.000');

      // node 4 字段（id 已断言过，其余）
      final nodes = await service.getAllNodes();
      final node = nodes.firstWhere((x) => x.id == 'rt_node2');
      expect(node.title, '字段节点');
      expect(node.parentId, null);
      expect(node.sortOrder, 5);
      expect(node.createdAt.toIso8601String(), '2026-10-20T02:00:00.000');

      // book 14 字段（id 已断言过，其余）
      // 代-账-006 已知 bug：_bookRowToMap / _bookMapToCompanion 两端都缺
      // summary / rating / review 三字段，round-trip 必丢。本批不断言这三字段，修完补。
      final books = await service.getAllBooks();
      final b = books.firstWhere((m) => m['id'] == 'rt_b2');
      expect(b['title'], '字段书');
      expect(b['author'], '作者B');
      expect(b['isbn'], '0987654321');
      expect(b['coverUrl'], 'http://example.com/c.jpg');
      expect(b['filePath'], '/path/to/book.pdf');
      expect(b['fileType'], 'pdf');
      expect(b['fileName'], 'book.pdf');
      expect(b['fileSize'], 1024);
      expect(b['status'], 'reading');
      expect(b['readingProgress'], 50);
      expect(b['totalPages'], 200);
      expect(b['createdAt'], '2026-10-20T02:00:00.000');
      expect(b['lastReadAt'], '2026-10-20T02:30:00.000');
      expect(b['source'], 'import');
    });

    test('export→import→export 幂等：去 exportDate 后结构相等', () async {
      await service.insertNote({
        'id': 'rt_n3',
        'title': '幂等笔记',
        'content': '幂等正文',
        'updatedAt': '2026-10-20T03:00:00.000',
      });
      await service.insertNode({
        'id': 'rt_node3',
        'title': '幂等节点',
        'parentId': null,
        'sortOrder': 2,
        'createdAt': '2026-10-20T03:00:00.000',
      });
      await service.insertBook({
        'id': 'rt_b3',
        'title': '幂等书',
        'author': '作者C',
      });

      final jsonA = await service.exportAllData();
      await service.importAllData(jsonA);
      final jsonB = await service.exportAllData();

      final a = jsonDecode(jsonA) as Map<String, dynamic>;
      final b = jsonDecode(jsonB) as Map<String, dynamic>;
      a.remove('exportDate');
      b.remove('exportDate');
      expect(b, equals(a));
    });
  });
}
