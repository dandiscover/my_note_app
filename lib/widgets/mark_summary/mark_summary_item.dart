// lib/widgets/mark_summary/mark_summary_item.dart
// 摘要面板展示层 DTO — 第四轮批 2a 新增
//
// 责任：承载 tag_index 原始行 + 反查得到的来源标题。
// 不 import DatabaseService。纯数据容器。
//
// 为什么放 widgets/ 而不是 models/：
//   这是展示层 DTO，不是领域模型。与面板组件同层。

class MarkSummaryItem {
  /// 标记类型：'custom' / 'highlight' / 'annotation'
  final String type;

  /// 标记值：'重要' / '高亮' / '批注' / 用户自定义名
  final String tag;

  /// 内容预览：
  ///   custom → 空字符串（笔记级标记无正文）
  ///   highlight → 选中原文
  ///   annotation → 批注内容
  final String text;

  /// 来源类型：'note' / 'book'
  final String sourceType;

  /// 来源 id：noteId / bookId
  final String sourceId;

  /// 来源标题（反查得到）
  final String sourceTitle;

  /// 跳转定位：'page:N' 或 null
  final String? blockId;

  /// 创建时间（ISO8601 字符串）
  final String createdAt;

  const MarkSummaryItem({
    required this.type,
    required this.tag,
    required this.text,
    required this.sourceType,
    required this.sourceId,
    required this.sourceTitle,
    this.blockId,
    required this.createdAt,
  });

  /// blockId 形如 'page:N' 时返回 N-1（章节 index，0-based）。
  /// blockId 为 null 或格式不符时返回 null。
  ///
  /// 第四轮批 2a 新增。方案 v3 §4.2。
  int? get chapterIndex {
    final id = blockId;
    if (id == null) return null;
    if (!id.startsWith('page:')) return null;
    final n = int.tryParse(id.substring(5));
    if (n == null || n <= 0) return null;
    return n - 1;
  }
}