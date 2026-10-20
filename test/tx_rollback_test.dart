@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database/database.dart';
import 'package:my_note_app/database_service.dart';

void main() {
  late AppDatabase db;
  late DatabaseService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    
    // 确保 Drift 建表完成后再创建 Trigger
    await db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS tx_fail_nodes
      BEFORE INSERT ON nodes
      BEGIN
        SELECT RAISE(ABORT, 'simulated nodes insert failure');
      END;
    ''');
    
    service = DatabaseService.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('insertNoteAndNodeTx 事务回滚：nodes 插入失败时 notes 不残留', () async {
    const noteId = 'tx_test_note_1';
    final noteMap = <String, dynamic>{
      'id': noteId,
      'title': 'tx',
      'content': 'x',
      'updatedAt': DateTime.now().toIso8601String(),
    };
    final nodeMap = <String, dynamic>{
      'id': 'tx_test_node_1',
      'title': 'tx_node',
      'nodeType': 'folder',
    };

    await expectLater(
      () => service.insertNoteAndNodeTx(noteMap: noteMap, nodeMap: nodeMap),
      throwsA(anything),
    );

    final rows = await db.select(db.notes).get();
    expect(
      rows.where((r) => r.id == noteId),
      isEmpty,
      reason: '事务失败后 notes 应回滚，不应残留',
    );
  });
}