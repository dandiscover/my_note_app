// lib/web_shortcut.dart
// Web 快捷键管理

import 'dart:async';
import 'dart:html' as html;

typedef ShortcutCallback = void Function(String shortcutId);

class WebShortcutManager {
  final ShortcutCallback onExecute;
  final void Function(String) onShowSnackBar;

  StreamSubscription<html.KeyboardEvent>? _listener;

  WebShortcutManager({
    required this.onExecute,
    required this.onShowSnackBar,
  });

  void startListening() {
    _listener = html.document.onKeyDown.listen((event) {
      // 忽略输入框中的快捷键（让原生行为处理）
      final target = event.target;
      if (target is html.Element) {
        final tag = target.tagName.toLowerCase();
        if (tag == 'input' || tag == 'textarea' || tag == 'select') {
          return;
        }
      }

      final isCtrl = event.ctrlKey || event.metaKey;
      final key = (event.key ?? '').toLowerCase();

      if (key.isEmpty) return;

      // Ctrl+S 保存
      if (isCtrl && key == 's') {
        event.preventDefault();
        onExecute('save');
        onShowSnackBar('💾 保存');
        return;
      }

      // Escape
      if (key == 'escape') {
        event.preventDefault();
        onExecute('escape');
        onShowSnackBar('🔙 返回');
        return;
      }

      // Ctrl+B 加粗
      if (isCtrl && key == 'b') {
        event.preventDefault();
        onExecute('bold');
        onShowSnackBar('🔤 加粗');
        return;
      }

      // Ctrl+I 斜体
      if (isCtrl && key == 'i') {
        event.preventDefault();
        onExecute('italic');
        onShowSnackBar('🔤 斜体');
        return;
      }

      // Ctrl+Z 撤销（不拦截，让编辑器处理）
      if (isCtrl && key == 'z') {
        return;
      }

      // ✅ 改用 print（无需额外导入）
      print('📌 Web 键盘事件: key=$key, ctrl=$isCtrl');
    });
  }

  void dispose() {
    _listener?.cancel();
    _listener = null;
  }
}