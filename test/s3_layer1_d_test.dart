@TestOn('vm')
library;

import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database/database.dart';
import 'package:my_note_app/database_service.dart';
import 'package:my_note_app/services/markdown_import_service.dart';

void main() {
  late AppDatabase db;
  late DatabaseService service;
  late MarkdownImportService importService;
  late Directory tmpDir;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = DatabaseService.forTesting(db);
    importService = MarkdownImportService.forTesting(service);
    tmpDir = Directory.systemTemp.createTempSync('md_import_');
  });

  tearDown(() async {
    await db.close();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  void noopProgress(String _, int __, int ___, String ____) {}

  test('目录不存在抛 Exception', () async {
    await expectLater(
      () => importService.importDirectory(
        sourceDir: '${tmpDir.path}/nonexistent',
        targetFolderName: '测试文件夹',
        onProgress: noopProgress,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('空目录：total=0 success=0 skipped=0 failed 空', () async {
    final r = await importService.importDirectory(
      sourceDir: tmpDir.path,
      targetFolderName: '测试文件夹',
      onProgress: noopProgress,
    );
    expect(r.total, 0);
    expect(r.success, 0);
    expect(r.skipped, 0);
    expect(r.failed, isEmpty);
  });

  test('1 个 md 文件：total=1 success=1；notes 表 1 行', () async {
    File('${tmpDir.path}/a.md').writeAsStringSync('# 标题A\n\n正文内容A');
    final r = await importService.importDirectory(
      sourceDir: tmpDir.path,
      targetFolderName: '测试文件夹',
      onProgress: noopProgress,
    );
    expect(r.total, 1);
    expect(r.success, 1, reason: '_parseMdFile 应能解析 "# 标题\\n\\n正文" 简单格式');
    expect(r.failed, isEmpty);

    final notes = await service.getAllNotes(includeDeleted: true);
    expect(notes.length, 1, reason: '_insertOne 调 insertNoteAndNodeTx 写 1 note');
  });

  test('3 个 md 文件：total=3 success=3', () async {
    for (var i = 1; i <= 3; i++) {
      File('${tmpDir.path}/n$i.md').writeAsStringSync('# 标题$i\n\n内容$i');
    }
    final r = await importService.importDirectory(
      sourceDir: tmpDir.path,
      targetFolderName: '测试文件夹',
      onProgress: noopProgress,
    );
    expect(r.total, 3);
    expect(r.success, 3);
    expect(r.failed, isEmpty);
    final notes = await service.getAllNotes(includeDeleted: true);
    expect(notes.length, 3);
  });

  test('非 .md 文件被忽略：total 只算 .md', () async {
    File('${tmpDir.path}/a.md').writeAsStringSync('# A\n\n内容');
    File('${tmpDir.path}/b.txt').writeAsStringSync('非 md');
    final r = await importService.importDirectory(
      sourceDir: tmpDir.path,
      targetFolderName: '测试文件夹',
      onProgress: noopProgress,
    );
    expect(r.total, 1, reason: '_scanMdFiles 只扫 .md（:114）');
    expect(r.success, 1);
  });
}