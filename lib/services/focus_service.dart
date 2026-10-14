// lib/services/focus_service.dart
// 专注计时服务 — R-7-3a 单A 迁 DB

import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';

class FocusSession {
  final String id;
  final DateTime startAt;
  final int minutes;

  FocusSession({
    String? id,
    required this.startAt,
    required this.minutes,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() => {
        'id': id,
        'start_at': startAt.toIso8601String(),
        'minutes': minutes,
      };

  factory FocusSession.fromMap(Map<String, dynamic> m) => FocusSession(
        id: m['id'] as String?,
        startAt: DateTime.parse(m['start_at'] as String),
        minutes: m['minutes'] as int? ?? 0,
      );
}

class FocusService {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  static const int _retentionDays = 365;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 记录一次专注会话
  Future<void> recordFocusSession(int minutes) async {
    final session = FocusSession(
      startAt: DateTime.now(),
      minutes: minutes,
    );
    final db = DatabaseService();
    await db.insertFocusSession(session.toMap());
    final cutoff =
        DateTime.now().subtract(const Duration(days: _retentionDays));
    await db.deleteFocusSessionsBefore(cutoff);
  }

  /// 获取今日专注总时长
  Future<int> getTodayTotal() async {
    final rows = await DatabaseService().getAllFocusSessions();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (final m in rows) {
      final s = FocusSession.fromMap(m);
      if (s.startAt.year == today.year &&
          s.startAt.month == today.month &&
          s.startAt.day == today.day) {
        total += s.minutes;
      }
    }
    return total;
  }

  /// 获取本周专注总时长
  Future<int> getWeekTotal() async {
    final rows = await DatabaseService().getAllFocusSessions();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int total = 0;
    for (final m in rows) {
      final s = FocusSession.fromMap(m);
      if (s.startAt.isAfter(weekStart)) {
        total += s.minutes;
      }
    }
    return total;
  }

  /// 获取总专注次数
  Future<int> getTotalSessions() async {
    final rows = await DatabaseService().getAllFocusSessions();
    return rows.length;
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