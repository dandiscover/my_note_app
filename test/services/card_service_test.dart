// test/services/card_service_test.dart
// CardService 完整单元测试
// ✅ 修复 1：getCardsBySource 改用命名参数（任务三后签名变更）
// ✅ 修复 2-6：过滤系统预置卡 system_guide_card（懒加载副作用）

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_note_app/services/card_service.dart';
import 'package:my_note_app/models/card.dart';

/// 过滤掉系统预置卡（system_guide_card），只返回用户创建的卡片。
/// 理由：CardService.getAllCards() 首次调用会懒加载 system_guide_card，
/// 测试断言需排除它，才能聚焦于用户卡片的行为。
List<CardModel> _userCards(List<CardModel> all) {
  return all.where((c) => c.id != 'system_guide_card').toList();
}

void main() {
  late CardService cardService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    cardService = CardService();
  });

  // ─── 组1：基础 CRUD ──────────────────────────────────────

  group('基础 CRUD', () {
    test('空数据应返回空列表', () async {
      final cards = _userCards(await cardService.getAllCards());
      expect(cards, isEmpty);
    });

    test('添加卡片后应能获取', () async {
      final card = CardModel(
        id: 'card_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        sourceTitle: '测试笔记',
        front: '测试正面',
        back: '测试背面',
      );

      await cardService.addCard(card);
      final cards = _userCards(await cardService.getAllCards());

      expect(cards.length, 1);
      expect(cards.first.id, 'card_1');
      expect(cards.first.front, '测试正面');
      expect(cards.first.back, '测试背面');
    });

    test('更新卡片应修改内容', () async {
      final card = CardModel(
        id: 'card_2',
        cardType: CardType.indexCard,
        sourceType: 'note',
        sourceId: 'note_2',
        indexTitle: '原始标题',
        highlight: '原始高光',
      );

      await cardService.addCard(card);

      final updated = card.copyWith(
        indexTitle: '更新标题',
        highlight: '更新高光',
      );
      await cardService.updateCard(updated);

      final cards = _userCards(await cardService.getAllCards());
      expect(cards.first.indexTitle, '更新标题');
      expect(cards.first.highlight, '更新高光');
    });

    test('删除卡片应移除', () async {
      final card = CardModel(
        id: 'card_3',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_3',
      );

      await cardService.addCard(card);
      await cardService.deleteCard('card_3');

      final cards = _userCards(await cardService.getAllCards());
      expect(cards, isEmpty);
    });

    test('批量添加卡片应全部保存', () async {
      final cards = [
        CardModel(
          id: 'batch_1',
          cardType: CardType.review,
          sourceType: 'note',
          sourceId: 'note_1',
        ),
        CardModel(
          id: 'batch_2',
          cardType: CardType.indexCard,
          sourceType: 'note',
          sourceId: 'note_1',
        ),
        CardModel(
          id: 'batch_3',
          cardType: CardType.qa,
          sourceType: 'note',
          sourceId: 'note_1',
        ),
      ];

      await cardService.addCards(cards);
      final all = _userCards(await cardService.getAllCards());
      expect(all.length, 3);
    });
  });

  // ─── 组2：6种卡片类型 ────────────────────────────────────

  group('6种卡片类型', () {
    test('应支持全部6种卡片类型', () async {
      final types = [
        CardType.review,
        CardType.indexCard,
        CardType.qa,
        CardType.fill,
        CardType.choice,
        CardType.truefalse,
      ];

      for (var type in types) {
        await cardService.addCard(CardModel(
          id: 'type_${type.name}',
          cardType: type,
          sourceType: 'note',
          sourceId: 'note_1',
        ));
      }

      final cards = _userCards(await cardService.getAllCards());
      final typeNames = cards.map((c) => c.cardType).toSet();
      expect(typeNames.length, 6);
    });

    test('getCardsByCardType 应筛选正确类型', () async {
      await cardService.addCard(CardModel(
        id: 'filter_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
      ));
      await cardService.addCard(CardModel(
        id: 'filter_2',
        cardType: CardType.indexCard,
        sourceType: 'note',
        sourceId: 'note_1',
      ));

      final reviewCards = await cardService.getCardsByCardType(CardType.review);
      expect(reviewCards.length, 1);
      expect(reviewCards.first.cardType, CardType.review);
    });

    test('getCardsBySource 应筛选正确来源', () async {
      await cardService.addCard(CardModel(
        id: 'source_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
      ));
      await cardService.addCard(CardModel(
        id: 'source_2',
        cardType: CardType.indexCard,
        sourceType: 'note',
        sourceId: 'note_2',
      ));

      // ✅ 修复：命名参数
      final cards = await cardService.getCardsBySource(
        sourceType: 'note',
        sourceId: 'note_1',
      );
      expect(cards.length, 1);
      expect(cards.first.sourceId, 'note_1');
    });
  });

  // ─── 组3：复习调度 ────────────────────────────────────────

  group('复习调度 (艾宾浩斯)', () {
    test('新卡片初始阶段为0', () async {
      final card = CardModel(
        id: 'stage_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        front: '测试',
        back: '测试',
      );

      await cardService.addCard(card);
      final cards = _userCards(await cardService.getAllCards());
      expect(cards.first.stage, 0);
      expect(cards.first.mastered, false);
    });

    test('rateRemembered 推进1个阶段', () async {
      final card = CardModel(
        id: 'stage_2',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        front: '测试',
        back: '测试',
      );

      await cardService.addCard(card);
      await cardService.rateRemembered(card);

      final cards = _userCards(await cardService.getAllCards());
      expect(cards.first.stage, 1);
      expect(cards.first.totalReviews, 1);
    });

    test('连续记住7次后卡片掌握', () async {
      final card = CardModel(
        id: 'master_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        front: '测试',
        back: '测试',
      );

      await cardService.addCard(card);

      // 连续记住7次
      var currentCard = card;
      for (var i = 0; i < 7; i++) {
        await cardService.rateRemembered(currentCard);
        final cards = _userCards(await cardService.getAllCards());
        currentCard = cards.first;
      }

      final finalCards = _userCards(await cardService.getAllCards());
      expect(finalCards.first.mastered, true);
      expect(finalCards.first.stage, 7);
    });

    test('rateForgotten 重置卡片阶段', () async {
      final card = CardModel(
        id: 'forget_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        front: '测试',
        back: '测试',
      );

      await cardService.addCard(card);

      // 先记住3次，然后忘记
      var currentCard = card;
      for (var i = 0; i < 3; i++) {
        await cardService.rateRemembered(currentCard);
        final cards = _userCards(await cardService.getAllCards());
        currentCard = cards.first;
      }

      // 忘记
      final cardsBefore = _userCards(await cardService.getAllCards());
      await cardService.rateForgotten(cardsBefore.first);

      final cardsAfter = _userCards(await cardService.getAllCards());
      expect(cardsAfter.first.stage, 0);
      expect(cardsAfter.first.failedCount, 1);
    });

    test('getDueCards 应返回需要复习的卡片', () async {
      // 添加一张已掌握的卡片（不应返回）
      await cardService.addCard(CardModel(
        id: 'due_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        mastered: true,
        nextReviewDate: DateTime.now().add(Duration(days: 180)),
      ));

      // 添加一张待复习的卡片
      await cardService.addCard(CardModel(
        id: 'due_2',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        mastered: false,
        nextReviewDate: DateTime.now().subtract(Duration(days: 1)),
      ));

      final dueCards = await cardService.getDueCards();
      expect(dueCards.length, 1);
      expect(dueCards.first.id, 'due_2');
    });
  });

  // ─── 组4：统计 ────────────────────────────────────────────

  group('统计功能', () {
    test('getStats 应返回正确统计', () async {
      // 添加5张卡片：2张掌握，3张学习中（其中2张待复习）
      for (var i = 0; i < 5; i++) {
        final isMastered = i < 2;
        final isDue = i >= 3;
        await cardService.addCard(CardModel(
          id: 'stats_$i',
          cardType: CardType.review,
          sourceType: 'note',
          sourceId: 'note_1',
          front: '测试$i',
          back: '测试$i',
          stage: isMastered ? 7 : 3,
          mastered: isMastered,
          nextReviewDate: isDue
              ? DateTime.now().subtract(Duration(days: 1))
              : DateTime.now().add(Duration(days: 10)),
        ));
      }

      final stats = await cardService.getStats();
      expect(stats['total'], 5);
      expect(stats['mastered'], 2);
      expect(stats['learning'], 3);
      expect(stats['due'], 2);
    });
  });

  // ─── 组5：重置卡片 ────────────────────────────────────────

  group('重置卡片', () {
    test('resetCard 应重置为初始状态', () async {
      final card = CardModel(
        id: 'reset_1',
        cardType: CardType.review,
        sourceType: 'note',
        sourceId: 'note_1',
        front: '测试',
        back: '测试',
        stage: 5,
        mastered: false,
        totalReviews: 10,
        failedCount: 2,
        memoryLevel: 0.8,
      );

      await cardService.addCard(card);
      await cardService.resetCard('reset_1');

      final cards = _userCards(await cardService.getAllCards());
      expect(cards.first.stage, 0);
      expect(cards.first.mastered, false);
      expect(cards.first.totalReviews, 0);
      expect(cards.first.failedCount, 0);
      expect(cards.first.memoryLevel, 0.3);
    });
  });
}