// lib/services/tts_service.dart
import 'package:flutter/material.dart';

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
}

class EmptyTtsService implements TtsService {
  @override
  Future<void> speak(String text) async {
    debugPrint('TtsService: 尚未接入，朗读文本="$text"');
  }

  @override
  Future<void> stop() async {}
}