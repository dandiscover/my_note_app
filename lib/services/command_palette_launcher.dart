// lib/services/command_palette_launcher.dart
// 命令面板启动器 —— 解 wisdom_page ↔ main.dart 循环依赖

import 'package:flutter/foundation.dart';

class CommandPaletteLauncher {
  static VoidCallback? _handler;

  static void register(VoidCallback handler) => _handler = handler;
  static void unregister() => _handler = null;
  static void open() => _handler?.call();
}