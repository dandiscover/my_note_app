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

  Map<String, dynamic> noteMap(String id, {String title = 't', String content = 'c'}) => {
        'id': id,
        'title': title,
        'content': content,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  test('C1 insertNote 正向写库', () async {
    await service.insertNote(noteMap('c1_note', title: 'c1_title'));
    final rows = await db.select(db.notes).get();
    final hit = rows.where((r) => r.id == 'c1_note').toList();
    expect(hit.length, 1);
    expect(hit.first.title, 'c1_title');
    expect(hit.first.status, 'raw');
  });

  test('C2 updateNote 改标题/内容', () async {
    await service.insertNote(noteMap('c2_note', title: 'old', content: 'old_c'));
    await service.updateNote(noteMap('c2_note', title: 'new', content: 'new_c'));
    final rows = await db.select(db.notes).get();
    final hit = rows.firstWhere((r) => r.id == 'c2_note');
    expect(hit.title, 'new');
    expect(hit.content, 'new_c');
  });

  test('C3 deleteNote 软删：status=deleted，includeDeleted 口径正确', () async {
    await service.insertNote(noteMap('c3_note'));
    await service.deleteNote('c3_note');

    final visible = await service.getAllNotes(includeDeleted: false);
    expect(visible.where((m) => m['id'] == 'c3_note'), isEmpty);

    final all = await service.getAllNotes(includeDeleted: true);
    final hit = all.where((m) => m['id'] == 'c3_note').toList();
    expect(hit.length, 1);
    expect(hit.first['status'], 'deleted');
  });

  test('C4 hardDeleteNote 硬删：物理消失，includeDeleted 也查不到', () async {
    await service.insertNote(noteMap('c4_note'));
    await service.hardDeleteNote('c4_note');

    final all = await service.getAllNotes(includeDeleted: true);
    expect(all.where((m) => m['id'] == 'c4_note'), isEmpty);
  });

  test('C5 insertNoteAndNodeTx 正例：notes + nodes 各 1 行，无异常', () async {
    final nm = noteMap('c5_note', title: 'c5');
    final nd = <String, dynamic>{
      'id': 'c5_node',
      'title': 'c5_node',
      'nodeType': 'folder',
    };

    await service.insertNoteAndNodeTx(noteMap: nm, nodeMap: nd);

    final notes = await db.select(db.notes).get();
    final nodes = await db.select(db.nodes).get();
    expect(notes.where((r) => r.id == 'c5_note').length, 1);
    expect(nodes.where((r) => r.id == 'c5_node').length, 1);
  });
}