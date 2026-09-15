// lib/services/richtext_adapter/shared/delta_ops.dart
// Delta 底层操作工具集
//
// 职责：对 Delta 操作列表做机械操作（找边界、合并、检查类型）。
// 不做语义解释——语义解释由 structure_to_delta / delta_to_structure 负责。

class DeltaOps {
  DeltaOps._();

  // ─── 1. op 类型判断 ──────────────────────────
  static bool isInsert(Map<String, dynamic> op) => op.containsKey('insert');

  static bool isTextInsert(Map<String, dynamic> op) =>
      op['insert'] is String;

  static bool isEmbedInsert(Map<String, dynamic> op) =>
      op['insert'] is Map;

  static bool isNewline(Map<String, dynamic> op) =>
      isTextInsert(op) && op['insert'] == '\n';

  // ─── 2. op 内容提取 ──────────────────────────
  static String? getText(Map<String, dynamic> op) =>
      isTextInsert(op) ? op['insert'] as String : null;

  static Map<String, dynamic>? getEmbed(Map<String, dynamic> op) =>
      isEmbedInsert(op) ? Map<String, dynamic>.from(op['insert'] as Map) : null;

  static Map<String, dynamic> getAttributes(Map<String, dynamic> op) {
    final attrs = op['attributes'];
    return attrs is Map ? Map<String, dynamic>.from(attrs) : {};
  }

  static bool hasAttribute(Map<String, dynamic> op, String attrName) =>
      getAttributes(op).containsKey(attrName);

  // ─── 3. op 构造 ─────────────────────────────
  static Map<String, dynamic> textInsert(
    String text, {
    Map<String, dynamic>? attributes,
  }) {
    final op = <String, dynamic>{'insert': text};
    if (attributes != null && attributes.isNotEmpty) {
      op['attributes'] = attributes;
    }
    return op;
  }

  static Map<String, dynamic> embedInsert(
    Map<String, dynamic> embed, {
    Map<String, dynamic>? attributes,
  }) {
    final op = <String, dynamic>{'insert': embed};
    if (attributes != null && attributes.isNotEmpty) {
      op['attributes'] = attributes;
    }
    return op;
  }

  static Map<String, dynamic> newline({
    Map<String, dynamic>? attributes,
  }) =>
      textInsert('\n', attributes: attributes);

  // ─── 4. Delta 切块 ───────────────────────────
  static List<List<Map<String, dynamic>>> splitIntoBlocks(
    List<Map<String, dynamic>> delta,
  ) {
    final blocks = <List<Map<String, dynamic>>>[];
    var current = <Map<String, dynamic>>[];

    for (final op in delta) {
      current.add(op);
      if (isNewline(op)) {
        blocks.add(current);
        current = <Map<String, dynamic>>[];
      }
    }

    if (current.isNotEmpty) {
      blocks.add(current);
    }

    return blocks;
  }

  // ─── 5. 块内 op 拆分 ──────────────────────────
  static List<Map<String, dynamic>> contentOpsOf(
    List<Map<String, dynamic>> block,
  ) {
    if (block.isEmpty) return const [];
    if (isNewline(block.last)) {
      return block.sublist(0, block.length - 1);
    }
    return List<Map<String, dynamic>>.from(block);
  }

  static Map<String, dynamic>? newlineOpOf(
    List<Map<String, dynamic>> block,
  ) {
    if (block.isEmpty) return null;
    final last = block.last;
    return isNewline(last) ? last : null;
  }

  static Map<String, dynamic> blockAttributesOf(
    List<Map<String, dynamic>> block,
  ) {
    final nl = newlineOpOf(block);
    if (nl == null) return {};
    return getAttributes(nl);
  }

  // ─── 6. 文本合并 ─────────────────────────────
  static List<Map<String, dynamic>> mergeAdjacentTexts(
    List<Map<String, dynamic>> ops,
  ) {
    if (ops.isEmpty) return const [];

    final result = <Map<String, dynamic>>[];
    Map<String, dynamic>? pendingTextOp;

    void flushPending() {
      if (pendingTextOp != null) {
        result.add(pendingTextOp!);
        pendingTextOp = null;
      }
    }

    for (final op in ops) {
      if (!isTextInsert(op) || isNewline(op)) {
        flushPending();
        result.add(op);
        continue;
      }

      if (pendingTextOp == null) {
        pendingTextOp = Map<String, dynamic>.from(op);
        continue;
      }

      final pendingAttrs = getAttributes(pendingTextOp!);
      final currentAttrs = getAttributes(op);
      if (_attrsEqual(pendingAttrs, currentAttrs)) {
        pendingTextOp!['insert'] =
            (pendingTextOp!['insert'] as String) + (op['insert'] as String);
      } else {
        flushPending();
        pendingTextOp = Map<String, dynamic>.from(op);
      }
    }

    flushPending();
    return result;
  }

  // ─── 7. 属性比较 ─────────────────────────────
  static bool _attrsEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}