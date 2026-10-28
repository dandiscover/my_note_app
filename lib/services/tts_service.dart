// lib/services/tts_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
}

/// 诊断+加固版：类名保留 EmptyTtsService，内部含全量 DEBUG 日志。
/// Windows 语音包依赖系统，中文 voice 需系统已安装。
class EmptyTtsService implements TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // 1. 打印系统支持的语言
    try {
      final languages = await _flutterTts.getLanguages;
      debugPrint('DEBUG TTS getLanguages => $languages');
    } catch (e) {
      debugPrint('DEBUG TTS getLanguages 失败: $e');
    }

    // 2. 打印系统支持的 voices，并检测中文 voice
    bool hasChineseVoice = false;
    try {
      final voicesRaw = await _flutterTts.getVoices;
      debugPrint('DEBUG TTS getVoices 类型: ${voicesRaw.runtimeType}');
      if (voicesRaw is List) {
        for (final v in voicesRaw) {
          if (v is Map) {
            final locale = v['locale'] ?? v['language'] ?? v['lang'] ?? '';
            final name = v['name'] ?? '';
            final gender = v['gender'] ?? '';
            final id = v['identifier'] ?? '';
            debugPrint(
              'DEBUG TTS voice => locale=$locale name=$name gender=$gender id=$id',
            );
            if (locale.toString().toLowerCase().startsWith('zh')) {
              hasChineseVoice = true;
            }
            if (id.toString().toLowerCase().contains('zh')) {
              hasChineseVoice = true;
            }
          } else {
            debugPrint('DEBUG TTS voice(raw) => $v');
            if (v.toString().toLowerCase().contains('zh')) {
              hasChineseVoice = true;
            }
          }
        }
      } else {
        debugPrint('DEBUG TTS getVoices 非 List: $voicesRaw');
      }
    } catch (e) {
      debugPrint('DEBUG TTS getVoices 失败: $e');
    }
    if (!hasChineseVoice) {
      debugPrint('🔴 TTS 警告：系统未找到 zh 开头的 voice，朗读中文可能无声');
    } else {
      debugPrint('DEBUG TTS 已检测到中文 voice');
    }

    // 3. 强制基础参数
    try {
      await _flutterTts.setLanguage('zh-CN');
      debugPrint('DEBUG TTS setLanguage(zh-CN) 完成');
    } catch (e) {
      debugPrint('DEBUG TTS setLanguage 失败: $e');
    }
    try {
      await _flutterTts.setVolume(1.0);
      debugPrint('DEBUG TTS setVolume(1.0) 完成');
    } catch (e) {
      debugPrint('DEBUG TTS setVolume 失败: $e');
    }
    try {
      await _flutterTts.setPitch(1.0);
      debugPrint('DEBUG TTS setPitch(1.0) 完成');
    } catch (e) {
      debugPrint('DEBUG TTS setPitch 失败: $e');
    }
    try {
      await _flutterTts.setSpeechRate(0.5);
      debugPrint('DEBUG TTS setSpeechRate(0.5) 完成');
    } catch (e) {
      debugPrint('DEBUG TTS setSpeechRate 失败: $e');
    }

    // 4. 全量回调
    try {
      _flutterTts.setStartHandler(() => debugPrint('DEBUG TTS: 开始朗读'));
      _flutterTts.setCompletionHandler(() => debugPrint('DEBUG TTS: 朗读完成'));
      _flutterTts.setErrorHandler((msg) => debugPrint('DEBUG TTS 报错: $msg'));
      _flutterTts.setCancelHandler(() => debugPrint('DEBUG TTS: 朗读取消'));
    } catch (e) {
      debugPrint('DEBUG TTS 设置回调失败: $e');
    }

    _initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    try {
      debugPrint('DEBUG TTS speak 入参长度: ${text.length}');
      final r = await _flutterTts.speak(text);
      debugPrint('DEBUG TTS speak 返回: $r');
    } catch (e) {
      debugPrint('DEBUG TTS speak 异常: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      debugPrint('DEBUG TTS stop 完成');
    } catch (e) {
      debugPrint('DEBUG TTS stop 失败: $e');
    }
  }
}