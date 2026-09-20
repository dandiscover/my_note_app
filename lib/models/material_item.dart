// lib/models/material_item.dart
// E批：素材面板统一项

import 'card.dart';
import 'note.dart';
import '../utils/app_string_utils.dart';

enum MaterialItemType { card, note }

enum MaterialSortKey { timeDesc, timeAsc, titleAsc, tagCount }

/// 素材分层（1c-redo-甲）
enum MaterialLayer { priority, structure, library }

/// 素材面板统一项
///
/// 两源：卡片（CardModel）+ 笔记（NotebookEntry）
/// **认重**：挂对象引用，不复制字段。理由：
///   1. 一屏几十条可控
///   2. 一致优先——卡片改了，面板看到最新
///   3. 轻方案跳转要重查库且可能过期
class MaterialItem {
  final String id;
  final MaterialItemType type;
  final String sourceType; // 'note' / 'book'
  final String title;
  final String summary;
  final List<String> tags;
  final DateTime updatedAt;
  final MaterialLayer layer;

  final CardModel? card;
  final NotebookEntry? note;

  const MaterialItem({
    required this.id,
    required this.type,
    required this.sourceType,
    required this.title,
    required this.summary,
    this.tags = const [],
    required this.updatedAt,
    this.layer = MaterialLayer.library,
    this.card,
    this.note,
  });

  /// 卡片 → 素材项
  factory MaterialItem.fromCard(
    CardModel card, {
    MaterialLayer layer = MaterialLayer.library,
  }) {
    final raw = card.highlight ?? card.displayFront;
    return MaterialItem(
      id: card.id,
      type: MaterialItemType.card,
      sourceType: card.sourceType,
      title: card.indexTitle ?? '未命名',
      summary: _safeTruncate(raw, 50),
      tags: card.tags,
      updatedAt: card.updatedAt,
      layer: layer,
      card: card,
    );
  }

  /// 笔记 → 素材项（title 用 displayNoteTitle 兜底——A 批规则）
  factory MaterialItem.fromNote(
    NotebookEntry note, {
    MaterialLayer layer = MaterialLayer.library,
  }) {
    return MaterialItem(
      id: note.id,
      type: MaterialItemType.note,
      sourceType: 'note',
      title: AppStringUtils.displayNoteTitle(note.title, note.content),
      summary: _safeTruncate(note.content, 50),
      tags: note.tags,
      updatedAt: note.updatedAt,
      layer: layer,
      note: note,
    );
  }

  /// emoji 安全截断——参照 AppStringUtils.virtualNoteTitle 代理对逻辑
  /// E-5：trim + \n 替换（同 virtualNoteTitle）
  static String _safeTruncate(String text, int max) {
    final c = text.trim().replaceAll('\n', ' ');
    if (c.length <= max) return c;
    final code = c.codeUnitAt(max - 1);
    final end = (code >= 0xD800 && code <= 0xDBFF) ? max - 1 : max;
    return '${c.substring(0, end)}…';
  }
}