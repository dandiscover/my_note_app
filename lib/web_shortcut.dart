// lib/web_shortcut.dart
// Web 平台专用 — 键盘快捷键拦截

import 'dart:html' as html;
import 'dart:async';

class WebShortcutManager {
  StreamSubscription<html.KeyboardEvent>? _subscription;
  final void Function(String shortcutId) onExecute;
  final void Function(String label) onShowSnackBar;

  WebShortcutManager({
    required this.onExecute,
    required this.onShowSnackBar,
  });

  void startListening() {
    _subscription = html.window.onKeyDown.listen((event) {
      final isCtrl = event.ctrlKey || event.metaKey;
      final key = event.key?.toLowerCase() ?? '';

      if (key.isEmpty) return;

      print('📌 Web 键盘事件: key=$key, ctrl=$isCtrl');

      if (isCtrl && key == 's') {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        onExecute('save');
        onShowSnackBar('Ctrl+S 保存');
        return;
      }

      if (isCtrl && key == 'b') {
        event.preventDefault();
        onExecute('bold');
        onShowSnackBar('Ctrl+B 加粗');
        return;
      }

      if (isCtrl && key == 'i') {
        event.preventDefault();
        onExecute('italic');
        onShowSnackBar('Ctrl+I 斜体');
        return;
      }

      if (isCtrl && key == 'z') {
        event.preventDefault();
        onExecute('undo');
        onShowSnackBar('Ctrl+Z 撤销');
        return;
      }

      if (isCtrl && event.shiftKey && key == 'z') {
        event.preventDefault();
        onExecute('redo');
        onShowSnackBar('Ctrl+Shift+Z 重做');
        return;
      }

      if (key == 'escape') {
        event.preventDefault();
        onExecute('escape');
        onShowSnackBar('Esc 返回');
        return;
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}