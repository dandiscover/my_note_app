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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:epubx/epubx.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../database_service.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import '../models/card.dart';
import '../models/note.dart';
import '../services/book_service.dart';
import '../services/card_service.dart';
import '../widgets/reader/card_box_peek.dart';
import '../widgets/reader/reading_guide_card.dart';

class EpubReaderPage extends StatefulWidget {
  final String bookId;
  final String? filePath;
  final String? fileUrl;
  final bool isWeb;
  final String fileName;

  const EpubReaderPage({
    super.key,
    required this.bookId,
    this.filePath,
    this.fileUrl,
    this.isWeb = false,
    this.fileName = '文档',
  });

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
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
  String _fontFamily = 'sans-serif';
  int _themeMode = 0;
  Color _customBackgroundColor = const Color(0xFFF5F0E1);
  Color _customTextColor = const Color(0xFF4E342E);

  DateTime? _readingStartTime;
  bool _isFocusMode = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  double _dailyGoalMinutes = 0.0;
  bool _reminderEnabled = false;
  double _reminderInterval = 30.0;
  Timer? _reminderTimer;
  bool _reminderShown = false;

  bool _cardBoxVisible = false;
  Timer? _cardBoxDelayTimer;
  Timer? _cardBoxHideTimer;
  String? _peekSelectedText;

  // ✅ 问题1：专注模式"单击退出"指针判定状态
  static const int _focusTapMaxDurationMs = 300;
  Offset? _focusPointerDownPos;
  DateTime? _focusPointerDownAt;

  String _bookTitle = '';
  String _bookAuthor = '';

  Color _highlightColor = const Color(0xFFFFEB3B);
  final ScrollController _scrollController = ScrollController();

  String? _selectedText;
  final PageController _pageController = PageController();

  final Map<int, List<_HighlightRange>> _highlightRanges = {};
  final Set<String> _highlightedWithCard = {};

  @override
  void initState() {
    super.initState();
    _readingStartTime = DateTime.now();
    _loadBook();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _reminderTimer?.cancel();
    _cardBoxDelayTimer?.cancel();
    _cardBoxHideTimer?.cancel();
    _saveReadingTime();
    super.dispose();
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
    setState(() {
      if (_bookmarks.contains(page)) {
        _bookmarks.remove(page);
      } else {
        _bookmarks.add(page);
      }
    });
    await _saveBookmarks();
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

  void _showRatingReviewDialog() {
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

  void _openSettings() {
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
                              setState(() {});
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
                              setState(() {});
                            },
                          ),
                        ),
                        Text(_lineHeight.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
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

  void _showSearch() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _searchQuery);
        return AlertDialog(
          title: const Text('全文搜索'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入关键词', border: OutlineInputBorder()),
            onSubmitted: (value) {
              setState(() => _searchQuery = value.trim());
              Navigator.pop(context);
              _performSearch();
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            ElevatedButton(onPressed: () {
              setState(() => _searchQuery = controller.text.trim());
              Navigator.pop(context);
              _performSearch();
            }, child: const Text('搜索')),
          ],
        );
      },
    );
  }

  void _performSearch() {
    if (_searchQuery.isEmpty || _chapters == null) return;
    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < _chapters!.length; i++) {
      final title = _chapters![i].Title ?? '第 ${i + 1} 章';
      final content = i < _chapterContents.length ? _stripHtmlTags(_chapterContents[i]) : '';
      final titleMatch = title.toLowerCase().contains(_searchQuery.toLowerCase());
      final contentMatches = content.toLowerCase().split(_searchQuery.toLowerCase()).length - 1;
      if (titleMatch || contentMatches > 0) {
        results.add({'index': i, 'title': title, 'count': contentMatches});
      }
    }
    setState(() => _searchResults = results);
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未找到结果')));
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, idx) {
            final r = results[idx];
            return ListTile(
              leading: const Icon(Icons.search),
              title: Text(r['title']),
              subtitle: Text('匹配 ${r['count']} 处'),
              onTap: () {
                Navigator.pop(context);
                _pageController.jumpToPage(r['index'] as int);
              },
            );
          },
        ),
      );
    }
  }

  void _showToc() {
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
                      Navigator.pop(context);
                      _pageController.jumpToPage(index);
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

  void _toggleFocusMode() {
    setState(() => _isFocusMode = !_isFocusMode);
  }

  void _exportNotes() {
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

  void _exportMindMap() {
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
    if (_cardBoxVisible && start.dx >= cardBoxLeft) {
      return;
    }

    final elapsed = DateTime.now().difference(startAt).inMilliseconds;
    final moved = (event.position - start).distance;
    if (elapsed < _focusTapMaxDurationMs && moved < kTouchSlop) {
      setState(() => _isFocusMode = false);
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
    setState(() => _cardBoxVisible = true);
    _cardBoxHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _cardBoxVisible = false);
    });
  }

  void _onMenuActionTapped() {
    _cardBoxDelayTimer?.cancel();
    if (_cardBoxVisible) {
      _cardBoxHideTimer?.cancel();
      if (mounted) setState(() => _cardBoxVisible = false);
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
    return CardBoxPeek(
      visible: _cardBoxVisible,
      onReadThrough: () {
        final text = _peekSelectedText ?? '';
        if (text.isNotEmpty) _openReadingGuide(text);
      },
      onCardSelected: (card) {
        if (card.cardType == CardType.guide) {
          final text = _peekSelectedText ?? '';
          if (text.isNotEmpty) {
            _openReadingGuide(text);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('指导卡需要在阅读时使用。打开一本书，划线后调出。')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${card.typeLabel} 尚未接入阅读器')),
            );
          }
        }
      },
    );
  }

  // ---------------------- 核心交互 ----------------------
  Future<void> _saveHighlight(String selectedText) async {
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
      selectedText: selectedText,
      comment: '',
      color: '#${_highlightColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      isHighlight: true,
    );
    await _bookService.saveNote(note);
    await _loadNotes();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🖍️ 已高亮')));
  }

  void _showWriteThoughtDialog(String selectedText) {
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
                  selectedText: selectedText,
                  comment: comment,
                  color: '#${_highlightColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                  isHighlight: true,
                );
                if (exists) {
                  final existing = _notes.firstWhere((n) =>
                      n.selectedText == selectedText &&
                      n.pageNumber == _currentChapterIndex + 1 &&
                      n.isHighlight);
                  final updated = BookNote(
                    id: existing.id,
                    bookId: existing.bookId,
                    pageNumber: existing.pageNumber,
                    selectedText: existing.selectedText,
                    comment: comment,
                    color: existing.color,
                    isHighlight: true,
                  );
                  await _bookService.saveNote(updated);
                } else {
                  await _bookService.saveNote(note);
                }
                await _loadNotes();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💭 想法已保存')));
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCardDirectly(String selectedText) async {
    if (selectedText.isEmpty) return;
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
    await _refreshCardMarkers();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 已删除高亮')));
    }
  }

  // ---------------------- 构建富文本 ----------------------
  Widget _buildRichText(String content, int chapterIndex) {
    final plain = _stripHtmlTags(content);
    if (plain.isEmpty) {
      return Text(
        '（本章无内容）',
        style: TextStyle(fontSize: _fontSize, height: _lineHeight, color: _textColor, fontFamily: _fontFamily),
      );
    }

    final ranges = _highlightRanges[chapterIndex] ?? [];
    final List<InlineSpan> spans = [];
    int currentPos = 0;
    final sorted = List<_HighlightRange>.from(ranges)..sort((a, b) => a.start.compareTo(b.start));

    const int shortTextThreshold = 50;

    for (var range in sorted) {
      if (range.start > plain.length) continue;
      if (range.start < currentPos) continue;
      if (range.start > currentPos) {
        spans.add(TextSpan(
          text: plain.substring(currentPos, range.start),
          style: TextStyle(fontSize: _fontSize, height: _lineHeight, color: _textColor, fontFamily: _fontFamily),
        ));
      }

      final end = range.end > plain.length ? plain.length : range.end;
      String highlightedText = plain.substring(range.start, end);
      final bool isLong = highlightedText.length > shortTextThreshold;
      final bool hasComment = range.note.comment.isNotEmpty;
      final bool hasCard = _highlightedWithCard.contains(range.note.selectedText);

      if (!isLong) {
        spans.add(TextSpan(
          text: highlightedText,
          style: TextStyle(
            fontSize: _fontSize,
            height: _lineHeight,
            color: _textColor,
            fontFamily: _fontFamily,
            backgroundColor: _highlightColor.withOpacity(0.6),
          ),
        ));
      } else {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 4,
            height: _fontSize * _lineHeight,
            color: Colors.orange.shade700,
            margin: const EdgeInsets.only(right: 6),
          ),
        ));

        spans.add(TextSpan(
          text: '「',
          style: TextStyle(
            fontSize: _fontSize - 2,
            height: _lineHeight,
            color: Colors.orange.shade700,
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ));

        spans.add(TextSpan(
          text: highlightedText,
          style: TextStyle(
            fontSize: _fontSize,
            height: _lineHeight,
            color: _textColor,
            fontFamily: _fontFamily,
            backgroundColor: _highlightColor.withOpacity(0.15),
          ),
        ));

        spans.add(TextSpan(
          text: '」',
          style: TextStyle(
            fontSize: _fontSize - 2,
            height: _lineHeight,
            color: Colors.orange.shade700,
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ));
      }

      if (hasComment) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('💭 ${range.note.comment}')),
              );
            },
            child: Icon(
              Icons.cloud_outlined,
              size: _fontSize * 0.9,
              color: Colors.grey.shade600,
            ),
          ),
        ));
      }

      if (hasCard) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📇 已生成卡片')),
              );
            },
            child: Icon(
              Icons.credit_card,
              size: _fontSize * 0.9,
              color: Colors.orange.shade600,
            ),
          ),
        ));
      }

      currentPos = end;
    }

    if (currentPos < plain.length) {
      spans.add(TextSpan(
        text: plain.substring(currentPos),
        style: TextStyle(fontSize: _fontSize, height: _lineHeight, color: _textColor, fontFamily: _fontFamily),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(fontSize: _fontSize, height: _lineHeight, color: _textColor, fontFamily: _fontFamily),
      contextMenuBuilder: (context, editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        if (!selection.isValid || selection.isCollapsed) return const SizedBox.shrink();
        final selectedText = selection.textInside(editableTextState.textEditingValue.text);
        if (selectedText.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startCardBoxDelayTimer(selectedText);
        });

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
              label: '复制',
              onPressed: () {
                _onMenuActionTapped();
                Clipboard.setData(ClipboardData(text: selectedText));
                editableTextState.hideToolbar();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已复制')));
              },
            ),
            ContextMenuButtonItem(
              label: '高亮',
              onPressed: () {
                _onMenuActionTapped();
                _saveHighlight(selectedText);
                editableTextState.hideToolbar();
              },
            ),
            ContextMenuButtonItem(
              label: '写想法',
              onPressed: () {
                _onMenuActionTapped();
                editableTextState.hideToolbar();
                _showWriteThoughtDialog(selectedText);
              },
            ),
            ContextMenuButtonItem(
              label: '做卡片',
              onPressed: () {
                _onMenuActionTapped();
                editableTextState.hideToolbar();
                _createCardDirectly(selectedText);
              },
            ),
          ],
        );
      },
    );
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
    if (text.isEmpty && _selectedText == null) return;
    final note = BookNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      pageNumber: _currentChapterIndex + 1,
      selectedText: _selectedText ?? text,
      comment: _selectedText != null ? text : '',
      color: '#FFD93D',
      isHighlight: false,
    );
    await _bookService.saveNote(note);
    _selectedText = null;
    await _loadNotes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 书摘已保存')));
  }

  void _showBatchCardDialog() {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 已生成 $count 张卡片')));
    }
  }

  void _showReadingStats() async {
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
            const Text('最近7天阅读时长（分钟）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      if (epubData == null && sourcePath != null && sourcePath.isNotEmpty) {
        final file = File(sourcePath);
        if (await file.exists()) epubData = Uint8List.fromList(await file.readAsBytes());
      }
      if (epubData == null) {
        setState(() { _errorMessage = '无法加载EPUB文件'; _isLoading = false; });
        return;
      }
      _epubBook = await EpubReader.readBook(epubData);
      _chapters = _epubBook?.Chapters;
      if (_epubBook != null) {
        _bookTitle = _epubBook!.Title ?? widget.fileName;
        _bookAuthor = _epubBook!.Author ?? '未知作者';
      }
      _currentChapterIndex = _book?.readingProgress ?? 0;
      if (_currentChapterIndex >= (_chapters?.length ?? 0)) _currentChapterIndex = 0;
      await _loadChapterContent(_currentChapterIndex);
      setState(() => _isLoading = false);
      if (_currentChapterIndex > 0) _pageController.jumpToPage(_currentChapterIndex);
      _startReminderTimer();
    } catch (e) {
      debugPrint('加载EPUB失败: $e');
      setState(() { _errorMessage = '加载失败: $e'; _isLoading = false; });
    }
  }

  Future<void> _loadChapterContent(int index) async {
    if (_epubBook == null || _chapters == null || index >= _chapters!.length) return;
    try {
      final chapter = _chapters![index];
      String content = chapter.HtmlContent ?? '（本章无内容）';
      if (content.isEmpty) content = '（本章无内容）';
      if (index >= _chapterContents.length) _chapterContents.addAll(List.filled(index - _chapterContents.length + 1, ''));
      _chapterContents[index] = content;
      _rebuildHighlightRanges();
    } catch (_) {}
  }

  Future<void> _saveProgress() async {
    if (_book != null && _chapters != null) {
      final total = _chapters!.length;
      final progress = total > 0 ? (_currentChapterIndex / total * 100).round() : 0;
      final updated = _book!.copyWith(readingProgress: progress, totalPages: total, lastReadAt: DateTime.now());
      await _bookService.saveBook(updated);
      _book = updated;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📖 已保存进度: 第 ${_currentChapterIndex + 1} / $total 章')));
    }
  }

  void _showNotesPanel() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭标注列表',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.white,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: _NotesPanelContent(
                  getNotes: () => _notes,
                  pageController: _pageController,
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

  void _showMindMap() {
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
                                      _pageController.jumpToPage(index);
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

  void _showAggregatedNotes() {
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

  Future<void> _convertToNote(BookNote note) async {
    final content = '书籍：${_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle}\n章节：第${note.pageNumber}章\n原文：${note.selectedText}\n批注：${note.comment}';
    await _appendToBookNote(content);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已转为智库笔记')));
    }
  }

  Widget _buildChapterContent(int index) {
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
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildRichText(content, index),
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
                  IconButton(icon: Icon(Icons.bookmark_border, size: 20, color: _textColor.withOpacity(0.6)), onPressed: _saveProgress, tooltip: '保存进度'),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: _appBarBgColor,
          foregroundColor: _appBarFgColor,
        ),
        body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('加载EPUB中...', style: TextStyle(color: Colors.grey))])),
      );
    }
    if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: _appBarBgColor,
          foregroundColor: _appBarFgColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories, size: 64, color: Colors.orange.shade400),
                const SizedBox(height: 16),
                Text(_errorMessage ?? '无法加载EPUB', style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回'),
                  style: ElevatedButton.styleFrom(backgroundColor: _appBarBgColor, foregroundColor: _appBarFgColor),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final total = _chapters!.length;
    final current = _currentChapterIndex;

    if (_isFocusMode) {
      // ✅ v2：Listener 是 Stack 的 parent，不是 child。
      //   Stack.hitTestChildren 命中即停，Stack 内部的 Listener 会阻断下层 PageView / SelectableText。
      //   现在 Stack 内部只有 PageView 和 CardBoxPeek，两个都能正常接收手势。
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Listener(
          onPointerDown: _onFocusPointerDown,
          onPointerUp: _onFocusPointerUp,
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentChapterIndex = index);
                  if (index > 0 && index < total) _loadChapterContent(index);
                },
                children: List.generate(total, (index) => _buildChapterContent(index)),
              ),
              _buildCardBoxPeek(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_bookTitle.isEmpty ? widget.fileName : _bookTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_bookAuthor.isNotEmpty) Text(_bookAuthor, style:TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        backgroundColor: _appBarBgColor,
        foregroundColor: _appBarFgColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.menu_book), onPressed: _showToc, tooltip: '目录'),
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearch, tooltip: '搜索'),
          IconButton(icon: const Icon(Icons.format_list_bulleted), onPressed: _showNotesPanel, tooltip: '标注列表'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'focus': _toggleFocusMode(); break;
                case 'mindmap': _showMindMap(); break;
                case 'export_mindmap': _exportMindMap(); break;
                case 'aggregate': _showAggregatedNotes(); break;
                case 'rating': _showRatingReviewDialog(); break;
                case 'stats': _showReadingStats(); break;
                case 'batch_cards': _showBatchCardDialog(); break;
                case 'export_notes': _exportNotes(); break;
                case 'save_progress': _saveProgress(); break;
                case 'settings': _openSettings(); break;
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
              const PopupMenuItem(value: 'save_progress', child: Text('保存进度')),
              const PopupMenuItem(value: 'settings', child: Text('设置')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('第 ${current + 1} / $total 章', style: TextStyle(fontSize: 12, color: _textColor)),
                    Text('${total > 0 ? ((current + 1) / total * 100).round() : 0}%', style: TextStyle(fontSize: 12, color: _textColor.withOpacity(0.7))),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentChapterIndex = index);
                    if (index > 0 && index < total) _loadChapterContent(index);
                  },
                  children: List.generate(total, (index) => _buildChapterContent(index)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: current > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('上一章', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: current < total - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
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
      ),
    );
  }
}

// ---- 标注面板内容组件（带筛选功能，支持动态刷新） ----
class _NotesPanelContent extends StatefulWidget {
  final List<BookNote> Function() getNotes;
  final PageController pageController;
  final int chaptersLength;
  final Future<void> Function(BookNote) onGenerateCard;
  final Future<void> Function(BookNote) onDeleteHighlight;

  const _NotesPanelContent({
    required this.getNotes,
    required this.pageController,
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

  @override
  void initState() {
    super.initState();
    _notes = widget.getNotes();
  }

  @override
  void didUpdateWidget(_NotesPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notes = widget.getNotes();
  }

  List<BookNote> get _filteredNotes {
    if (_filter == 'highlight') {
      return _notes.where((n) => n.isHighlight).toList();
    } else if (_filter == 'comment') {
      return _notes.where((n) => n.comment.isNotEmpty).toList();
    }
    return _notes;
  }

  int get _highlightCount => _notes.where((n) => n.isHighlight).length;
  int get _commentCount => _notes.where((n) => n.comment.isNotEmpty).length;

  void _refresh() {
    setState(() {
      _notes = widget.getNotes();
    });
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
          child: Row(
            children: [
              _buildFilterChip('全部', _notes.length, 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('高亮', _highlightCount, 'highlight'),
              const SizedBox(width: 8),
              _buildFilterChip('批注', _commentCount, 'comment'),
            ],
          ),
        ),
        Expanded(
          child: _filteredNotes.isEmpty
              ? const Center(child: Text('暂无标注', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = _filteredNotes[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        note.isHighlight ? Icons.highlight : Icons.comment,
                        color: note.isHighlight ? Colors.yellow.shade700 : Colors.orange,
                        size: 20,
                      ),
                      title: Text(
                        note.selectedText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: note.comment.isNotEmpty
                          ? Text(
                              note.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (note.pageNumber > 0 && note.pageNumber <= widget.chaptersLength) {
                          widget.pageController.jumpToPage(note.pageNumber - 1);
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