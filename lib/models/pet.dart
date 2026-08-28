// lib/models/pet.dart
// 宠物数据模型 — 8阶段成长：水滴→星云脑

import 'dart:convert';
import 'dart:developer';

enum PetStage {
  droplet,   // 💧 水滴 (Lv.1)
  steam,     // ♨️ 蒸汽 (Lv.2)
  mist,      // 🌫️ 雾 (Lv.3)
  cloud,     // ☁️ 云 (Lv.4-5)
  sunny,     // 🌤️ 晴 (Lv.6)
  rainy,     // 🌦️ 雨 (Lv.7)
  glowing,   // ⛅✨ 辉光云 (Lv.8-9)
  brain,     // 🌌 星云脑 (Lv.10)
}

class Pet {
  String name;
  int level;
  int exp;
  PetStage stage;
  int happiness;
  int lastFed;

  Pet({
    this.name = '小云',
    this.level = 1,
    this.exp = 0,
    this.stage = PetStage.droplet,
    this.happiness = 80,
    this.lastFed = 0,
  });

  int get maxHappiness => 100;
  int get nextLevelExp => level * 20 + 10;

  static PetStage getStageForLevel(int level) {
    if (level <= 1) return PetStage.droplet;
    if (level == 2) return PetStage.steam;
    if (level == 3) return PetStage.mist;
    if (level <= 5) return PetStage.cloud;
    if (level == 6) return PetStage.sunny;
    if (level == 7) return PetStage.rainy;
    if (level <= 9) return PetStage.glowing;
    return PetStage.brain;
  }

  String get stageLabel {
    switch (stage) {
      case PetStage.droplet:
        return '水滴';
      case PetStage.steam:
        return '蒸汽';
      case PetStage.mist:
        return '雾';
      case PetStage.cloud:
        return '云';
      case PetStage.sunny:
        return '晴';
      case PetStage.rainy:
        return '雨';
      case PetStage.glowing:
        return '辉光云';
      case PetStage.brain:
        return '星云脑';
    }
  }

  String get stageIcon {
    switch (stage) {
      case PetStage.droplet:
        return '💧';
      case PetStage.steam:
        return '♨️';
      case PetStage.mist:
        return '🌫️';
      case PetStage.cloud:
        return '☁️';
      case PetStage.sunny:
        return '🌤️';
      case PetStage.rainy:
        return '🌦️';
      case PetStage.glowing:
        return '⛅✨';
      case PetStage.brain:
        return '🌌';
    }
  }

  String get emoji {
    if (happiness <= 20) return '😢';
    if (happiness <= 50) return '😐';
    return '😊';
  }

  Pet completeTask() {
    final newExp = exp + 15;
    int newLevel = level;
    int remainingExp = newExp;

    while (remainingExp >= nextLevelExp && newLevel < 10) {
      remainingExp -= nextLevelExp;
      newLevel++;
    }

    return Pet(
      name: name,
      level: newLevel,
      exp: remainingExp,
      stage: Pet.getStageForLevel(newLevel),
      happiness: (happiness + 5).clamp(0, maxHappiness),
      lastFed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// ✅ 修复：lastFed = 0 时视为新宠物，不扣幸福感
  Pet dailyUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // 如果 lastFed == 0，说明是新宠物，设置为当前时间，不扣幸福感
    if (lastFed == 0) {
      return Pet(
        name: name,
        level: level,
        exp: exp,
        stage: stage,
        happiness: happiness,
        lastFed: now,
      );
    }

    final daysSinceFed = (now - lastFed) ~/ (24 * 60 * 60);
    return Pet(
      name: name,
      level: level,
      exp: exp,
      stage: stage,
      happiness: (happiness - daysSinceFed * 2).clamp(0, maxHappiness),
      lastFed: lastFed,
    );
  }

  Pet pet() {
    return Pet(
      name: name,
      level: level,
      exp: exp,
      stage: stage,
      happiness: (happiness + 2).clamp(0, maxHappiness),
      lastFed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'exp': exp,
      'stage': stage.name,
      'happiness': happiness,
      'lastFed': lastFed,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    final happinessRaw = map['happiness'] ?? 80;
    final lastFedRaw = map['lastFed'] ?? 0;

    return Pet(
      name: map['name'] ?? '小云',
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      stage: PetStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => PetStage.droplet,
      ),
      happiness: happinessRaw is int ? happinessRaw : (happinessRaw as double).toInt(),
      lastFed: lastFedRaw is int ? lastFedRaw : (lastFedRaw as double).toInt(),
    );
  }
}