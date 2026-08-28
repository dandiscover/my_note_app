// lib/services/focus_service.dart
// 专注计时服务 — 修复异步问题

import 'package:shared_preferences/shared_preferences.dart';

class FocusService {
  static const String _keySessions = 'focus_sessions';
  static const String _keySettings = 'focus_settings';
  static const String _keyTodayTotal = 'focus_today_total';
  static const String _keyWeekTotal = 'focus_week_total';
  static const String _keyTotalSessions = 'focus_total_sessions';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// ✅ 修复：获取会话列表（异步）
  Future<List<String>> _getSessions() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_keySessions) ?? [];
  }

  /// 记录一次专注会话
  Future<void> recordFocusSession(int minutes) async {
    final prefs = await _getPrefs();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 更新今日专注
    final todayKey = 'focus_${today.toIso8601String()}';
    final todayTotal = prefs.getInt(todayKey) ?? 0;
    await prefs.setInt(todayKey, todayTotal + minutes);

    // 更新总次数
    final totalSessions = prefs.getInt(_keyTotalSessions) ?? 0;
    await prefs.setInt(_keyTotalSessions, totalSessions + 1);

    // 保存会话记录
    final sessions = await _getSessions();
    sessions.add('${now.toIso8601String()}|$minutes');
    await prefs.setStringList(_keySessions, sessions);
  }

  /// ✅ 修复：获取今日专注总时长（异步）
  Future<int> getTodayTotal() async {
    final sessions = await _getSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (var session in sessions) {
      final parts = session.split('|');
      if (parts.length == 2) {
        final date = DateTime.tryParse(parts[0]);
        if (date != null &&
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          total += int.parse(parts[1]);
        }
      }
    }
    return total;
  }

  /// ✅ 修复：获取本周专注总时长（异步）
  Future<int> getWeekTotal() async {
    final sessions = await _getSessions();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int total = 0;
    for (var session in sessions) {
      final parts = session.split('|');
      if (parts.length == 2) {
        final date = DateTime.tryParse(parts[0]);
        if (date != null && date.isAfter(weekStart)) {
          total += int.parse(parts[1]);
        }
      }
    }
    return total;
  }

  /// ✅ 修复：获取总专注次数（异步）
  Future<int> getTotalSessions() async {
    final sessions = await _getSessions();
    return sessions.length;
  }

  /// 获取设置
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await _getPrefs();
    return {
      'focusMinutes': prefs.getInt('focus_minutes') ?? 25,
    };
  }

  /// 保存设置
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await _getPrefs();
    if (settings.containsKey('focusMinutes')) {
      await prefs.setInt('focus_minutes', settings['focusMinutes'] as int);
    }
  }
}