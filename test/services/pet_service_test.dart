// test/services/pet_service_test.dart
// PetService 完整单元测试（修复后）

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_note_app/services/pet_service.dart';
import 'package:my_note_app/models/pet.dart';

void main() {
  late PetService petService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    petService = PetService();
  });

  // ─── 组1：基础功能 ────────────────────────────────────────

  group('基础功能', () {
    test('getOrCreatePet 首次应创建新宠物', () async {
      final pet = await petService.getOrCreatePet();
      expect(pet.name, '小云');
      expect(pet.level, 1);
      expect(pet.stage, PetStage.droplet);
      expect(pet.happiness, 80);
    });

    test('getOrCreatePet 第二次应返回已有宠物', () async {
      final pet1 = await petService.getOrCreatePet();
      final pet2 = await petService.getOrCreatePet();
      expect(pet1.level, pet2.level);
      expect(pet1.name, pet2.name);
    });

    test('保存和加载宠物数据一致', () async {
      final original = Pet(
        name: '测试小云',
        level: 5,
        exp: 60,
        stage: PetStage.cloud,
        happiness: 90,
        lastFed: 1234567890,
      );

      await petService.savePet(original);
      final loaded = await petService.loadPet();

      expect(loaded, isNotNull);
      expect(loaded!.name, '测试小云');
      expect(loaded.level, 5);
      expect(loaded.exp, 60);
      expect(loaded.stage, PetStage.cloud);
      expect(loaded.happiness, 90);
      expect(loaded.lastFed, 1234567890);
    });
  });

  // ─── 组2：完成任务 ────────────────────────────────────────

  group('完成任务', () {
    test('completeTask 应增加经验', () async {
      final pet = await petService.getOrCreatePet();
      final initialExp = pet.exp;
      await petService.completeTask();

      final updated = await petService.getOrCreatePet();
      expect(updated.exp, initialExp + 15);
    });

    test('completeTask 经验足够时应升级', () async {
      final pet = await petService.getOrCreatePet();
      final nearLevelUp = Pet(
        name: pet.name,
        level: pet.level,
        exp: pet.nextLevelExp - 10,
        stage: pet.stage,
        happiness: pet.happiness,
        lastFed: pet.lastFed,
      );
      await petService.savePet(nearLevelUp);

      await petService.completeTask();
      final updated = await petService.getOrCreatePet();
      expect(updated.level, nearLevelUp.level + 1);
    });

    test('连续完成15个任务至少升1级', () async {
      final pet = await petService.getOrCreatePet();
      final initialLevel = pet.level;

      for (var i = 0; i < 15; i++) {
        await petService.completeTask();
      }

      final updated = await petService.getOrCreatePet();
      expect(updated.level, greaterThan(initialLevel));
    });
  });

  // ─── 组3：交互与幸福感 ────────────────────────────────────

  group('交互与幸福感', () {
    test('petInteraction 应增加幸福感', () async {
      // ✅ 修复：先重置，然后创建宠物，确保 lastFed 被设置
      await petService.resetPet();

      // 创建宠物时，lastFed 会被 dailyUpdate 设置为当前时间
      final pet = await petService.getOrCreatePet();
      final initialHappiness = pet.happiness;

      await petService.petInteraction();
      final updated = await petService.getOrCreatePet();

      // ✅ 修复：期望 initialHappiness + 2
      expect(updated.happiness, initialHappiness + 2);
    });

    test('幸福感不应超过100', () async {
      await petService.resetPet();

      // 创建一个幸福感为 99 的宠物
      final pet = Pet(
        name: '测试',
        level: 1,
        exp: 0,
        stage: PetStage.droplet,
        happiness: 99,
        lastFed: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ✅ 设置当前时间
      );
      await petService.savePet(pet);

      await petService.petInteraction();
      final updated = await petService.getOrCreatePet();

      // ✅ 修复：应该达到 100
      expect(updated.happiness, 100);
    });

    test('幸福感不应低于0', () async {
      await petService.resetPet();

      final pet = Pet(
        name: '测试',
        level: 1,
        exp: 0,
        stage: PetStage.droplet,
        happiness: 0,
        lastFed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await petService.savePet(pet);

      final updated = await petService.getOrCreatePet();
      expect(updated.happiness, 0);
    });
  });

  // ─── 组4：每日更新 ────────────────────────────────────────

  group('每日更新', () {
    test('dailyUpdate 应降低未互动的幸福感', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final pet = Pet(
        name: '测试',
        level: 1,
        exp: 0,
        stage: PetStage.droplet,
        happiness: 80,
        lastFed: now - 86400 * 2,
      );
      await petService.savePet(pet);

      final updated = await petService.getOrCreatePet();
      expect(updated.happiness, 76);
    });

    test('近期互动过不扣幸福感', () async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final pet = Pet(
        name: '测试',
        level: 1,
        exp: 0,
        stage: PetStage.droplet,
        happiness: 80,
        lastFed: now - 3600 * 12,
      );
      await petService.savePet(pet);

      final updated = await petService.getOrCreatePet();
      expect(updated.happiness, 80);
    });

    // ✅ 新增测试：lastFed=0 时新宠物不扣幸福感
    test('新宠物 lastFed=0 不扣幸福感', () async {
      await petService.resetPet();

      final pet = Pet(
        name: '新宠物',
        level: 1,
        exp: 0,
        stage: PetStage.droplet,
        happiness: 80,
        lastFed: 0,
      );
      await petService.savePet(pet);

      final updated = await petService.getOrCreatePet();
      // ✅ 应该保持 80，不扣幸福感
      expect(updated.happiness, 80);
      // ✅ lastFed 应该被设置为当前时间
      expect(updated.lastFed, greaterThan(0));
    });
  });

  // ─── 组5：8阶段映射 ───────────────────────────────────────

  group('8阶段映射', () {
    test('等级对应的阶段正确', () {
      final stageMap = {
        1: PetStage.droplet,
        2: PetStage.steam,
        3: PetStage.mist,
        4: PetStage.cloud,
        5: PetStage.cloud,
        6: PetStage.sunny,
        7: PetStage.rainy,
        8: PetStage.glowing,
        9: PetStage.glowing,
        10: PetStage.brain,
      };

      for (var entry in stageMap.entries) {
        final level = entry.key;
        final expected = entry.value;
        final actual = Pet.getStageForLevel(level);
        expect(actual, expected, reason: '等级 $level 应为 $expected');
      }
    });

    test('阶段标签对应正确', () {
      final labelMap = {
        PetStage.droplet: '水滴',
        PetStage.steam: '蒸汽',
        PetStage.mist: '雾',
        PetStage.cloud: '云',
        PetStage.sunny: '晴',
        PetStage.rainy: '雨',
        PetStage.glowing: '辉光云',
        PetStage.brain: '星云脑',
      };

      for (var entry in labelMap.entries) {
        final pet = Pet(stage: entry.key);
        expect(pet.stageLabel, entry.value);
      }
    });

    test('阶段图标对应正确', () {
      final iconMap = {
        PetStage.droplet: '💧',
        PetStage.steam: '♨️',
        PetStage.mist: '🌫️',
        PetStage.cloud: '☁️',
        PetStage.sunny: '🌤️',
        PetStage.rainy: '🌦️',
        PetStage.glowing: '⛅✨',
        PetStage.brain: '🌌',
      };

      for (var entry in iconMap.entries) {
        final pet = Pet(stage: entry.key);
        expect(pet.stageIcon, entry.value);
      }
    });
  });

  // ─── 组6：重置宠物 ────────────────────────────────────────

  group('重置宠物', () {
    test('resetPet 应删除宠物数据', () async {
      await petService.getOrCreatePet();
      await petService.resetPet();

      final pet = await petService.getOrCreatePet();
      expect(pet.level, 1);
    });
  });

  // ─── 组7：宠物名字 ────────────────────────────────────────

  group('宠物名字', () {
    test('updatePetName 应更新名字', () async {
      await petService.getOrCreatePet();
      await petService.updatePetName('新名字');

      final updated = await petService.getOrCreatePet();
      expect(updated.name, '新名字');
    });
  });
}