// lib/web_shortcut_stub.dart
// 桌面端快捷键桩（测试环境兼容）

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebShortcutManager {
  final Function(String) onExecute;
  final Function(String) onShowSnackBar;

  WebShortcutManager({
    required this.onExecute,
    required this.onShowSnackBar,
  });

  void startListening() {
    // 桌面端或测试环境不执行
    if (kIsWeb) {
      // Web 环境不在此文件处理
    }
  }

  void dispose() {
    // 空实现
  }
}