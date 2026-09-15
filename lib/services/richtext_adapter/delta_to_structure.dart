// lib/services/richtext_adapter/delta_to_structure.dart
// Delta → 自定义结构 转换
//
// ─── T-134 跨文件契约（与第 6 文件一致）─────────
//
// contentHash：FNV-1a 32 位。算法同 structure_to_delta.dart。
// 各块「可读文本」定义：见 structure_to_delta.dart 文件头。
//
// ─── 嵌套块处理（与第 6 文件一致）────────────
//
// 平坦化降级：Delta 里连续的 list 项合并为一个 list 块；
// 每个 list 项作为一个 paragraph 子块，不嵌更深。
// 同理 blockquote。
//
// ─── code_block.language 降级说明 ─────────────────────
//
// ✅ 已实测：flutter_quill 11.5.1 不在 Delta 里挂 code-block 语言名。
//    从 Delta 回读时 language 固定为 null。

import 'dart:convert';
import 'dart:math';

import 'shared/attributes.dart';
import 'shared/block_memo.dart';
import 'shared/delta_ops.dart';

class DeltaToStructure {
  DeltaToStructure._();

  static Map<String, dynamic> convert(
    List<Map<String, dynamic>> delta, {
    List<BlockMemo>? memo,
  }) {
    final deltaBlocks = DeltaOps.splitIntoBlocks(delta);

    final builder = _StructureBuilder(memo: memo ?? const []);
    builder.consumeDeltaBlocks(deltaBlocks);

    return {
      'version': 2,
      'blocks': builder.result,
    };
  }
}

class _StructureBuilder {
  _StructureBuilder({required this.memo});

  static final Random _random = Random();

  final List<BlockMemo> memo;
  final List<Map<String, dynamic>> result = [];
  final Set<int> _usedMemoIndices = {};
  int _dfsCounter = 0;

  void consumeDeltaBlocks(List<List<Map<String, dynamic>>> deltaBlocks) {
    int i = 0;
    while (i < deltaBlocks.length) {
      final block = deltaBlocks[i];
      final type = _identifyBlockType(block);

      if (type == 'list_item') {
        final listValue = _getListValue(block);
        final group = <List<Map<String, dynamic>>>[];
        while (i < deltaBlocks.length &&
            _identifyBlockType(deltaBlocks[i]) == 'list_item' &&
            _getListValue(deltaBlocks[i]) == listValue) {
          group.add(deltaBlocks[i]);
          i++;
        }
        result.add(_buildListBlock(group, listValue));
        continue;
      }

      if (type == 'blockquote_para') {
        final group = <List<Map<String, dynamic>>>[];
        while (i < deltaBlocks.length &&
            _identifyBlockType(deltaBlocks[i]) == 'blockquote_para') {
          group.add(deltaBlocks[i]);
          i++;
        }
        result.add(_buildBlockquoteBlock(group));
        continue;
      }

      final single = _buildSingleBlock(block, type);
      if (single != null) {
        result.add(single);
      }
      i++;
    }
  }

  String _identifyBlockType(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    final blockAttrs = DeltaOps.blockAttributesOf(block);

    if (contentOps.length == 1 && DeltaOps.isEmbedInsert(contentOps[0])) {
      final embed = DeltaOps.getEmbed(contentOps[0])!;
      if (embed.containsKey(DeltaAttributes.image)) return 'image';
      if (embed.containsKey(DeltaAttributes.divider)) return 'divider';
      if (embed.containsKey(DeltaAttributes.inkPlaceholder)) return 'ink';
      return 'unknown_embed';
    }

    if (blockAttrs.containsKey(DeltaAttributes.header)) return 'heading';
    if (blockAttrs.containsKey(DeltaAttributes.codeBlock)) return 'code_block';
    if (blockAttrs.containsKey(DeltaAttributes.blockquote)) {
      return 'blockquote_para';
    }
    if (blockAttrs.containsKey(DeltaAttributes.list)) {
      final v = blockAttrs[DeltaAttributes.list];
      if (v == DeltaListValues.bullet || v == DeltaListValues.ordered) {
        return 'list_item';
      }
      if (v == DeltaListValues.checked || v == DeltaListValues.unchecked) {
        return 'todo';
      }
      return 'unknown_list';
    }
    return 'paragraph';
  }

  dynamic _getListValue(List<Map<String, dynamic>> block) =>
      DeltaOps.blockAttributesOf(block)[DeltaAttributes.list];

  Map<String, dynamic> _buildListBlock(
    List<List<Map<String, dynamic>>> group,
    dynamic listValue,
  ) {
    final listType = 'list';
    final listText = _readableTextOfListGroup(group);
    final listHash = _hashReadableText(listText);
    final listId = _matchMemoId(_dfsCounter, listType, listHash);
    _dfsCounter++;

    final ordered = listValue == DeltaListValues.ordered;
    final listBlock = <String, dynamic>{
      'id': listId,
      'type': 'list',
      'ordered': ordered,
      'items': <Map<String, dynamic>>[],
      'marks': _matchMemoMarks(listId),
    };

    for (final block in group) {
      final contentOps = DeltaOps.contentOpsOf(block);
      final inlines = _extractInlines(contentOps);
      final itemText = inlines
          .map((i) => i['text'] as String? ?? '')
          .join();
      final itemHash = _hashReadableText(itemText);
      final itemId = _matchMemoId(_dfsCounter, 'paragraph', itemHash);
      _dfsCounter++;

      final itemBlock = <String, dynamic>{
        'id': itemId,
        'type': 'paragraph',
        'inlines': inlines,
        'marks': _matchMemoMarks(itemId),
      };
      (listBlock['items'] as List).add({'blocks': [itemBlock]});
    }

    return listBlock;
  }

  Map<String, dynamic> _buildBlockquoteBlock(
    List<List<Map<String, dynamic>>> group,
  ) {
    final bqType = 'blockquote';
    final bqText = group
        .map((b) => _readableTextOfBlock(b))
        .join('\n');
    final bqHash = _hashReadableText(bqText);
    final bqId = _matchMemoId(_dfsCounter, bqType, bqHash);
    _dfsCounter++;

    final bqBlock = <String, dynamic>{
      'id': bqId,
      'type': 'blockquote',
      'children': <Map<String, dynamic>>[],
      'marks': _matchMemoMarks(bqId),
    };

    for (final block in group) {
      final contentOps = DeltaOps.contentOpsOf(block);
      final inlines = _extractInlines(contentOps);
      final childText = inlines
          .map((i) => i['text'] as String? ?? '')
          .join();
      final childHash = _hashReadableText(childText);
      final childId = _matchMemoId(_dfsCounter, 'paragraph', childHash);
      _dfsCounter++;

      (bqBlock['children'] as List).add(<String, dynamic>{
        'id': childId,
        'type': 'paragraph',
        'inlines': inlines,
        'marks': _matchMemoMarks(childId),
      });
    }

    return bqBlock;
  }

  Map<String, dynamic>? _buildSingleBlock(
    List<Map<String, dynamic>> block,
    String type,
  ) {
    switch (type) {
      case 'paragraph':
        return _buildParagraph(block);
      case 'heading':
        return _buildHeading(block);
      case 'code_block':
        return _buildCodeBlock(block);
      case 'todo':
        return _buildTodo(block);
      case 'image':
        return _buildImage(block);
      case 'divider':
        return _buildDivider(block);
      case 'ink':
        return _buildInk(block);
      case 'unknown_embed':
      case 'unknown_list':
      default:
        return _buildParagraph(block);
    }
  }

  Map<String, dynamic> _buildParagraph(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    final inlines = _extractInlines(contentOps);
    final text = inlines.map((i) => i['text'] as String? ?? '').join();
    final hash = _hashReadableText(text);
    final id = _matchMemoId(_dfsCounter, 'paragraph', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'paragraph',
      'inlines': inlines,
      'marks': _matchMemoMarks(id),
    };
  }

  Map<String, dynamic> _buildHeading(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    final attrs = DeltaOps.blockAttributesOf(block);
    final level = attrs[DeltaAttributes.header] as int? ?? 1;
    final inlines = _extractInlines(contentOps);
    final text = inlines.map((i) => i['text'] as String? ?? '').join();
    final hash = _hashReadableText(text);
    final id = _matchMemoId(_dfsCounter, 'heading', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'heading',
      'level': level,
      'inlines': inlines,
      'marks': _matchMemoMarks(id),
    };
  }

  Map<String, dynamic> _buildCodeBlock(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    final text = contentOps
        .map((op) => DeltaOps.getText(op) ?? '')
        .join();
    final hash = _hashReadableText(text);
    final id = _matchMemoId(_dfsCounter, 'code_block', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'code_block',
      // ✅ 已实测：flutter_quill 11.5.1 不在 Delta 里挂 code-block 语言名。
      //    从 Delta 回读时 language 固定为 null。
      //    用户存过语言的旧笔记，往返一次会丢语言。本轮接受此降级。
      'language': null,
      'text': text,
      'marks': _matchMemoMarks(id),
    };
  }

  Map<String, dynamic> _buildTodo(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    final attrs = DeltaOps.blockAttributesOf(block);
    final listValue = attrs[DeltaAttributes.list];
    final checked = listValue == DeltaListValues.checked;

    final inlines = _extractInlines(contentOps);
    final text = inlines.map((i) => i['text'] as String? ?? '').join();
    final hash = _hashReadableText(text);
    final id = _matchMemoId(_dfsCounter, 'todo', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'todo',
      'checked': checked,
      'inlines': inlines,
      'marks': _matchMemoMarks(id),
    };
  }

  Map<String, dynamic> _buildImage(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    final embed = DeltaOps.getEmbed(contentOps[0])!;
    final src = embed[DeltaAttributes.image] as String? ?? '';
    final hash = _hashReadableText('');
    final id = _matchMemoId(_dfsCounter, 'image', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'image',
      'src': src,
      'alt': null,
      'marks': _matchMemoMarks(id),
    };
  }

  Map<String, dynamic> _buildDivider(List<Map<String, dynamic>> block) {
    final hash = _hashReadableText('');
    final id = _matchMemoId(_dfsCounter, 'divider', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'divider',
      'marks': _matchMemoMarks(id),
    };
  }

  Map<String, dynamic> _buildInk(List<Map<String, dynamic>> block) {
    final hash = _hashReadableText('');
    final id = _matchMemoId(_dfsCounter, 'ink', hash);
    _dfsCounter++;

    return <String, dynamic>{
      'id': id,
      'type': 'ink',
      'strokes': <dynamic>[],
      'backgroundText': null,
      'marks': _matchMemoMarks(id),
    };
  }

  List<Map<String, dynamic>> _extractInlines(
    List<Map<String, dynamic>> contentOps,
  ) {
    final inlines = <Map<String, dynamic>>[];
    for (final op in contentOps) {
      if (DeltaOps.isNewline(op)) continue;
      if (!DeltaOps.isTextInsert(op)) continue;

      final inline = _inlineFromOp(op);
      if (inline != null) inlines.add(inline);
    }
    return inlines;
  }

  Map<String, dynamic>? _inlineFromOp(Map<String, dynamic> op) {
    final text = DeltaOps.getText(op);
    if (text == null) return null;

    final attrs = DeltaOps.getAttributes(op);
    final inline = <String, dynamic>{'text': text};

    if (attrs[DeltaAttributes.bold] == true) inline['bold'] = true;
    if (attrs[DeltaAttributes.italic] == true) inline['italic'] = true;
    if (attrs[DeltaAttributes.underline] == true) inline['underline'] = true;
    if (attrs[DeltaAttributes.strike] == true) inline['strike'] = true;
    if (attrs[DeltaAttributes.code] == true) inline['code'] = true;

    final color = attrs[DeltaAttributes.color];
    if (color is String && color.isNotEmpty) inline['color'] = color;
    final hl = attrs[DeltaAttributes.highlight];
    if (hl is String && hl.isNotEmpty) inline['highlight'] = hl;
    final link = attrs[DeltaAttributes.link];
    if (link is String && link.isNotEmpty) inline['link'] = link;

    return inline;
  }

  String _matchMemoId(int dfsIndex, String type, String contentHash) {
    for (var i = 0; i < memo.length; i++) {
      if (_usedMemoIndices.contains(i)) continue;
      if (memo[i].orderIndex == dfsIndex && memo[i].type == type) {
        _usedMemoIndices.add(i);
        return memo[i].id;
      }
    }
    for (var i = 0; i < memo.length; i++) {
      if (_usedMemoIndices.contains(i)) continue;
      if (memo[i].contentHash == contentHash) {
        _usedMemoIndices.add(i);
        return memo[i].id;
      }
    }
    return _generateBlockId();
  }

  List<String> _matchMemoMarks(String id) {
    for (final m in memo) {
      if (m.id == id) return List<String>.from(m.marks);
    }
    return const [];
  }

  String _readableTextOfBlock(List<Map<String, dynamic>> block) {
    final contentOps = DeltaOps.contentOpsOf(block);
    return contentOps
        .map((op) => DeltaOps.getText(op) ?? '')
        .join();
  }

  String _readableTextOfListGroup(
    List<List<Map<String, dynamic>>> group,
  ) {
    final parts = <String>[];
    for (final block in group) {
      parts.add(_readableTextOfBlock(block));
    }
    return parts.join('\n');
  }

  String _hashReadableText(String text) {
    const int fnvOffset = 0x811c9dc5;
    const int fnvPrime = 0x01000193;
    final bytes = utf8.encode(text);
    int hash = fnvOffset;
    for (final b in bytes) {
      hash = hash ^ b;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _generateBlockId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _random.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    return 'b_${ts}_$rand';
  }
}