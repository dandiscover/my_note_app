import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer';
import '../models/user_settings.dart';

class SettingsService {
  static const String _key = 'user_settings';

  Future<UserSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) {
      return UserSettings();
    }
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      return UserSettings.fromMap(map);
    } catch (_) {
      return UserSettings();
    }
  }

  Future<void> save(UserSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toMap()));
  }

  Future<void> update(Future<void> Function(UserSettings) updater) async {
    final settings = await load();
    await updater(settings);
    await save(settings);
  }
}