// lib/services/translation_service.dart
import 'package:flutter/material.dart';

abstract class TranslationService {
  Future<String> translate(String text, {String targetLang = 'zh'});
}

class EmptyTranslationService implements TranslationService {
  @override
  Future<String> translate(String text, {String targetLang = 'zh'}) async {
    debugPrint('TranslationService: 尚未接入，文本="$text", 目标语言=$targetLang');
    return '[翻译尚未接入]';
  }
}