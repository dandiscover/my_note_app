// lib/services/richtext_adapter/richtext_adapter.dart
// 适配层主入口 — 对外唯一门面

import 'delta_to_structure.dart';
import 'structure_to_delta.dart';
import 'shared/block_memo.dart';
import 'shared/delta_with_memo.dart';
export 'shared/block_memo.dart';
export 'shared/delta_with_memo.dart';
/// 富文本适配层主入口。
class RichtextAdapter {
  RichtextAdapter._();

  /// 自定义结构 → Delta（打开笔记时用）。
  ///
  /// 抛：
  ///   - [InvalidStructureException]：结构非法（缺字段、类型错、版本不是 2）
  ///   - [UnsupportedBlockTypeException]：遇到 `table` 等不支持的块
  static DeltaWithMemo structureToDelta(Map<String, dynamic> structure) {
    return StructureToDelta.convert(structure);
  }

  /// Delta → 自定义结构（保存笔记时用）。
  ///
  /// 抛：暂无抛点。未知块降级为 paragraph（保留用户数据）。
  ///   [InvalidDeltaException] 类已定义（见 errors.dart），当前未使用，
  ///   留待将来输入校验需要时启用。
  static Map<String, dynamic> deltaToStructure(
    List<Map<String, dynamic>> delta, {
    List<BlockMemo>? memo,
  }) {
    return DeltaToStructure.convert(delta, memo: memo);
  }
}