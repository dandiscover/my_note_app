import '../database_service.dart';
import '../models/card.dart';
import '../models/material_item.dart';
import '../models/note.dart';
import 'card_service.dart';

/// 素材栏数据源服务（1c-redo · 乙方案）
///
/// ─── 结构：两块 ───
///
/// ┌─ 优先推荐（关联驱动——和当前笔记有关）
/// │  · tag 交集：笔记 / 索引卡，其 tags 与当前笔记 tags 有交集
/// │  · 双链：⏳ 留口——引用关系表未建——机制存在后接入
/// │  · 本块只做 tag 交集
/// │
/// ├─ 库展示（展示驱动——库里有什么）
/// │  · 其他索引卡：tags 未命中当前笔记
/// │  · 同文件夹、上一级、最近编辑：⏳ 留口——L5 补丁接入
/// │  · 本块只做其他索引卡
///
/// ─── 边界 ───
/// 两块之间是「推荐 vs 展示」——不是强度轴
/// 返回单列表——优先推荐在前——库展示在后——组内 updatedAt DESC
///
/// ─── 可视化债 ───
/// 两块只靠排序区分——用户看不出「为什么上面在上面」
/// 轻量视觉分隔（分隔线 / 标签）归「素材栏视觉分组」批
///
/// ─── 本块范围 ───
///   ✅ 优先推荐 · tag 交集
///   ✅ 库展示 · 索引卡
///   ⏳ 留口：L3 双链、L5 同文件夹 / 上一级
///   ❌ 不做：L6 最近编辑（发现流——归洞察页）
///   ❌ 不做：L1 手动关联（语义待定——另立专项）
class MaterialService {
  /// 优先推荐上限
  static const int quotaPriority = 25;

  /// 库展示上限
  static const int quotaLibrary = 15;

  /// 拉「当前笔记」的素材（单列表——优先推荐在前）
  ///
  /// [note] 当前笔记（焦点栏）
  /// [nodeId] 当前笔记的 node id
  ///          本块不用——L5 补丁接入（同文件夹 / 上一级）
  ///          接口预留——L5 只改服务内部——不动调用点
  static Future<List<MaterialItem>> loadFor(
    NotebookEntry note, {
    String? nodeId,
  }) async {
    final db = DatabaseService();
    final cardService = CardService();

    final allCards = await cardService.getAllCards();
    final indexCards =
        allCards.where((c) => c.cardType == CardType.indexCard).toList();

    final noteMaps = await db.getAllNotes(includeDeleted: false);
    final allNotes = noteMaps.map((m) => NotebookEntry.fromMap(m)).toList();

    bool hitsTags(List<String> tags) =>
        tags.any((t) => note.tags.contains(t));

    // ─── 优先推荐 · tag 交集 ───
    final priorityNotes = allNotes
        .where((n) => n.id != note.id && hitsTags(n.tags))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final priorityCards = indexCards
        .where((c) => hitsTags(c.tags))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // ─── 库展示 · 其他索引卡（未命中 tag）───
    final libraryCards = indexCards
        .where((c) => !hitsTags(c.tags))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // ─── 组装（单列表——优先推荐在前——不重复）───
    final priority = <MaterialItem>[
      ...priorityNotes.map(MaterialItem.fromNote),
      ...priorityCards.map(MaterialItem.fromCard),
    ].take(quotaPriority).toList();

    final library = libraryCards
        .map(MaterialItem.fromCard)
        .take(quotaLibrary)
        .toList();

    return [...priority, ...library];
  }
}