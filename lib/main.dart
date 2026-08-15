import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'database_service.dart';
import 'pages/collection_page.dart';
import 'pages/wisdom_page.dart';
import 'pages/insight_page.dart';
import 'pages/creation_page.dart';
import 'pages/profile_page.dart';
import 'widgets/fullscreen_editor.dart';
import 'services/keyboard_shortcut_manager.dart';
import 'models/keyboard_shortcut.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云脑计划',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 238, 241, 242),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 155, 194, 236),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          elevation: 0,
        ),
      ),
      home: const NotebookPage(),
    );
  }
}

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  int _currentIndex = 0;
  final FocusNode _focusNode = FocusNode();
  KeyboardShortcutManager? _shortcutManager;

  final GlobalKey<WisdomPageState> _wisdomKey = GlobalKey<WisdomPageState>();
  final GlobalKey<InsightPageState> _insightKey = GlobalKey<InsightPageState>();
  final GlobalKey<CreationPageState> _creationKey = GlobalKey<CreationPageState>();

  StreamSubscription<html.KeyboardEvent>? _webKeyHandler;

  @override
  void initState() {
    super.initState();
    print('📌 NotebookPage initState');
    _initShortcuts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        print('📌 Web 平台，设置键盘拦截');
        _setupWebKeyboardInterceptor();
      }
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  Future<void> _initShortcuts() async {
    _shortcutManager = KeyboardShortcutManager();
    await _shortcutManager!.load();
    print('📌 快捷键加载完成，共 ${_shortcutManager?.all.length ?? 0} 个');
  }

  void _setupWebKeyboardInterceptor() {
    _webKeyHandler = html.window.onKeyDown.listen((event) {
      final isCtrl = event.ctrlKey || event.metaKey;
      final key = event.key?.toLowerCase() ?? '';

      if (key.isEmpty) return;

      print('📌 Web 键盘事件: key=$key, ctrl=$isCtrl');

      // 始终阻止 Ctrl+S、Ctrl+Shift+S
      if (isCtrl && key == 's') {
        print('📌 检测到 Ctrl+S，阻止默认行为');
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        _triggerSave();
        _showShortcutSnackBar('Ctrl+S 保存');
        return;
      }

      if (_shortcutManager != null) {
        final matched = _shortcutManager!.match(
          key,
          isCtrl,
          event.shiftKey,
          event.altKey,
        );

        if (matched != null) {
          print('📌 匹配到快捷键: ${matched.displayName}');
          event.preventDefault();
          event.stopPropagation();
          event.stopImmediatePropagation();
          _executeShortcut(matched.id);
          _showShortcutSnackBar(matched.displayName);
        }
      }
    });
  }

  void _showShortcutSnackBar(String label) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⌨️ $label'),
        duration: const Duration(milliseconds: 400),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _webKeyHandler?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      _wisdomKey.currentState?.refreshData();
    }
    if (index == 2) {
      _insightKey.currentState?.refreshData();
    }
  }

  void _onRefreshWisdom() {
    _wisdomKey.currentState?.refreshData();
  }

  void _onSwitchToTaskTab() {
    setState(() {
      _currentIndex = 3;
    });
    _creationKey.currentState?.switchToTaskTab();
  }

  void _onSwitchToFocusMode() {
    setState(() {
      _currentIndex = 3;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🐾 专注模式开发中，敬请期待'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _executeShortcut(String id) {
    switch (id) {
      case 'save':
        _triggerSave();
        break;
      case 'escape':
        Navigator.of(context).maybePop();
        break;
      case 'bold':
        _insertMarkdown('**');
        break;
      case 'italic':
        _insertMarkdown('*');
        break;
      default:
        break;
    }
  }

  void _triggerSave() {
    print('📌 _triggerSave 被调用');
    // 采集页快速笔记
    CollectionPage.triggerSave();
    // 全屏编辑器（智库笔记详情）
    FullscreenEditor.triggerSave();
  }

  void _insertMarkdown(String mark) {
    final controller = _getFocusedController();
    if (controller == null) return;

    final selection = controller.selection;
    if (!selection.isValid) return;

    final start = selection.baseOffset;
    final end = selection.extentOffset;
    final selectedText = controller.text.substring(start, end);
    final newText = controller.text.replaceRange(start, end, '$mark$selectedText$mark');
    controller.text = newText;
    controller.selection = TextSelection(
      baseOffset: start + mark.length,
      extentOffset: end + mark.length,
    );
  }

  TextEditingController? _getFocusedController() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return null;

    final editableState = focus.context!.findAncestorStateOfType<EditableTextState>();
    if (editableState != null) {
      return editableState.widget.controller;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        if (kIsWeb) return;

        if (event is RawKeyDownEvent) {
          final isCtrl = event.isControlPressed || event.isMetaPressed;
          final key = event.logicalKey;

          String keyName = '';
          if (key == LogicalKeyboardKey.escape) {
            keyName = 'escape';
          } else {
            keyName = key.keyLabel.toLowerCase();
            if (keyName.isEmpty) return;
          }

          if (isCtrl && keyName == 's') {
            _triggerSave();
            _showShortcutSnackBar('Ctrl+S 保存');
            return;
          }

          if (_shortcutManager != null) {
            final matched = _shortcutManager!.match(
              keyName,
              isCtrl,
              event.isShiftPressed,
              event.isAltPressed,
            );
            if (matched != null) {
              _executeShortcut(matched.id);
              _showShortcutSnackBar(matched.displayName);
            }
          }

          if (isCtrl && (key == LogicalKeyboardKey.keyZ)) return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('云脑计划'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: '关于',
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: '云脑计划',
                  applicationVersion: 'v1.0.0',
                  applicationLegalese: '© 2026 三少爷',
                  children: const [
                    Text('一个稳定智慧的外脑。'),
                  ],
                );
              },
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const CollectionPage(),
            WisdomPage(key: _wisdomKey),
            InsightPage(
              key: _insightKey,
              onTabChange: _onTabChange,
              onRefreshWisdom: _onRefreshWisdom,
              onSwitchToTaskTab: _onSwitchToTaskTab,
              onSwitchToFocusMode: _onSwitchToFocusMode,
            ),
            CreationPage(key: _creationKey),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _onTabChange(index);
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload_outlined),
              label: '采集',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories),
              label: '智库',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights),
              label: '洞察',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.create),
              label: '创作',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}