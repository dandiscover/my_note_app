// lib/pages/txt_reader_page.dart
// TXT / MD 阅读页 —— Step 4B
// 对齐 EpubReaderPage 签名，支持 embedMode 多栏接入。
// 4B 不做进度保存，_saveProgress() 留空钩子，4C 填。
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../services/book_service.dart';
import '../services/multi_pane_bus.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';
import '../services/txt_parser_service.dart';
import 'reader/reader_shell.dart';

class TxtReaderPage extends StatefulWidget {
  final String bookId;
  final String filePath;
  final String? fileUrl;
  final String fileName;
  final bool isWeb;
  final MultiPaneBus? multiPaneBus;
  final bool embedMode;
  final VoidCallback? onExit;

  const TxtReaderPage({
    super.key,
    required this.bookId,
    required this.filePath,
    this.fileUrl,
    required this.fileName,
    this.isWeb = false,
    this.multiPaneBus,
    this.embedMode = false,
    this.onExit,
  });

  @override
  State<TxtReaderPage> createState() => _TxtReaderPageState();
}

class _TxtReaderPageState extends State<TxtReaderPage> {
  final BookService _bookService = BookService();
  final TxtParserService _parser = TxtParserService();

  Book? _book;
  List<TxtChapter>? _chapters;
  int _currentChapterIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  TxtParserPreset _preset = TxtParserPreset.defaultNewline;
  String? _customRegEx;
  String? _customPrefix;

  Color _backgroundColor = const Color(0xFFF5F0E1);
  Color _textColor = const Color(0xFF4E342E);
  double _fontSize = 16.0;
  double _lineHeight = 1.8;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  /// 4C 钩子：进度保存挂这里
  void _saveProgress() {
    // TODO(4C): 统一进度保存方案
  }

  Future<void> _loadBook() async {
    try {
      _book = await _bookService.getBook(widget.bookId);
      final raw = await _readRawText();
      final chapters = _parser.parse(
        raw,
        preset: _preset,
        customRegEx: _customRegEx,
        customPrefix: _customPrefix,
      );
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _currentChapterIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  Future<String> _readRawText() async {
    if (widget.isWeb) {
      final url = widget.fileUrl?.isNotEmpty == true ? widget.fileUrl! : widget.filePath;
      final resp = await http.get(Uri.parse(url));
      return resp.body;
    }
    final file = File(widget.filePath);
    return await file.readAsString();
  }

  void _onChapterTap(int index) {
    setState(() => _currentChapterIndex = index);
    Navigator.pop(context);
  }

  void _openChapterList() {
    final chapters = _chapters;
    if (chapters == null || chapters.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          itemCount: chapters.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(chapters[i].title),
            selected: i == _currentChapterIndex,
            onTap: () => _onChapterTap(i),
          ),
        ),
      ),
    );
  }

  Future<void> _translateSelection(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🌐 正在翻译...'), duration: Duration(seconds: 1)),
      );
    }
    final result = await EmptyTranslationService().translate(t);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('翻译结果'),
        content: SingleChildScrollView(child: SelectableText(result)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  Future<void> _readCurrentChapter() async {
    final chapters = _chapters;
    if (chapters == null || chapters.isEmpty) return;
    final content = chapters[_currentChapterIndex].content;
    if (content.trim().isEmpty) return;
    await EmptyTtsService().speak(content);
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: Text(_book?.title ?? widget.fileName),
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book),
          tooltip: '目录',
          onPressed: _openChapterList,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            switch (v) {
              case 'tts_read':
                _readCurrentChapter();
                break;
              case 'tts_stop':
                EmptyTtsService().stop();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'tts_read', child: Text('🔊 朗读本页')),
            PopupMenuItem(value: 'tts_stop', child: Text('⏹ 停止朗读')),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingBody() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '无法加载 TXT',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenu(BuildContext context, SelectableRegionState state) {
    final items = state.contextMenuButtonItems;
    items.add(
      ContextMenuButtonItem(
        label: '🌐 翻译',
        onPressed: () {
          ContextMenuController.removeAny();
          _translateSelection(_selectedText);
        },
      ),
    );
    items.add(
      ContextMenuButtonItem(
        label: '🔊 朗读',
        onPressed: () {
          ContextMenuController.removeAny();
          if (_selectedText.trim().isNotEmpty) {
            EmptyTtsService().speak(_selectedText);
          }
        },
      ),
    );
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  Widget _buildNormalBody() {
    final chapters = _chapters;
    if (chapters == null || chapters.isEmpty) {
      return const Center(child: Text('无内容'));
    }
    final content = chapters[_currentChapterIndex].content;
    return SelectionArea(
      onSelectionChanged: (sel) {
        _selectedText = sel?.plainText ?? '';
      },
      contextMenuBuilder: _buildContextMenu,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: TextStyle(
            fontSize: _fontSize,
            height: _lineHeight,
            color: _textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      if (_isLoading) return _buildLoadingBody();
      if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
        return _buildErrorBody();
      }
      return _buildNormalBody();
    }

    if (_isLoading) {
      return ReaderShell(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: Colors.grey.shade200,
        ),
        body: _buildLoadingBody(),
      );
    }
    if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
      return ReaderShell(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: Colors.grey.shade200,
        ),
        body: _buildErrorBody(),
      );
    }
    return ReaderShell(
      backgroundColor: _backgroundColor,
      appBar: _buildNormalAppBar(),
      body: _buildNormalBody(),
    );
  }
}