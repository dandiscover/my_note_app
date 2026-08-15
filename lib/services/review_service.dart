import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/review_card.dart';

class ReviewService {
  static const String _key = 'review_cards';

  Future<List<ReviewCard>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) return [];
    try {
      final list = jsonDecode(data) as List;
      return list.map((m) => ReviewCard.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<ReviewCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(cards.map((c) => c.toMap()).toList());
    await prefs.setString(_key, data);
  }

  Future<List<ReviewCard>> getDueCards() async {
    final all = await loadAll();
    return all.where((c) => c.isDue).toList();
  }

  Future<int> getDueCount() async {
    final due = await getDueCards();
    return due.length;
  }

  Future<ReviewCard> addCard(ReviewCard card) async {
    final all = await loadAll();
    all.add(card);
    await saveAll(all);
    return card;
  }

  Future<void> removeCard(String cardId) async {
    final all = await loadAll();
    all.removeWhere((c) => c.id == cardId);
    await saveAll(all);
  }

  Future<ReviewCard> reviewCard(String cardId, int quality) async {
    final all = await loadAll();
    final index = all.indexWhere((c) => c.id == cardId);
    if (index == -1) throw Exception('卡片不存在');
    final updated = all[index].review(quality: quality);
    all[index] = updated;
    await saveAll(all);
    return updated;
  }

  Future<ReviewCard> createCardFromNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final card = ReviewCard.fromNote(
      noteId: noteId,
      title: title,
      content: content,
    );
    return await addCard(card);
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final all = await loadAll();
    final due = await getDueCards();
    final today = DateTime.now();
    final reviewedToday = all.where((c) =>
      c.lastReviewedAt != null &&
      c.lastReviewedAt!.year == today.year &&
      c.lastReviewedAt!.month == today.month &&
      c.lastReviewedAt!.day == today.day
    ).toList();

    return {
      'totalCards': all.length,
      'dueCards': due.length,
      'reviewedToday': reviewedToday.length,
      'remaining': due.length - reviewedToday.length,
    };
  }
}