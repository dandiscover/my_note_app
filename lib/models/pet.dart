// lib/models/pet.dart
// 宠物数据模型 — 7阶段成长：水滴→云脑

import 'dart:convert';

enum PetStage {
  droplet,    // 1滴 💧 (Lv.1)
  droplets,   // 多滴 💧💧 (Lv.2)
  cloudlet,   // 小云 ☁️ (Lv.3-4)
  cloud,      // 大云 ☁️☁️ (Lv.5-6)
  cloudbrain, // 云脑 🧠✨ (Lv.7+)
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
    if (level <= 2) return PetStage.droplets;
    if (level <= 4) return PetStage.cloudlet;
    if (level <= 6) return PetStage.cloud;
    return PetStage.cloudbrain;
  }

  String get stageLabel {
    switch (stage) {
      case PetStage.droplet:
        return '小水滴';
      case PetStage.droplets:
        return '水滴群';
      case PetStage.cloudlet:
        return '小云';
      case PetStage.cloud:
        return '云';
      case PetStage.cloudbrain:
        return '云脑';
    }
  }

  String get stageIcon {
    switch (stage) {
      case PetStage.droplet:
        return '💧';
      case PetStage.droplets:
        return '💧💧';
      case PetStage.cloudlet:
        return '☁️';
      case PetStage.cloud:
        return '☁️☁️';
      case PetStage.cloudbrain:
        return '🧠';
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

    // 🔧 修复1：使用 Pet.getStageForLevel 而不是 PetStage.getStageForLevel
    return Pet(
      name: name,
      level: newLevel,
      exp: remainingExp,
      stage: Pet.getStageForLevel(newLevel),
      happiness: (happiness + 5).clamp(0, maxHappiness),
      lastFed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Pet dailyUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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
    return Pet(
      name: map['name'] ?? '小云',
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      stage: PetStage.values.firstWhere(
        (e) => e.name == map['stage'],
        orElse: () => PetStage.droplet,
      ),
      happiness: map['happiness'] ?? 80,
      lastFed: map['lastFed'] ?? 0,
    );
  }
}