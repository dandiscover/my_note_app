// lib/web_shortcut_stub.dart
// 桌面端备用 — 空实现

class WebShortcutManager {
  final void Function(String shortcutId) onExecute;
  final void Function(String label) onShowSnackBar;

  WebShortcutManager({
    required this.onExecute,
    required this.onShowSnackBar,
  });

  void startListening() {
    print('📌 桌面端：Web 键盘监听已禁用');
  }

  void dispose() {}
}