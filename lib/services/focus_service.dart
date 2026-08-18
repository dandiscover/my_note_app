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

  // 记录一次专注会话
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
    final sessions = prefs.getStringList(_keySessions) ?? [];
    sessions.add('${now.toIso8601String()}|$minutes');
    await prefs.setStringList(_keySessions, sessions);
  }

  // 获取今日专注总时长
  int getTodayTotal() {
    // 简化实现：从会话记录中统计
    final sessions = _getSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (var session in sessions) {
      final parts = session.split('|');
      if (parts.length == 2) {
        final date = DateTime.parse(parts[0]);
        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          total += int.parse(parts[1]);
        }
      }
    }
    return total;
  }

  // 获取本周专注总时长
  int getWeekTotal() {
    final sessions = _getSessions();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int total = 0;
    for (var session in sessions) {
      final parts = session.split('|');
      if (parts.length == 2) {
        final date = DateTime.parse(parts[0]);
        if (date.isAfter(weekStart)) {
          total += int.parse(parts[1]);
        }
      }
    }
    return total;
  }

  // 获取总专注次数
  int getTotalSessions() {
    final sessions = _getSessions();
    return sessions.length;
  }

  List<String> _getSessions() {
    final prefs = SharedPreferences.getInstance();
    return prefs.then((p) => p.getStringList(_keySessions) ?? []).asStream().first as List<String>;
  }

  // 获取设置
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await _getPrefs();
    return {
      'focusMinutes': prefs.getInt('focus_minutes') ?? 25,
    };
  }

  // 保存设置
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await _getPrefs();
    if (settings.containsKey('focusMinutes')) {
      await prefs.setInt('focus_minutes', settings['focusMinutes'] as int);
    }
  }
}