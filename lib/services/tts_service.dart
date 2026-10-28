// lib/services/tts_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
}

/// 类名保留为 EmptyTtsService（历史原因，调用点若存在不受影响），
/// 内部已接入 flutter_tts 真实实现。
///
/// 环境依赖（Windows）：
/// - Windows 端依赖系统已安装的语音包。
/// - 中文语音需用户在「Windows 设置 → 时间和语言 → 语音」中
///   自行安装「中文（简体）」语音包，否则 speak 可能无声音。
/// - pause 在 Windows 上不支持，本类只暴露 speak / stop。
class EmptyTtsService implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('TtsService: 初始化失败（可能缺少中文语音包）$e');
    }
    _initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TtsService: speak 失败 $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TtsService: stop 失败 $e');
    }
  }
}