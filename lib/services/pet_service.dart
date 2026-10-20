// lib/services/pet_service.dart
// 宠物服务 — 集成云端同步（迁 DB）

import '../database_service.dart';
import '../models/pet.dart';
import 'sync/cloud_sync_service.dart';
import 'sync/sync_manager.dart';
import 'settings_service.dart';

class PetService {
  Future<Pet?> loadPet() async {
    try {
      final map = await DatabaseService().loadPet();
      if (map == null) return null;
      return Pet.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> savePet(Pet pet) async {
    try {
      await DatabaseService().savePet(pet.toMap());
    } catch (e) {
      print('保存宠物失败: $e');
    }
  }

  String getPetSkin() {
    return 'default';
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

    if (CloudSyncService().isLoggedIn) {
      try {
        await CloudSyncService().syncPet(updated);
      } catch (_) {}
    }
  }

  Future<void> updatePetSkin(String skin) async {
    await SettingsService().update((settings) async {
      settings.petSkin = skin;
    });
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

    if (CloudSyncService().isLoggedIn) {
      try {
        await CloudSyncService().syncPet(updated);
        SyncManager().markClean();
      } catch (e) {
        SyncManager().markDirty();
      }
    }
  }

  Future<void> petInteraction() async {
    final pet = await getOrCreatePet();
    final updated = pet.pet();
    await savePet(updated);

    if (CloudSyncService().isLoggedIn) {
      try {
        await CloudSyncService().syncPet(updated);
      } catch (_) {}
    }
  }

  Future<void> resetPet() async {
    await DatabaseService().clearPet();
  }
}