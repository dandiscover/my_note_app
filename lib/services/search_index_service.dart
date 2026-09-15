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
// ─── 第四轮批 1 变更 ─────────────────────────
//
// 依据老白裁定 1（转达）：
//   - tag_index 加 sourceType 列（'note' / 'book'）
//   - noteId 列改名 sourceId
//
// 依据老白裁定 2（转达）：
//   - tag 字段装值：highlight→'高亮' / annotation→'批注' / custom→用户自定义名
//   - type 字段保留，区分 custom / highlight / annotation
//
// 依据老白裁 B（转达）：
//   - computeSearchRowsFromTagRows 的 searchText 按 type 分流
//     highlight→'高亮' / annotation→'批注' / custom→'标记 $tag'

import 'dart:convert';

class SearchIndexService {
  SearchIndexService._();

  // ═══════════════════════════════════════════════════════
  // 1. 建表 SQL
  // ═══════════════════════════════════════════════════════

  /// 建表 SQL 列表。全部用 IF NOT EXISTS，SQL 层幂等。
  ///
  /// 第四轮批 1 变更（老白裁定 1，转达）：
  ///   - tag_index 加 sourceType 列
  ///   - noteId 改名 sourceId
  ///   - idx_tag_index_note → idx_tag_index_source
  static List<String> getCreateTableSql() {
    return [
      '''
      CREATE TABLE IF NOT EXISTS tag_index(
        id TEXT PRIMARY KEY,
        sourceType TEXT NOT NULL DEFAULT 'note',
        sourceId TEXT NOT NULL,
        type TEXT NOT NULL,
        tag TEXT NOT NULL,
        blockId TEXT,
        text TEXT,
        createdAt TEXT NOT NULL
      )
      ''',
      'CREATE INDEX IF NOT EXISTS idx_tag_index_tag ON tag_index(tag)',
      'CREATE INDEX IF NOT EXISTS idx_tag_index_source ON tag_index(sourceId)',
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
  ///
  /// 第四轮批 1：search_index 表结构未变，本方法不变。
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
  // 3. tag_index 行（note 来源）
  // ═══════════════════════════════════════════════════════

  /// 算 tag_index 行列表（note 来源）。
  ///
  /// 第四轮批 1 变更：
  ///   - 先读 noteMap['tags'] 字段（笔记级自定义标记），
  ///     产出 type='custom'、blockId=null 的行
  ///   - 再按 format 分派 markdown / richtext 提取
  ///   - 所有产出行的 sourceType='note'，sourceId=noteId
  ///
  /// ⚠️ format 参数来源（已核，database_service.dart 原文）：
  ///    DatabaseService._syncSearchIndexForNote 内
  ///    `final format = (noteMap['contentFormat'] as String?) ?? 'markdown';`
  ///    即 richtext 笔记会走 _extractRichTextMarks 分支。
  static List<Map<String, dynamic>> computeTagRows(
    Map<String, dynamic> noteMap,
    String format,
  ) {
    final noteId = noteMap['id'] as String?;
    if (noteId == null || noteId.isEmpty) return const [];

    final rows = <Map<String, dynamic>>[];

    // 3.1 笔记级自定义标记（notes.tags 字段）
    rows.addAll(_extractNoteFieldTags(noteMap, noteId));

    // 3.2 按 content format 分派
    if (format == 'markdown') {
      rows.addAll(_extractMarkdownTags(noteMap, noteId));
    } else if (format == 'richtext') {
      rows.addAll(_extractRichTextMarks(noteMap, noteId));
    }

    return rows;
  }

  /// 笔记级自定义标记：从 noteMap['tags']（List<String>）提取。
  ///
  /// 这是第四轮批 1 新增的通路——编辑器 AppBar 的 ⭐/❓ 入口写 notes.tags，
  /// 保存后经 DatabaseService._syncSearchIndexForNote 落到这里。
  ///
  /// ⚠️ 已核（note.dart 原文）：NotebookEntry.toMap() 里 'tags': tags，
  ///    直接放 List<String>，不 jsonEncode。故此处 tagsRaw 是 List。
  ///
  /// ⚠️ 已知：本通路与 markdown #tag 提取可能产同 tag 两行（id 不同）。
  ///    本轮接受——两通路语义不同（笔记级 vs 正文级），去重会丢位置信息。
  static List<Map<String, dynamic>> _extractNoteFieldTags(
    Map<String, dynamic> noteMap,
    String noteId,
  ) {
    final tagsRaw = noteMap['tags'];
    if (tagsRaw is! List) return const [];

    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();
    final seen = <String>{};

    for (final tagRaw in tagsRaw) {
      if (tagRaw is! String) continue;
      final tag = tagRaw.trim();
      if (tag.isEmpty) continue;
      if (seen.contains(tag)) continue;
      seen.add(tag);

      rows.add({
        'id': 'tag_${noteId}_field_$tag',
        'sourceType': 'note',
        'sourceId': noteId,
        'type': 'custom',
        'tag': tag,
        'blockId': null,
        'text': null,
        'createdAt': now,
      });
    }
    return rows;
  }

  /// Markdown 提取 `#标签`。
  ///
  /// ⚠️ 中文标点结尾（如 `#重要。`）会捕获"重要。"。
  /// 本轮接受，记 T-161。
  ///
  /// 第四轮批 1 变更：产出行的 sourceType='note'，noteId→sourceId。
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
        'sourceType': 'note',
        'sourceId': noteId,
        'type': 'custom',
        'tag': tag,
        'blockId': null,
        'text': match.group(0),
        'createdAt': now,
      });
    }
    return rows;
  }

  /// 富文本提取 `blocks[].marks`。
  ///
  /// ⚠️ 已核（database_service.dart 原文）：format 来自
  ///    `(noteMap['contentFormat'] as String?) ?? 'markdown'`。
  ///    contentFormat='richtext' 的笔记（第三轮起由 RichtextEditorPage 产生）
  ///    会走本分支；contentFormat='markdown' 的笔记不走本分支。
  ///
  /// 第四轮批 1 变更：产出行的 sourceType='note'，noteId→sourceId。
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
          'sourceType': 'note',
          'sourceId': noteId,
          'type': 'custom',
          'tag': mark,
          'blockId': blockId,
          'text': blockText,
          'createdAt': now,
        });
      }
    }
    return rows;
  }

  // ═══════════════════════════════════════════════════════
  // 3.5 tag_index 行（book 来源，第四轮批 1 新增）
  // ═══════════════════════════════════════════════════════

  /// 算书来源（高亮 / 批注）的 tag_index 行列表。
  ///
  /// 依据老白裁定 1（转达）+ 2（转达）：
  ///   - sourceType='book'，sourceId=bookId
  ///   - 有 comment → type='annotation'，tag='批注'，text=comment
  ///   - 无 comment 且 isHighlight → type='highlight'，tag='高亮'，text=selectedText
  ///   - 无 comment 且非 isHighlight → 跳过
  ///
  /// 输入 bookNoteMaps 是 BookNote.toMap() 产出的 Map 列表。
  ///
  /// ⚠️ 已核（book_note.dart 原文）：toMap() 里 'isHighlight': isHighlight ? 1 : 0，
  ///    是 int（1/0），故此处 as int? 类型正确。
  static List<Map<String, dynamic>> computeBookTagRows(
    List<Map<String, dynamic>> bookNoteMaps,
    String bookId,
  ) {
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now().toIso8601String();

    for (final noteMap in bookNoteMaps) {
      final noteId = noteMap['id'] as String?;
      if (noteId == null || noteId.isEmpty) continue;

      final comment = (noteMap['comment'] as String?)?.trim() ?? '';
      // 缺字段视为「非高亮」（异常数据不默认写入索引）
      final isHighlight = (noteMap['isHighlight'] as int? ?? 0) == 1;
      final selectedText = (noteMap['selectedText'] as String?) ?? '';
      final pageNumber = noteMap['pageNumber'] as int? ?? 0;
      final location = noteMap['location'] as String?;
      final createdAt = noteMap['createdAt'] as String? ?? now;

      final String type;
      final String tag;
      final String text;
      if (comment.isNotEmpty) {
        type = 'annotation';
        tag = '批注';
        text = comment;
      } else if (isHighlight) {
        type = 'highlight';
        tag = '高亮';
        text = selectedText;
      } else {
        continue;
      }

      rows.add({
        'id': 'tag_book_$noteId',
        'sourceType': 'book',
        'sourceId': bookId,
        'type': type,
        'tag': tag,
        'blockId': location ?? 'page:$pageNumber',
        'text': text,
        'createdAt': createdAt,
      });
    }
    return rows;
  }

  // ═══════════════════════════════════════════════════════
  // 4. 从 tag_index 行派生 search_index 行
  // ═══════════════════════════════════════════════════════

  /// 从 tag_index 行派生 search_index 行。
  ///
  /// 第四轮批 1 变更：
  ///   - sourceType / sourceId 从 tagRow 取（不再硬编码 'note'）
  ///   - searchText 按 type 分流（老白裁 B，转达）：
  ///       highlight  → '高亮'
  ///       annotation → '批注'
  ///       custom     → '标记 $tag'
  ///   - kind 按 type 分流：
  ///       custom     → 'note_tag'
  ///       highlight  → 'book_highlight'
  ///       annotation → 'book_annotation'
  ///
  /// 参数名 noteId 在函数体内已无使用点（sourceType / sourceId 均从 tagRow 读），
  /// 为签名兼容调用方保留。正式改名见待办 T-新-3。
  static List<Map<String, dynamic>> computeSearchRowsFromTagRows(
    String noteId,
    List<Map<String, dynamic>> tagRows,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final tagRow in tagRows) {
      final tagId = tagRow['id'] as String?;
      final tag = tagRow['tag'] as String?;
      if (tagId == null || tag == null) continue;

      // sourceType 有 NOT NULL DEFAULT 'note' 约束，NULL 不应出现；
      // 若真出现，'note' 是安全回退（历史数据全是 note）。sourceId 无默认约束，缺则 skip。
      final sourceType = tagRow['sourceType'] as String? ?? 'note';
      final sourceId = tagRow['sourceId'] as String?;
      // 脏行（缺 sourceId）跳过，不崩
      if (sourceId == null) continue;
      final tagType = tagRow['type'] as String? ?? 'custom';

      final (String searchText, String kind) = switch (tagType) {
        'highlight' => ('高亮', 'book_highlight'),
        'annotation' => ('批注', 'book_annotation'),
        _ => ('标记 $tag', 'note_tag'),
      };

      rows.add({
        'id': 'tag_search_$tagId',
        'sourceType': sourceType,
        'sourceId': sourceId,
        'subId': tagId,
        'location': tagRow['blockId'],
        'kind': kind,
        'searchText': searchText,
        'rawText': tagRow['text'],
        'createdAt': tagRow['createdAt'] ?? DateTime.now().toIso8601String(),
      });
    }
    return rows;
  }

  // ═══════════════════════════════════════════════════════
  // 5. 删除范围
  // ═══════════════════════════════════════════════════════

  /// 算该 noteId / bookId 的 search_index 清理范围。
  ///
  /// 第四轮批 1 变更：扩为 4 项（新增 book_highlight / book_annotation）。
  ///
  /// 注意：`tag_index` 表的清理不由本方法表达——
  /// 那是 DatabaseService 在调本方法前先做的一步。
  static List<({String sourceType, String kind})> computeDeleteScopes() {
    return const [
      (sourceType: 'note', kind: 'note_text'),
      (sourceType: 'note', kind: 'note_tag'),
      (sourceType: 'book', kind: 'book_highlight'),
      (sourceType: 'book', kind: 'book_annotation'),
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