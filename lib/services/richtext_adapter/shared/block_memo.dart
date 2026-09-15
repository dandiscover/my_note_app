// lib/services/richtext_adapter/shared/block_memo.dart
// BlockMemo — 适配层块暂存结构
// 读时从存储结构提取，保存时用于挂回 id 和 marks
// 不持久化，仅在会话内有效

/// 单个块的暂存信息。
///
/// 用途：解决"自定义结构 → Delta → 自定义结构"往返时
/// 块 id 和 marks 会丢的问题。
///
/// 生命周期：读笔记时生成，保存笔记时使用，之后丢弃。
/// 不落盘。若未来需要持久化，contentHash 必须换成确定性 hash。
class BlockMemo {
  /// 块的 id（来自存储结构）
  final String id;

  /// 块的 type（'paragraph' / 'heading' / 'list' / ...）
  final String type;

  /// 块可读文本的 hash（sha1 前 8 位，或等价的确定性摘要）
  /// 用于在顺序失配时按内容找回
  final String contentHash;

  /// 块在全局 DFS 遍历中的 0-based 序号
  /// 见第二轮方案 v4 第 5.2.1 节
  final int orderIndex;

  /// 块级 marks
  final List<String> marks;

  const BlockMemo({
    required this.id,
    required this.type,
    required this.contentHash,
    required this.orderIndex,
    required this.marks,
  });

  @override
  String toString() =>
      'BlockMemo(id: $id, type: $type, orderIndex: $orderIndex, marks: $marks)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockMemo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          contentHash == other.contentHash &&
          orderIndex == other.orderIndex &&
          _listEquals(marks, other.marks);

  @override
  int get hashCode =>
      Object.hash(id, type, contentHash, orderIndex, Object.hashAll(marks));

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}