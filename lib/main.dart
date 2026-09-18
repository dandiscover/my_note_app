// lib/main.dart
// ✅ 云脑计划 — 完整修复：跨页面刷新 + 快捷键 + 登录同步 + 系统人格
// ✅ 新增：迁移旧探究数据到多任务模型
// ✅ Spike：全局悬浮宠物加 3 个隐藏边界（弹窗/键盘/全屏阅读）+ 暂隐（双击 30 秒）
// ✅ 小云尺寸调整：手机 100 / Pad 280（断点 600 dp）

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'pages/collection_page.dart';
import 'pages/workbench/editor_kernel.dart';
import 'models/pet.dart';
import 'dart:io';
import 'web_shortcut.dart'
    if (dart.library.html) 'web_shortcut.dart'
    if (dart.library.io) 'web_shortcut_stub.dart';

import 'services/supabase_service.dart';
import 'services/keyboard_shortcut_manager.dart';
import 'services/pet_service.dart';
import 'services/env_service.dart';
import 'services/sync/sync_manager.dart';
import 'database_service.dart';
import 'widgets/fullscreen_editor.dart';
import 'widgets/adaptive_navigation.dart';
import 'widgets/floating_pet.dart';  // ✅ 导出 floatingPetKey + PetVisibilityController
import 'widgets/sync_indicator.dart';

import 'pages/collection_page.dart';
import 'pages/wisdom_page.dart';
import 'pages/insight_page.dart';
import 'pages/creation_page.dart' as creation;

// ✅ Spike：弹窗/底部面板可见时隐藏宠物
final ValueNotifier<bool> _popupVisible = ValueNotifier(false);

// ✅ Spike：监听 Navigator 栈顶是否 PopupRoute（showDialog / showModalBottomSheet）
class _PetNavigatorObserver extends NavigatorObserver {
  @override
  void didChangeTop(Route<dynamic>? topRoute, Route<dynamic>? previousTopRoute) {
    _popupVisible.value = topRoute is PopupRoute;
  }
}

// ✅ Spike：单例，生命周期与 app 一致，避免 StatelessWidget rebuild 漂移
final _PetNavigatorObserver _petObserver = _PetNavigatorObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  final supabaseUrl = EnvService.supabaseUrl;
  final supabaseAnonKey = EnvService.supabaseAnonKey;

  print('🔑 Supabase URL: $supabaseUrl');
  print('🔑 Supabase Key: ${supabaseAnonKey.substring(0, 20)}...');

  await SupabaseService.init(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // ✅ 清理旧独立探究任务
  try {
    await DatabaseService.ensureMigrationAndCleanup();
  } catch (e) {
    print('⚠️ 清理旧任务失败: $e，将在下次启动重试');
  }

  // ✅ 迁移笔记旧字段到多任务模型
  await DatabaseService().ensureExploreMigration();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云脑计划',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [_petObserver],   // ✅ Spike：弹窗/底部面板隐藏宠物

      // ✅ Quill 本地化配置（flutter_quill 渲染工具栏 / 编辑器的界面文字需要）
      localizationsDelegates: const [
        quill.FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],

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
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              if (child != null) child,
              const _FloatingPetOverlay(),
            ],
          ),
        );
      },
      home: const NotebookPage(),
    );
  }
}

// ─── 悬浮宠物覆盖层 ──────────────────────────────────────────

class _FloatingPetOverlay extends StatefulWidget {
  const _FloatingPetOverlay();

  @override
  State<_FloatingPetOverlay> createState() => _FloatingPetOverlayState();
}

class _FloatingPetOverlayState extends State<_FloatingPetOverlay> {
  final PetService _petService = PetService();
  Pet? _pet;
  bool _isLoading = true;
  Offset _position = const Offset(16, 80);
  bool _isDragging = false;

  // ✅ Spike：暂隐（双击触发，30 秒后自动恢复）
  bool _isTemporarilyHidden = false;
  Timer? _hideTimer;
  static const Duration _temporaryHideDuration = Duration(seconds: 30);

  // ✅ 小云尺寸调整：底部安全间隙（原 clamp 纵向 -150 里的 80 抽出来）
  static const double _petBottomMargin = 80.0;

  // ✅ 小云尺寸调整：断点 600 dp，手机 100 / Pad 280
  double get _petSize {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 ? 280.0 : 100.0;
  }

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPet() async {
    try {
      final pet = await _petService.getOrCreatePet();
      setState(() {
        _pet = pet;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _interact() async {
    if (_pet == null) return;
    await _petService.petInteraction();
    final updated = await _petService.getOrCreatePet();
    setState(() {
      _pet = updated;
    });
  }

  // ✅ Spike：双击暂隐 30 秒
  void _hideTemporarily() {
    setState(() => _isTemporarilyHidden = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(_temporaryHideDuration, () {
      if (mounted) setState(() => _isTemporarilyHidden = false);
    });
  }

  void _onPanStart() {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(Offset delta) {
    setState(() {
      _position += delta;
      final size = MediaQuery.of(context).size;
      // ✅ 小云尺寸调整：双重 clamp 保护，避免 Pad 窄屏时上限为负
      _position = Offset(
        _position.dx.clamp(
          0,
          (size.width - _petSize).clamp(0.0, double.infinity),
        ),
        _position.dy.clamp(
          0,
          (size.height - _petSize - _petBottomMargin).clamp(0.0, double.infinity),
        ),
      );
    });
  }

  void _onPanEnd() {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Spike：监听 全屏阅读计数 + 弹窗可见，二者合并（一层包裹）
    return ListenableBuilder(
      listenable: Listenable.merge([
        PetVisibilityController.fullscreenCount,
        _popupVisible,
      ]),
      builder: (context, child) {
        if (_isLoading || _pet == null) {
          return const SizedBox.shrink();
        }
        // ✅ Spike：暂隐期间隐藏
        if (_isTemporarilyHidden) {
          return const SizedBox.shrink();
        }
        // ✅ Spike：键盘弹出时隐藏
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          return const SizedBox.shrink();
        }
        // ✅ Spike：弹窗/底部面板可见时隐藏
        if (_popupVisible.value) {
          return const SizedBox.shrink();
        }
        // ✅ Spike：全屏阅读（EPUB / PDF）时隐藏
        if (PetVisibilityController.fullscreenCount.value > 0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: IgnorePointer(
            ignoring: false,
            child: FloatingPet(
              key: floatingPetKey,
              pet: _pet!,
              size: _petSize,                  // ✅ 小云尺寸调整：手机 100 / Pad 280
              onTap: _interact,
              onDoubleTap: _hideTemporarily,   // ✅ Spike
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
            ),
          ),
        );
      },
    );
  }
}

// ─── NotebookPage ─────────────────────────────────────────────

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  final FocusNode _focusNode = FocusNode();
  KeyboardShortcutManager? _shortcutManager;
  WebShortcutManager? _webShortcutManager;

  // ✅ 所有页面的 GlobalKey（用于跨页面刷新）
  final GlobalKey<WisdomPageState> _wisdomKey = GlobalKey<WisdomPageState>();
  final GlobalKey<InsightPageState> _insightKey = GlobalKey<InsightPageState>();
  final GlobalKey<creation.CreationPageState> _creationKey =
      GlobalKey<creation.CreationPageState>();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initShortcuts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        _setupWebShortcuts();
      }
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _webShortcutManager?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── 快捷键 ──────────────────────────────────────────────

  Future<void> _initShortcuts() async {
    _shortcutManager = KeyboardShortcutManager();
    await _shortcutManager!.load();
  }

  void _setupWebShortcuts() {
    _webShortcutManager = WebShortcutManager(
      onExecute: _executeShortcut,
      onShowSnackBar: _showShortcutSnackBar,
    );
    _webShortcutManager!.startListening();
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

  void _executeShortcut(String id) {
    switch (id) {
      case 'save':
        final editorActive = EditorKernel.isActive;
        final dialogActive = CollectionPage.isActive;

        if (editorActive) {
          EditorKernel.triggerSave();
          _showShortcutSnackBar('💾 笔记已保存');
        } else if (dialogActive) {
          CollectionPage.triggerSave();
          _showShortcutSnackBar('💾 笔记已保存');
        } else {
          _showShortcutSnackBar('ℹ️ 没有可保存的内容');
        }
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

  // ─── Tab 切换刷新 ────────────────────────────────────────

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      _wisdomKey.currentState?.refreshData();
    }
    if (index == 2) {
      _insightKey.currentState?.refreshData();
    }
    if (index == 3) {
      _creationKey.currentState?.refreshTasks();
    }
  }

  // ✅ 刷新所有页面（图书导入后调用）
  void _refreshAllPages() {
    _wisdomKey.currentState?.refreshData();
    _insightKey.currentState?.refreshData();
    _creationKey.currentState?.refreshTasks();
  }

  // ✅ 登录后自动同步
  void _syncAfterLogin() async {
    final syncManager = SyncManager();
    try {
      final cloudData = await syncManager.pullAll();
      if (cloudData != null) {
        final db = DatabaseService();

        for (var note in cloudData.notes) {
          await db.updateNote(note.toMap());
        }
        for (var node in cloudData.nodes) {
          await db.updateNode(node);
        }
        for (var book in cloudData.books) {
          await db.updateBook(book.toMap());
        }
        if (cloudData.pet != null) {
          final petService = PetService();
          await petService.savePet(cloudData.pet!);
        }

        _refreshAllPages();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('☁️ 数据已从云端同步')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ 同步失败: $e')),
        );
      }
    }
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
            final editorActive = EditorKernel.isActive;
            final dialogActive = CollectionPage.isActive;

            if (editorActive) {
              EditorKernel.triggerSave();
              _showShortcutSnackBar('💾 笔记已保存');
            } else if (dialogActive) {
              CollectionPage.triggerSave();
              _showShortcutSnackBar('💾 笔记已保存');
            } else {
              _showShortcutSnackBar('ℹ️ 没有可保存的内容');
            }
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
            const SyncIndicator(),
            IconButton(
              tooltip: '关于',
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: '云脑计划',
                  applicationVersion: 'v1.0.0',
                  applicationLegalese: '© 2026 三少爷',
                  children: const [Text('一个稳定智慧的外脑。')],
                );
              },
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: AdaptiveNavigation(
          onTabChange: _onTabChange,
          onLoginSuccess: _syncAfterLogin,
          wisdomKey: _wisdomKey,
          insightKey: _insightKey,
          creationKey: _creationKey,
          onRefreshAll: _refreshAllPages,
        ),
      ),
    );
  }
}