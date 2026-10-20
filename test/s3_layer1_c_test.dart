@TestOn('vm')
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database/database.dart';
import 'package:my_note_app/database_service.dart';
import 'package:my_note_app/models/card.dart';
import 'package:my_note_app/services/card_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('L1-2 卡片（CardService）', () {
    late AppDatabase db;
    late DatabaseService dbService;
    late CardService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dbService = DatabaseService.forTesting(db);
      service = CardService.forTesting(dbService);
    });

    tearDown(() async {
      await db.close();
    });

    CardModel makeCard(String id) => CardModel(
          id: id,
          cardType: CardType.guide,
          sourceType: 'note',
          sourceId: 'src_$id',
        );

    test('addCard → getCard 返回同 id；getAllCards 含此卡', () async {
      await service.addCard(makeCard('c1'));
      final got = await service.getCard('c1');
      expect(got, isNotNull);
      expect(got!.id, 'c1');
      final all = await service.getAllCards();
      expect(all.where((c) => c.id == 'c1').length, 1);
    });

    test('getAllCards 懒加载 system_guide_card（首次访问自动补）', () async {
      final all = await service.getAllCards();
      expect(all.where((c) => c.id == 'system_guide_card').length, 1,
          reason: 'card_service.dart:24-31：getAllCards 懒加载 guide card');
    });

    test('updateCard 修改后 getCard 反映', () async {
      await service.addCard(makeCard('c2'));
      final updated = CardModel(
        id: 'c2',
        cardType: CardType.guide,
        sourceType: 'note',
        sourceId: 'src_c2',
        sourceTitle: 'updated_title',
      );
      await service.updateCard(updated);
      final after = await service.getCard('c2');
      expect(after!.sourceTitle, 'updated_title');
    });

    test('deleteCard 后 getCard 为 null', () async {
      await service.addCard(makeCard('c3'));
      await service.deleteCard('c3');
      final got = await service.getCard('c3');
      expect(got, isNull);
    });

    test('addCard 增量：两张卡均可查回', () async {
      await service.addCard(makeCard('c4'));
      await service.addCard(makeCard('c5'));
      final all = await service.getAllCards();
      expect(all.where((c) => c.id == 'c4').length, 1);
      expect(all.where((c) => c.id == 'c5').length, 1);
    });
  });
}