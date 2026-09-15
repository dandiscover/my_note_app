// test/models/note_test.dart
// NotebookEntry.copyWith 哨兵行为测试 + contentFormat 字段测试
//
// 重点：
//   1. copyWith 三行为（不传保留 / 传 null 清空 / 传值覆盖）
//      —— BUG-001 的核心，不测则下次改动可能回退无人知
//   2. inquiryQuestion + inquiryConclusion 两字段同规则
//   3. contentFormat 字段（9b 加）的构造 / fromMap / toMap / copyWith
//
// 不 import flutter_quill，不碰 UI。

import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/models/note.dart';

void main() {
  // ─── 辅助：构造一个最小 NotebookEntry ───
  NotebookEntry makeEntry({
    String? inquiryQuestion = 'Q0',
    String? inquiryConclusion = 'C0',
    String contentFormat = 'markdown',
  }) {
    return NotebookEntry(
      id: 'n1',
      title: 't',
      content: 'c',
      updatedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      inquiryQuestion: inquiryQuestion,
      inquiryConclusion: inquiryConclusion,
      contentFormat: contentFormat,
    );
  }

  // ─── 辅助：构造最小 map ───
  Map<String, dynamic> baseMap({
    Object? contentFormat,
    bool includeContentFormat = false,
  }) {
    final map = <String, dynamic>{
      'id': 'n1',
      'title': '测试标题',
      'content': '测试内容',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    };
    if (includeContentFormat) {
      map['contentFormat'] = contentFormat;
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════
  // 1. copyWith 哨兵 — inquiryQuestion
  // ═══════════════════════════════════════════════════════

  group('copyWith · inquiryQuestion', () {
    test('不传 → 保留旧值', () {
      final entry = makeEntry(inquiryQuestion: '旧问题');
      final copied = entry.copyWith(title: '改标题');
      expect(copied.inquiryQuestion, '旧问题');
    });

    test('传 null → 清空（BUG-001 核心）', () {
      final entry = makeEntry(inquiryQuestion: '旧问题');
      final copied = entry.copyWith(inquiryQuestion: null);
      expect(copied.inquiryQuestion, isNull);
    });

    test('传新值 → 覆盖', () {
      final entry = makeEntry(inquiryQuestion: '旧问题');
      final copied = entry.copyWith(inquiryQuestion: '新问题');
      expect(copied.inquiryQuestion, '新问题');
    });

    test('从 null 传 null → 仍是 null', () {
      final entry = makeEntry(inquiryQuestion: null);
      final copied = entry.copyWith(inquiryQuestion: null);
      expect(copied.inquiryQuestion, isNull);
    });

    test('从 null 传值 → 赋值', () {
      final entry = makeEntry(inquiryQuestion: null);
      final copied = entry.copyWith(inquiryQuestion: '新问题');
      expect(copied.inquiryQuestion, '新问题');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 2. copyWith 哨兵 — inquiryConclusion
  // ═══════════════════════════════════════════════════════

  group('copyWith · inquiryConclusion', () {
    test('不传 → 保留旧值', () {
      final entry = makeEntry(inquiryConclusion: '旧结论');
      final copied = entry.copyWith(title: '改标题');
      expect(copied.inquiryConclusion, '旧结论');
    });

    test('传 null → 清空（BUG-001 核心）', () {
      final entry = makeEntry(inquiryConclusion: '旧结论');
      final copied = entry.copyWith(inquiryConclusion: null);
      expect(copied.inquiryConclusion, isNull);
    });

    test('传新值 → 覆盖', () {
      final entry = makeEntry(inquiryConclusion: '旧结论');
      final copied = entry.copyWith(inquiryConclusion: '新结论');
      expect(copied.inquiryConclusion, '新结论');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 3. copyWith 哨兵 — 两字段同时
  // ═══════════════════════════════════════════════════════

  group('copyWith · 两字段同时', () {
    test('两字段都传 null → 都清空', () {
      final entry = makeEntry(
        inquiryQuestion: '旧问题',
        inquiryConclusion: '旧结论',
      );
      final copied = entry.copyWith(
        inquiryQuestion: null,
        inquiryConclusion: null,
      );
      expect(copied.inquiryQuestion, isNull);
      expect(copied.inquiryConclusion, isNull);
    });

    test('一清一留 → 各按规则', () {
      final entry = makeEntry(
        inquiryQuestion: '旧问题',
        inquiryConclusion: '旧结论',
      );
      final copied = entry.copyWith(inquiryQuestion: null);
      expect(copied.inquiryQuestion, isNull);
      expect(copied.inquiryConclusion, '旧结论');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 4. contentFormat — 构造
  // ═══════════════════════════════════════════════════════

  group('contentFormat · 构造', () {
    test('不传 → 默认 markdown', () {
      final entry = NotebookEntry(
        id: 'n1',
        title: 't',
        content: 'c',
        updatedAt: DateTime.now(),
      );
      expect(entry.contentFormat, 'markdown');
    });

    test('传 richtext → 保留', () {
      final entry = makeEntry(contentFormat: 'richtext');
      expect(entry.contentFormat, 'richtext');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 5. contentFormat — fromMap
  // ═══════════════════════════════════════════════════════

  group('contentFormat · fromMap', () {
    test('map 无 key → markdown', () {
      final entry = NotebookEntry.fromMap(baseMap());
      expect(entry.contentFormat, 'markdown');
    });

    test('map 有 richtext → richtext', () {
      final entry = NotebookEntry.fromMap(
        baseMap(includeContentFormat: true, contentFormat: 'richtext'),
      );
      expect(entry.contentFormat, 'richtext');
    });

    test('map 有 "" → markdown', () {
      final entry = NotebookEntry.fromMap(
        baseMap(includeContentFormat: true, contentFormat: ''),
      );
      expect(entry.contentFormat, 'markdown');
    });

    test('map 有脏数据 42 → markdown，不崩（T-177）', () {
      final map = baseMap();
      map['contentFormat'] = 42;
      final entry = NotebookEntry.fromMap(map);
      expect(entry.contentFormat, 'markdown');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 6. contentFormat — toMap
  // ═══════════════════════════════════════════════════════

  group('contentFormat · toMap', () {
    test('richtext 的 entry → map 含 richtext', () {
      final entry = makeEntry(contentFormat: 'richtext');
      final map = entry.toMap();
      expect(map['contentFormat'], 'richtext');
    });
  });

  // ═══════════════════════════════════════════════════════
  // 7. contentFormat — copyWith
  // ═══════════════════════════════════════════════════════

  group('contentFormat · copyWith', () {
    test('不传 → 保留旧值', () {
      final entry = makeEntry(contentFormat: 'richtext');
      final copied = entry.copyWith(title: '改标题');
      expect(copied.contentFormat, 'richtext');
    });

    test('传值 → 覆盖', () {
      final entry = makeEntry(contentFormat: 'richtext');
      final copied = entry.copyWith(contentFormat: 'markdown');
      expect(copied.contentFormat, 'markdown');
    });

    test('传 null → 保留旧值（不用哨兵）', () {
      final entry = makeEntry(contentFormat: 'richtext');
      final copied = entry.copyWith(contentFormat: null);
      expect(copied.contentFormat, 'richtext');
    });
  });
}