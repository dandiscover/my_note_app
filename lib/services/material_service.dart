import '../database_service.dart';
import '../models/card.dart';
import '../models/material_item.dart';
import '../models/note.dart';
import 'card_service.dart';

/// 素材栏数据源服务（1c-redo · 乙 + L5 + 甲）
///
/// ─── 结构：三段 ───
///
/// ┌─ priority（关联驱动——和当前笔记有关）
/// │  · tag 交集：笔记 / 索引卡，其 tags 与当前笔记 tags 有交集
/// │  · 双链：⏳ 留口——引用关系表未建——机制存在后接入
/// │
/// ├─ structure（结构驱动——零门槛）
/// │  · 同文件夹笔记（不含当前笔记；已去重 priority）
/// │  · 上一级、最近编辑：⏳ 留口
/// │
/// └─ library（展示驱动——库里有什么）
///    · 其他索引卡：tags 未命中当前笔记
///
/// ─── 去重 ───
/// priority → structure → library 单向去重——同一 id 不重复出现
///
/// ─── 配额 ───
///   priority: 25
///   library（structure + library 共享）: 15
///
/// ─── 本块范围 ───
///   ✅ priority · tag 交集
///   ✅ structure · 同文件夹
///   ✅ library · 索引卡
///   ⏳ 留口：L3 双链、L5 上一级
///   ❌ 不做：L6 最近编辑（发现流——归洞察页）
///   ❌ 不做：L1 手动关联（语义待定——另立专项）
class MaterialService {
  /// 优先推荐上限
  static const int quotaPriority = 25;

  /// 同文件夹上限（structure）
  static const int quotaStructure = 10;

  /// 库展示上限（library）
  static const int quotaLibrary = 15;

  /// 三段总数防爆上限
  static const int quotaTotal = 50;
  /// 拉「当前笔记」的素材（单列表——priority → structure → library）
  ///
  /// [note] 当前笔记（焦点栏）
  /// [nodeId] 当前笔记的 node id
  ///          未传时——服务内部用 getNodeByNoteId 反查
  ///          note_detail 已传——multi_pane 不传
  static Future<List<MaterialItem>> loadFor(
    NotebookEntry note, {
    String? nodeId,
  }) async {
    final db = DatabaseService();
    final cardService = CardService();

    // ─── 数据加载 ───
    final allCards = await cardService.getAllCards();
    final indexCards =
        allCards.where((c) => c.cardType == CardType.indexCard).toList();

    final noteMaps = await db.getAllNotes(includeDeleted: false);
    final allNotes = noteMaps.map((m) => NotebookEntry.fromMap(m)).toList();

    // ─── tag 命中判定 ───
    bool hitsTags(List<String> tags) =>
        tags.any((t) => note.tags.contains(t));

    // ─── priority · tag 交集 ───
    final priorityNotes = allNotes
        .where((n) => n.id != note.id && hitsTags(n.tags))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final priorityCards = indexCards
        .where((c) => hitsTags(c.tags))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // ─── 去重集合（priority 已占 id）───
    final priorityIds = <String>{
      ...priorityNotes.map((n) => n.id),
      ...priorityCards.map((c) => c.id),
    };

    // ─── structure · 同文件夹 ───
    final resolvedNodeId =
        nodeId ?? (await db.getNodeByNoteId(note.id))?.id;
    final sameFolderNotes = <NotebookEntry>[];
    if (resolvedNodeId != null) {
      final selfNode = await db.getNode(resolvedNodeId);
      final folderId = selfNode?.parentId;
      if (folderId != null) {
        final siblings = await db.getContentNodesInFolder(folderId);
        final sibIds = siblings
            .where((n) =>
                n.nodeType == 'note' &&
                n.targetId != null &&
                n.targetId != note.id)
            .map((n) => n.targetId!)
            .toSet();
        sameFolderNotes.addAll(
          allNotes.where((n) =>
              sibIds.contains(n.id) && !priorityIds.contains(n.id)),
        );
      }
    }

    // ─── library · 所有卡片 + 所有笔记（去 priority / structure）───

    // 卡片池：排除 guide 卡（系统预置，非素材）
    final allUsableCards = allCards
        .where((c) => c.cardType != CardType.guide)
        .toList();

    // library 卡片候选
    final libraryCards = allUsableCards
        .where((c) => !priorityIds.contains(c.id))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // library 笔记候选（去 priority / 去 structure）
    final structureNoteIds = sameFolderNotes.map((n) => n.id).toSet();
    final libraryNotes = allNotes
        .where((n) =>
            n.id != note.id &&
            !priorityIds.contains(n.id) &&
            !structureNoteIds.contains(n.id))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // ─── 组装三段 ───
    final priority = <MaterialItem>[
      ...priorityNotes.map(
        (n) => MaterialItem.fromNote(n, layer: MaterialLayer.priority),
      ),
      ...priorityCards.map(
        (c) => MaterialItem.fromCard(c, layer: MaterialLayer.priority),
      ),
    ].take(quotaPriority).toList();

    // structure：同文件夹笔记，独立配额
    final structure = <MaterialItem>[
      ...sameFolderNotes.map(
        (n) => MaterialItem.fromNote(n, layer: MaterialLayer.structure),
      ),
    ].take(quotaStructure).toList();

    // library：卡片在前、笔记在后（老白裁 3），独立配额
    final library = <MaterialItem>[
      ...libraryCards.map(
        (c) => MaterialItem.fromCard(c, layer: MaterialLayer.library),
      ),
      ...libraryNotes.map(
        (n) => MaterialItem.fromNote(n, layer: MaterialLayer.library),
      ),
    ].take(quotaLibrary).toList();

    // ─── 总数防爆 ───
    final all = <MaterialItem>[...priority, ...structure, ...library];
    if (all.length > quotaTotal) {
      return all.take(quotaTotal).toList();
    }
    return all;
  }
}