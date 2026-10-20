@TestOn('vm')
library;

import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database/database.dart';
import 'package:my_note_app/database_service.dart';
import 'package:my_note_app/models/review_card.dart';
import 'package:my_note_app/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('L1-4 复习', () {
    late ReviewService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = ReviewService();
    });

    test('addCard -> loadAll 一致；新卡 repetitions=0、isNew=true', () async {
      final card = ReviewCard(
        id: 'r1',
        noteId: 'n1',
        question: 'Q1',
        answer: 'A1',
        createdAt: DateTime.now(),
      );
      await service.addCard(card);

      final all = await service.loadAll();
      expect(all.length, 1);
      expect(all.first.id, 'r1');
      expect(all.first.question, 'Q1');
      expect(all.first.answer, 'A1');
      expect(all.first.repetitions, 0);
      expect(all.first.isNew, true);
    });

    test('新建卡 nextReviewAt==null -> isDue=true -> getDueCards 含此卡', () async {
      await service.addCard(ReviewCard(
        id: 'r2',
        noteId: 'n2',
        question: 'Q',
        answer: 'A',
        createdAt: DateTime.now(),
      ));

      final due = await service.getDueCards();
      expect(due.map((c) => c.id), contains('r2'));
    });

    test('reviewCard 返回同 id 卡；loadAll 可读回', () async {
      await service.addCard(ReviewCard(
        id: 'r3',
        noteId: 'n3',
        question: 'Q',
        answer: 'A',
        createdAt: DateTime.now(),
      ));

      final updated = await service.reviewCard('r3', 3);
      expect(updated.id, 'r3');

      final all = await service.loadAll();
      expect(all.where((c) => c.id == 'r3').length, 1);
    });

    test('reviewCard 不存在 id 抛 Exception', () async {
      await expectLater(
        () => service.reviewCard('nope', 3),
        throwsA(isA<Exception>()),
      );
    });

    test('removeCard 后 loadAll 不含', () async {
      await service.addCard(ReviewCard(
        id: 'r4',
        noteId: 'n',
        question: 'q',
        answer: 'a',
        createdAt: DateTime.now(),
      ));
      await service.removeCard('r4');
      final all = await service.loadAll();
      expect(all.where((c) => c.id == 'r4'), isEmpty);
    });
  });

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
  });
}