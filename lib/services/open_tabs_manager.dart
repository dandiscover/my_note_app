// lib/services/open_tabs_manager.dart
// 已开笔记标签管理器 —— A2 标签条数据源

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../database_service.dart';

class OpenTab {
  final String noteId;
  final String title;
  const OpenTab({required this.noteId, required this.title});

  Map<String, dynamic> toJson() => {'noteId': noteId, 'title': title};
  factory OpenTab.fromJson(Map<String, dynamic> j) =>
      OpenTab(noteId: j['noteId'] as String, title: j['title'] as String);
}

class OpenTabsManager {
  OpenTabsManager._();
  static final OpenTabsManager instance = OpenTabsManager._();

  static const String _prefsKey = 'open_tabs';
  static final ValueNotifier<List<OpenTab>> tabs = ValueNotifier([]);
  static final ValueNotifier<String?> activeTabId = ValueNotifier(null);
  static final ValueNotifier<int> reopenTick = ValueNotifier(0);

  /// 启动读 —— 校验 noteId 存在性 —— 已删跳过
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      final loaded = list
          .map((e) => OpenTab.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final allNotes =
          await DatabaseService().getAllNotes(includeDeleted: false);
      final validIds = allNotes.map((m) => m['id'] as String).toSet();
      final filtered =
          loaded.where((t) => validIds.contains(t.noteId)).toList();
      tabs.value = filtered;
      if (filtered.isNotEmpty) {
        activeTabId.value = filtered.first.noteId;
      }
    } catch (e) {
      debugPrint('OpenTabsManager.load 失败: $e');
    }
  }

  void open(OpenTab tab) {
    final current = tabs.value;
    final exists = current.any((t) => t.noteId == tab.noteId);
    if (!exists) {
      tabs.value = [...current, tab];
    }
    activeTabId.value = tab.noteId;
    reopenTick.value++;
    _persist();
  }

  void close(String noteId) {
    final current = tabs.value;
    final removed = current.where((t) => t.noteId != noteId).toList();
    tabs.value = removed;
    if (activeTabId.value == noteId) {
      activeTabId.value = removed.isEmpty ? null : removed.first.noteId;
    }
    _persist();
  }

  void activate(String noteId) {
    activeTabId.value = noteId;
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(tabs.value.map((t) => t.toJson()).toList());
    await prefs.setString(_prefsKey, json);
  }
}