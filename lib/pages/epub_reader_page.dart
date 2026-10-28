// lib/pages/epub_reader_page.dart
// EPUB 阅读器 — 增强稳定版
// 功能：划线留痕（短文本黄底/长文本侧边竖线）、批注/卡片图标、专注模式、右侧标注面板
// 使用 SelectableText.rich + AdaptiveTextSelectionToolbar 自定义菜单
// 修复：长按标注条目不再关闭面板，直接在面板内弹菜单，避免 context 失效
// ✅ 指导卡：集成 CardBoxPeek（划线后滑出一角）+ ReadingGuideCard（三层提问）
// ✅ 500ms 延迟逻辑：划线后启动 500ms 计时器；内点菜单动作 → 取消计时器，卡片盒不滑出
// ✅ 卡片盒滑出后 3 秒自动滑回
// ✅ 指导卡回答追加到"与这本书关联的读书笔记"（老白方案 B + T-050）
// ✅ `_convertToNote` 改为追加模式（T-050）
// ✅ 首次机制：保存成功后触发 `isFirstUse('guide')` + `markCardUsed('guide')` + usageCount 递增
// ✅ v2 修复（问题1）：专注模式 Listener 从 Stack 内部移到 Stack 外层。
//     原因：Stack.hitTestChildren 命中即停，Stack 内部的 Listener 会阻断 PageView / SelectableText 的 hitTest。
//     现在 Listener 是 Stack 的 parent，Stack 内部只有 PageView 和 CardBoxPeek，两个都能正常接收手势。
// ✅ Spike：进入/退出阅读器时通知 PetVisibilityController，隐藏全局悬浮宠物。
// ✅ BUG-002：卡片盒显隐改 ValueNotifier（避免 setState 重建 PageView
//    导致 SelectableText.rich 失锚 / 菜单闪）；云脑菜单删「做卡片」
//    （功能移到卡片盒）；_createCardDirectly 加 _onMenuActionTapped 与
//    _openReadingGuide 对称。
import 'package:webview_ultra/webview_ultra.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/debouncer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart' hide Image;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import '../database_service.dart';

import '../services/epub_jump_service.dart';
import '../services/navigation_service.dart' show NavigationService;
import '../services/multi_pane_bus.dart';
import 'reader/reader_shell.dart';
import 'multi_pane_page.dart';
import '../widgets/reader_hub_search_dialog.dart' show ReaderHubSearchDialog;
import '../models/book.dart';
import '../models/book_note.dart';
import '../models/card.dart';
import '../models/note.dart';
import '../services/book_service.dart';
import '../services/card_service.dart';
import '../widgets/reader/card_box_peek.dart';
import '../widgets/reader/reading_guide_card.dart';
import '../widgets/floating_pet.dart';   // ✅ Spike：PetVisibilityController
class EpubReaderPage extends StatefulWidget {
  final String bookId;
  final String? filePath;
  final String? fileUrl;
  final bool isWeb;
  final String fileName;
  // ✅ 批2a T-新-2：初始章节 index。
  //   null = 不定位，用 Book.readingProgress（现状不变）
  //   非 null = 定位到该章节（0 是有效值，表示第一页）
  final int? initialChapterIndex;
  final BookNote? initialJumpNote;               // 全智库入口：加载后跳转
  final String? initialLocation;                 // 全智库入口：location 字符串
  final MultiPaneBus? multiPaneBus;              // 多栏融合：主动推送上下文
  final bool embedMode;                          // 批 3：嵌入模式——只 body 无 Scaffold
  final VoidCallback? onExit;                    // 批 3：embed 错误态返回
  final ValueChanged<bool>? onFocusModeChanged;  // 批 3：专注态变更同步

  const EpubReaderPage({
    super.key,
    required this.bookId,
    this.filePath,
    this.fileUrl,
    this.isWeb = false,
    this.fileName = '文档',
    this.initialChapterIndex,
    this.initialJumpNote,
    this.initialLocation,
    this.multiPaneBus,
    this.embedMode = false,
    this.onExit,
    this.onFocusModeChanged,
  });

  @override
  State<EpubReaderPage> createState() => EpubReaderPageState();
}

class EpubReaderPageState extends State<EpubReaderPage> {
  final BookService _bookService = BookService();
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();

  Book? _book;
  EpubBook? _epubBook;
  List<EpubChapter>? _chapters;
  final List<String> _chapterContents = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentChapterIndex = 0;

  List<BookNote> _notes = [];
  Set<int> _bookmarks = {};
  Map<int, String> _summaries = {};

  double _rating = 0.0;
  String _review = '';

  double _fontSize = 16.0;
  double _lineHeight = 1.8;
  double _maxWidth = 800.0;
  double _pageMargin = 16.0;
  final Debouncer _layoutDebouncer = Debouncer(const Duration(milliseconds: 200));
  final Debouncer _searchDebouncer = Debouncer(const Duration(milliseconds: 300));
  String _fontFamily = 'sans-serif';
  int _themeMode = 0;
  Color _customBackgroundColor = const Color(0xFFF5F0E1);
  Color _customTextColor = const Color(0xFF4E342E);

  DateTime? _readingStartTime;
  late bool _isFocusMode;   // 批 3：initState 赋值（依赖 widget.embedMode）
  String _searchQuery = '';

  double _dailyGoalMinutes = 0.0;
  bool _reminderEnabled = false;
  double _reminderInterval = 30.0;
  Timer? _reminderTimer;
  bool _reminderShown = false;

  // ✅ BUG-002：卡片盒显隐改 ValueNotifier，避免 setState 重建 PageView
  //   导致 SelectableText.rich 失锚。
  final ValueNotifier<bool> _cardBoxVisible = ValueNotifier<bool>(false);
  Timer? _cardBoxDelayTimer;
  Timer? _cardBoxHideTimer;
  String? _peekSelectedText;

  // ✅ 问题1：专注模式"单击退出"指针判定状态
  static const int _focusTapMaxDurationMs = 300;
  Offset? _focusPointerDownPos;
  DateTime? _focusPointerDownAt;

  String _bookTitle = '';
  String _bookAuthor = '';
  int _totalWords = 0;

  Color _highlightColor = const Color(0xFFFFEB3B);
  final ScrollController _scrollController = ScrollController();

  String? _selectedText;

  WebviewUltraController? _mainController;
  Completer<void>? _pageLoadCompleter;
  int _jumpGeneration = 0;
  EpubJumpService? _jumpServiceInstance;

  EpubJumpService get _jumpService => _jumpServiceInstance ??= EpubJumpService(runJs: (js) async {
    if (_mainController != null) {
      await _mainController!.runJavaScript(js);
    }
    return null;
  });
  Timer? _webviewPollTimer;
  String _webviewSelectedText = '';

  final Map<int, List<_HighlightRange>> _highlightRanges = {};
  final Set<String> _highlightedWithCard = {};

  @override
  void initState() {
    super.initState();
    _isFocusMode = !widget.embedMode;   // 批 3：embed 模式禁专注
    _readingStartTime = DateTime.now();
    PetVisibilityController.enterFullscreen();   // ✅ Spike：隐藏全局悬浮宠物
    _startWebviewPolling();
    _loadBook();
  }

  void hideCardBoxPeek() {
    _cardBoxVisible.value = false;
    _cardBoxDelayTimer?.cancel();
    _cardBoxHideTimer?.cancel();
  }

  @override
  void dispose() {
    _layoutDebouncer.cancel();
    _searchDebouncer.cancel();
    _scrollController.dispose();
    _reminderTimer?.cancel();
    _cardBoxDelayTimer?.cancel();
    _cardBoxHideTimer?.cancel();
    _cardBoxVisible.dispose();
    _webviewPollTimer?.cancel();
    // 清理所有 WebView 控制器防内存泄漏
    _mainController?.dispose();
    PetVisibilityController.exitFullscreen();    // ✅ Spike：恢复全局悬浮宠物
    _saveReadingTime();
    super.dispose();
  }
  void _startWebviewPolling() {
    _webviewPollTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (!mounted) return;
      try {
        final controller = _mainController;
if (controller == null) return;
        final selResult = await controller.runJavaScriptReturningResult("window._sel || ''");
        final selText = selResult.toString().trim().replaceAll("'", "").replaceAll('"', '');
        
        if (selText.isNotEmpty && selText != _webviewSelectedText) {
          _webviewSelectedText = selText;
          _selectedText = selText;
          widget.multiPaneBus?.updateContext(text: selText);
          _startCardBoxDelayTimer(selText);
          await controller.runJavaScript('window._sel = "";');
        }

        final actionResult = await controller.runJavaScriptReturningResult("window._selAction || ''");
        final actionText = actionResult.toString().trim().replaceAll("'", "").replaceAll('"', '');
        if (actionText.isNotEmpty) {
           debugPrint('DEBUG 轮询收到 action: $actionText');
           final actionSelResult = await controller.runJavaScriptReturningResult("window._selActionText || ''");
           final actionSel = actionSelResult.toString().trim().replaceAll("'", "").replaceAll('"', '');
           final actionIdResult = await controller.runJavaScriptReturningResult("window._selActionId || ''");
           final actionId = actionIdResult.toString().trim().replaceAll("'", "").replaceAll('"', '');
           
           if (actionSel.isNotEmpty) {
               if (actionText == 'highlight') {
                   _saveHighlight(actionSel, actionId);
               } else if (actionText == 'comment') {
                   _selectedText = actionSel;
                   _showWriteThoughtDialog(actionSel, actionId);
               } else if (actionText == 'search') {
                   showSearch(actionSel);
               } else if (actionText == 'translate') {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🌐 翻译功能即将上线，敬请期待')));
               }
           }
           await controller.runJavaScript('window._selAction = ""; window._selActionText = ""; window._selActionId = "";');
        }

        final hlResult = await controller.runJavaScriptReturningResult("window._hl || ''");
        final hlText = hlResult.toString().trim().replaceAll("'", "").replaceAll('"', '');
        
        if (hlText.isNotEmpty && hlText.startsWith('hl://')) {
          final noteId = hlText.replaceFirst('hl://', '');
          debugPrint('DEBUG 收到高亮点击: noteId=$noteId');
          final note = _notes.firstWhere(
            (n) => n.id == noteId,
            orElse: () => BookNote(id: '', bookId: '', pageNumber: 0, selectedText: '', isHighlight: false),
          );
          if (note.id.isNotEmpty) {
            _showNoteOptions(note);
          }
          await controller.runJavaScript('window._hl = "";');
        }
      } catch (e) {
        debugPrint('DEBUG 轮询异常: $e');
      }
    });
  }

  // ---------------------- 数据加载 ----------------------
  Future<void> _loadBook() async {
    _book = await _bookService.getBook(widget.bookId);
    await _loadNotes();
    await _loadBookmarks();
    await _loadSummaries();
    await _loadRatingReview();
    await _loadUISettings();
    await _loadDailyGoal();
    await _loadReminderSettings();
    await _refreshCardMarkers();
    await _loadEpub();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await _bookService.getNotes(widget.bookId);
      setState(() {
        _notes = notes;
        _rebuildHighlightRanges();
      });
    } catch (e) {
      debugPrint('加载标注失败: $e');
    }
  }

  Future<void> _refreshCardMarkers() async {
    _highlightedWithCard.clear();
    try {
      final allCards = await _cardService.getAllCards();
      for (var note in _notes.where((n) => n.isHighlight)) {
        final hasCard = allCards.any((c) =>
            c.highlight == note.selectedText &&
            c.sourceId == widget.bookId &&
            c.sourceType == 'book');
        if (hasCard) {
          _highlightedWithCard.add(note.selectedText);
        }
      }
    } catch (_) {}
  }

  void _rebuildHighlightRanges() {
    _highlightRanges.clear();
    for (int i = 0; i < _chapterContents.length; i++) {
      final content = _chapterContents[i];
      final plain = _stripHtmlTags(content);
      final ranges = <_HighlightRange>[];
      final pageNotes = _notes.where((n) => n.pageNumber == i + 1 && n.isHighlight).toList();
      for (var note in pageNotes) {
        final text = note.selectedText.trim();
        if (text.isEmpty) continue;
        final index = plain.indexOf(text);
        if (index == -1) continue;
        final start = index;
        final end = start + text.length;
        ranges.add(_HighlightRange(start, end, note));
      }
      if (ranges.isNotEmpty) {
        _highlightRanges[i] = ranges;
      }
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('book_bookmarks_${widget.bookId}');
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List;
        setState(() => _bookmarks = list.map((e) => e as int).toSet());
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    final page = _currentChapterIndex + 1;
    final isRemoving = _bookmarks.contains(page);
    setState(() {
      if (isRemoving) {
        _bookmarks.remove(page);
      } else {
        _bookmarks.add(page);
      }
    });
    await _saveBookmarks();

    // 同步到 BookNote
    if (isRemoving) {
      try {
        final bookmarkNote = _notes.firstWhere((n) => n.pageNumber == page && n.selectedText == '【书签】');
        await _bookService.deleteNote(widget.bookId, bookmarkNote.id);
        await _loadNotes();
      } catch (_) {}
    } else {
      int scrollTop = 0;
      try {
        final r = await _mainController?.runJavaScriptReturningResult('window.scrollY || 0');
        String rStr = r?.toString() ?? '0';
        rStr = rStr.replaceAll('"', '').replaceAll("'", '');
        final parsedScroll = double.tryParse(rStr) ?? 0.0;
        scrollTop = parsedScroll.toInt();
      } catch (_) {}
      final newNote = BookNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: widget.bookId,
        pageNumber: page,
        // location 格式：type|page:N|top:M，type 预留 pdf/txt
        location: 'epub|page:$page|top:$scrollTop',
        selectedText: '【书签】',
        comment: '',
        color: '#FFD93D',
        isHighlight: false,
      );
      await _bookService.saveNote(newNote);
      await _loadNotes();
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('book_bookmarks_${widget.bookId}', jsonEncode(_bookmarks.toList()..sort()));
    } catch (_) {}
  }

  bool _isBookmarked(int page) => _bookmarks.contains(page);

  Future<void> _loadSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('book_summaries_${widget.bookId}');
      if (data != null && data.isNotEmpty) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        setState(() => _summaries = map.map((k, v) => MapEntry(int.parse(k), v.toString())));
      }
    } catch (_) {}
  }

  Future<void> _saveSummaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _summaries.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString('book_summaries_${widget.bookId}', jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _editSummary() async {
    final page = _currentChapterIndex + 1;
    final controller = TextEditingController(text: _summaries[page] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('章节总结'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: '写下本章总结...', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        if (result.isEmpty) {
          _summaries.remove(page);
        } else {
          _summaries[page] = result;
        }
      });
      await _saveSummaries();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 总结已保存')));
    }
  }

  Future<void> _loadRatingReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rating = prefs.getDouble('book_rating_${widget.bookId}') ?? 0.0;
      _review = prefs.getString('book_review_${widget.bookId}') ?? '';
    } catch (_) {}
  }

  Future<void> _saveRatingReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('book_rating_${widget.bookId}', _rating);
      await prefs.setString('book_review_${widget.bookId}', _review);
    } catch (_) {}
  }

  void showRatingReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double localRating = _rating;
        final controller = TextEditingController(text: _review);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('评分与书评'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(i < localRating ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => setDialogState(() => localRating = i + 1.0),
                  )),
                ),
                TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: '写点书评...', border: OutlineInputBorder())),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              ElevatedButton(onPressed: () {
                _rating = localRating;
                _review = controller.text.trim();
                _saveRatingReview();
                setState(() {});
                Navigator.pop(context);
              }, child: const Text('保存')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadUISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble('reader_font_size') ?? 16.0;
      _lineHeight = prefs.getDouble('reader_line_height') ?? 1.8;
      _maxWidth = prefs.getDouble('reader_max_width') ?? 800.0;
      _pageMargin = prefs.getDouble('reader_page_margin') ?? 16.0;
      _fontFamily = prefs.getString('reader_font_family') ?? 'sans-serif';
      _themeMode = prefs.getInt('reader_theme_mode') ?? 0;
      _customBackgroundColor = Color(prefs.getInt('reader_custom_bg') ?? 0xFFF5F0E1);
      _customTextColor = Color(prefs.getInt('reader_custom_text') ?? 0xFF4E342E);
      _highlightColor = Color(prefs.getInt('reader_highlight_color') ?? 0xFFFFEB3B);
    } catch (_) {}
  }

  Future<void> _saveUISettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('reader_font_size', _fontSize);
      await prefs.setDouble('reader_line_height', _lineHeight);
      await prefs.setDouble('reader_max_width', _maxWidth);
      await prefs.setDouble('reader_page_margin', _pageMargin);
      await prefs.setString('reader_font_family', _fontFamily);
      await prefs.setInt('reader_theme_mode', _themeMode);
      await prefs.setInt('reader_custom_bg', _customBackgroundColor.value);
      await prefs.setInt('reader_custom_text', _customTextColor.value);
      await prefs.setInt('reader_highlight_color', _highlightColor.value);
    } catch (_) {}
  }

  Future<void> _loadDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyGoalMinutes = prefs.getDouble('reader_daily_goal') ?? 0.0;
    } catch (_) {}
  }

  Future<void> _saveDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('reader_daily_goal', _dailyGoalMinutes);
    } catch (_) {}
  }

  Future<void> _loadReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reminderEnabled = prefs.getBool('reader_reminder_enabled') ?? false;
      _reminderInterval = prefs.getDouble('reader_reminder_interval') ?? 30.0;
    } catch (_) {}
  }

  Future<void> _saveReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reader_reminder_enabled', _reminderEnabled);
      await prefs.setDouble('reader_reminder_interval', _reminderInterval);
    } catch (_) {}
  }

  void _startReminderTimer() {
    _reminderTimer?.cancel();
    if (_reminderEnabled && _reminderInterval > 0) {
      _reminderTimer = Timer.periodic(Duration(minutes: _reminderInterval.round()), (timer) {
        if (mounted && !_reminderShown) {
          _reminderShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🧘 你已经阅读一段时间了，休息一下吧')),
          );
          Future.delayed(const Duration(minutes: 5), () {
            _reminderShown = false;
          });
        }
      });
    }
  }

  Color get _backgroundColor {
    switch (_themeMode) {
      case 0: return Colors.grey.shade50;
      case 1: return _customBackgroundColor;
      case 2: return const Color(0xFF1E1E1E);
      default: return Colors.grey.shade50;
    }
  }

  Color get _textColor {
    switch (_themeMode) {
      case 0: return Colors.black87;
      case 1: return _customTextColor;
      case 2: return Colors.white70;
      default: return Colors.black87;
    }
  }

  Color get _appBarBgColor => Colors.grey.shade100;
  Color get _appBarFgColor => Colors.black87;

  void openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('阅读设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('字体大小', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 12,
                            max: 26,
                            divisions: 14,
                            label: _fontSize.round().toString(),
                            onChanged: (value) {
                              setModalState(() => _fontSize = value);
                              _mainController?.runJavaScript("document.body.style.fontSize = '${value}px';");
                            },
                          ),
                        ),
                        Text('${_fontSize.round()}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('行高', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: _lineHeight,
                            min: 1.2,
                            max: 2.5,
                            divisions: 13,
                            label: _lineHeight.toStringAsFixed(1),
                            onChanged: (value) {
                              setModalState(() => _lineHeight = value);
                              _mainController?.runJavaScript("document.body.style.lineHeight = '$value';");
                            },
                          ),
                        ),
                        Text(_lineHeight.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('宽度', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: _maxWidth,
                            min: 400,
                            max: 1200,
                            divisions: 16,
                            label: _maxWidth.round().toString(),
                            onChanged: (value) {
                              setModalState(() => _maxWidth = value);
                              _layoutDebouncer.run(() => setState(() {}));
                            },
                          ),
                        ),
                        Text('${_maxWidth.round()}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('边距', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: _pageMargin,
                            min: 0,
                            max: 64,
                            divisions: 16,
                            label: _pageMargin.round().toString(),
                            onChanged: (value) {
                              setModalState(() => _pageMargin = value);
                              _layoutDebouncer.run(() => setState(() {}));
                            },
                          ),
                        ),
                        Text('${_pageMargin.round()}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('字体', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'sans-serif', label: Text('黑体')),
                              ButtonSegment(value: 'serif', label: Text('宋体')),
                              ButtonSegment(value: 'monospace', label: Text('等宽')),
                            ],
                            selected: {_fontFamily},
                            onSelectionChanged: (values) {
                              setModalState(() => _fontFamily = values.first);
                              setState(() {});
                              debugPrint('DEBUG fontFamily: ${values.first}');
                              _mainController?.runJavaScript("document.body.style.fontFamily = '${values.first}';");
                            },
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('主题', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('白天')),
                              ButtonSegment(value: 1, label: Text('护眼')),
                              ButtonSegment(value: 2, label: Text('夜间')),
                            ],
                            selected: {_themeMode},
                            onSelectionChanged: (values) {
                              setModalState(() => _themeMode = values.first);
                              setState(() {});
                              final _bgHex = '#${_backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                              final _fgHex = '#${_textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                              _mainController?.runJavaScript(
                                "document.body.style.backgroundColor = '$_bgHex';"
                                "document.body.style.color = '$_fgHex';"
                              );
                            },
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                          ),
                        ),
                      ],
                    ),
                    if (_themeMode == 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('背景色', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                _colorOption(const Color(0xFFF5F0E1), setModalState, isBg: true),
                                _colorOption(const Color(0xFFFAF3E0), setModalState, isBg: true),
                                _colorOption(const Color(0xFFE8F0E3), setModalState, isBg: true),
                                _colorOption(const Color(0xFFFDE8E8), setModalState, isBg: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('文字色', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                _colorOption(const Color(0xFF4E342E), setModalState, isBg: false),
                                _colorOption(const Color(0xFF3E2723), setModalState, isBg: false),
                                _colorOption(const Color(0xFF1B5E20), setModalState, isBg: false),
                                _colorOption(const Color(0xFFB71C1C), setModalState, isBg: false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('每日阅读目标（分钟）', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Slider(
                            value: _dailyGoalMinutes,
                            min: 0,
                            max: 180,
                            divisions: 36,
                            label: _dailyGoalMinutes.round().toString(),
                            onChanged: (value) {
                              setModalState(() => _dailyGoalMinutes = value);
                              setState(() {});
                            },
                          ),
                        ),
                        Text('${_dailyGoalMinutes.round()}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('连续阅读提醒'),
                      subtitle: const Text('每段时间提醒休息'),
                      value: _reminderEnabled,
                      onChanged: (value) {
                        setModalState(() => _reminderEnabled = value);
                        setState(() {});
                      },
                    ),
                    if (_reminderEnabled)
                      Row(
                        children: [
                          const Text('提醒间隔（分钟）', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: _reminderInterval,
                              min: 10,
                              max: 60,
                              divisions: 10,
                              label: _reminderInterval.round().toString(),
                              onChanged: (value) {
                                setModalState(() => _reminderInterval = value);
                                setState(() {});
                              },
                            ),
                          ),
                          Text('${_reminderInterval.round()}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
                        ElevatedButton(
                          onPressed: () {
                            _saveUISettings();
                            _saveDailyGoal();
                            _saveReminderSettings();
                            _startReminderTimer();
                            Navigator.pop(context);
                          },
                          child: const Text('保存设置'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _colorOption(Color color, StateSetter setModalState, {required bool isBg}) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          if (isBg) _customBackgroundColor = color; else _customTextColor = color;
        });
        setState(() {});
        final _bgHex = '#${_customBackgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        final _fgHex = '#${_customTextColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        debugPrint('DEBUG colorOption: isBg=$isBg, bg=$_bgHex, fg=$_fgHex');
        _mainController?.runJavaScript(
          "document.body.style.backgroundColor = '$_bgHex';"
          "document.body.style.color = '$_fgHex';"
        );
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: (isBg ? _customBackgroundColor : _customTextColor) == color ? Colors.orange : Colors.grey),
        ),
      ),
    );
  }

  Future<void> _saveReadingTime() async {
    if (_readingStartTime == null) return;
    final duration = DateTime.now().difference(_readingStartTime!);
    if (duration.inSeconds < 5) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'reading_time_stats';
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final data = prefs.getString(key);
      Map<String, dynamic> map = {};
      if (data != null && data.isNotEmpty) {
        try { map = jsonDecode(data) as Map<String, dynamic>; } catch (_) {}
      }
      final current = map[dateStr] is int ? map[dateStr] as int : 0;
      map[dateStr] = current + duration.inSeconds;
      await prefs.setString(key, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> showSearch([String? initialText]) async {
    await showDialog(
      context: context,
      builder: (_) => ReaderHubSearchDialog(
        initialText: initialText ?? _searchQuery,
        bookId: widget.bookId,
        onExecuteBookSearch: (query) async => _executeSearch(query),
        onJumpToBook: (payload) async {
          final targetBookId = payload['bookId'] as String?;
          final pageNumber = payload['pageNumber'] as int?;
          final selectedText = payload['selectedText'] as String?;
          if (targetBookId == null || targetBookId.isEmpty) return;
          if (targetBookId == widget.bookId && pageNumber != null) {
            await _loadChapterContent(pageNumber - 1);
            if (selectedText != null && selectedText.isNotEmpty) {
              await _jumpService.jumpToText(selectedText);
            }
          } else if (targetBookId != widget.bookId) {
            await NavigationService.openBook(context, targetBookId);
          }
        },
        onOpenNote: (noteId) {
          NavigationService.openNote(context, noteId);
        },
        onOpenCard: (cardMap) {
          NavigationService.openCard(context, cardMap);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _executeSearch(String query) {
    if (query.isEmpty || _chapters == null) return [];
    final results = <Map<String, dynamic>>[];
    final regex = RegExp(RegExp.escape(query), caseSensitive: false);
    for (int i = 0; i < _chapters!.length; i++) {
      final title = _chapters![i].Title ?? '第 ${i + 1} 章';
      final content = i < _chapterContents.length ? _stripHtmlTags(_chapterContents[i]) : '';
      final titleMatch = title.toLowerCase().contains(query.toLowerCase());
      final contentMatches = content.toLowerCase().split(query.toLowerCase()).length - 1;
      if (titleMatch || contentMatches > 0) {
        String snippet = '标题匹配';
        if (contentMatches > 0) {
          final match = regex.firstMatch(content);
          if (match != null) {
            final textRunes = content.runes.toList();
            final matchStartRune = content.substring(0, match.start).runes.length;
            final matchLengthRunes = content.substring(match.start, match.end).runes.length;
            final snippetStart = (matchStartRune - 20).clamp(0, textRunes.length);
            final snippetEnd = (matchStartRune + matchLengthRunes + 20).clamp(0, textRunes.length);
            final before = String.fromCharCodes(textRunes.sublist(snippetStart, matchStartRune));
            final matched = String.fromCharCodes(textRunes.sublist(matchStartRune, matchStartRune + matchLengthRunes));
            final after = String.fromCharCodes(textRunes.sublist(matchStartRune + matchLengthRunes, snippetEnd));
            snippet = '$before【$matched】$after';
          }
        }
        results.add({'index': i, 'title': title, 'count': contentMatches, 'snippet': snippet});
        if (results.length >= 50) break;
      }
    }
    return results;
  }



  void showToc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('目录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const Divider(),
            Expanded(
              child: _chapters == null ? const Center(child: Text('暂无章节')) : ListView.builder(
                controller: scrollController,
                itemCount: _chapters!.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters![index];
                  final title = chapter.Title ?? '第 ${index + 1} 章';
                  return ListTile(
                    dense: true,
                    selected: index == _currentChapterIndex,
                    title: Text(title),
                    onTap: () {
                      debugPrint('DEBUG toc tap: index=$index, beforeCurrent=$_currentChapterIndex, chapters=${_chapters?.length}');
                      Navigator.pop(context);
                      _loadChapterContent(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void toggleFocusMode() {
    if (widget.embedMode) return;   // 批 3：embed 禁进专注
    setState(() => _isFocusMode = !_isFocusMode);
    widget.onFocusModeChanged?.call(_isFocusMode);
  }

  void exportNotes() {
    final buffer = StringBuffer();
    buffer.writeln('《${_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle}》阅读笔记');
    buffer.writeln('导出时间：${DateTime.now().toString()}');
    buffer.writeln('');
    for (var note in _notes) {
      buffer.writeln('---');
      buffer.writeln('章节：第${note.pageNumber}章');
      buffer.writeln('原文：${note.selectedText}');
      if (note.comment.isNotEmpty) buffer.writeln('批注：${note.comment}');
      buffer.writeln('');
    }
    for (var e in _summaries.entries) {
      buffer.writeln('---');
      buffer.writeln('第${e.key}章总结：${e.value}');
      buffer.writeln('');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已复制到剪贴板')));
  }

  void exportMindMap() {
    final buffer = StringBuffer();
    buffer.writeln('# ${_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle}');
    buffer.writeln('');
    if (_chapters != null) {
      for (int i = 0; i < _chapters!.length; i++) {
        final chapter = _chapters![i];
        final title = chapter.Title ?? '第 ${i + 1} 章';
        buffer.writeln('## $title');
        final page = i + 1;
        if (_summaries.containsKey(page)) buffer.writeln('- 总结：${_summaries[page]}');
        final chapterNotes = _notes.where((n) => n.pageNumber == page).toList();
        for (var note in chapterNotes) {
          buffer.writeln('- ${note.isHighlight ? "高亮" : "批注"}：${note.selectedText}');
          if (note.comment.isNotEmpty) buffer.writeln('  - 批注：${note.comment}');
        }
        buffer.writeln('');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 思维导图已复制为 Markdown')));
  }

  // ---------------------- 专注模式手势判定 ----------------------
  // ✅ v2 问题1：Listener 是 Stack 的 parent，不是 child。
  //   - Stack.hitTestChildren 命中即停，Stack 内部的 Listener 会阻断 PageView / SelectableText。
  //   - 现在 Listener 在 Stack 外层，Stack 内部只有 PageView 和 CardBoxPeek，两个都能正常接收手势。
  //   - Listener 依然收到全部 onPointerDown / onPointerUp，位置判定逻辑不变。
  //   - 已知边界：多指场景下 _focusPointerDownPos 只记第一根手指，第二指覆盖。概率极低，本轮接受。
  void _onFocusPointerDown(PointerDownEvent event) {
    _focusPointerDownPos = event.position;
    _focusPointerDownAt = DateTime.now();
  }

  void _onFocusPointerUp(PointerUpEvent event) {
    final start = _focusPointerDownPos;
    final startAt = _focusPointerDownAt;
    _focusPointerDownPos = null;
    _focusPointerDownAt = null;
    if (start == null || startAt == null) return;

    // 卡片盒区域判定：以 down 位置为准。
    // 卡片盒宽度 140（CardBoxPeek._buildPanel 内 hardcoded），贴右边缘。
    // 若未来卡片盒宽度改变，此处需同步（T-071）。
    const cardBoxWidth = 140.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardBoxLeft = screenWidth - cardBoxWidth;
    if (_cardBoxVisible.value && start.dx >= cardBoxLeft) {
      return;
    }

    final elapsed = DateTime.now().difference(startAt).inMilliseconds;
    final moved = (event.position - start).distance;
    if (elapsed < _focusTapMaxDurationMs && moved < kTouchSlop) {
      setState(() => _isFocusMode = false);
      widget.onFocusModeChanged?.call(false);
    }
  }

  // ---------------------- 指导卡集成 ----------------------
  void _startCardBoxDelayTimer(String selectedText) {
    _cardBoxDelayTimer?.cancel();
    _peekSelectedText = selectedText;
    _cardBoxDelayTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _showCardBoxPeek();
    });
  }

  void _showCardBoxPeek() {
    _cardBoxHideTimer?.cancel();
    _cardBoxVisible.value = true;
    _cardBoxHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _cardBoxVisible.value = false;
    });
  }

  void _onMenuActionTapped() {
    _cardBoxDelayTimer?.cancel();
    if (_cardBoxVisible.value) {
      _cardBoxHideTimer?.cancel();
      if (mounted) _cardBoxVisible.value = false;
    }
  }

  Future<void> _openReadingGuide(String selectedText) async {
    if (selectedText.isEmpty) return;
    _onMenuActionTapped();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadingGuideCard(
        selectedText: selectedText,
        onFinish: (markdown) async {
          await _appendToBookNote(markdown);
        },
        onCompleted: () async {
          final isFirst = await _cardService.isFirstUse('guide');
          if (isFirst) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('这是你的第一张指导卡。')),
              );
            }
            await _cardService.markCardUsed('guide');
          }
          final guideCard = await _cardService.getCard('system_guide_card');
          if (guideCard != null) {
            await _cardService.updateCard(
              guideCard.copyWith(usageCount: guideCard.usageCount + 1),
            );
          }
        },
      ),
    );
  }

  Future<void> _appendToBookNote(String markdown) async {
    if (markdown.trim().isEmpty) return;
    final bookId = widget.bookId;
    final existingNoteId = await _cardService.getBookReadingNoteId(bookId);

    if (existingNoteId != null) {
      final notes = await _db.getAllNotes(includeDeleted: true);
      Map<String, dynamic>? existing;
      for (final m in notes) {
        if (m['id'] == existingNoteId) {
          existing = m;
          break;
        }
      }
      if (existing == null || existing['status'] == 'deleted') {
        await _cardService.clearBookReadingNoteId(bookId);
      } else {
        final oldContent = (existing['content'] as String?) ?? '';
        final newContent = oldContent.isEmpty ? markdown : '$oldContent\n\n$markdown';
        existing['content'] = newContent;
        existing['updatedAt'] = DateTime.now().toIso8601String();
        await _db.updateNote(existing);
        return;
      }
    }

    await _createNewBookReadingNote(bookId, markdown);
  }

  Future<void> _createNewBookReadingNote(String bookId, String markdown) async {
    final title = '阅读笔记：《${_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle}》';
    final now = DateTime.now();
    final noteEntry = NotebookEntry(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: markdown,
      updatedAt: now,
      status: 'active',
      editorMode: 'plain',
      tags: ['阅读笔记', _bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle],
    );
    await _db.insertNote(noteEntry.toMap());
    final folderId = await _db.ensureReviewFolder();
    await _db.attachNoteToNode(
      noteId: noteEntry.id,
      title: title,
      parentId: folderId,
      tags: noteEntry.tags,
    );
    await _cardService.setBookReadingNoteId(bookId, noteEntry.id);
  }

  Widget _buildCardBoxPeek() {
    return ValueListenableBuilder<bool>(
      valueListenable: _cardBoxVisible,
      builder: (context, visible, _) => CardBoxPeek(
        visible: visible,
        onReadThrough: () {
          final text = _peekSelectedText ?? '';
          if (text.isNotEmpty) _openReadingGuide(text);
        },
        onCreateIndexCard: () {
          final text = _peekSelectedText ?? '';
          if (text.isNotEmpty) _createCardDirectly(text, '');
        },
      ),
    );
  }

  // ---------------------- 核心交互 ----------------------
  Future<void> _saveHighlight(String selectedText, String actionId) async {
    if (selectedText.isEmpty) return;
    final exists = _notes.any((n) =>
        n.selectedText == selectedText &&
        n.pageNumber == _currentChapterIndex + 1 &&
        n.isHighlight);
    if (exists) return;
    final note = BookNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      pageNumber: _currentChapterIndex + 1,
      // location 格式：type|page:N|top:M，type 预留 pdf/txt
      location: 'epub|page:${_currentChapterIndex + 1}|top:0',
      selectedText: selectedText,
      comment: '',
      color: '#${_highlightColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      isHighlight: true,
    );
    await _bookService.saveNote(note);
    await _loadNotes(); // 提前刷新内存，防点击时找不到数据

    debugPrint('DEBUG 开始活化高亮: actionId=$actionId');
    // 活化前端 DOM，让刚变黄的 span 立刻变成可点击的 <a>
    if (_mainController != null && actionId.isNotEmpty) {
      final js = """
        var els = document.querySelectorAll('span.${actionId}');
        els.forEach(function(el) {
          var a = document.createElement('a');
          a.setAttribute('href', 'hl://${note.id}');
          a.setAttribute('data-id', '${note.id}');
          a.setAttribute('onclick', "event.preventDefault(); window._hl = 'hl://${note.id}';");
          a.style.backgroundColor = '#FFD93D';
          a.style.textDecoration = 'none';
          a.style.color = 'inherit';
          a.innerHTML = el.innerHTML;
          el.parentNode.replaceChild(a, el);
        });
      """;
      await _mainController!.runJavaScript(js);
    }
  }

  void _showWriteThoughtDialog(String selectedText, String actionId) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('💭 写想法'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('原文：', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text(selectedText, style: const TextStyle(fontSize: 14)),
              ),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '写下你的想法...', border: OutlineInputBorder()),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                final comment = controller.text.trim();
                Navigator.pop(context);
                final exists = _notes.any((n) =>
                    n.selectedText == selectedText &&
                    n.pageNumber == _currentChapterIndex + 1 &&
                    n.isHighlight);
                final note = BookNote(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  bookId: widget.bookId,
                  pageNumber: _currentChapterIndex + 1,
                  location: 'epub|page:${_currentChapterIndex + 1}|top:0',
                  selectedText: selectedText,
                  comment: comment,
                  color: '#${_highlightColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                  isHighlight: true,
                );
                
                String finalNoteId = '';
                if (exists) {
                  final existing = _notes.firstWhere((n) =>
                      n.selectedText == selectedText &&
                      n.pageNumber == _currentChapterIndex + 1 &&
                      n.isHighlight);
                  finalNoteId = existing.id;
                  final updated = BookNote(
                    id: existing.id,
                    bookId: existing.bookId,
                    pageNumber: existing.pageNumber,
                    location: existing.location ?? 'page:${existing.pageNumber}',
                    selectedText: existing.selectedText,
                    comment: comment,
                    color: existing.color,
                    isHighlight: true,
                  );
                  await _bookService.saveNote(updated);
                } else {
                  finalNoteId = note.id;
                  await _bookService.saveNote(note);
                }
                
                await _loadNotes(); // 提前刷新内存

                if (_mainController != null && actionId.isNotEmpty) {
                  final js = """
                    var els = document.querySelectorAll('span.' + '$actionId');
                    els.forEach(function(el) {
                      var a = document.createElement('a');
                      a.setAttribute('href', 'hl://$finalNoteId');
                      a.setAttribute('data-id', '$finalNoteId');
                      a.setAttribute('onclick', "event.preventDefault(); window._hl = 'hl://$finalNoteId';");
                      a.setAttribute('data-comment', 'true');
                      a.style.backgroundColor = '#FFD93D';
                      a.style.textDecoration = 'none';
                      a.style.color = 'inherit';
                      a.innerHTML = el.innerHTML;
                      el.parentNode.replaceChild(a, el);
                    });
                  """;
                  await _mainController!.runJavaScript(js);
                }

                await _loadNotes();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCardDirectly(String selectedText, String actionId) async {
    if (selectedText.isEmpty) return;
    _onMenuActionTapped();
    try {
      final allCards = await _cardService.getAllCards();
      final exists = allCards.any((c) =>
          c.highlight == selectedText &&
          c.sourceId == widget.bookId &&
          c.sourceType == 'book');
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📇 卡片已存在')));
        }
        return;
      }
    } catch (_) {}
    final card = CardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardType: CardType.indexCard,
      sourceType: 'book',
      sourceId: widget.bookId,
      sourceTitle: _book?.title ?? 'EPUB阅读',
      tags: [],
      front: selectedText,
      back: '',
      indexTitle: _chapters != null && _currentChapterIndex < _chapters!.length
          ? _chapters![_currentChapterIndex].Title ?? '第 ${_currentChapterIndex + 1} 章'
          : '第 ${_currentChapterIndex + 1} 章',
      author: _book?.author,
      highlight: selectedText,
      importance: Importance.medium,
      stage: 0,
      nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
    );
    await _cardService.addCard(card);
    
    String finalNoteId = '';
    try {
      final savedNote = _notes.firstWhere((n) => n.selectedText == selectedText && n.pageNumber == _currentChapterIndex + 1);
      finalNoteId = savedNote.id;
    } catch (_) {
      final newNote = BookNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookId: widget.bookId,
        pageNumber: _currentChapterIndex + 1,
        location: 'epub|page:${_currentChapterIndex + 1}|top:0',
        selectedText: selectedText,
        comment: '',
        color: '#${_highlightColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        isHighlight: false,
      );
      finalNoteId = newNote.id;
      await _bookService.saveNote(newNote);
    }
    
    await _refreshCardMarkers();
    await _loadNotes();

    if (_mainController != null && actionId.isNotEmpty && finalNoteId.isNotEmpty) {
      final js = """
        var els = document.querySelectorAll('span.' + '$actionId');
        els.forEach(function(el) {
          var a = document.createElement('a');
          a.setAttribute('href', 'hl://$finalNoteId');
          a.setAttribute('data-id', '$finalNoteId');
          a.setAttribute('onclick', "event.preventDefault(); window._hl = 'hl://$finalNoteId';");
          a.setAttribute('data-card', 'true');
          a.style.backgroundColor = '#FFD93D';
          a.style.textDecoration = 'none';
          a.style.color = 'inherit';
          a.innerHTML = el.innerHTML;
          el.parentNode.replaceChild(a, el);
        });
      """;
      await _mainController!.runJavaScript(js);
    }

    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📇 卡片已生成')));
    }
  }

  Future<void> _generateCardFromNote(BookNote note) async {
    try {
      final allCards = await _cardService.getAllCards();
      final exists = allCards.any((c) =>
          c.highlight == note.selectedText &&
          c.sourceId == widget.bookId &&
          c.sourceType == 'book');
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📇 卡片已存在')));
        }
        return;
      }
    } catch (_) {}
    final card = CardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardType: CardType.indexCard,
      sourceType: 'book',
      sourceId: widget.bookId,
      sourceTitle: _book?.title ?? 'EPUB阅读',
      tags: [],
      front: note.selectedText,
      back: note.comment,
      indexTitle: _chapters != null && note.pageNumber <= _chapters!.length
          ? _chapters![note.pageNumber - 1].Title ?? '第 ${note.pageNumber} 章'
          : '第 ${note.pageNumber} 章',
      author: _book?.author,
      highlight: note.selectedText,
      importance: Importance.medium,
      stage: 0,
      nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
    );
    await _cardService.addCard(card);
    await _refreshCardMarkers();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📇 卡片已生成')));
    }
  }

  Future<void> _deleteHighlightNote(BookNote note) async {
    await _bookService.deleteNote(widget.bookId, note.id);

    // JS 定点拔除当前 DOM 上的高亮（不重载页面，不闪屏，不丢进度）
    if (_mainController != null) {
      final js = """
        var els = document.querySelectorAll('a[data-id="${note.id}"]');
        els.forEach(function(el) {
          var text = document.createTextNode(el.textContent);
          el.parentNode.replaceChild(text, el);
        });
      """;
      await _mainController!.runJavaScript(js);
    }

    try {
      final allCards = await _cardService.getAllCards();
      for (var card in allCards) {
        if (card.highlight == note.selectedText &&
            card.sourceId == widget.bookId &&
            card.sourceType == 'book') {
          await _cardService.deleteCard(card.id);
        }
      }
    } catch (_) {}
    await _loadNotes();
    if (mounted) {
      // 静默保存
    }
  }
  // ---------------------- 构建富文本 ----------------------
    String _buildWebViewHtml(String content, int chapterIndex) {
    debugPrint('DEBUG buildWebViewHtml: chapterIndex=$chapterIndex, contentLen=${content.length}, themeMode=$_themeMode, bg=$_backgroundColor, fg=$_textColor');
    if (content.isEmpty) return '<html><body>（本章无内容）</body></html>';

    final document = html_parser.parse(content);
    final body = document.body;
    if (body == null) return '<html><body>解析失败</body></html>';
    debugPrint('DEBUG bodyLen=${body.outerHtml.length}, chapterIndex=$chapterIndex');

    final scripts = body.querySelectorAll('style, script');
    for (var el in scripts) { el.remove(); }

    // 1. 处理高亮
    final pageNotes = _notes.where((n) => n.pageNumber == chapterIndex + 1 && n.isHighlight).toList();
    if (pageNotes.isNotEmpty) {
      final textNodes = <html_dom.Text>[];
      final nodeRanges = <Map<String, dynamic>>[];
      int currentPos = 0;
      final StringBuffer plainBuffer = StringBuffer();
      
      void mapNodes(html_dom.Node node) {
        if (node is html_dom.Text) {
          final len = node.data.length;
          textNodes.add(node);
          nodeRanges.add({'node': node, 'start': currentPos, 'end': currentPos + len});
          plainBuffer.write(node.data);
          currentPos += len;
        } else if (node is html_dom.Element) {
          if (node.localName == 'br') {
            currentPos += 1;
            plainBuffer.write('\n');
          }
          for (var c in node.nodes) { mapNodes(c); }
          if (node.localName == 'p') {
            currentPos += 1;
            plainBuffer.write('\n');
          }
        }
      }
      mapNodes(body);
      final plainText = plainBuffer.toString();
      
      final targets = <Map<String, dynamic>>[];
      for (var note in pageNotes) {
        final text = note.selectedText.trim();
        if (text.isEmpty) continue;
        
        int start = plainText.indexOf(text);
        int end = start != -1 ? start + text.length : -1;
        
        if (start == -1) {
          final parts = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).map(RegExp.escape).toList();
          if (parts.isNotEmpty) {
            final pattern = parts.join(r'\s+');
            final match = RegExp(pattern).firstMatch(plainText);
            if (match != null) {
              start = match.start;
              end = match.end;
            }
          }
        }

        if (start != -1 && end != -1) {
          targets.add({'start': start, 'end': end, 'note': note});
          debugPrint('DEBUG 高亮匹配成功: text=${text.substring(0, min(20, text.length))}, start=$start, end=$end');
        } else {
          debugPrint('DEBUG 高亮匹配失败: text=$text');
        }
      }
      targets.sort((a, b) => (b['start'] as int).compareTo(a['start'] as int));

      for (var target in targets) {
        final start = target['start'] as int;
        final end = target['end'] as int;
        final note = target['note'] as BookNote;
        final isLong = note.selectedText.length > 50;
        final hasCard = _highlightedWithCard.contains(note.selectedText);

        final hitNodes = nodeRanges.where((r) => (r['start'] as int) < end && (r['end'] as int) > start).toList();
        for (var hit in hitNodes) {
          final tn = hit['node'] as html_dom.Text;
          final tnStart = hit['start'] as int;
          final tnEnd = hit['end'] as int;
          if (tn.parent == null) continue;

          final overlapStart = max(start, tnStart);
          final overlapEnd = min(end, tnEnd);
          final relStart = overlapStart - tnStart;
          final relEnd = overlapEnd - tnStart;
          if (relStart >= relEnd) continue;

          String style = 'background-color: ${note.color.isNotEmpty ? note.color : "#FFD93D"}; text-decoration: none; color: inherit; ';
          if (isLong) style += 'border-left: 4px solid #FF9800; padding-left: 6px; ';
          if (hasCard) style += 'border-bottom: 2px solid #4CAF50; ';

          final a = html_dom.Element.tag('a');
          a.attributes['href'] = 'hl://${note.id}';
          a.attributes['data-id'] = note.id;
          a.attributes['style'] = style;
          if (note.comment.isNotEmpty) a.attributes['data-comment'] = 'true';
          if (hasCard) a.attributes['data-card'] = 'true';
          
          String textContent = tn.data.substring(relStart, relEnd);
          if (isLong && overlapStart == start) textContent = '「$textContent';
          if (isLong && overlapEnd == end) textContent = '$textContent」';
          a.append(html_dom.Text(textContent));

          final parent = tn.parent!;
          final idx = parent.nodes.indexOf(tn);
          if (idx == -1) continue;

          final newNodes = <html_dom.Node>[];
          if (relStart > 0) newNodes.add(html_dom.Text(tn.data.substring(0, relStart)));
          newNodes.add(a);
          if (relEnd < tn.data.length) newNodes.add(html_dom.Text(tn.data.substring(relEnd)));
          parent.nodes.removeAt(idx);
          for (int i = newNodes.length - 1; i >= 0; i--) { parent.nodes.insert(idx, newNodes[i]); }
        }
      }
    }

    // 2. 处理图片 Base64 (动态 MIME 修复版)
    final images = _epubBook?.Content?.Images;
    if (images != null) {
      final imgElements = body.querySelectorAll('img');
      for (var img in imgElements) {
        final src = img.attributes['src'];
        if (src == null) continue;
        var imgFile = images[src];
        if (imgFile == null) {
          final fileName = src.split('/').last;
          for (var entry in images.entries) {
            if (entry.key.endsWith(fileName)) { imgFile = entry.value; break; }
          }
        }
        if (imgFile != null && imgFile.Content != null) {
          final base64Str = base64Encode(imgFile.Content!);
          String ext = src.split('.').last.toLowerCase();
          String mime = 'image/jpeg';
          if (ext == 'png') mime = 'image/png';
          else if (ext == 'gif') mime = 'image/gif';
          else if (ext == 'webp') mime = 'image/webp';
          
          img.attributes['src'] = 'data:$mime;base64,$base64Str';
        }
      }
    }

    // 3. 渲染并注入防闪回的 CSS 和 划词/高亮点击 JS
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style id="dynamic-style">
        body { font-family: $_fontFamily; padding: 20px; margin: 0; line-height: $_lineHeight; font-size: ${_fontSize}px; background: #${_backgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}; color: #${_textColor.value.toRadixString(16).padLeft(8, '0').substring(2)}; }
        img { max-width: 100%; height: auto; margin: 10px 0; }
        a[href^="hl://"] { text-decoration: none; color: inherit; }
        a[data-comment="true"]::after { content: '💭'; font-size: 12px; margin-left: 2px; pointer-events: none; }
        @keyframes flashHL { 0% { background-color: #FFD93D; } 50% { background-color: #FF9800; } 100% { background-color: #FFD93D; } }
        .flash-target { animation: flashHL 0.9s ease-in-out 2; }
        a[data-card="true"]::after { content: '📇'; font-size: 12px; margin-left: 2px; pointer-events: none; }
        a[data-comment="true"][data-card="true"]::after { content: '💭📇'; font-size: 12px; margin-left: 2px; pointer-events: none; }
        .epub-menu {
            position: absolute;
            display: none;
            background-color: #333333;
            color: #ffffff;
            border-radius: 8px;
            padding: 6px 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            z-index: 99999;
            font-size: 14px;
            font-family: sans-serif;
            align-items: center;
            gap: 12px;
            user-select: none;
        }
        .epub-menu::after {
            content: '';
            position: absolute;
            bottom: -6px;
            left: 50%;
            margin-left: -6px;
            border-width: 6px 6px 0;
            border-style: solid;
            border-color: #333333 transparent transparent transparent;
        }
        .epub-menu-item {
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 4px;
            transition: color 0.2s;
        }
        .epub-menu-item:hover {
            color: #FFD93D;
        }
    </style>
</head>
<body id="reader-body">
    ${body.outerHtml}
    <div id="epub-menu" class="epub-menu">
        <div class="epub-menu-item" onclick="handleAction('highlight')">🖍️ 高亮</div>
        <div class="epub-menu-item" onclick="handleAction('copy')">📋 复制</div>
        <div class="epub-menu-item" onclick="handleAction('comment')">💭 批注</div>
        <div class="epub-menu-item" onclick="handleAction('search')">🔍 搜索</div>
        <div class="epub-menu-item" onclick="handleAction('translate')">🌐 翻译</div>
    </div>
    <script>
        window._sel = '';
        window._hl = '';
        document.addEventListener('selectionchange', function() {
            window._sel = window.getSelection().toString();
        });
        document.addEventListener('click', function(e) {
            var target = e.target.closest('a[data-id]');
            if (target) {
                e.preventDefault();
                window._hl = 'hl://' + target.getAttribute('data-id');
                console.log('DEBUG JS 触发点击高亮: ' + window._hl);
            }
        });
        document.addEventListener('click', function(e) {
            var target = e.target.closest('a');
            if (target && target.href && !target.href.startsWith('hl://') && !target.href.startsWith('javascript:')) {
                e.preventDefault();
                window._tocJump = target.getAttribute('href');
            }
        });

        // 气泡菜单逻辑
        var menu = document.getElementById('epub-menu');
        var currentSelText = '';

        document.addEventListener('contextmenu', function(e) { e.preventDefault(); });

        document.addEventListener('mouseup', function(e) {
            var sel = window.getSelection();
            if (sel && !sel.isCollapsed && sel.toString().trim().length > 0) {
                currentSelText = sel.toString().trim();
                var range = sel.getRangeAt(0);
                var rect = range.getBoundingClientRect();
                
                menu.style.display = 'flex';
                var menuWidth = menu.offsetWidth;
                var menuHeight = menu.offsetHeight;
                
                var top = rect.top + window.scrollY - menuHeight - 10;
                if (top < 10) top = rect.bottom + window.scrollY + 10;
                var left = rect.left + window.scrollX + (rect.width / 2) - (menuWidth / 2);
                if (left < 10) left = 10;
                
                menu.style.top = top + 'px';
                menu.style.left = left + 'px';
            } else {
                menu.style.display = 'none';
            }
        });

        function handleAction(action) {
            window._tempId = 'hl-tmp-' + Date.now();
            menu.style.display = 'none';
            if (action === 'highlight' || action === 'comment') {
                try {
                    var sel = window.getSelection();
                    if (sel && sel.rangeCount > 0) {
                        var range = sel.getRangeAt(0);
                        var startNode = range.startContainer;
                        var endNode = range.endContainer;
                        var startOffset = range.startOffset;
                        var endOffset = range.endOffset;
                        var textNodes = [];

                        if (startNode.nodeType === 3 && endNode.nodeType === 3) {
                            if (startNode === endNode) {
                                textNodes.push({ node: startNode, start: startOffset, end: endOffset });
                            } else {
                                textNodes.push({ node: startNode, start: startOffset, end: startNode.length });
                                textNodes.push({ node: endNode, start: 0, end: endOffset });
                                var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
                                var inBetween = false;
                                while (walker.nextNode()) {
                                    var node = walker.currentNode;
                                    if (node === startNode) inBetween = true;
                                    else if (node === endNode) inBetween = false;
                                    else if (inBetween) textNodes.push({ node: node, start: 0, end: node.length });
                                }
                            }
                        }

                        // 倒序处理，防止影响后面的节点偏移量
                        textNodes.reverse().forEach(function(item) {
                            var node = item.node;
                            var start = item.start;
                            var end = item.end;
                            if (start < end) {
                                if (end < node.length) node.splitText(end);
                                var selectedNode = node;
                                if (start > 0) selectedNode = node.splitText(start);
                                
                                var span = document.createElement('span');
                                span.className = 'fresh-hl ' + window._tempId;
                                span.style.backgroundColor = '#FFD93D';
                                selectedNode.parentNode.insertBefore(span, selectedNode);
                                span.appendChild(selectedNode);
                            }
                        });
                    }
                } catch(e) { console.log('DEBUG JS handleAction异常: ' + e.message); }
            } else if (action === 'copy') {
                try { navigator.clipboard.writeText(currentSelText); } catch(e) {}
            }
            window._selAction = action;
            window._selActionText = currentSelText;
            window._selActionId = window._tempId;
        }
    </script>
</body>
</html>
''';
  }   
  
  void _showQuickNoteInput() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('页边书摘'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedText != null && _selectedText!.isNotEmpty) ...[
                Text('原文：$_selectedText', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '记录你的想法...', border: OutlineInputBorder()),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(onPressed: () {
              Navigator.pop(context);
              _saveQuickNote(controller.text.trim());
            }, child: const Text('保存')),
          ],
        );
      },
    );
  }

  Future<void> _saveQuickNote(String text) async {
    if (text.isEmpty) return;
    final note = BookNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      pageNumber: _currentChapterIndex + 1,
      location: 'epub|page:${_currentChapterIndex + 1}|top:0',
      selectedText: _selectedText ?? '页边书摘',
      comment: text,
      color: '#FFD93D',
      isHighlight: false,
    );
    await _bookService.saveNote(note);
    _selectedText = null;
    
    // 页边书摘无高亮锚点，无需 JS 追加

    await _loadNotes();
  }

  void showBatchCardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量生成卡片'),
        content: Text('是否将当前所有批注和高亮批量转换为复习卡片？\n共 ${_notes.length} 条标注。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            Navigator.pop(context);
            _batchGenerateCards();
          }, child: const Text('生成')),
        ],
      ),
    );
  }

  Future<void> _batchGenerateCards() async {
    int count = 0;
    for (var note in _notes) {
      final card = CardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + count.toString(),
        cardType: CardType.review,
        sourceType: 'book',
        sourceId: widget.bookId,
        sourceTitle: _book?.title ?? 'EPUB阅读',
        tags: [],
        front: note.selectedText,
        back: note.comment,
        importance: Importance.medium,
        stage: 0,
        nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
      );
      await _cardService.addCard(card);
      count++;
    }
    await _refreshCardMarkers();
    setState(() {});
    if (mounted) {
      // 静默保存
    }
  }

  void showReadingStats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('reading_time_stats');
    Map<String, dynamic> stats = {};
    if (data != null && data.isNotEmpty) {
      try { stats = jsonDecode(data) as Map<String, dynamic>; } catch (_) {}
    }
    final now = DateTime.now();
    final days = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = date.toIso8601String().substring(0, 10);
      days[key] = stats[key] is int ? stats[key] as int : 0;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('最近7天阅读时长（分钟）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('本书共 $_totalWords 字', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.entries.map((e) {
                  final minutes = e.value / 60.0;
                  final maxMinutes = days.values.isEmpty ? 1 : days.values.reduce((a,b) => a > b ? a : b) / 60.0;
                  final height = maxMinutes == 0 ? 0.0 : (minutes / maxMinutes) * 150;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(minutes.round().toString(), style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(height: height, width: 20, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 4),
                        Text(e.key.substring(5), style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // 强行拆开合并的烂排版章节
  List<EpubChapter> _splitMergedChapters(List<EpubChapter> original) {
    final List<EpubChapter> result = [];
    // 只认 h1 标签作为切分点，防止 h2/h3 导致碎片化
    final regex = RegExp(r'<h1[^>]*>.*?</h1>', caseSensitive: false, dotAll: true);

    for (var chapter in original) {
      final html = chapter.HtmlContent ?? '';
      final matches = regex.allMatches(html).toList();

      // 如果只有 1 个或 0 个标题，说明是正常章节，不拆
      if (matches.length <= 1) {
        result.add(chapter);
        continue;
      }

      // 提取原书的 <head> 和样式
      String headHtml = '<html><head></head><body>';
      final bodyMatch = RegExp(r'<body[^>]*>', caseSensitive: false).firstMatch(html);
      int bodyStart = 0;
      if (bodyMatch != null) {
        headHtml = html.substring(0, bodyMatch.end);
        bodyStart = bodyMatch.end;
      }
      
      int bodyEnd = html.lastIndexOf('</body>');
      if (bodyEnd == -1) bodyEnd = html.length;

      for (int i = 0; i < matches.length; i++) {
        final start = matches[i].start;
        
        // 截取第一个匹配前的内容（比如序、推荐序）
        if (i == 0 && start > bodyStart) {
          final headChunk = html.substring(bodyStart, start).trim();
          // 修复：去掉 HTML 标签后，如果还有文字，才认为是真正的卷首/前言，避免空标签生成空白页
          final plainHead = headChunk.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll(RegExp(r'\s+'), '');
          if (plainHead.isNotEmpty) {
            final newChapter = EpubChapter();
            newChapter.Title = '卷首';
            newChapter.HtmlContent = '$headHtml\n$headChunk\n</body></html>';
            newChapter.ContentFileName = chapter.ContentFileName;
            debugPrint('DEBUG SPLIT: 卷首');
            result.add(newChapter);
          }
        }

        final end = (i < matches.length - 1) ? matches[i + 1].start : bodyEnd;
        if (start >= end) continue;

        var contentChunk = html.substring(start, end).trim();
        // 提取标题文本并去掉内部标签
        final titleText = matches[i].group(0)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();

        final newChapter = EpubChapter();
        newChapter.Title = titleText;
        newChapter.HtmlContent = '$headHtml\n$contentChunk\n</body></html>';
        newChapter.ContentFileName = chapter.ContentFileName; 
        
        debugPrint('DEBUG SPLIT: $titleText');
        result.add(newChapter);
      }
    }
    return result;
  }

  // 递归展平 EPUB 的多级章节目录，并进行去重
  List<EpubChapter> _flattenChapters(List<EpubChapter>? chapters) {
    if (chapters == null) return [];
    final List<EpubChapter> flatList = [];
    final Set<String> seenFiles = {}; // 用于记录已经加载过的文件，防止重复

    void extract(List<EpubChapter> list) {
      for (var chapter in list) {
        final hasSub = chapter.SubChapters != null && chapter.SubChapters!.isNotEmpty;
        final content = chapter.HtmlContent;
        final hasContent = content != null && content.trim().isNotEmpty;
        
        // 只要有内容，就尝试加入列表
        if (hasContent) {
          final file = chapter.ContentFileName;
          // 如果文件名存在且在历史记录中，说明是重复引用的内容，跳过
          if (file != null && seenFiles.contains(file)) {
            // 跳过重复文件
          } else {
            if (file != null) seenFiles.add(file);
            flatList.add(chapter);
          }
        }

        // 递归处理子章节
        if (hasSub) {
          extract(chapter.SubChapters!);
        }
      }
    }
    
    extract(chapters);
    return flatList;
  }
  Future<void> _loadEpub() async {
    setState(() => _isLoading = true);
    try {
      Uint8List? epubData;
      String? sourcePath = widget.filePath ?? _book?.filePath;
      if (widget.isWeb && widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        final response = await http.get(Uri.parse(widget.fileUrl!));
        if (response.statusCode == 200) epubData = Uint8List.fromList(response.bodyBytes);
      }
      if (widget.isWeb && sourcePath != null && sourcePath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(sourcePath));
        if (response.statusCode == 200) epubData = Uint8List.fromList(response.bodyBytes);
      }
      if (epubData == null && sourcePath != null && sourcePath.length > 200 && !sourcePath.startsWith('/') && !sourcePath.startsWith('blob:') && !sourcePath.startsWith('http') && !sourcePath.startsWith('file:')) {
        try { epubData = Uint8List.fromList(base64Decode(sourcePath)); } catch (_) {}
      }
      if (epubData == null && sourcePath != null && sourcePath.isNotEmpty && !widget.isWeb) {
        final file = File(sourcePath);
        if (await file.exists()) epubData = Uint8List.fromList(await file.readAsBytes());
      }
      if (epubData == null) {
        setState(() { _errorMessage = '无法加载EPUB文件'; _isLoading = false; });
        return;
      }
      _epubBook = await EpubReader.readBook(epubData);
      // 调用展平方法，把所有层级的章节全部拉平
      _chapters = _flattenChapters(_epubBook?.Chapters);
      _chapters = _splitMergedChapters(_chapters!);

      // 初始化唯一 Controller
      _mainController?.dispose(); // 防内存泄漏
      _mainController = WebviewUltraController(
        onPageStarted: (url) => debugPrint('DEBUG webview start: $url'),
        onPageFinished: (url) {
          debugPrint('DEBUG webview finish: $url');
          if (!(_pageLoadCompleter?.isCompleted ?? true)) {
            _pageLoadCompleter!.complete();
          }
        },
        onWebResourceError: (e) => debugPrint('DEBUG webview error: $e'),
      );
      if (_epubBook != null) {
        _bookTitle = _epubBook!.Title ?? widget.fileName;
        _bookAuthor = _epubBook!.Author ?? '未知作者';
      }
      if (_chapters != null) {
        int count = 0;
        for (var chapter in _chapters!) {
          final text = _stripHtmlTags(chapter.HtmlContent ?? '');
          count += text.replaceAll(RegExp(r'\s+'), '').length;
        }
        _totalWords = count;

        // 调试代码已移除
      }
      if (widget.initialChapterIndex != null) {
        _currentChapterIndex = widget.initialChapterIndex!;
      } else {
        _currentChapterIndex = _book?.readingProgress ?? 0;
      }
      if (_currentChapterIndex >= (_chapters?.length ?? 0)) _currentChapterIndex = 0;
      
      // --- 临时调试：打印前 5 章的 HTML 特征，用于分析烂排版 ---
      if (_chapters != null) {
        for (int i = 0; i < min(5, _chapters!.length); i++) {
          final ch = _chapters![i];
          final html = ch.HtmlContent ?? '';
          debugPrint('DEBUG chapter $i Title=${ch.Title}');
          debugPrint('DEBUG chapter $i Preview=${html.replaceAll("\n", " ").substring(0, min(300, html.length))}');
        }
      }
      // --------------------------------------------------------

      await _loadChapterContent(_currentChapterIndex);
      setState(() => _isLoading = false);
      _startReminderTimer();
    } catch (e) {
      debugPrint('加载EPUB失败: $e');
      setState(() { _errorMessage = '加载失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadChapterContent(int index) async {
    if (_epubBook == null || _chapters == null || index >= _chapters!.length) return;
    _jumpGeneration++;
    final myGeneration = _jumpGeneration;
    if (_pageLoadCompleter != null && !_pageLoadCompleter!.isCompleted) {
      _pageLoadCompleter!.complete();
    }
    _pageLoadCompleter = Completer<void>();
    final completer = _pageLoadCompleter!;
    try {
      final chapter = _chapters![index];
      String content = chapter.HtmlContent ?? '（本章无内容）';
      if (content.isEmpty) content = '（本章无内容）';
      if (index >= _chapterContents.length) _chapterContents.addAll(List.filled(index - _chapterContents.length + 1, ''));
      _chapterContents[index] = content;
      _rebuildHighlightRanges();
      
      final targetHtml = _buildWebViewHtml(content, index);
      if (mounted) {
        setState(() {
          _currentChapterIndex = index;
        });
        _mainController?.loadHtmlString(targetHtml);
      }
      try {
        await completer.future.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        debugPrint('_loadChapterContent 加载超时: index=$index');
      }
      if (myGeneration != _jumpGeneration) return;
      debugPrint('DEBUG loadChapterContent done: index=$index, contentLen=${content.length}');
      widget.multiPaneBus?.updateContext(chapter: index);
      _saveProgress(); // 自动保存进度
    } catch (e, st) {
      debugPrint('_loadChapterContent 失败: $e\n$st');
    }
  }

  Future<void> _saveProgress() async {
    if (_book != null && _chapters != null) {
      final total = _chapters!.length;
      final progress = total > 0 ? (_currentChapterIndex / total * 100).round() : 0;
      final updated = _book!.copyWith(readingProgress: progress, totalPages: total, lastReadAt: DateTime.now());
      await _bookService.saveBook(updated);
      _book = updated;
      // 静默保存
    }
  }

  void showNotesPanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭标注列表',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: _NotesPanelContent(
                  getNotes: () => _notes,
                  onJumpToNote: (note) async {
                    await _loadChapterContent(note.pageNumber - 1);
                    await _jumpService.jumpToNote(note);
                  },
                  chaptersLength: _chapters?.length ?? 0,
                  onGenerateCard: _generateCardFromNote,
                  onDeleteHighlight: _deleteHighlightNote,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = Curves.easeOut;
        final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  void _showNoteOptions(BookNote note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 如果已有批注，直接在菜单上方展示批注内容
            if (note.comment.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💭 我的批注：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(note.comment, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('生成卡片'),
              onTap: () {
                Navigator.pop(context);
                _generateCardFromNote(note);
              },
            ),
            if (note.isHighlight)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除高亮', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteHighlightNote(note);
                },
              ),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void showMindMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('🧠 思维导图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(leading: const Icon(Icons.menu_book, color: Colors.orange), title: Text(_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const Divider(),
                  if (_chapters != null)
                    ..._chapters!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final chapter = entry.value;
                      final page = index + 1;
                      final chapterNotes = _notes.where((n) => n.pageNumber == page).toList();
                      final isBookmarked = _bookmarks.contains(page);
                      final summary = _summaries[page];
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Icon(isBookmarked ? Icons.bookmark : Icons.article, color: isBookmarked ? Colors.orange : Colors.grey, size: 20),
                          title: Text(chapter.Title ?? '第 $page 章', style: const TextStyle(fontSize: 14)),
                          subtitle: summary != null ? Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                          children: [
                            if (chapterNotes.isEmpty)
                              const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('暂无标注', style: TextStyle(color: Colors.grey, fontSize: 12)))
                            else
                              ...chapterNotes.map((note) => ListTile(
                                    dense: true,
                                    leading: Icon(note.isHighlight ? Icons.highlight : Icons.comment, color: note.isHighlight ? Colors.yellow.shade700 : Colors.orange, size: 18),
                                    title: Text(note.selectedText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _loadChapterContent(index);
                                    },
                                  )),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAggregatedNotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('📚 关联笔记聚合', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(leading: const Icon(Icons.star, color: Colors.amber), title: Text('评分：$_rating', style: const TextStyle(fontSize: 14))),
                  if (_review.isNotEmpty) ListTile(leading: const Icon(Icons.rate_review), title: Text(_review)),
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(8), child: Text('批注与高亮', style: TextStyle(fontWeight: FontWeight.w600))),
                  if (_notes.isEmpty)
                    const Padding(padding: EdgeInsets.all(8), child: Text('暂无批注', style: TextStyle(color: Colors.grey)))
                  else
                    ..._notes.map((note) => ListTile(
                          dense: true,
                          leading: Icon(note.isHighlight ? Icons.highlight : Icons.comment, color: note.isHighlight ? Colors.yellow.shade700 : Colors.orange, size: 18),
                          title: Text(note.selectedText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          subtitle: note.comment.isNotEmpty ? Text(note.comment, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                        )),
                  const Divider(),
                  const Padding(padding: EdgeInsets.all(8), child: Text('章节总结', style: TextStyle(fontWeight: FontWeight.w600))),
                  if (_summaries.isEmpty)
                    const Padding(padding: EdgeInsets.all(8), child: Text('暂无总结', style: TextStyle(color: Colors.grey)))
                  else
                    ..._summaries.entries.map((e) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.summarize, size: 18),
                          title: Text('第 ${e.key} 章', style: const TextStyle(fontSize: 13)),
                          subtitle: Text(e.value, maxLines: 2, overflow: TextOverflow.ellipsis),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildChapterContent(int index) {
    debugPrint('DEBUG buildChapterContent: index=$index, current=$_currentChapterIndex, cacheLen=${_chapterContents.length}, hasContent=${index < _chapterContents.length && _chapterContents[index].isNotEmpty}');
    if (_chapters == null || index >= _chapters!.length) return const Center(child: Text('章节不存在'));
    final chapter = _chapters![index];
    final content = index < _chapterContents.length ? _chapterContents[index] : '（加载中...）';
    final title = chapter.Title ?? '第 ${index + 1} 章';
    final page = index + 1;
    final isBookmarked = _isBookmarked(page);
    final summary = _summaries[page];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold, color: _textColor)),
          const SizedBox(height: 12),
          Divider(color: _textColor.withOpacity(0.2)),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                if (_mainController != null)
                  WebviewUltra(
                    key: const ValueKey('main_webview'), 
                    controller: _mainController!,
                    initialHtml: _buildWebViewHtml(content, index),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.add_comment, color: Colors.orange),
                    onPressed: () {
                      _selectedText = null;
                      _showQuickNoteInput();
                    },
                    tooltip: '页边书摘',
                  ),
                ),
              ],
            ),
          ),
          if (summary != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📌 本章总结：', style: TextStyle(fontWeight: FontWeight.w600, fontSize: _fontSize - 3, color: _textColor)),
                  Expanded(child: Text(summary, style: TextStyle(fontSize: _fontSize - 3, color: _textColor))),
                  IconButton(icon: Icon(Icons.edit, size: 16, color: Colors.blue), onPressed: _editSummary, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: isBookmarked ? Colors.orange : Colors.grey), onPressed: _toggleBookmark, tooltip: '书签'),
                  TextButton.icon(onPressed: _editSummary, icon: const Icon(Icons.summarize, size: 16), label: Text(summary == null ? '写总结' : '改总结', style: TextStyle(color: _textColor))),
                ],
              ),
              Row(
                children: [
                  Text('第 $page / ${_chapters!.length} 章', style: TextStyle(fontSize: 11, color: _textColor.withOpacity(0.6))),

                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stripHtmlTags(String html) {
    var text = html.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    // 批 3：embed 模式 → 只 body（无 Scaffold + AppBar）
    if (widget.embedMode) {
      if (_isLoading) return _buildLoadingBody();
      if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
        return _buildErrorBody();
      }
      // embed 不启专注 → 恒走 Normal
      return _buildNormalBody();
    }

    // 非 embed：原态——Scaffold + AppBar
    if (_isLoading) {
      return ReaderShell(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: _appBarBgColor,
          foregroundColor: _appBarFgColor,
        ),
        body: _buildLoadingBody(),
      );
    }
    if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
      return ReaderShell(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: _appBarBgColor,
          foregroundColor: _appBarFgColor,
        ),
        body: _buildErrorBody(),
      );
    }
    if (_isFocusMode) {
      return ReaderShell(
        backgroundColor: _backgroundColor,
        isFocusMode: true,
        body: _buildFocusBody(),
      );
    }
    return ReaderShell(
      backgroundColor: _backgroundColor,
      appBar: _buildNormalAppBar(context),
      body: _buildNormalBody(),
    );
  }

  // ─── 批 3：body 抽离 ───

  Widget _buildLoadingBody() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载EPUB中...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 64, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            Text(_errorMessage ?? '无法加载EPUB',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.embedMode) {
                  widget.onExit?.call();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _appBarBgColor,
                  foregroundColor: _appBarFgColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusBody() {
    // ✅ v2：Listener 是 Stack 的 parent，不是 child。
    //   Stack.hitTestChildren 命中即停，Stack 内部的 Listener 会阻断下层 PageView / SelectableText。
    //   现在 Stack 内部只有 PageView 和 CardBoxPeek，两个都能正常接收手势。
    return Listener(
      onPointerDown: _onFocusPointerDown,
      onPointerUp: _onFocusPointerUp,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _buildChapterContent(_currentChapterIndex),
          _buildCardBoxPeek(),
        ],
      ),
    );
  }

  Future<void> _openMultiPaneFromReader() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiPanePage(
          initialLayout: 2,
          initialReaderBookId: widget.bookId,
          initialReaderBookTitle:
              _bookTitle.isEmpty ? widget.fileName : _bookTitle,
          initialReaderBookPath: widget.filePath,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_bookTitle.isEmpty ? widget.fileName : _bookTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (_bookAuthor.isNotEmpty)
            Text(_bookAuthor, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
      backgroundColor: _appBarBgColor,
      foregroundColor: _appBarFgColor,
      elevation: 0,
      actions: [
        IconButton(icon: const Icon(Icons.menu_book), onPressed: showToc, tooltip: '目录'),
        IconButton(icon: const Icon(Icons.search), onPressed: showSearch, tooltip: '搜索'),
        IconButton(icon: const Icon(Icons.format_list_bulleted), onPressed: showNotesPanel, tooltip: '标注列表'),
        if (!widget.embedMode)
          IconButton(
            icon: const Icon(Icons.view_column),
            tooltip: '并排阅读',
            onPressed: _openMultiPaneFromReader,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'focus': toggleFocusMode(); break;
              case 'mindmap': showMindMap(); break;
              case 'export_mindmap': exportMindMap(); break;
              case 'aggregate': showAggregatedNotes(); break;
              case 'rating': showRatingReviewDialog(); break;
              case 'stats': showReadingStats(); break;
              case 'batch_cards': showBatchCardDialog(); break;
              case 'export_notes': exportNotes(); break;

              case 'settings': openSettings(); break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'focus', child: Text('专注模式')),
            const PopupMenuItem(value: 'mindmap', child: Text('思维导图')),
            const PopupMenuItem(value: 'export_mindmap', child: Text('导出思维导图')),
            const PopupMenuItem(value: 'aggregate', child: Text('关联聚合')),
            const PopupMenuItem(value: 'rating', child: Text('评分书评')),
            const PopupMenuItem(value: 'stats', child: Text('阅读统计')),
            const PopupMenuItem(value: 'batch_cards', child: Text('批量生成卡片')),
            const PopupMenuItem(value: 'export_notes', child: Text('导出笔记')),

            const PopupMenuItem(value: 'settings', child: Text('设置')),
          ],
        ),
      ],
    );
  }

  Widget _buildNormalBody() {
    final total = _chapters!.length;
    final current = _currentChapterIndex;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('第 ${current + 1} / $total 章',
                      style: TextStyle(fontSize: 12, color: _textColor)),
                  Text('${total > 0 ? ((current + 1) / total * 100).round() : 0}%',
                      style: TextStyle(fontSize: 12, color: _textColor.withOpacity(0.7))),
                ],
              ),
            ),
            Expanded(
              child: _buildChapterContent(current),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: current > 0 ? () {
                      _loadChapterContent(current - 1);
                    } : null,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('上一章', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: current < total - 1 ? () {
                      _loadChapterContent(current + 1);
                    } : null,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('下一章', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildCardBoxPeek(),
      ],
    );
  }
}

// ---- 标注面板内容组件（带筛选功能，支持动态刷新） ----
class _NotesPanelContent extends StatefulWidget {
  final List<BookNote> Function() getNotes;
  final ValueChanged<BookNote> onJumpToNote;
  final int chaptersLength;
  final Future<void> Function(BookNote) onGenerateCard;
  final Future<void> Function(BookNote) onDeleteHighlight;

  const _NotesPanelContent({
    required this.getNotes,
    required this.onJumpToNote,
    required this.chaptersLength,
    required this.onGenerateCard,
    required this.onDeleteHighlight,
  });

  @override
  State<_NotesPanelContent> createState() => _NotesPanelContentState();
}

class _NotesPanelContentState extends State<_NotesPanelContent> {
  String _filter = 'all';
  List<BookNote> _notes = [];
  List<CardModel> _allCards = [];

  @override
  void initState() {
    super.initState();
    _notes = widget.getNotes();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await CardService().getAllCards();
      if (mounted) setState(() => _allCards = cards);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(_NotesPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notes = widget.getNotes();
  }

  List<BookNote> get _filteredNotes {
    if (_filter == 'highlight') {
      return _notes.where((n) => n.isHighlight && n.comment.isEmpty && n.selectedText != '【书签】').toList();
    } else if (_filter == 'comment') {
      return _notes.where((n) => n.comment.isNotEmpty && n.selectedText != '【书签】').toList();
    } else if (_filter == 'bookmark') {
      return _notes.where((n) => n.selectedText == '【书签】').toList();
    } else if (_filter == 'card') {
      return _notes.where((n) => n.selectedText != '【书签】' && _allCards.any((c) => c.sourceId == n.bookId && c.highlight == n.selectedText)).toList();
    }
    return _notes;
  }

  int get _highlightCount => _notes.where((n) => n.isHighlight && n.comment.isEmpty && n.selectedText != '【书签】').length;
  int get _commentCount => _notes.where((n) => (n.comment.isNotEmpty || !n.isHighlight) && n.selectedText != '【书签】').length;
  int get _bookmarkCount => _notes.where((n) => n.selectedText == '【书签】').length;
  int get _cardCount => _notes.where((n) => n.selectedText != '【书签】' && _allCards.any((c) => c.sourceId == n.bookId && c.highlight == n.selectedText)).length;

  void _refresh() {
    setState(() {
      _notes = widget.getNotes();
    });
    _loadCards();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📑 标注列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('全部', _notes.length, 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('高亮', _highlightCount, 'highlight'),
                const SizedBox(width: 8),
                _buildFilterChip('批注', _commentCount, 'comment'),
                const SizedBox(width: 8),
                _buildFilterChip('卡片', _cardCount, 'card'),
                const SizedBox(width: 8),
                _buildFilterChip('书签', _bookmarkCount, 'bookmark'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filteredNotes.isEmpty
              ? const Center(child: Text('暂无标注', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    // 查找关联的卡片
                    CardModel? matchedCard;
                    for (var c in _allCards) {
                      if (c.sourceId == note.bookId && c.highlight == note.selectedText) {
                        matchedCard = c;
                        break;
                      }
                    }
                    final isSticky = note.selectedText == '页边书摘';
                    final isBookmark = note.selectedText == '【书签】';

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isBookmark
                            ? Icons.bookmark
                            : (isSticky
                                ? Icons.sticky_note_2
                                : (note.comment.isNotEmpty
                                    ? Icons.comment
                                    : (matchedCard != null
                                        ? Icons.credit_card
                                        : (note.isHighlight ? Icons.highlight : Icons.comment)))),
                        color: isBookmark
                            ? Colors.red
                            : (isSticky
                                ? Colors.amber.shade700
                                : (note.comment.isNotEmpty
                                    ? Colors.orange
                                    : (matchedCard != null
                                        ? Colors.green
                                        : (note.isHighlight ? Colors.yellow.shade700 : Colors.orange)))),
                        size: 20,
                      ),
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: isSticky
                                ? const Text('随笔', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange))
                                : (isBookmark
                                    ? const Text('🔖 书签', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red))
                                    : Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                        child: Text(note.selectedText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      )),
                          ),
                          if (matchedCard != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: matchedCard.cardType == CardType.guide ? Colors.amber.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: matchedCard.cardType == CardType.guide ? Colors.amber.shade700 : Colors.grey.shade400),
                              ),
                              child: Text(
                                matchedCard.cardType == CardType.guide ? '读透卡' : '原子卡',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: matchedCard.cardType == CardType.guide ? Colors.orange.shade900 : Colors.grey.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: note.comment.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                note.comment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (note.pageNumber > 0 && note.pageNumber <= widget.chaptersLength) {
                          widget.onJumpToNote(note);
                        }
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.credit_card),
                                  title: const Text('生成卡片'),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await widget.onGenerateCard(note);
                                    _refresh();
                                  },
                                ),
                                if (note.isHighlight)
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                                    title: const Text('删除高亮', style: TextStyle(color: Colors.red)),
                                    onTap: () async {
                                      Navigator.pop(ctx);
                                      await widget.onDeleteHighlight(note);
                                      _refresh();
                                    },
                                  ),
                                ListTile(
                                  leading: const Icon(Icons.arrow_back),
                                  title: const Text('取消'),
                                  onTap: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int count, String filterValue) {
    final isSelected = _filter == filterValue;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = filterValue);
        }
      },
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ---- 辅助类 ----
class _HighlightRange {
  final int start;
  final int end;
  final BookNote note;
  _HighlightRange(this.start, this.end, this.note);
}