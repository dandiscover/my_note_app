// lib/services/settings_service.dart
// 设置服务 — 迁 DB

import '../database_service.dart';
import '../models/user_settings.dart';
import 'sync/cloud_sync_service.dart';
import 'sync/sync_manager.dart';

class SettingsService {
  Future<UserSettings> load() async {
    final map = await DatabaseService().loadSettings();
    if (map == null) return UserSettings();
    try {
      return UserSettings.fromMap(map);
    } catch (_) {
      return UserSettings();
    }
  }

  Future<void> save(UserSettings settings) async {
    await DatabaseService().saveSettings(settings.toMap());
    if (CloudSyncService().isLoggedIn) {
      try {
        await CloudSyncService().syncSettings(settings);
      } catch (_) {
        SyncManager().markDirty();
      }
    }
  }

  Future<void> update(Future<void> Function(UserSettings) updater) async {
    final settings = await load();
    await updater(settings);
    await save(settings);
  }
}