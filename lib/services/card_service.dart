// lib/services/card_service.dart
// 卡片服务 — 集成云端同步
// ✅ 复习相关方法过滤拐杖卡（kind == CardKind.scaffold）
// ✅ 统计口径与按类型查询统一过滤拐杖卡
// ✅ 任务三：getCardsBySource 签名改为 named + required（sourceType + sourceId）
// ✅ 指导卡：加 ensureGuideCard（系统预置卡）+ getCard（按 id 查）
// ✅ 懒加载：getAllCards 前置检查，指导卡不存在则补一张（幂等）
// ✅ 首次机制：getFirstUsedCards / markCardUsed / isFirstUse / markCardBoxOpened
// ✅ 读书笔记关联：getBookReadingNoteId / setBookReadingNoteId / clearBookReadingNoteId
// ✅ 批 2-4：加 revision notifier —— 卡库增删改时递增 —— 素材区监听自动 reload

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card.dart';
import 'sync/cloud_sync_service.dart';
import 'sync/sync_manager.dart';

class CardService {
  static const String _cardsKey = 'cards_data';
  static const String _firstUsedCardsKey = 'first_used_cards';
  static const String _systemGuideCardId = 'system_guide_card';

  /// 批 2-4：卡片库版本号——增删改时递增——素材区监听自动 reload
  static final ValueNotifier<int> revision = ValueNotifier(0);

  // ✅ 懒加载：确保系统预置指导卡存在（幂等）
  Future<List<CardModel>> getAllCards() async {
    final cards = await _loadCards();
    if (!cards.any((c) => c.id == _systemGuideCardId)) {
      final guideCard = CardModel(
        id: _systemGuideCardId,
        cardType: CardType.guide,
        sourceType: 'system',
        sourceId: 'system',
        sourceTitle: '系统预置',
        kind: CardKind.scaffold,
        tags: const ['拐杖卡', '指导'],
      );
      cards.add(guideCard);
      await _saveCards(cards);
      revision.value++;                         // 批 2-4
      // 同步到云端
      if (CloudSyncService().isLoggedIn) {
        try {
          await CloudSyncService().syncCard(guideCard);
        } catch (_) {}
      }
    }
    return cards;
  }

  // ✅ 私有：纯读逻辑（原 getAllCards 的读取部分）
  Future<List<CardModel>> _loadCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_cardsKey);
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // ✅ 保留为公共方法，内部只触发懒加载
  Future<void> ensureGuideCard() async {
    await getAllCards();
  }

  // ✅ 按 id 查单张卡
  Future<CardModel?> getCard(String id) async {
    final cards = await getAllCards();
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _saveCards(List<CardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(cards.map((c) => c.toJson()).toList());
    await prefs.setString(_cardsKey, json);
  }

  Future<void> addCard(CardModel card) async {
    final cards = await _loadCards();
    cards.add(card);
    await _saveCards(cards);

    revision.value++;                           // 批 2-4

    // ✅ 同步到云端
    if (CloudSyncService().isLoggedIn) {
      try {
        await CloudSyncService().syncCard(card);
        SyncManager().markClean();
      } catch (e) {
        SyncManager().markDirty();
      }
    }
  }

  Future<void> addCards(List<CardModel> newCards) async {
    final cards = await _loadCards();
    cards.addAll(newCards);
    await _saveCards(cards);

    if (newCards.isNotEmpty) revision.value++;  // 批 2-4（空列表不递增）

    // ✅ 同步到云端
    if (CloudSyncService().isLoggedIn) {
      for (var card in newCards) {
        try {
          await CloudSyncService().syncCard(card);
        } catch (_) {}
      }
    }
  }
/// 导入批：批量导入专用 —— 只写本地 + 打 dirty 标记，不循环推云。
  Future<void> addCardsSilent(List<CardModel> newCards) async {
    if (newCards.isEmpty) return;
    final cards = await _loadCards();
    cards.addAll(newCards);
    await _saveCards(cards);
    revision.value++;
    SyncManager().markDirty();
  }
  Future<void> updateCard(CardModel card) async {
    final cards = await _loadCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
      await _saveCards(cards);

      revision.value++;                         // 批 2-4

      // ✅ 同步到云端
      if (CloudSyncService().isLoggedIn) {
        try {
          await CloudSyncService().syncCard(card);
        } catch (_) {}
      }
    }
  }

  Future<void> deleteCard(String id) async {
    final cards = await _loadCards();
    cards.removeWhere((c) => c.id == id);
    await _saveCards(cards);

    revision.value++;                           // 批 2-4

    // ✅ 同步到云端
    if (CloudSyncService().isLoggedIn) {
      try {
        await CloudSyncService().deleteCard(id);
      } catch (_) {}
    }
  }

  Future<List<CardModel>> getCardsByCardType(CardType type) async {
    final cards = await getAllCards();
    return cards.where((c) => c.cardType == type && c.kind == CardKind.atomic).toList();
  }

  // ✅ 任务三：签名改为 named + required，双条件（sourceType + sourceId）
  Future<List<CardModel>> getCardsBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    final cards = await getAllCards();
    return cards.where((c) =>
      c.sourceType == sourceType && c.sourceId == sourceId).toList();
  }

  Future<List<CardModel>> getDueCards() async {
    final cards = await getAllCards();
    final reviewable = cards.where((c) => c.kind == CardKind.atomic).toList();
    return reviewable.where((c) => c.isDue && !c.mastered).toList();
  }

  Future<List<CardModel>> getMasteredCards() async {
    final cards = await getAllCards();
    final reviewable = cards.where((c) => c.kind == CardKind.atomic).toList();
    return reviewable.where((c) => c.mastered).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final cards = await getAllCards();
    final reviewable = cards.where((c) => c.kind == CardKind.atomic).toList();
    final total = reviewable.length;
    final mastered = reviewable.where((c) => c.mastered).length;
    final learning = reviewable.where((c) => !c.mastered).length;
    final due = reviewable.where((c) => c.isDue && !c.mastered).length;
    final reviewCards = reviewable.where((c) => c.cardType == CardType.review).length;
    final indexCards = reviewable.where((c) => c.cardType == CardType.indexCard).length;
    return {
      'total': total,
      'mastered': mastered,
      'learning': learning,
      'due': due,
      'reviewCards': reviewCards,
      'indexCards': indexCards,
    };
  }

  Future<void> rateRemembered(CardModel card) async {
    final updated = card.rateRemembered();
    await updateCard(updated);
  }

  Future<void> rateForgotten(CardModel card) async {
    final updated = card.rateForgotten();
    await updateCard(updated);
  }

  Future<void> resetCard(String id) async {
    final cards = await _loadCards();
    final index = cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      final reset = cards[index].copyWith(
        stage: 0,
        mastered: false,
        nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
        totalReviews: 0,
        failedCount: 0,
        memoryLevel: 0.3,
        updatedAt: DateTime.now(),
      );
      cards[index] = reset;
      await _saveCards(cards);

      revision.value++;                         // 批 2-4

      // ✅ 同步到云端
      if (CloudSyncService().isLoggedIn) {
        try {
          await CloudSyncService().syncCard(reset);
        } catch (_) {}
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 系统预置卡
  // ═══════════════════════════════════════════════════════════════

  // ✅ 判断是否为系统预置卡（不可删）
  bool isSystemCard(String cardId) => cardId == _systemGuideCardId;

  // ═══════════════════════════════════════════════════════════════
  // 首次机制：first_used_cards
  // ═══════════════════════════════════════════════════════════════

  // ✅ 读取已用过的卡列表
  Future<List<String>> getFirstUsedCards() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_firstUsedCardsKey) ?? [];
  }

  // ✅ 判断某张卡是否是第一次用
  Future<bool> isFirstUse(String cardKey) async {
    final used = await getFirstUsedCards();
    return !used.contains(cardKey);
  }

  // ✅ 标记某张卡已用过
  Future<void> markCardUsed(String cardKey) async {
    final used = await getFirstUsedCards();
    if (used.contains(cardKey)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_firstUsedCardsKey, [...used, cardKey]);
  }

  // ✅ 标记"第一次打开卡片盒"（特殊值 card_box_opened）
  Future<void> markCardBoxOpened() async {
    await markCardUsed('card_box_opened');
  }

  // ═══════════════════════════════════════════════════════════════
  // 读书笔记关联：book_reading_note_id_${bookId}
  // ═══════════════════════════════════════════════════════════════

  // ✅ 读取某本书关联的读书笔记 id
  Future<String?> getBookReadingNoteId(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('book_reading_note_id_$bookId');
  }

  // ✅ 记录某本书关联的读书笔记 id
  Future<void> setBookReadingNoteId(String bookId, String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book_reading_note_id_$bookId', noteId);
  }

  // ✅ 清除某本书的读书笔记关联（笔记已被删时用）
  Future<void> clearBookReadingNoteId(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('book_reading_note_id_$bookId');
  }
}