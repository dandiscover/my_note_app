// lib/services/pet_service.dart
// 宠物服务（修复保存/加载逻辑）

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/user_settings.dart';

class PetService {
  static const String _key = 'pet_data';
  static const String _settingsKey = 'user_settings';

  Future<Pet?> loadPet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_key);
      if (data == null || data.isEmpty) return null;
      final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
      final pet = Pet.fromMap(map);
      
      // ✅ 调试日志（可移除）
      print('📦 加载宠物: happiness=${pet.happiness}, level=${pet.level}');
      
      return pet;
    } catch (e) {
      print('加载宠物失败: $e');
      return null;
    }
  }

  Future<void> savePet(Pet pet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(pet.toMap());
      await prefs.setString(_key, data);
      
      // ✅ 调试日志（可移除）
      print('💾 保存宠物: happiness=${pet.happiness}, level=${pet.level}');
    } catch (e) {
      print('保存宠物失败: $e');
    }
  }

  String getPetSkin() {
    try {
      return 'default';
    } catch (e) {
      return 'default';
    }
  }

  Future<void> updatePetName(String newName) async {
    final pet = await getOrCreatePet();
    final updated = Pet(
      name: newName,
      level: pet.level,
      exp: pet.exp,
      stage: pet.stage,
      happiness: pet.happiness,
      lastFed: pet.lastFed,
    );
    await savePet(updated);
  }

  Future<void> updatePetSkin(String skin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_settingsKey);
      Map<String, dynamic> settingsMap;
      if (data != null && data.isNotEmpty) {
        settingsMap = jsonDecode(data) as Map<String, dynamic>;
      } else {
        settingsMap = {};
      }
      settingsMap['petSkin'] = skin;
      await prefs.setString(_settingsKey, jsonEncode(settingsMap));
    } catch (e) {
      print('保存皮肤设置失败: $e');
    }
  }

  Future<Pet> getOrCreatePet() async {
    final existing = await loadPet();
    if (existing != null) {
      final updated = existing.dailyUpdate();
      if (updated.happiness != existing.happiness) {
        await savePet(updated);
      }
      return updated;
    }
    final newPet = Pet();
    await savePet(newPet);
    return newPet;
  }

  Future<void> completeTask() async {
    final pet = await getOrCreatePet();
    final updated = pet.completeTask();
    await savePet(updated);
  }

  Future<void> petInteraction() async {
    final pet = await getOrCreatePet();
    final updated = pet.pet();
    await savePet(updated);
  }

  Future<void> resetPet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}