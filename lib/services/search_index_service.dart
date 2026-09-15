// lib/services/search_index_service.dart
// 搜索索引服务 — 纯计算层
//
// 职责：算出该往 tag_index / search_index 写什么行。
// 不做数据库读写——那些由 DatabaseService 负责。
//
// 边界：
//   - 不 import sqflite / shared_preferences
//   - 不 import DatabaseService
//   - 只 import dart:convert（JSON 解析）
//   - 零数据库依赖，可在测试环境独立跑
//
// ⚠️ 本轮（9a）：noteMap['contentFormat'] 不存在，调用方（DatabaseService）兜底 'markdown'。
//    9b 落地后从 noteMap 读 contentFormat 字段，兜底自然失效。

import 'dart:convert';

class SearchIndexService {
  SearchIndexService._();

  // ═══════════════════════════════════════════════════════
  // 1. 建表 SQL
  // ═══════════════════════════════════════════════════════

  /// 建表 SQL 列表。全部用 IF NOT EXISTS，SQL 层幂等。
  static List<String> getCreateTableSql() {
    return [
      '''
      CREATE TABLE IF NOT EXISTS tag_index(
        id TEXT PRIMARY KEY,
        tag TEXT NOT NULL,
        type TEXT NOT NULL,
        noteId TEXT NOT NULL,
        blockId TEXT,
        text TEXT,
        createdAt TEXT NOT NULL
      )
      ''',
      'CREATE INDEX IF NOT EXISTS idx_tag_index_tag ON tag_index(tag)',
      'CREATE INDEX IF NOT EXISTS idx_tag_index_note ON tag_index(noteId)',
      'CREATE INDEX IF NOT EXISTS idx_tag_index_type ON tag_index(type)',
      '''
      CREATE TABLE IF NOT EXISTS search_index(
        id TEXT PRIMARY KEY,
        sourceType TEXT NOT NULL,
        sourceId TEXT NOT NULL,
        subId TEXT,
        location TEXT,
        kind TEXT NOT NULL,
        searchText TEXT NOT NULL,
        rawText TEXT,
        createdAt TEXT NOT NULL
      )
      ''',
      'CREATE INDEX IF NOT EXISTS idx_search_index_source ON search_index(sourceType, sourceId)',
      'CREATE INDEX IF NOT EXISTS idx_search_index_text ON search_index(searchText)',
    ];
  }

  // ═══════════════════════════════════════════════════════
  // 2. note_text 行
  // ═══════════════════════════════════════════════════════

  /// 算 note_text 行。
  ///
  /// 返回 null 表示内容为空，无需写行。
  ///
  /// ⚠️ 本方法只算行，不删旧行。
  /// 「先删该 noteId 的 note_text 行再写新行」由 DatabaseService 编排。
  static Map<String, dynamic>? computeNoteTextRow(
    Map<String, dynamic> noteMap,
  ) {
    final noteId = noteMap['id'] as String?;
    if (noteId == null || noteId.isEmpty) return null;

    final content = (noteMap['content'] as String?) ?? '';
    if (content.isEmpty) return null;

    return {
      'id': 'note_text_$noteId',
      'sourceType': 'note',
      'sourceId': noteId,
      'subId': null,
      'location': null,
      'kind': 'note_text',
      'searchText': content,
      'rawText': content.length > 200
          ? '${content.substring(0, 200)}...'
          : content,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════════════════
  // 3. tag_index 行
  // ═══════════════════════════════════════════════════════

  /// 算 tag_index 行列表。
  static List<Map<String, dynamic>> computeTagRows(
    Map<String, dynamic> noteMap,
    String format,
  ) {
    final noteId = noteMap['id'] as String?;
    if (noteId == null || noteId.isEmpty) return const [];

    if (format == 'markdown') {
      return _extractMarkdownTags(noteMap, noteId);
    } else if (format == 'richtext') {
      return _extractRichTextMarks(noteMap, noteId);
    }
    return const [];
  }

  /// Markdown 提取 `#标签`。
  ///
  /// ⚠️ 中文标点结尾（如 `#重要。`）会捕获"重要。"。
  /// 本轮接受，记 T-161。
  static List<Map<String, dynamic>> _extractMarkdownTags(
    Map<String, dynamic> noteMap,
    String noteId,
  ) {
    final content = (noteMap['content'] as String?) ?? '';
    if (content.isEmpty) return const [];

    final regex = RegExp(r'#([^\s#]+)');
    final seen = <String>{};
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    for (final match in regex.allMatches(content)) {
      final tag = match.group(1);
      if (tag == null || tag.isEmpty) continue;
      if (seen.contains(tag)) continue;
      seen.add(tag);

      rows.add({
        'id': 'tag_${noteId}_$tag',
        'tag': tag,
        'type': 'custom',
        'noteId': noteId,
        'blockId': null,
        'text': match.group(0),
        'createdAt': now,
      });
    }
    return rows;
  }

  /// 富文本提取 `blocks[].marks`。
  ///
  /// 本轮（9a）未触发——`contentFormat` 由 DatabaseService 兜底为 'markdown'。
  /// 为 9b 后的富文本笔记预留。
  static List<Map<String, dynamic>> _extractRichTextMarks(
    Map<String, dynamic> noteMap,
    String noteId,
  ) {
    final content = (noteMap['content'] as String?) ?? '';
    if (content.isEmpty) return const [];

    Map<String, dynamic> structure;
    try {
      structure = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const [];
    }

    final blocks = structure['blocks'];
    if (blocks is! List) return const [];

    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    int blockIdx = 0;
    for (final block in blocks) {
      if (block is! Map) continue;
      final blockMap = Map<String, dynamic>.from(block);
      final blockId = blockMap['id'] as String?;
      // T-162：缺 id 的块用索引兜底，避免相同 mark 触发 id 碰撞
      final idSuffix = blockId ?? 'idx$blockIdx';
      blockIdx++;
      final marks = blockMap['marks'];
      if (marks is! List) continue;

      final blockText = _readableTextOfBlock(blockMap);

      for (final mark in marks) {
        if (mark is! String || mark.isEmpty) continue;
        rows.add({
          'id': 'tag_${noteId}_${idSuffix}_$mark',
          'tag': mark,
          'type': 'custom',
          'noteId': noteId,
          'blockId': blockId,
          'text': blockText,
          'createdAt': now,
        });
      }
    }
    return rows;
  }

  // ═══════════════════════════════════════════════════════
  // 4. 从 tag_index 行派生 search_index 的 note_tag 行
  // ═══════════════════════════════════════════════════════

  static List<Map<String, dynamic>> computeSearchRowsFromTagRows(
    String noteId,
    List<Map<String, dynamic>> tagRows,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final tagRow in tagRows) {
      final tagId = tagRow['id'] as String?;
      final tag = tagRow['tag'] as String?;
      if (tagId == null || tag == null) continue;

      rows.add({
        'id': 'tag_search_$tagId',
        'sourceType': 'note',
        'sourceId': noteId,
        'subId': tagId,
        'location': tagRow['blockId'],
        'kind': 'note_tag',
        'searchText': '标记 $tag',
        'rawText': tagRow['text'],
        'createdAt': tagRow['createdAt'] ?? DateTime.now().toIso8601String(),
      });
    }
    return rows;
  }

  // ═══════════════════════════════════════════════════════
  // 5. 删除范围
  // ═══════════════════════════════════════════════════════

  /// 算该 noteId 的 search_index 清理范围。
  ///
  /// 当前固定清两类：
  ///   - ('note', 'note_text')：笔记正文行
  ///   - ('note', 'note_tag')：笔记标记派生行
  ///
  /// 注意：`tag_index` 表的清理不由本方法表达——
  /// 那是 DatabaseService 在调本方法前先做的一步。
  static List<({String sourceType, String kind})> computeDeleteScopes() {
    return const [
      (sourceType: 'note', kind: 'note_text'),
      (sourceType: 'note', kind: 'note_tag'),
    ];
  }

  // ═══════════════════════════════════════════════════════
  // 内部工具：可读文本
  // ═══════════════════════════════════════════════════════

  /// 各块类型取文本方式：
  ///
  ///   paragraph / heading / todo  → inlines[].text 拼接（无分隔）
  ///   code_block                  → text 字段原样
  ///   image                       → alt 字段，无则空字符串
  ///   divider / ink               → 空字符串
  ///   list                        → 只读 item 内 paragraph 子块，
  ///                                 段落间 '\n' 拼接
  ///   blockquote                  → 只读 children 内 paragraph 子块，
  ///                                 段落间 '\n' 拼接
  static String _readableTextOfBlock(Map<String, dynamic> block) {
    final type = block['type'];
    switch (type) {
      case 'paragraph':
      case 'heading':
      case 'todo':
        return _inlinesToText(block['inlines']);
      case 'code_block':
        return (block['text'] as String?) ?? '';
      case 'image':
        return (block['alt'] as String?) ?? '';
      case 'divider':
      case 'ink':
        return '';
      case 'list':
        return _listToText(block['items']);
      case 'blockquote':
        return _blockquoteToText(block['children']);
      default:
        return '';
    }
  }

  static String _inlinesToText(dynamic inlines) {
    if (inlines is! List) return '';
    final buf = StringBuffer();
    for (final inline in inlines) {
      if (inline is! Map) continue;
      final text = inline['text'];
      if (text is String) buf.write(text);
    }
    return buf.toString();
  }

  static String _listToText(dynamic items) {
    if (items is! List) return '';
    final parts = <String>[];
    for (final item in items) {
      if (item is! Map) continue;
      final blocks = item['blocks'];
      if (blocks is! List) continue;
      for (final child in blocks) {
        if (child is! Map) continue;
        final childMap = Map<String, dynamic>.from(child);
        if (childMap['type'] == 'paragraph') {
          parts.add(_inlinesToText(childMap['inlines']));
        }
      }
    }
    return parts.join('\n');
  }

  static String _blockquoteToText(dynamic children) {
    if (children is! List) return '';
    final parts = <String>[];
    for (final child in children) {
      if (child is! Map) continue;
      final childMap = Map<String, dynamic>.from(child);
      if (childMap['type'] == 'paragraph') {
        parts.add(_inlinesToText(childMap['inlines']));
      }
    }
    return parts.join('\n');
  }
}