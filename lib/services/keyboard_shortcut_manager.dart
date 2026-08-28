// lib/services/keyboard_shortcut_manager.dart
// 快捷键管理服务 — 支持自定义快捷键
import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/keyboard_shortcut.dart';

class KeyboardShortcutManager {
  static const String _key = 'keyboard_shortcuts';

  List<KeyboardShortcut> all = [];
  KeyboardShortcut? saveShortcut;

  KeyboardShortcutManager() {
    _initDefaults();
  }

  void _initDefaults() {
    all = KeyboardShortcut.defaults;
    saveShortcut = all.firstWhere((s) => s.id == 'save');
  }

  // ─── 加载用户自定义 ─────────────────────────────
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_key);
      if (data == null || data.isEmpty) return;
      final List<dynamic> list = jsonDecode(data);
      for (var item in list) {
        final loaded = KeyboardShortcut.fromJson(item as Map<String, dynamic>);
        final index = all.indexWhere((s) => s.id == loaded.id);
        if (index != -1) {
          all[index] = loaded;
        }
      }
      saveShortcut = all.firstWhere((s) => s.id == 'save');
    } catch (e) {
      print('加载快捷键失败: $e');
    }
  }

  // ─── 保存用户自定义 ─────────────────────────────
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(all.map((s) => s.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (e) {
      print('保存快捷键失败: $e');
    }
  }

  // ─── 🆕 重置所有快捷键为默认 ─────────────────────────────
  Future<void> reset() async {
    _initDefaults();
    await save();
  }

  // ─── 🆕 更新单个快捷键 ─────────────────────────────
  Future<void> update(String id, KeyboardShortcut newShortcut) async {
    final index = all.indexWhere((s) => s.id == id);
    if (index != -1) {
      all[index] = newShortcut;
      await save();
      if (id == 'save') {
        saveShortcut = all[index];
      }
    }
  }

  // ─── 🆕 更新快捷键（通过参数） ─────────────────────────────
  Future<void> updateShortcut(String id, {
    String? key,
    bool? isCtrlRequired,
    bool? isShiftRequired,
    bool? isAltRequired,
  }) async {
    final index = all.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = all[index];
      all[index] = old.copyWith(
        key: key,
        isCtrlRequired: isCtrlRequired,
        isShiftRequired: isShiftRequired,
        isAltRequired: isAltRequired,
      );
      await save();
      if (id == 'save') {
        saveShortcut = all[index];
      }
    }
  }

  // ─── 匹配快捷键 ─────────────────────────────
  KeyboardShortcut? match(String key, bool ctrl, bool shift, bool alt) {
    String normalizedKey = key.toLowerCase();
    if (normalizedKey == 'escape') {
      normalizedKey = 'escape';
    }

    for (var shortcut in all) {
      if (shortcut.key.toLowerCase() == normalizedKey &&
          shortcut.isCtrlRequired == ctrl &&
          shortcut.isShiftRequired == shift &&
          shortcut.isAltRequired == alt) {
        return shortcut;
      }
    }
    return null;
  }
}