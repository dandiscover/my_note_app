// lib/pages/epub_reader_page.dart
// EPUB 阅读器 — 完整功能版

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  bool _isFocusMode = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  double _dailyGoalMinutes = 0.0;
  bool _reminderEnabled = false;
  double _reminderInterval = 30.0;
  Timer? _reminderTimer;
  bool _reminderShown = false;

  String _bookTitle = '';
  String _bookAuthor = '';

  Color _highlightColor = const Color(0xFFFFEB3B); // 默认黄色高亮
  final ScrollController _scrollController = ScrollController();

  String? _selectedText;
  final TextEditingController _noteController = TextEditingController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _readingStartTime = DateTime.now();
    _loadBook();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _reminderTimer?.cancel();
    _saveReadingTime();
    super.dispose();
  }

  Future<void> _loadBook() async {
    _book = await _bookService.getBook(widget.bookId);
    await _loadNotes();
    await _loadBookmarks();
    await _loadSummaries();
    await _loadRatingReview();
    await _loadUISettings();
    await _loadDailyGoal();
    await _loadReminderSettings();
    await _loadEpub();
  }

  // 批注加载
  Future<void> _loadNotes() async {
    try {
      final notes = await _bookService.getNotes(widget.bookId);
      setState(() => _notes = notes);
    } catch (e) {
      debugPrint('加载标注失败: $e');
    }
  }

  // 书签
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

  // 章节总结
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

  // 评分书评
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

  // UI 设置
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

  // 连续阅读提醒
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

  Color get _appBarColor {
    switch (_themeMode) {
      case 0: return Colors.orange.shade900;
      case 1: return const Color(0xFF8D6E63);
      case 2: return Colors.grey.shade900;
      default: return Colors.orange.shade900;
    }
  }

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

  // 阅读时长
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

  // 搜索
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

  // 目录
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

  // 专注模式
  void _toggleFocusMode() {
    setState(() => _isFocusMode = !_isFocusMode);
  }

  // 导出笔记
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

  // 导出思维导图
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

  // 页边书摘
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

  // 批量生成卡片
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ 已生成 $count 张卡片')));
    }
  }

  // 阅读统计
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

  // 加载 EPUB
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

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty && _selectedText == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选中文字或输入笔记内容')));
      return;
    }
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
    _noteController.clear();
    await _loadNotes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 批注已保存')));
  }

  Future<void> _highlightSelected(String selectedText) async {
    final highlightNote = BookNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      pageNumber: _currentChapterIndex + 1,
      selectedText: selectedText,
      comment: '',
      color: '#${_highlightColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      isHighlight: true,
    );
    await _bookService.saveNote(highlightNote);
    await _loadNotes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🖍️ 已高亮')));
  }

  Future<void> _generateCardFromSelected() async {
    if (_selectedText == null || _selectedText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选中文字')));
      return;
    }
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CardTypeDialog(selectedText: _selectedText!),
    );
    if (result != null && mounted) {
      final card = CardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardType: result['cardType'] as CardType,
        sourceType: 'book',
        sourceId: widget.bookId,
        sourceTitle: _book?.title ?? 'EPUB阅读',
        tags: [],
        front: result['front'] as String?,
        back: result['back'] as String?,
        indexTitle: result['indexTitle'] as String?,
        author: _book?.author,
        highlight: result['highlight'] as String?,
        question: result['question'] as String?,
        answer: result['answer'] as String?,
        importance: result['importance'] ?? Importance.medium,
        stage: 0,
        nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
      );
      await _cardService.addCard(card);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 卡片已生成！可在「智库 → 卡片盒」查看')));
    }
  }

  void _showNoteInputDialog(String? selectedText) {
    _selectedText = selectedText;
    _noteController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.note_add, color: Colors.orange), const SizedBox(width: 8), const Text('添加批注')]),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedText != null && selectedText.isNotEmpty) ...[
                const Text('📖 选中文字：', style: TextStyle(fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text(selectedText, style: const TextStyle(fontSize: 14)),
                ),
                const Text('💭 我的想法（可选）：'),
              ] else ...[
                const Text('💭 批注内容：'),
              ],
              const SizedBox(height: 4),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '写下你的思考...', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text('📌 第 ${_currentChapterIndex + 1} 章', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(context); _saveNote(); },
            icon: const Icon(Icons.save),
            label: const Text('保存批注'),
          ),
        ],
      ),
    );
  }

  void _showNotesList({String filter = '全部'}) {
    final grouped = <int, List<BookNote>>{};
    for (var note in _notes) {
      if (filter == '高亮' && !note.isHighlight) continue;
      if (filter == '批注' && note.isHighlight) continue;
      grouped.putIfAbsent(note.pageNumber, () => []).add(note);
    }
    final sortedPages = grouped.keys.toList()..sort();
    final highlightCount = _notes.where((n) => n.isHighlight).length;
    final commentCount = _notes.where((n) => !n.isHighlight).length;
    final bookmarkedCount = _bookmarks.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📑 标注列表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('高亮 $highlightCount · 批注 $commentCount · 书签 $bookmarkedCount', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(child: Text('暂无标注', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: sortedPages.length,
                      itemBuilder: (context, sectionIndex) {
                        final page = sortedPages[sectionIndex];
                        final items = grouped[page]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text('第 $page 章', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                            ...items.map((note) => ListTile(
                                  dense: true,
                                  leading: Icon(note.isHighlight ? Icons.highlight : Icons.comment, color: note.isHighlight ? Colors.yellow.shade700 : Colors.orange, size: 20),
                                  title: Text(note.selectedText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                  subtitle: note.comment.isNotEmpty ? Text(note.comment, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)) : null,
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (page > 0 && page <= (_chapters?.length ?? 0)) _pageController.jumpToPage(page - 1);
                                  },
                                  onLongPress: () {
                                    Navigator.pop(context);
                                    _convertToNote(note);
                                  },
                                )),
                          ],
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(onPressed: () { Navigator.pop(context); _showNotesList(filter: '全部'); }, child: const Text('全部')),
                  TextButton(onPressed: () { Navigator.pop(context); _showNotesList(filter: '高亮'); }, child: const Text('高亮')),
                  TextButton(onPressed: () { Navigator.pop(context); _showNotesList(filter: '批注'); }, child: const Text('批注')),
                  TextButton(onPressed: () { Navigator.pop(context); _showNotesList(filter: '书签'); }, child: const Text('书签')),
                ],
              ),
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
    final title = '阅读笔记：《${_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle}》';
    final content = '书籍：${_bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle}\n章节：第${note.pageNumber}章\n原文：${note.selectedText}\n批注：${note.comment}';
    final now = DateTime.now();
    final noteEntry = NotebookEntry(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      updatedAt: now,
      status: 'active',
      editorMode: 'plain',
      tags: ['阅读笔记', _bookTitle.isEmpty ? _book?.title ?? widget.fileName : _bookTitle],
    );
    await _db.insertNote(noteEntry.toMap());
    final folderId = await _db.ensureReviewFolder();
    await _db.attachNoteToNode(noteId: noteEntry.id, title: title, parentId: folderId, tags: noteEntry.tags);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 已转为智库笔记')));
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
                  child: SelectableText(
                    _stripHtmlTags(content),
                    style: TextStyle(fontSize: _fontSize, height: _lineHeight, color: _textColor, fontFamily: _fontFamily),
                    contextMenuBuilder: (context, editableTextState) {
                      final selectedText = editableTextState.textEditingValue.selection.textInside(editableTextState.textEditingValue.text);
                      if (selectedText.isEmpty) return const SizedBox.shrink();
                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: [
                          ContextMenuButtonItem(label: '🖍️ 高亮', onPressed: () => _highlightSelected(selectedText)),
                          ContextMenuButtonItem(label: '📝 批注', onPressed: () => _showNoteInputDialog(selectedText)),
                          ContextMenuButtonItem(label: '📇 生成卡片', onPressed: () { _selectedText = selectedText; _generateCardFromSelected(); }),
                          ...editableTextState.contextMenuButtonItems,
                        ],
                      );
                    },
                  ),
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
        appBar: AppBar(title: Text(widget.fileName), backgroundColor: _appBarColor, foregroundColor: Colors.white),
        body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('加载EPUB中...', style: TextStyle(color: Colors.grey))])),
      );
    }
    if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.fileName), backgroundColor: _appBarColor, foregroundColor: Colors.white),
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
                ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('返回'), style: ElevatedButton.styleFrom(backgroundColor: _appBarColor, foregroundColor: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }
    final total = _chapters!.length;
    final current = _currentChapterIndex;

    if (_isFocusMode) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: GestureDetector(
          onTap: _toggleFocusMode,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentChapterIndex = index);
              if (index > 0 && index < total) _loadChapterContent(index);
            },
            children: List.generate(total, (index) => _buildChapterContent(index)),
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
            if (_bookAuthor.isNotEmpty) Text(_bookAuthor, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: _appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.menu_book), onPressed: _showToc, tooltip: '目录'),
          IconButton(icon: const Icon(Icons.search), onPressed: _showSearch, tooltip: '搜索'),
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings, tooltip: '设置'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'focus': _toggleFocusMode(); break;
                case 'mindmap': _showMindMap(); break;
                case 'export_mindmap': _exportMindMap(); break;
                case 'aggregate': _showAggregatedNotes(); break;
                case 'rating': _showRatingReviewDialog(); break;
                case 'notes': _showNotesList(); break;
                case 'stats': _showReadingStats(); break;
                case 'batch_cards': _showBatchCardDialog(); break;
                case 'export_notes': _exportNotes(); break;
                case 'save_progress': _saveProgress(); break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'focus', child: Text('专注模式')),
              const PopupMenuItem(value: 'mindmap', child: Text('思维导图')),
              const PopupMenuItem(value: 'export_mindmap', child: Text('导出思维导图')),
              const PopupMenuItem(value: 'aggregate', child: Text('关联聚合')),
              const PopupMenuItem(value: 'rating', child: Text('评分书评')),
              const PopupMenuItem(value: 'notes', child: Text('标注列表')),
              const PopupMenuItem(value: 'stats', child: Text('阅读统计')),
              const PopupMenuItem(value: 'batch_cards', child: Text('批量生成卡片')),
              const PopupMenuItem(value: 'export_notes', child: Text('导出笔记')),
              const PopupMenuItem(value: 'save_progress', child: Text('保存进度')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: _appBarColor.withOpacity(0.1),
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
            color: _backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(onPressed: current > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null, icon: const Icon(Icons.arrow_back, size: 16), label: const Text('上一章', style: TextStyle(fontSize: 12))),
                TextButton.icon(onPressed: current < total - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null, icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('下一章', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTypeDialog extends StatefulWidget {
  final String selectedText;
  const _CardTypeDialog({required this.selectedText});
  @override
  State<_CardTypeDialog> createState() => _CardTypeDialogState();
}

class _CardTypeDialogState extends State<_CardTypeDialog> {
  CardType _selectedType = CardType.review;
  Importance _importance = Importance.medium;
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _frontController.text = widget.selectedText;
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📇 生成卡片'),
      content: SizedBox(
        width: 450,
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              children: CardType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _selectedType == type,
                  onSelected: (selected) => setState(() => _selectedType = type),
                  selectedColor: type.color.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _frontController, decoration: const InputDecoration(labelText: '正面 / 问题', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 8),
            TextField(controller: _backController, decoration: const InputDecoration(labelText: '背面 / 答案', border: OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('重要性：', style: TextStyle(fontWeight: FontWeight.w600)),
                ...Importance.values.map((imp) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      label: Text(imp.name),
                      selected: _importance == imp,
                      onSelected: (selected) => setState(() => _importance = imp),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            final result = {
              'cardType': _selectedType,
              'importance': _importance,
              'front': _frontController.text.trim(),
              'back': _backController.text.trim(),
            };
            Navigator.pop(context, result);
          },
          child: const Text('生成卡片'),
        ),
      ],
    );
  }
}