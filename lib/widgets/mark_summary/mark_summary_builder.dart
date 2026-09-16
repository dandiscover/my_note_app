// lib/widgets/mark_summary/mark_summary_builder.dart
// 摘要面板构造层 — 第四轮批 3 新增
//
// 职责：把 tag_index 原始行构造为 MarkSummaryItem（含来源标题反查）。
//
// 责任分层：
//   MarkSummaryItem（DTO）—— 只装数据
//   本 builder（业务）—— 反查标题 + 构造 DTO
//   wisdom_page / insight_page —— 调本 builder，拿 List<MarkSummaryItem>
//
// 为什么单独立文件而非塞进 DTO：
//   DTO 只装数据，不做业务逻辑。反查是业务，归本文件。

import '../../models/book.dart';
import '../../models/node.dart';
import 'mark_summary_item.dart';

class MarkSummaryBuilder {
  MarkSummaryBuilder._();

  /// 单行构造。
  ///
  /// sourceType='note' → 从 nodes 反查（nodeType='note' && targetId=sourceId）
  /// sourceType='book' → 从 books 反查（b.id=sourceId）
  /// 反查不到 → sourceTitle 填「（笔记已删除）」/「（书已删除）」
  static MarkSummaryItem fromTagRow(
    Map<String, dynamic> tagRow, {
    required List<Node> nodes,
    required List<Book> books,
  }) {
    final sourceType = tagRow['sourceType'] as String? ?? '';
    final sourceId = tagRow['sourceId'] as String? ?? '';

    String sourceTitle = '';
    if (sourceType == 'note') {
      final node = nodes.firstWhere(
        (n) => n.nodeType == 'note' && n.targetId == sourceId,
        orElse: () => Node.empty,
      );
      sourceTitle = node.id.isEmpty ? '（笔记已删除）' : node.title;
    } else if (sourceType == 'book') {
      final book = books.firstWhere(
        (b) => b.id == sourceId,
        orElse: () => Book.empty,
      );
      sourceTitle = book.id.isEmpty ? '（书已删除）' : book.title;
    }

    return MarkSummaryItem(
      type: tagRow['type'] as String? ?? 'custom',
      tag: tagRow['tag'] as String? ?? '',
      text: (tagRow['text'] as String?) ?? '',
      sourceType: sourceType,
      sourceId: sourceId,
      sourceTitle: sourceTitle,
      blockId: tagRow['blockId'] as String?,
      createdAt: tagRow['createdAt'] as String? ?? '',
    );
  }

  /// 批量构造。
  static List<MarkSummaryItem> build(
    List<Map<String, dynamic>> tagRows, {
    required List<Node> nodes,
    required List<Book> books,
  }) =>
      tagRows
          .map((r) => fromTagRow(r, nodes: nodes, books: books))
          .toList();
}