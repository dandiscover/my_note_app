// lib/services/card_note_service.dart
// 批 2-2：卡片拓展成笔记

import '../database_service.dart';
import '../models/card.dart';
import '../models/note.dart';
import 'card_service.dart';

class CardNoteService {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();

  /// 卡片 → 新笔记（乙语义：引用块进正文 + 来源标记 + 保留卡 + 建关联）
  /// 返回：新笔记 id
  /// 一对多：relatedIds 列表——同卡可拓展多次
  Future<String> expandToNote(CardModel card) async {
    final source = _formatSource(card);
    final body = _formatBody(card);
    final content = source != null
        ? '> $body\n>\n> —— $source'
        : '> $body';

    final noteId = DateTime.now().millisecondsSinceEpoch.toString();
    final title = _formatTitle(card);
    final note = NotebookEntry(
      id: noteId,
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      status: 'active',
      editorMode: 'plain',
      tags: List.from(card.tags),
    );
    await _db.insertNote(note.toMap());

    final folderId = await _db.ensureReviewFolder();
    await _db.attachNoteToNode(
      noteId: noteId,
      title: title,
      parentId: folderId,
      tags: note.tags,
    );

    final newRelatedIds = card.relatedIds.contains(noteId)
        ? card.relatedIds
        : [...card.relatedIds, noteId];
    await _cardService.updateCard(card.copyWith(relatedIds: newRelatedIds));

    return noteId;
  }

  String? _formatSource(CardModel card) {
    if (card.sourceType == 'book' && card.sourceTitle != null && card.sourceTitle!.isNotEmpty) {
      return '来自《${card.sourceTitle}》';
    }
    if (card.sourceType == 'note' && card.sourceTitle != null && card.sourceTitle!.isNotEmpty) {
      return '来自笔记《${card.sourceTitle}》';
    }
    return null;
  }

  String _formatTitle(CardModel card) {
    final candidates = [
      card.indexTitle,
      card.highlight,
      card.front,
      card.question,
    ];
    final base = candidates.firstWhere(
      (s) => s != null && s.isNotEmpty,
      orElse: () => '卡片',
    )!;
    final trimmed = base.length > 20 ? '${base.substring(0, 20)}…' : base;
    return '拓展：$trimmed';
  }

  String _formatBody(CardModel card) {
    final parts = <String>[];
    if (card.highlight != null && card.highlight!.isNotEmpty) parts.add(card.highlight!);
    if (card.front != null && card.front!.isNotEmpty) parts.add(card.front!);
    if (card.back != null && card.back!.isNotEmpty) parts.add(card.back!);
    if (card.question != null && card.question!.isNotEmpty) parts.add(card.question!);
    if (card.answer != null && card.answer!.isNotEmpty) parts.add(card.answer!);
    if (parts.isEmpty) parts.add('[空卡片]');
    return parts.join('\n\n');
  }
}