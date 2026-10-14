// lib/services/writing_session_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WritingSession {
  final String id;
  final String noteId;
  final DateTime startAt;
  final DateTime endAt;
  final int wordCount;
  final int pausedSeconds;

  WritingSession({
    String? id,
    required this.noteId,
    required this.startAt,
    required this.endAt,
    required this.wordCount,
    this.pausedSeconds = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  int get durationSeconds =>
      endAt.difference(startAt).inSeconds - pausedSeconds;

  Map<String, dynamic> toMap() => {
        'id': id,
        'noteId': noteId,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'wordCount': wordCount,
        'pausedSeconds': pausedSeconds,
      };

  factory WritingSession.fromMap(Map<String, dynamic> m) => WritingSession(
        id: m['id'] as String?,
        noteId: m['noteId'] as String,
        startAt: DateTime.parse(m['startAt'] as String),
        endAt: DateTime.parse(m['endAt'] as String),
        wordCount: m['wordCount'] as int? ?? 0,
        pausedSeconds: m['pausedSeconds'] as int? ?? 0,
      );
}

class WritingSessionService {
  static const String _key = 'writing_sessions';
  static const int _retentionDays = 365;

  static final WritingSessionService _instance =
      WritingSessionService._internal();
  factory WritingSessionService() => _instance;
  WritingSessionService._internal();

  String? _currentNoteId;
  DateTime? _sessionStart;
  int _startWordCount = 0;
  int _currentWordCount = 0;
  int _pausedSeconds = 0;
  DateTime? _pauseStart;
  Timer? _pauseTimer;
  Timer? _endTimer;

  void startSession(String noteId, int wordCount) {
    if (_currentNoteId != null) endSession();
    _currentNoteId = noteId;
    _sessionStart = DateTime.now();
    _startWordCount = wordCount;
    _currentWordCount = wordCount;
    _pausedSeconds = 0;
    _pauseStart = null;
    _resetTimers();
  }

  void onInput(int wordCount, {String? noteId}) {
    if (_currentNoteId == null) {
      if (noteId == null || noteId.isEmpty) return;
      startSession(noteId, wordCount);
      return;
    }
    if (_pauseStart != null) {
      _pausedSeconds += DateTime.now().difference(_pauseStart!).inSeconds;
      _pauseStart = null;
    }
    _currentWordCount = wordCount;
    _resetTimers();
  }

  void _resetTimers() {
    _pauseTimer?.cancel();
    _endTimer?.cancel();
    _pauseTimer = Timer(const Duration(minutes: 5), () {
      _pauseStart = DateTime.now();
    });
    _endTimer = Timer(const Duration(minutes: 30), () {
      endSession();
    });
  }

  Future<void> endSession() async {
    if (_currentNoteId == null || _sessionStart == null) return;
    if (_pauseStart != null) {
      _pausedSeconds += DateTime.now().difference(_pauseStart!).inSeconds;
      _pauseStart = null;
    }
    _pauseTimer?.cancel();
    _endTimer?.cancel();

    final session = WritingSession(
      noteId: _currentNoteId!,
      startAt: _sessionStart!,
      endAt: DateTime.now(),
      wordCount: _currentWordCount - _startWordCount,
      pausedSeconds: _pausedSeconds,
    );
    _currentNoteId = null;
    _sessionStart = null;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final list = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        for (final e in (jsonDecode(raw) as List)) {
          list.add(Map<String, dynamic>.from(e as Map));
        }
      } catch (_) {}
    }
    list.add(session.toMap());
    final cutoff =
        DateTime.now().subtract(const Duration(days: _retentionDays));
    list.removeWhere((m) {
      final d = DateTime.tryParse(m['startAt'] as String? ?? '');
      return d != null && d.isBefore(cutoff);
    });
    await prefs.setString(_key, jsonEncode(list));
  }

  Future<List<WritingSession>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) =>
              WritingSession.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getTodayWordCount() async {
    final all = await _loadAll();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int total = 0;
    for (final s in all) {
      final d = DateTime(s.startAt.year, s.startAt.month, s.startAt.day);
      if (d == today) total += s.wordCount;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getDailyLogs(int days) async {
    final all = await _loadAll();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final byDay = <String, Map<String, dynamic>>{};
    for (final s in all) {
      if (s.startAt.isBefore(cutoff)) continue;
      final key =
          '${s.startAt.year}-${s.startAt.month.toString().padLeft(2, '0')}-${s.startAt.day.toString().padLeft(2, '0')}';
      final entry = byDay.putIfAbsent(
        key,
        () => {'date': key, 'duration': 0, 'words': 0, 'sessions': 0},
      );
      entry['duration'] = (entry['duration'] as int) + s.durationSeconds;
      entry['words'] = (entry['words'] as int) + s.wordCount;
      entry['sessions'] = (entry['sessions'] as int) + 1;
    }
    final list = byDay.values.toList();
    list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return list;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}