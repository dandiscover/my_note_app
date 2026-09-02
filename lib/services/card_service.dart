// lib/services/card_service.dart
// 卡片服务 — 集成云端同步
// ✅ 复习相关方法过滤拐杖卡（kind == CardKind.scaffold）
// ✅ 统计口径与按类型查询统一过滤拐杖卡

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card.dart';
import 'sync/cloud_sync_service.dart';
import 'sync/sync_manager.dart';

class CardService {
  static const String _cardsKey = 'cards_data';

  Future<List<CardModel>> getAllCards() async {
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

  Future<void> _saveCards(List<CardModel> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(cards.map((c) => c.toJson()).toList());
    await prefs.setString(_cardsKey, json);
  }

  Future<void> addCard(CardModel card) async {
    final cards = await getAllCards();
    cards.add(card);
    await _saveCards(cards);

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
    final cards = await getAllCards();
    cards.addAll(newCards);
    await _saveCards(cards);

    // ✅ 同步到云端
    if (CloudSyncService().isLoggedIn) {
      for (var card in newCards) {
        try {
          await CloudSyncService().syncCard(card);
        } catch (_) {}
      }
    }
  }

  Future<void> updateCard(CardModel card) async {
    final cards = await getAllCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
      await _saveCards(cards);

      // ✅ 同步到云端
      if (CloudSyncService().isLoggedIn) {
        try {
          await CloudSyncService().syncCard(card);
        } catch (_) {}
      }
    }
  }

  Future<void> deleteCard(String id) async {
    final cards = await getAllCards();
    cards.removeWhere((c) => c.id == id);
    await _saveCards(cards);

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

  Future<List<CardModel>> getCardsBySource(String sourceId) async {
    final cards = await getAllCards();
    return cards.where((c) => c.sourceId == sourceId).toList();
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
    final cards = await getAllCards();
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

      // ✅ 同步到云端
      if (CloudSyncService().isLoggedIn) {
        try {
          await CloudSyncService().syncCard(reset);
        } catch (_) {}
      }
    }
  }
}