// lib/services/richtext_adapter/shared/delta_with_memo.dart
// DeltaWithMemo — structureToDelta 的复合返回值

import 'block_memo.dart';

/// `structureToDelta` 的返回值。
class DeltaWithMemo {
  /// 转换后的 Delta 操作列表。
  final List<Map<String, dynamic>> delta;

  /// 从存储结构提取的块暂存信息。
  final List<BlockMemo> memo;

  const DeltaWithMemo({
    required this.delta,
    required this.memo,
  });
}