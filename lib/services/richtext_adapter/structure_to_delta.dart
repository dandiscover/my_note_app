// lib/services/richtext_adapter/structure_to_delta.dart
// 自定义结构 → Delta 转换
//
// ─── T-134：contentHash 生成算法 ───────────────────
//
// 算法：FNV-1a 32 位。纯 Dart 实现，零依赖。
//
//   hash = 2166136261
//   for each byte b in utf8(text):
//     hash = hash XOR b
//     hash = (hash * 16777619) & 0xFFFFFFFF
//   return hash.toRadixString(16).padLeft(8, '0')
//
// ─── T-134：各块"可读文本"定义 ───────────────────
//
//   paragraph     → inlines 里所有 text 拼接（无分隔）
//   heading       → inlines 里所有 text 拼接
//   todo          → inlines 里所有 text 拼接
//   code_block    → text 字段原样
//   divider       → 空字符串（分割线无文本）
//   ink           → 空字符串（手写无文本语义）
//
//   list          → 只读 item 内 paragraph 子块的文本，
//                   用 '\n' 拼接。嵌套非 paragraph 块被平坦化
//                   拍出成为独立顶层块，不计入 list 自身的 hash。
//   blockquote    → 只读 children 内 paragraph 子块的文本，
//                   用 '\n' 拼接。同 list 的平坦化处理。
//   image         → 空字符串。
//                   Delta 往返不保留 alt / width / height，
//                   hash 对齐"Delta 能保的信息"。
//
// 与 delta_to_structure.dart 的契约：
//   本文件的 _readableTextOf 与第 7 文件的 _readableTextOfListGroup /
//   _readableTextOfBlock / _hashReadableText 必须产出同一字符串。
//   第 7 文件以本文件注释为准。
//
// ─── 嵌套块降级说明 ─────────────────────
//
// list / blockquote 里的非 paragraph 子块：递归转换，不裹上 list 属性。
// 数据保留，层级丢失。
//
// ─── code_block.language 降级说明 ─────────────────────
//
// ✅ 已实测：flutter_quill 11.5.1 里 `code-block` 属性值为 `true`，
//    不支持挂语言名。
//    存储结构的 `language` 字段本轮不进 Delta。

import 'dart:convert';

import 'errors.dart';
import 'shared/attributes.dart';
import 'shared/block_memo.dart';
import 'shared/delta_ops.dart';
import 'shared/delta_with_memo.dart';

class StructureToDelta {
  StructureToDelta._();

  static DeltaWithMemo convert(Map<String, dynamic> structure) {
    if (structure['version'] != 2) {
      throw InvalidStructureException(
        'structure["version"] 不是 2，实际为 ${structure['version']}',
      );
    }

    final blocks = structure['blocks'];
    if (blocks is! List) {
      throw InvalidStructureException('structure["blocks"] 不是 List');
    }

    if (blocks.isEmpty) {
      return DeltaWithMemo(
        delta: [DeltaOps.newline()],
        memo: const [],
      );
    }

    final deltaOps = <Map<String, dynamic>>[];
    final memos = <BlockMemo>[];
    int dfsCounter = 0;

    for (final block in blocks) {
      if (block is! Map) {
        throw InvalidStructureException('block 不是 Map');
      }
      dfsCounter = _emitBlock(
        Map<String, dynamic>.from(block),
        deltaOps,
        memos,
        dfsCounter,
      );
    }

    return DeltaWithMemo(delta: deltaOps, memo: memos);
  }

  static int _emitBlock(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> outDeltaOps,
    List<BlockMemo> outMemos,
    int dfsStart,
  ) {
    final type = block['type'];
    if (type is! String) {
      throw InvalidStructureException(
        '块缺 type 字段',
        blockId: block['id'] as String?,
      );
    }

    int next = dfsStart;
    switch (type) {
      case 'paragraph':
        next = _emitParagraph(block, outDeltaOps, outMemos, next);
        break;
      case 'heading':
        next = _emitHeading(block, outDeltaOps, outMemos, next);
        break;
      case 'list':
        next = _emitList(block, outDeltaOps, outMemos, next);
        break;
      case 'blockquote':
        next = _emitBlockquote(block, outDeltaOps, outMemos, next);
        break;
      case 'code_block':
        next = _emitCodeBlock(block, outDeltaOps, outMemos, next);
        break;
      case 'image':
        next = _emitImage(block, outDeltaOps, outMemos, next);
        break;
      case 'todo':
        next = _emitTodo(block, outDeltaOps, outMemos, next);
        break;
      case 'divider':
        next = _emitDivider(block, outDeltaOps, outMemos, next);
        break;
      case 'ink':
        next = _emitInk(block, outDeltaOps, outMemos, next);
        break;
      case 'table':
        throw UnsupportedBlockTypeException('table', 'structureToDelta');
      default:
        throw UnsupportedBlockTypeException(type, 'structureToDelta');
    }
    return next;
  }

  static int _emitParagraph(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final inlines = block['inlines'];
    if (inlines is! List) {
      throw InvalidStructureException('paragraph 缺 inlines', blockId: id);
    }
    final marks = _readMarks(block);

    for (final inline in inlines) {
      if (inline is! Map) continue;
      final op = _inlineToOp(Map<String, dynamic>.from(inline));
      if (op != null) out.add(op);
    }
    out.add(DeltaOps.newline());

    memos.add(BlockMemo(
      id: id,
      type: 'paragraph',
      contentHash: _hashReadableText(_readableTextOf(block)),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static int _emitHeading(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final level = block['level'];
    if (level is! int || level < 1 || level > 6) {
      throw InvalidStructureException('heading 的 level 不合法', blockId: id);
    }
    final inlines = block['inlines'];
    if (inlines is! List) {
      throw InvalidStructureException('heading 缺 inlines', blockId: id);
    }
    final marks = _readMarks(block);

    for (final inline in inlines) {
      if (inline is! Map) continue;
      final op = _inlineToOp(Map<String, dynamic>.from(inline));
      if (op != null) out.add(op);
    }
    out.add(DeltaOps.newline(attributes: {
      DeltaAttributes.header: level,
    }));

    memos.add(BlockMemo(
      id: id,
      type: 'heading',
      contentHash: _hashReadableText(_readableTextOf(block)),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static int _emitList(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final ordered = block['ordered'];
    if (ordered is! bool) {
      throw InvalidStructureException('list 缺 ordered', blockId: id);
    }
    final items = block['items'];
    if (items is! List) {
      throw InvalidStructureException('list 缺 items', blockId: id);
    }
    final marks = _readMarks(block);
    final listValue =
        ordered ? DeltaListValues.ordered : DeltaListValues.bullet;

    memos.add(BlockMemo(
      id: id,
      type: 'list',
      contentHash: _hashReadableText(_readableTextOf(block)),
      orderIndex: dfsStart,
      marks: marks,
    ));
    dfsStart += 1;

    for (final item in items) {
      if (item is! Map) continue;
      final itemBlocks = item['blocks'];
      if (itemBlocks is! List) continue;
      for (final childBlock in itemBlocks) {
        if (childBlock is! Map) continue;
        final child = Map<String, dynamic>.from(childBlock);
        final childType = child['type'];

        if (childType == 'paragraph') {
          final childId = child['id'] as String;
          final childInlines = child['inlines'];
          if (childInlines is! List) continue;
          for (final inline in childInlines) {
            if (inline is! Map) continue;
            final op = _inlineToOp(Map<String, dynamic>.from(inline));
            if (op != null) out.add(op);
          }
          out.add(DeltaOps.newline(attributes: {
            DeltaAttributes.list: listValue,
          }));

          memos.add(BlockMemo(
            id: childId,
            type: 'paragraph',
            contentHash: _hashReadableText(_readableTextOf(child)),
            orderIndex: dfsStart,
            marks: _readMarks(child),
          ));
          dfsStart += 1;
        } else {
          dfsStart = _emitBlock(child, out, memos, dfsStart);
        }
      }
    }

    return dfsStart;
  }

  static int _emitBlockquote(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final children = block['children'];
    if (children is! List) {
      throw InvalidStructureException('blockquote 缺 children', blockId: id);
    }
    final marks = _readMarks(block);

    memos.add(BlockMemo(
      id: id,
      type: 'blockquote',
      contentHash: _hashReadableText(_readableTextOf(block)),
      orderIndex: dfsStart,
      marks: marks,
    ));
    dfsStart += 1;

    for (final child in children) {
      if (child is! Map) continue;
      final childMap = Map<String, dynamic>.from(child);
      final childType = childMap['type'];

      if (childType == 'paragraph') {
        final childId = childMap['id'] as String;
        final inlines = childMap['inlines'];
        if (inlines is! List) continue;
        for (final inline in inlines) {
          if (inline is! Map) continue;
          final op = _inlineToOp(Map<String, dynamic>.from(inline));
          if (op != null) out.add(op);
        }
        out.add(DeltaOps.newline(attributes: {
          DeltaAttributes.blockquote: true,
        }));

        memos.add(BlockMemo(
          id: childId,
          type: 'paragraph',
          contentHash: _hashReadableText(_readableTextOf(childMap)),
          orderIndex: dfsStart,
          marks: _readMarks(childMap),
        ));
        dfsStart += 1;
      } else {
        dfsStart = _emitBlock(childMap, out, memos, dfsStart);
      }
    }

    return dfsStart;
  }

  static int _emitCodeBlock(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final text = block['text'];
    if (text is! String) {
      throw InvalidStructureException('code_block 缺 text', blockId: id);
    }
    final marks = _readMarks(block);

    out.add(DeltaOps.textInsert(text));

    // ✅ 已实测：flutter_quill 11.5.1 里 code-block 属性值为 true，
    //    不支持挂语言名。
    //    存储结构的 `language` 字段本轮不进 Delta。
    out.add(DeltaOps.newline(attributes: {
      DeltaAttributes.codeBlock: true,
    }));

    memos.add(BlockMemo(
      id: id,
      type: 'code_block',
      contentHash: _hashReadableText(text),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static int _emitImage(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final src = block['src'];
    if (src is! String || src.isEmpty) {
      throw InvalidStructureException('image 缺 src', blockId: id);
    }
    final marks = _readMarks(block);

    out.add(DeltaOps.embedInsert({DeltaAttributes.image: src}));
    out.add(DeltaOps.newline());

    memos.add(BlockMemo(
      id: id,
      type: 'image',
      contentHash: _hashReadableText(_readableTextOf(block)),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static int _emitTodo(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final checked = block['checked'];
    if (checked is! bool) {
      throw InvalidStructureException('todo 缺 checked', blockId: id);
    }
    final inlines = block['inlines'];
    if (inlines is! List) {
      throw InvalidStructureException('todo 缺 inlines', blockId: id);
    }
    final marks = _readMarks(block);

    for (final inline in inlines) {
      if (inline is! Map) continue;
      final op = _inlineToOp(Map<String, dynamic>.from(inline));
      if (op != null) out.add(op);
    }
    out.add(DeltaOps.newline(attributes: {
      DeltaAttributes.list:
          checked ? DeltaListValues.checked : DeltaListValues.unchecked,
    }));

    memos.add(BlockMemo(
      id: id,
      type: 'todo',
      contentHash: _hashReadableText(_readableTextOf(block)),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static int _emitDivider(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final marks = _readMarks(block);

    out.add(DeltaOps.embedInsert({DeltaAttributes.divider: true}));
    out.add(DeltaOps.newline());

    memos.add(BlockMemo(
      id: id,
      type: 'divider',
      contentHash: _hashReadableText(''),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static int _emitInk(
    Map<String, dynamic> block,
    List<Map<String, dynamic>> out,
    List<BlockMemo> memos,
    int dfsStart,
  ) {
    final id = block['id'] as String;
    final marks = _readMarks(block);

    out.add(DeltaOps.embedInsert({DeltaAttributes.inkPlaceholder: id}));
    out.add(DeltaOps.newline());

    memos.add(BlockMemo(
      id: id,
      type: 'ink',
      contentHash: _hashReadableText(''),
      orderIndex: dfsStart,
      marks: marks,
    ));
    return dfsStart + 1;
  }

  static Map<String, dynamic>? _inlineToOp(Map<String, dynamic> inline) {
    final text = inline['text'];
    if (text is! String) {
      return null;
    }

    final attrs = <String, dynamic>{};

    if (inline['bold'] == true) attrs[DeltaAttributes.bold] = true;
    if (inline['italic'] == true) attrs[DeltaAttributes.italic] = true;
    if (inline['underline'] == true) {
      attrs[DeltaAttributes.underline] = true;
    }
    if (inline['strike'] == true) attrs[DeltaAttributes.strike] = true;
    if (inline['code'] == true) attrs[DeltaAttributes.code] = true;

    final color = inline['color'];
    if (color is String && color.isNotEmpty) {
      attrs[DeltaAttributes.color] = color;
    }
    final highlight = inline['highlight'];
    if (highlight is String && highlight.isNotEmpty) {
      attrs[DeltaAttributes.highlight] = highlight;
    }
    final link = inline['link'];
    if (link is String && link.isNotEmpty) {
      attrs[DeltaAttributes.link] = link;
    }

    return DeltaOps.textInsert(text, attributes: attrs);
  }

  static String _readableTextOf(Map<String, dynamic> block) {
    final type = block['type'];
    switch (type) {
      case 'paragraph':
      case 'heading':
      case 'todo':
        return _inlinesToText(block['inlines']);
      case 'list':
        return _listToText(block['items']);
      case 'blockquote':
        return _blockquoteToText(block['children']);
      case 'code_block':
        return (block['text'] as String?) ?? '';
      case 'image':
        // T-144：Delta 往返不保留 alt。hash 也对齐"Delta 能保的信息"。
        return '';
      case 'divider':
      case 'ink':
        return '';
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
        // T-145：只读 paragraph 子块
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
      // T-145：只读 paragraph 子块
      if (childMap['type'] == 'paragraph') {
        parts.add(_inlinesToText(childMap['inlines']));
      }
    }
    return parts.join('\n');
  }

  static String _hashReadableText(String text) {
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

  static List<String> _readMarks(Map<String, dynamic> block) {
    final marks = block['marks'];
    if (marks is! List) return const [];
    return marks.whereType<String>().toList();
  }
}