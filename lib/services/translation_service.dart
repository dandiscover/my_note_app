// lib/services/translation_service.dart
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

abstract class TranslationService {
  Future<String> translate(String text, {String targetLang = 'zh'});
}

/// 类名保留为 EmptyTranslationService（历史原因，调用点若存在不受影响），
/// 内部已接入 translator 包真实实现。
///
/// 风险声明：
/// - translator 包爬取 Google Translate 网页，非官方 API，
///   可能随 Google 页面结构变更而失效。
/// - 仅用于教育/演示用途。
/// - 3A 阶段 UI 层不暴露，仍弹「即将上线」；3B 再开出口。
class EmptyTranslationService implements TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  @override
  Future<String> translate(String text, {String targetLang = 'zh'}) async {
    if (text.trim().isEmpty) return text;
    try {
      final result = await _translator.translate(text, to: targetLang);
      return result.text;
    } catch (e) {
      debugPrint('TranslationService: 翻译失败，返回原文。$e');
      return text;
    }
  }
}