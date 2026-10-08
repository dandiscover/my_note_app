// lib/main.dart
// ✅ 云脑计划 — 完整修复：跨页面刷新 + 快捷键 + 登录同步 + 系统人格
// ✅ 新增：迁移旧探究数据到多任务模型
// ✅ Spike：全局悬浮宠物加 3 个隐藏边界（弹窗/键盘/全屏阅读）+ 暂隐（双击 30 秒）
// ✅ 小云尺寸调整：手机 100 / Pad 280（断点 600 dp）
import 'services/open_tabs_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'pages/workbench/editor_kernel.dart';
import 'models/pet.dart';
import 'dart:io';
import 'services/note_opener.dart';
import 'services/supabase_service.dart';
import 'services/keyboard_shortcut_manager.dart';
import 'services/pet_service.dart';
import 'services/env_service.dart';
import 'services/sync/sync_manager.dart';
import 'database_service.dart';
import 'widgets/adaptive_navigation.dart';
import 'widgets/floating_pet.dart';  // ✅ 导出 floatingPetKey + PetVisibilityController
import 'widgets/sync_indicator.dart';
import 'models/command_item.dart';
import 'pages/workbench/clue_board_page.dart';
import 'services/command_palette_launcher.dart';
import 'services/spark_service.dart';
import 'pages/workbench/kernel_markdown.dart';
import 'services/open_tabs_manager.dart';
import 'services/note_opener.dart';
import 'pages/collection_page.dart';
import 'services/focus_mode_notifier.dart';
import 'models/note.dart';
import 'models/node.dart';
import 'widgets/quick_switch_dialog.dart';
import 'pages/note_detail_page.dart';
import 'pages/wisdom_page.dart';
import 'pages/insight_page.dart';
import 'pages/creation_page.dart' as creation;
import 'services/image_path_service.dart';
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
await ImagePathService.instance.init();   // R-3：图片路径
  await OpenTabsManager.instance.load();

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

  // ✅ 所有页面的 GlobalKey（用于跨页面刷新）
  final GlobalKey<AdaptiveNavigationState> _adaptiveNavKey =
      GlobalKey<AdaptiveNavigationState>();
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
      CommandPaletteLauncher.register(_handleCommandPalette);
    NoteOpener.onOpenNote = () => _adaptiveNavKey.currentState?.setTab(1);
    OpenTabsManager.noteViewActive.addListener(_onNoteViewChanged);
      KeyboardShortcutManager.revision.addListener(_onShortcutsChanged);
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }
  void _onNoteViewChanged() {
    if (mounted) setState(() {});
  }
  @override
  void dispose() {
    CommandPaletteLauncher.unregister();
    KeyboardShortcutManager.revision.removeListener(_onShortcutsChanged);
    OpenTabsManager.noteViewActive.removeListener(_onNoteViewChanged);
    _focusNode.dispose();
    super.dispose();
  }

  // ─── 快捷键 ──────────────────────────────────────────────

  Future<void> _initShortcuts() async {
    _shortcutManager = KeyboardShortcutManager();
    await _shortcutManager!.load();
  }

  void _onShortcutsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleCommandPalette() async {
    final maps = await DatabaseService().getAllNotes(includeDeleted: false);
    final notes = maps.map((m) => NotebookEntry.fromMap(m)).toList();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => QuickSwitchDialog(
        notes: notes,
        commands: _buildCommands(),
        onSelect: (note) {
          Navigator.pop(ctx);
          _openNoteFromQuickSwitch(note);
        },
      ),
    );
  }

  Future<void> _showSparkList() async {
    final sparks = await SparkService().getAllPending();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('💫 火花卡（${sparks.length}）'),
        content: SizedBox(
          width: 400,
          child: sparks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无待处理火花'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sparks.length,
                  itemBuilder: (_, i) {
                    final s = sparks[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        s.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        s.createdAt.toLocal().toString().substring(0, 16),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => Navigator.pop(ctx),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  List<CommandItem> _buildCommands() => [
    CommandItem(
      id: 'new_note',
      label: '新建笔记',
      description: '开一篇空白笔记',
      icon: Icons.note_add,
      onExecute: () => NoteOpener.open(
        context: context,
        entry: NotebookEntry.empty,
        isNew: true,
      ),
    ),
    CommandItem(
      id: 'open_collection',
      label: '打开采集',
      description: '进采集页',
      icon: Icons.add_box_outlined,
      onExecute: () => _adaptiveNavKey.currentState?.setTab(0),
    ),
    CommandItem(
      id: 'global_search',
      label: '全库搜索',
      description: '搜所有笔记和书',
      icon: Icons.search,
      onExecute: () {
        _adaptiveNavKey.currentState?.setTab(1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _wisdomKey.currentState?.toggleSearch();
        });
      },
    ),
    CommandItem(
      id: 'mark_summary',
      label: '标记汇总',
      description: '打开标记汇总面板',
      icon: Icons.bookmarks_outlined,
      onExecute: () {
        _adaptiveNavKey.currentState?.setTab(1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _wisdomKey.currentState?.openMarkSummary();
        });
      },
    ),
    CommandItem(
      id: 'open_clue_board',
      label: '打开线索墙',
      description: '进全局线索墙',
      icon: Icons.bubble_chart,
      onExecute: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClueBoardPage()),
      ),
    ),
    CommandItem(
      id: 'open_settings',
      label: '打开设置',
      description: '进「我的」设置',
      icon: Icons.settings,
      onExecute: () => _adaptiveNavKey.currentState?.setTab(4),
    ),
    CommandItem(
      id: 'spark_list',
      label: '查看火花卡',
      description: '查看所有待处理火花',
      icon: Icons.auto_awesome,
      onExecute: () { _showSparkList(); },
    ),
  ];

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
      case 'focus':
        focusModeNotifier.value = !focusModeNotifier.value;
        break;
      case 'quickSwitch':
        _handleQuickSwitch();
        break;
      case 'commandPalette':
        _handleCommandPalette();
        break;
      case 'sparkCard':
        MarkdownKernel.onSparkRequested?.call();
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

  Future<void> _handleQuickSwitch() => _handleCommandPalette();

  Future<void> _openNoteFromQuickSwitch(NotebookEntry note) async {
    final nodes = await DatabaseService().getAllNodes();
    final targetNode = nodes.firstWhere(
      (n) => n.nodeType == 'note' && n.targetId == note.id,
      orElse: () => Node.empty,
    );
    if (!mounted) return;
    NoteOpener.open(
      context: context,
      entry: note,
      nodeId: targetNode.id.isEmpty ? null : targetNode.id,
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

  // ─── 跨平台快捷键 ─────────────────────────────────────────

  static const Map<String, LogicalKeyboardKey> _keyStringMap = {
    'a': LogicalKeyboardKey.keyA, 'b': LogicalKeyboardKey.keyB,
    'c': LogicalKeyboardKey.keyC, 'd': LogicalKeyboardKey.keyD,
    'e': LogicalKeyboardKey.keyE, 'f': LogicalKeyboardKey.keyF,
    'g': LogicalKeyboardKey.keyG, 'h': LogicalKeyboardKey.keyH,
    'i': LogicalKeyboardKey.keyI, 'j': LogicalKeyboardKey.keyJ,
    'k': LogicalKeyboardKey.keyK, 'l': LogicalKeyboardKey.keyL,
    'm': LogicalKeyboardKey.keyM, 'n': LogicalKeyboardKey.keyN,
    'o': LogicalKeyboardKey.keyO, 'p': LogicalKeyboardKey.keyP,
    'q': LogicalKeyboardKey.keyQ, 'r': LogicalKeyboardKey.keyR,
    's': LogicalKeyboardKey.keyS, 't': LogicalKeyboardKey.keyT,
    'u': LogicalKeyboardKey.keyU, 'v': LogicalKeyboardKey.keyV,
    'w': LogicalKeyboardKey.keyW, 'x': LogicalKeyboardKey.keyX,
    'y': LogicalKeyboardKey.keyY, 'z': LogicalKeyboardKey.keyZ,
    'escape': LogicalKeyboardKey.escape,
    'space': LogicalKeyboardKey.space,
  };

  Map<ShortcutActivator, Intent> _buildShortcutsMap() {
    final map = <ShortcutActivator, Intent>{};
    for (final s in (_shortcutManager?.all ?? [])) {
      final trigger = _keyStringMap[s.key.toLowerCase()];
      if (trigger == null) continue;
      map[SingleActivator(
        trigger,
        control: s.isCtrlRequired,
        shift: s.isShiftRequired,
        alt: s.isAltRequired,
      )] = _ExecuteShortcutIntent(s.id);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Shortcuts(
        shortcuts: _buildShortcutsMap(),
        child: Actions(
          actions: {
            _ExecuteShortcutIntent: CallbackAction<_ExecuteShortcutIntent>(
              onInvoke: (intent) {
                _executeShortcut(intent.shortcutId);
                return null;
              },
            ),
          },
          child: Scaffold(
            appBar: OpenTabsManager.noteViewActive.value
                ? null
                : AppBar(
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
              key: _adaptiveNavKey,
              onTabChange: _onTabChange,
              onLoginSuccess: _syncAfterLogin,
              wisdomKey: _wisdomKey,
              insightKey: _insightKey,
              creationKey: _creationKey,
              onRefreshAll: _refreshAllPages,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 快捷键 Intent ────────────────────────────────────────────

class _ExecuteShortcutIntent extends Intent {
  final String shortcutId;
  const _ExecuteShortcutIntent(this.shortcutId);
}