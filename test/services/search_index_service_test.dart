// test/services/search_index_service_test.dart
// SearchIndexService 单元测试
//
// 覆盖五个公开方法：
//   - getCreateTableSql          → 建表 SQL
//   - computeNoteTextRow         → note_text 行
//   - computeTagRows             → tag_index 行（markdown / richtext 双分支）
//   - computeSearchRowsFromTagRows → note_tag 派生行
//   - computeDeleteScopes        → 删除范围
//
// 纯函数测试，不碰数据库 / SharedPreferences / UI。
// 不 import flutter_quill。

import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/services/search_index_service.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // 1. getCreateTableSql
  // ═══════════════════════════════════════════════════════

  group('getCreateTableSql', () {
    test('返回 7 条 SQL（2 张表 + 5 个索引）', () {
      final sqls = SearchIndexService.getCreateTableSql();
      expect(sqls.length, 7);
    });

    test('包含 tag_index 建表语句（含 IF NOT EXISTS）', () {
      final sqls = SearchIndexService.getCreateTableSql();
      expect(
        sqls.any((s) => s.contains('CREATE TABLE IF NOT EXISTS tag_index')),
        isTrue,
      );
    });

    test('包含 search_index 建表语句（含 IF NOT EXISTS）', () {
      final sqls = SearchIndexService.getCreateTableSql();
      expect(
        sqls.any((s) => s.contains('CREATE TABLE IF NOT EXISTS search_index')),
        isTrue,
      );
    });

    test('所有 CREATE TABLE 均带 IF NOT EXISTS', () {
      final sqls = SearchIndexService.getCreateTableSql();
      final createTables =
          sqls.where((s) => s.contains('CREATE TABLE')).toList();
      expect(createTables.isNotEmpty, isTrue);
      for (final sql in createTables) {
        expect(sql, contains('IF NOT EXISTS'));
      }
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. computeNoteTextRow
  // ═══════════════════════════════════════════════════════

  group('computeNoteTextRow', () {
    test('空 id → 返回 null', () {
      final row = SearchIndexService.computeNoteTextRow({
        'id': '',
        'content': 'x',
      });
      expect(row, isNull);
    });

    test('缺 id → 返回 null', () {
      final row = SearchIndexService.computeNoteTextRow({
        'content': 'x',
      });
      expect(row, isNull);
    });

    test('空内容 → 返回 null', () {
      final row = SearchIndexService.computeNoteTextRow({
        'id': 'n1',
        'content': '',
      });
      expect(row, isNull);
    });

    test('有内容 → 返回 note_text 行', () {
      final row = SearchIndexService.computeNoteTextRow({
        'id': 'n1',
        'content': 'abc',
      });
      expect(row, isNotNull);
      expect(row!['kind'], 'note_text');
      expect(row['sourceType'], 'note');
      expect(row['sourceId'], 'n1');
      expect(row['searchText'], 'abc');
      expect(row['rawText'], 'abc');
      expect(row['subId'], isNull);
      expect(row['location'], isNull);
    });

    test('内容 > 200 字 → searchText 全文，rawText 截断', () {
      final longContent = 'a' * 300;
      final row = SearchIndexService.computeNoteTextRow({
        'id': 'n1',
        'content': longContent,
      });
      expect(row, isNotNull);
      expect(row!['searchText'], longContent);
      expect(row['rawText'], '${'a' * 200}...');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 3. computeTagRows — markdown
  // ═══════════════════════════════════════════════════════

  group('computeTagRows (markdown)', () {
    test('提取两个不同标签', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': '正文 #重要 #待解决'},
        'markdown',
      );
      expect(rows.length, 2);
      final tags = rows.map((r) => r['tag']).toSet();
      expect(tags, containsAll(['重要', '待解决']));
      for (final row in rows) {
        expect(row['type'], 'custom');
        expect(row['noteId'], 'n1');
        expect(row['blockId'], isNull);
      }
    });

    test('同一标签重复 → 去重，只一行', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': '#重要 #重要'},
        'markdown',
      );
      expect(rows.length, 1);
      expect(rows[0]['tag'], '重要');
    });

    test('无标签 → 空列表', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': 'abc 无标签内容'},
        'markdown',
      );
      expect(rows, isEmpty);
    });

    test('空内容 → 空列表', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': ''},
        'markdown',
      );
      expect(rows, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. computeTagRows — richtext
  // ═══════════════════════════════════════════════════════

  group('computeTagRows (richtext)', () {
    test('结构 JSON 块带 marks → 每块每 mark 一行', () {
      const content =
          '{"version":2,"blocks":[{"id":"b1","type":"paragraph","marks":["重要"],"inlines":[{"text":"正文"}]}]}';
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': content},
        'richtext',
      );
      expect(rows.length, 1);
      expect(rows[0]['tag'], '重要');
      expect(rows[0]['blockId'], 'b1');
      expect(rows[0]['type'], 'custom');
      expect(rows[0]['noteId'], 'n1');
      expect(rows[0]['text'], '正文');
    });

    test('多个块多 marks → 逐行展开', () {
      const content =
          '{"version":2,"blocks":[{"id":"b1","type":"paragraph","marks":["重要","待解决"],"inlines":[{"text":"A"}]},{"id":"b2","type":"paragraph","marks":["灵感"],"inlines":[{"text":"B"}]}]}';
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': content},
        'richtext',
      );
      expect(rows.length, 3);
    });

    test('非 JSON → 空列表，不崩', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': 'this is not json'},
        'richtext',
      );
      expect(rows, isEmpty);
    });

    test('空内容 → 空列表', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': ''},
        'richtext',
      );
      expect(rows, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. computeTagRows — 未知 format / 空 id
  // ═══════════════════════════════════════════════════════

  group('computeTagRows (unknown)', () {
    test('未知 format → 空列表', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': 'n1', 'content': '#重要'},
        'unknown',
      );
      expect(rows, isEmpty);
    });

    test('空 id → 空列表', () {
      final rows = SearchIndexService.computeTagRows(
        {'id': '', 'content': '#重要'},
        'markdown',
      );
      expect(rows, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // 6. computeSearchRowsFromTagRows
  // ═══════════════════════════════════════════════════════

  group('computeSearchRowsFromTagRows', () {
    test('空输入 → 空输出', () {
      final rows =
          SearchIndexService.computeSearchRowsFromTagRows('n1', []);
      expect(rows, isEmpty);
    });

    test('单行 tag → 单行 note_tag', () {
      final tagRows = [
        {
          'id': 'tag_n1_重要',
          'tag': '重要',
          'noteId': 'n1',
          'blockId': null,
          'text': '#重要',
          'createdAt': '2026-01-01T00:00:00.000',
        },
      ];
      final rows =
          SearchIndexService.computeSearchRowsFromTagRows('n1', tagRows);
      expect(rows.length, 1);
      expect(rows[0]['kind'], 'note_tag');
      expect(rows[0]['sourceType'], 'note');
      expect(rows[0]['sourceId'], 'n1');
      expect(rows[0]['subId'], 'tag_n1_重要');
      expect(rows[0]['searchText'], '标记 重要');
      expect(rows[0]['rawText'], '#重要');
      expect(rows[0]['location'], isNull);
    });

    test('多行 tag → 多行 note_tag', () {
      final tagRows = [
        {
          'id': 't1',
          'tag': 'a',
          'noteId': 'n1',
          'blockId': null,
          'text': '',
          'createdAt': '2026-01-01T00:00:00.000',
        },
        {
          'id': 't2',
          'tag': 'b',
          'noteId': 'n1',
          'blockId': null,
          'text': '',
          'createdAt': '2026-01-01T00:00:00.000',
        },
        {
          'id': 't3',
          'tag': 'c',
          'noteId': 'n1',
          'blockId': null,
          'text': '',
          'createdAt': '2026-01-01T00:00:00.000',
        },
      ];
      final rows =
          SearchIndexService.computeSearchRowsFromTagRows('n1', tagRows);
      expect(rows.length, 3);
    });

    test('blockId 有值时 location 保留', () {
      final tagRows = [
        {
          'id': 't1',
          'tag': '重要',
          'noteId': 'n1',
          'blockId': 'b1',
          'text': '',
          'createdAt': '2026-01-01T00:00:00.000',
        },
      ];
      final rows =
          SearchIndexService.computeSearchRowsFromTagRows('n1', tagRows);
      expect(rows[0]['location'], 'b1');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 7. computeDeleteScopes
  // ═══════════════════════════════════════════════════════

  group('computeDeleteScopes', () {
    test('返回 2 项', () {
      final scopes = SearchIndexService.computeDeleteScopes();
      expect(scopes.length, 2);
    });

    test('含 note_text + note_tag 两组', () {
      final scopes = SearchIndexService.computeDeleteScopes();
      expect(
        scopes.any((s) => s.sourceType == 'note' && s.kind == 'note_text'),
        isTrue,
      );
      expect(
        scopes.any((s) => s.sourceType == 'note' && s.kind == 'note_tag'),
        isTrue,
      );
    });
  });
}