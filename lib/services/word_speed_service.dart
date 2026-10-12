// lib/services/word_speed_service.dart

import 'dart:async';

class WordSpeedService {
  final List<_Sample> _samples = [];
  Timer? _resetTimer;

  void onInput(int wordCount) {
    _samples.add(_Sample(DateTime.now(), wordCount));
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    _samples.removeWhere((s) => s.time.isBefore(cutoff));
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 30), () {
      _samples.clear();
    });
  }

  int get speed {
    if (_samples.length < 2) return 0;
    final first = _samples.first;
    final last = _samples.last;
    final seconds = last.time.difference(first.time).inSeconds;
    if (seconds < 1) return 0;
    final delta = last.wordCount - first.wordCount;
    return ((delta / seconds) * 60).round().clamp(0, 9999);
  }

  void reset() {
    _samples.clear();
    _resetTimer?.cancel();
  }

  void dispose() {
    _samples.clear();
    _resetTimer?.cancel();
    _resetTimer = null;
  }
}

class _Sample {
  final DateTime time;
  final int wordCount;
  _Sample(this.time, this.wordCount);
}