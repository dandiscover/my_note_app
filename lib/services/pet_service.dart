// lib/services/pet_service.dart
// 宠物服务

import 'dart:convert'; // 🆕 添加这行
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

class PetService {
  static const String _key = 'pet_data';

  Future<Pet?> loadPet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_key);
      if (data == null || data.isEmpty) return null;
      final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
      return Pet.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> savePet(Pet pet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(pet.toMap()));
    } catch (e) {
      print('保存宠物失败: $e');
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