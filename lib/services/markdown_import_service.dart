// lib/services/markdown_import_service.dart
// Markdown 批量导入 —— 桌面端
// 甲案：不引 html 包 —— 手写扫描器

import 'dart:io';
import 'package:path/path.dart' as p;
import '../database_service.dart';
import '../models/note.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'image_path_service.dart';
import 'package:flutter/foundation.dart';
class MarkdownImportResult {
  final int success;
  final int skipped;
  final int total;
  final List<ImportFailure> failed;
  MarkdownImportResult({
    required this.success,
    required this.skipped,
    required this.total,
    required this.failed,
  });
}

class ImportFailure {
  final String path;
  final String reason;
  ImportFailure({required this.path, required this.reason});
}

class ParsedMd {
  final String title;
  final String content;
  final DateTime updatedAt;
  final DateTime createdAt;
  ParsedMd({
    required this.title,
    required this.content,
    required this.updatedAt,
    required this.createdAt,
  });
}

class _ScannedFile {
  final File file;
  final String relPath;
  _ScannedFile({required this.file, required this.relPath});
}

class MarkdownImportService {
  final DatabaseService _db = DatabaseService();
  bool _cancelled = false;
  final Map<String, String> _folderCache = {};
String? _currentSourceRoot;
  void cancel() => _cancelled = true;
 void reset() {
  _cancelled = false;
  _folderCache.clear();
  _currentSourceRoot = null;
}

  Future<MarkdownImportResult> importDirectory({
    required String sourceDir,
    required String targetFolderName,
    required void Function(String phase, int current, int total, String label)
        onProgress,
  }) async {
    final failed = <ImportFailure>[];
    int success = 0;
    int skipped = 0;

    final dir = Directory(sourceDir);
    if (!await dir.exists()) throw Exception('目录不存在: $sourceDir');
_currentSourceRoot = sourceDir;
    final files = _scanMdFiles(dir, sourceDir);
    final total = files.length;

    final rootFolderId = await _db.ensureImportedFolder(targetFolderName);
    final dedupKeys = await _buildDedupKeys();

    for (int i = 0; i < total; i++) {
      if (_cancelled) break;
      final sf = files[i];
      onProgress('导入中', i + 1, total, sf.relPath);
      try {
        final parsed = _parseMdFile(sf.file);
        final key = _dedupKey(parsed.title, parsed.createdAt);
        if (dedupKeys.contains(key)) {
          skipped++;
          continue;
        }
        final folderId = await _ensureFolderChain(sf.relPath, rootFolderId);
        await _insertOne(parsed, folderId, i);
        dedupKeys.add(key);
        success++;
      } catch (e) {
        failed.add(ImportFailure(path: sf.relPath, reason: e.toString()));
      }
    }

    return MarkdownImportResult(
      success: success,
      skipped: skipped,
      total: total,
      failed: failed,
    );
  }

  List<_ScannedFile> _scanMdFiles(Directory dir, String sourceDir) {
    final result = <_ScannedFile>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.md')) {
        var rel = entity.path.substring(sourceDir.length);
        rel = rel.replaceAll('\\', '/');
        if (rel.startsWith('/')) rel = rel.substring(1);
        result.add(_ScannedFile(file: entity, relPath: rel));
      }
    }
    return result;
  }

  Future<String> _ensureFolderChain(
      String relPath, String rootFolderId) async {
    final parts = relPath.split('/');
    if (parts.length <= 1) return rootFolderId;

    final dirs = parts.sublist(0, parts.length - 1);
    String currentParent = rootFolderId;
    final accum = StringBuffer();

    for (final d in dirs) {
      if (accum.isNotEmpty) accum.write('/');
      accum.write(d);
      final key = accum.toString();

      if (_folderCache.containsKey(key)) {
        currentParent = _folderCache[key]!;
        continue;
      }
      final folderId =
          'folder_${DateTime.now().microsecondsSinceEpoch}_${key.hashCode}';
      await _db.insertNode({
  'id': folderId,
  'title': _cleanFileName(d),
  'parentId': currentParent,
  'isFolder': 1,
  'nodeType': 'folder',
  'targetId': null,
  'sortOrder': 0,
  'tags': <String>[],
  'createdAt': DateTime.now().toIso8601String(),
  'updatedAt': DateTime.now().toIso8601String(),
});
      _folderCache[key] = folderId;
      currentParent = folderId;
    }
    return currentParent;
  }

  ParsedMd _parseMdFile(File f) {
    final raw = f.readAsStringSync();
    final stat = f.statSync();
    final mtime = stat.modified;

    final yaml = _parseYaml(raw);
    String title;
    DateTime updatedAt;
    DateTime createdAt;

    final fileName = p.basename(f.path);   // 硬伤 2 修
    if (yaml != null) {
      final rawTitle = yaml['title'];
      title = (rawTitle != null && rawTitle.isNotEmpty)
          ? rawTitle
          : _cleanFileName(fileName);
      updatedAt = _tryParseDate(yaml['updated']) ?? mtime;
      createdAt = _tryParseDate(yaml['created'])
          ?? _tryParseDate(yaml['updated'])
          ?? mtime;
    } else {
      title = _cleanFileName(fileName);
      updatedAt = mtime;
      createdAt = mtime;
    }

    final body = _stripYamlHeader(raw);
    String translated = _htmlTableToMd(body);
    translated = _unescape(translated);

    return ParsedMd(
      title: title,
      content: translated,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }

  Map<String, String>? _parseYaml(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return null;
    int end = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        end = i;
        break;
      }
    }
    if (end == -1) return null;
    final map = <String, String>{};
    for (int i = 1; i < end; i++) {
      final line = lines[i];
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final k = line.substring(0, idx).trim();
      final v = line.substring(idx + 1).trim();
      if (k.isEmpty) continue;
      map[k] = v;
    }
    return map;
  }

  String _stripYamlHeader(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') return text;
    int end = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        end = i;
        break;
      }
    }
    if (end == -1) return text;
    return lines.sublist(end + 1).join('\n');
  }

  DateTime? _tryParseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _cleanFileName(String name) {
    var n = name;
    if (n.toLowerCase().endsWith('.md')) {
      n = n.substring(0, n.length - 3);
    }
    if (n.startsWith('# ')) n = n.substring(2);
    return n.trim();
  }

  String _htmlTableToMd(String content) {
    if (!content.contains('<table')) return content;
    final out = StringBuffer();
    final lower = content.toLowerCase();   // 硬伤 3 修：移出循环
    int i = 0;
    while (i < content.length) {
      final start = lower.indexOf('<table', i);
      if (start == -1) {
        out.write(content.substring(i));
        break;
      }
      out.write(content.substring(i, start));
      final end = _findMatchingTableEnd(content, start, lower);   // 兄弟函数补修
      if (end == -1) {
        out.write(content.substring(start));
        break;
      }
      final raw = content.substring(start, end);
      if (_isComplexTableHtml(raw)) {
        out.write(raw);
      } else {
        out.write(_simpleTableHtmlToMd(raw) ?? raw);
      }
      i = end;
    }
    return out.toString();
  }

  int _findMatchingTableEnd(String s, int start, String lower) {   // 兄弟函数补修：加 lower
    int depth = 0;
    int i = start;
    while (i < s.length) {
      if (lower.startsWith('<table', i)) {
        depth++;
        i += 6;
      } else if (lower.startsWith('</table>', i)) {
        depth--;
        if (depth == 0) return i + 8;
        i += 8;
      } else {
        i++;
      }
    }
    return -1;
  }

  bool _isComplexTableHtml(String html) {
    final lower = html.toLowerCase();
    int count = 0;
    int idx = 0;
    while ((idx = lower.indexOf('<table', idx)) != -1) {
      count++;
      idx += 6;
      if (count >= 2) return true;
    }
    final attrRegex = RegExp(
      r'<(?:td|th)[^>]*\s(?:colspan|rowspan)\s*=',
      caseSensitive: false,
    );
    return attrRegex.hasMatch(html);
  }

  String? _simpleTableHtmlToMd(String html) {
    final trRegex = RegExp(r'<tr[^>]*>([\s\S]*?)</tr>', caseSensitive: false);
    final rows = trRegex.allMatches(html).toList();
    if (rows.isEmpty) return null;
    final buffer = StringBuffer();
    for (int r = 0; r < rows.length; r++) {
      final cellRegex = RegExp(
        r'<(?:td|th)[^>]*>([\s\S]*?)</(?:td|th)>',
        caseSensitive: false,
      );
      final cells = cellRegex.allMatches(rows[r].group(1)!).toList();
      if (cells.isEmpty) continue;
      buffer.write('|');
      for (final c in cells) {
        var t = c.group(1) ?? '';
        t = t.replaceAll(RegExp(r'<[^>]+>'), '');
        t = t.trim().replaceAll('\n', ' ').replaceAll('|', r'\|');
        buffer.write(' $t |');
      }
      buffer.writeln();
      if (r == 0) {
        buffer.write('|');
        for (int i = 0; i < cells.length; i++) {
          buffer.write(' --- |');
        }
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  static const _escapeChars = ['#', '*', '_', '[', ']', '`', '|', '\\'];

  String _unescape(String s) {
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '\\' && i + 1 < s.length) {
        final next = s[i + 1];
        if (_escapeChars.contains(next)) {
          buffer.write(next);
          i++;
          continue;
        }
      }
      buffer.write(c);
    }
    return buffer.toString();
  }

  String _dedupKey(String title, DateTime created) {
    return '$title|${created.toIso8601String()}';
  }

  Future<Set<String>> _buildDedupKeys() async {
    final keys = <String>{};
    final notes = await _db.getAllNotes(includeDeleted: false);
    for (final m in notes) {
      final title = (m['title'] as String? ?? '').trim();
      final createdStr = m['createdAt'] as String?;
      if (createdStr == null || createdStr.isEmpty) continue;
      final created = DateTime.tryParse(createdStr);
      if (created == null) continue;
      keys.add('$title|${created.toIso8601String()}');
    }
    return keys;
  }

  Future<void> _insertOne(ParsedMd p, String folderId, int index) async {
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}_$index';
    final rewrittenContent = await _copyResourcesAndRewrite(
  rawContent: p.content,
  sourceRoot: _currentSourceRoot,
);
    final noteMap = {
      'id': id,
      'title': p.title,
      'content': rewrittenContent,
      'updatedAt': p.updatedAt.toIso8601String(),
      'createdAt': p.createdAt.toIso8601String(),
      'status': 'active',
      'editorMode': 'markdown',
      'tags': <String>[],
      'contentFormat': 'markdown',
    };
    final nodeMap = {
  'id': 'node_$id',
  'title': p.title,
  'parentId': folderId,
  'isFolder': 0,
  'nodeType': 'note',
  'targetId': id,
  'sortOrder': 0,
  'tags': <String>[],
  'createdAt': p.createdAt.toIso8601String(),
  'updatedAt': p.updatedAt.toIso8601String(),
};
    await _db.insertNoteAndNodeTx(noteMap: noteMap, nodeMap: nodeMap);
  }
  /// R-3：复制 md 引用的图片到 App Documents/note_images/
///      并把 content 里的 ../../resources/xxx 改成 note_images/xxx
Future<String> _copyResourcesAndRewrite({
  required String rawContent,
  required String? sourceRoot,
}) async {
  if (sourceRoot == null || rawContent.isEmpty) return rawContent;

  final imgRegex =
      RegExp(r'!\[([^\]]*)\]\((?:\.\./)+resources/([^)]+)\)');

  final matches = imgRegex.allMatches(rawContent).toList();
  if (matches.isEmpty) return rawContent;

  final targetDir = Directory(ImagePathService.instance.imageDir);
  if (!await targetDir.exists()) {
    await targetDir.create(recursive: true);
  }

  final copied = <String>{};
  for (final m in matches) {
    final filename = m.group(2)!;
    if (copied.contains(filename)) continue;
    copied.add(filename);

    final src = File(p.join(sourceRoot, 'resources', filename));
    final dst = File(ImagePathService.instance.targetPath(filename));

    if (await dst.exists()) continue;
    if (!await src.exists()) {
      debugPrint('⚠️ R-3：图片源缺失 —— $filename');
      continue;
    }
    try {
      await src.copy(dst.path);
    } catch (e) {
      debugPrint('⚠️ R-3：图片复制失败 —— $filename —— $e');
    }
  }

  return rawContent.replaceAllMapped(imgRegex, (m) {
    final alt = m.group(1)!;
    final filename = m.group(2)!;
    return '![$alt](${ImagePathService.imageSubDir}/$filename)';
  });
}
}