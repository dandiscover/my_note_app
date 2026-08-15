import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/keyboard_shortcut.dart';

class KeyboardShortcutManager {
  static const String _key = 'keyboard_shortcuts';

  static final KeyboardShortcutManager _instance = KeyboardShortcutManager._internal();
  factory KeyboardShortcutManager() => _instance;
  KeyboardShortcutManager._internal();

  List<KeyboardShortcut> _shortcuts = [];
  bool _isLoaded = false;

  // 加载快捷键配置
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) {
      _shortcuts = KeyboardShortcut.defaults;
      await save();
    } else {
      try {
        final list = jsonDecode(data) as List;
        _shortcuts = list.map((m) => KeyboardShortcut.fromMap(Map<String, dynamic>.from(m))).toList();
        _ensureDefaults();
      } catch (_) {
        _shortcuts = KeyboardShortcut.defaults;
        await save();
      }
    }
    _isLoaded = true;
  }

  void _ensureDefaults() {
    final existingIds = _shortcuts.map((s) => s.id).toSet();
    for (var def in KeyboardShortcut.defaults) {
      if (!existingIds.contains(def.id)) {
        _shortcuts.add(def);
      }
    }
  }

  // 保存快捷键配置
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_shortcuts.map((s) => s.toMap()).toList());
    await prefs.setString(_key, data);
  }

  // 获取所有快捷键
  List<KeyboardShortcut> get all => List.from(_shortcuts);

  // 获取某个快捷键（通过ID）
  KeyboardShortcut? getById(String id) {
    try {
      return _shortcuts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // 获取某个快捷键（通过按键匹配）
  KeyboardShortcut? match(String key, bool isCtrl, bool isShift, bool isAlt) {
    final lowerKey = key.toLowerCase();
    for (var s in _shortcuts) {
      if (s.key.toLowerCase() == lowerKey &&
          s.isCtrlRequired == isCtrl &&
          s.isShiftRequired == isShift &&
          s.isAltRequired == isAlt) {
        return s;
      }
    }
    return null;
  }

  // 更新快捷键
  Future<void> update(String id, KeyboardShortcut newShortcut) async {
    final index = _shortcuts.indexWhere((s) => s.id == id);
    if (index != -1) {
      // 检查是否与其他快捷键冲突
      final conflict = _shortcuts.where((s) =>
        s.id != id &&
        s.key.toLowerCase() == newShortcut.key.toLowerCase() &&
        s.isCtrlRequired == newShortcut.isCtrlRequired &&
        s.isShiftRequired == newShortcut.isShiftRequired &&
        s.isAltRequired == newShortcut.isAltRequired
      ).toList();
      if (conflict.isNotEmpty) {
        throw Exception('快捷键冲突：${conflict.first.name} 已使用此组合');
      }
      _shortcuts[index] = newShortcut;
      await save();
    }
  }

  // 重置为默认
  Future<void> reset() async {
    _shortcuts = KeyboardShortcut.defaults;
    await save();
  }

  // 获取保存动作的快捷键
  KeyboardShortcut? get saveShortcut => getById('save');
  KeyboardShortcut? get undoShortcut => getById('undo');
  KeyboardShortcut? get redoShortcut => getById('redo');
  KeyboardShortcut? get boldShortcut => getById('bold');
  KeyboardShortcut? get italicShortcut => getById('italic');
  KeyboardShortcut? get escapeShortcut => getById('escape');
}