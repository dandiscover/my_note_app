// lib/services/focus_mode_notifier.dart
// 功能批1 B+C：全局专注模式开关

import 'package:flutter/foundation.dart';

/// 专注模式全局开关
/// main.dart 快捷键设值；note_detail_page 监听
final ValueNotifier<bool> focusModeNotifier = ValueNotifier<bool>(false);