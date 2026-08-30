// lib/pages/epub_reader_page.dart
// EPUB 阅读器 — 支持选中文字做笔记 + 生成卡片

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:http/http.dart' as http;

import '../database_service.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import '../models/card.dart';
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

  // ✅ 选中文字相关
  String? _selectedText;
  final TextEditingController _noteController = TextEditingController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    _book = await _bookService.getBook(widget.bookId);
    await _loadEpub();
  }

  Future<void> _loadEpub() async {
    setState(() => _isLoading = true);

    try {
      Uint8List? epubData;
      String? sourcePath = widget.filePath ?? _book?.filePath;

      if (widget.isWeb && widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        final response = await http.get(Uri.parse(widget.fileUrl!));
        if (response.statusCode == 200) {
          epubData = Uint8List.fromList(response.bodyBytes);
        }
      }

      if (widget.isWeb && sourcePath != null && sourcePath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(sourcePath));
        if (response.statusCode == 200) {
          epubData = Uint8List.fromList(response.bodyBytes);
        }
      }

      if (epubData == null && sourcePath != null && sourcePath.length > 200 &&
          !sourcePath.startsWith('/') && !sourcePath.startsWith('blob:') &&
          !sourcePath.startsWith('http') && !sourcePath.startsWith('file:')) {
        try {
          final bytes = base64Decode(sourcePath);
          epubData = Uint8List.fromList(bytes);
        } catch (_) {}
      }

      if (epubData == null && sourcePath != null && sourcePath.isNotEmpty) {
        final file = File(sourcePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          epubData = Uint8List.fromList(bytes);
        }
      }

      if (epubData == null) {
        setState(() {
          _errorMessage = '无法加载EPUB文件';
          _isLoading = false;
        });
        return;
      }

      _epubBook = await EpubReader.readBook(epubData);
      _chapters = _epubBook?.Chapters;
      _currentChapterIndex = _book?.readingProgress ?? 0;
      if (_currentChapterIndex >= (_chapters?.length ?? 0)) {
        _currentChapterIndex = 0;
      }

      await _loadChapterContent(_currentChapterIndex);

      setState(() => _isLoading = false);

      if (_currentChapterIndex > 0) {
        _pageController.jumpToPage(_currentChapterIndex);
      }
    } catch (e) {
      debugPrint('加载EPUB失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChapterContent(int index) async {
    if (_epubBook == null || _chapters == null || index >= _chapters!.length) return;
    try {
      final chapter = _chapters![index];
      String content = chapter.HtmlContent ?? '（本章无内容）';

      if (content.isEmpty) {
        content = '（本章无内容）';
      }

      if (index >= _chapterContents.length) {
        _chapterContents.addAll(List.filled(index - _chapterContents.length + 1, ''));
      }
      _chapterContents[index] = content;
    } catch (e) {
      debugPrint('加载章节 $index 失败: $e');
      if (index >= _chapterContents.length) {
        _chapterContents.addAll(List.filled(index - _chapterContents.length + 1, ''));
      }
      _chapterContents[index] = '（加载章节内容失败）';
    }
  }

  Future<void> _saveProgress() async {
    if (_book != null && _chapters != null) {
      final total = _chapters!.length;
      final progress = total > 0 ? (_currentChapterIndex / total * 100).round() : 0;
      final updated = _book!.copyWith(
        readingProgress: progress,
        totalPages: total,
        lastReadAt: DateTime.now(),
      );
      await _bookService.saveBook(updated);
      _book = updated;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📖 已保存进度: 第 ${_currentChapterIndex + 1} / $total 章')),
      );
    }
  }

  // ─── ✅ 选中文字 → 做笔记 ──────────────────────────────────

  Future<void> _saveNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty && _selectedText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选中文字或输入笔记内容')),
      );
      return;
    }

    final note = BookNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      pageNumber: _currentChapterIndex + 1,
      selectedText: _selectedText ?? text,
      comment: _selectedText != null ? text : '',
      color: '#FFD93D',
    );

    await _bookService.saveNote(note);
    _selectedText = null;
    _noteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 笔记已保存')),
    );
  }

  // ─── ✅ 选中文字 → 生成卡片 ─────────────────────────────────

  Future<void> _generateCardFromSelected() async {
    if (_selectedText == null || _selectedText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选中文字')),
      );
      return;
    }

    // 显示卡片类型选择对话框
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 卡片已生成！可在「智库 → 卡片盒」查看')),
      );
    }
  }

  // ─── 显示笔记输入对话框 ────────────────────────────────────

  void _showNoteInputDialog(String? selectedText) {
    _selectedText = selectedText;
    _noteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.note_add, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('添加阅读笔记'),
          ],
        ),
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
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(selectedText, style: const TextStyle(fontSize: 14)),
                ),
                const Text('💭 我的想法（可选）：'),
              ] else ...[
                const Text('💭 笔记内容：'),
              ],
              const SizedBox(height: 4),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '写下你的思考...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Text(
                '📌 第 ${_currentChapterIndex + 1} 章',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveNote();
            },
            icon: const Icon(Icons.save),
            label: const Text('保存笔记'),
          ),
        ],
      ),
    );
  }

  // ─── ✅ 构建章节内容（支持选中文字） ────────────────────────

  Widget _buildChapterContent(int index) {
    if (_chapters == null || index >= _chapters!.length) {
      return const Center(child: Text('章节不存在'));
    }

    final chapter = _chapters![index];
    final content = index < _chapterContents.length
        ? _chapterContents[index]
        : '（加载中...）';

    final title = chapter.Title ?? '第 ${index + 1} 章';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // ✅ 使用 SelectableText 显示纯文本 + 悬浮工具栏
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                // 从 HTML 中提取纯文本（简化处理，保留换行）
                _stripHtmlTags(content),
                style: const TextStyle(fontSize: 16, height: 1.8),
                contextMenuBuilder: (context, editableTextState) {
                  final selectedText = editableTextState.textEditingValue.selection
                      .textInside(editableTextState.textEditingValue.text);
                  if (selectedText.isEmpty) return const SizedBox.shrink();

                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: [
                      // ✅ 做笔记
                      ContextMenuButtonItem(
                        label: '📝 做笔记',
                        onPressed: () {
                          _showNoteInputDialog(selectedText);
                        },
                      ),
                      // ✅ 生成卡片
                      ContextMenuButtonItem(
                        label: '📇 生成卡片',
                        onPressed: () {
                          _selectedText = selectedText;
                          _generateCardFromSelected();
                        },
                      ),
                      ...editableTextState.contextMenuButtonItems,
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.book, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    '第 ${index + 1} / ${_chapters!.length} 章',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: 20, color: Colors.orange),
                onPressed: _saveProgress,
                tooltip: '保存进度',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ 辅助方法：去除 HTML 标签，提取纯文本
  String _stripHtmlTags(String html) {
    // 去除 <style>...</style> 和 <script>...</script>
    var text = html.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    // 将 <br> 和 <p> 替换为换行
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    // 去除所有其他 HTML 标签
    text = text.replaceAll(RegExp(r'<[^>]+>', caseSensitive: false), '');
    // 解码 HTML 实体
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    // 合并多个换行
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: Colors.orange.shade900,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载EPUB中...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _chapters == null || _chapters!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: Colors.orange.shade900,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories, size: 64, color: Colors.orange.shade400),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? '无法加载EPUB',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total = _chapters!.length;
    final current = _currentChapterIndex;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.orange.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () => _showNoteInputDialog(null),
            tooltip: '添加笔记',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _saveProgress,
            tooltip: '保存进度',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📖 ${widget.fileName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${total > 0 ? ((current + 1) / total * 100).round() : 0}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentChapterIndex = index;
                });
                if (index > 0 && index < total) {
                  _loadChapterContent(index);
                }
              },
              children: List.generate(total, (index) {
                return _buildChapterContent(index);
              }),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: current > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('上一章'),
                ),
                TextButton.icon(
                  onPressed: current < total - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('下一章'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.shade900,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '第 ${current + 1} / $total 章',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.note_add, color: Colors.white70, size: 20),
                  onPressed: () => _showNoteInputDialog(null),
                  tooltip: '添加笔记',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Text(
                  '${total > 0 ? ((current + 1) / total * 100).round() : 0}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 卡片类型选择对话框 ──────────────────────────────────────

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
            // 卡片类型选择
            Wrap(
              spacing: 4,
              children: CardType.values.map((type) {
                return ChoiceChip(
                  label: Text(type.label),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() => _selectedType = type);
                  },
                  selectedColor: type.color.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 正面/问题
            TextField(
              controller: _frontController,
              decoration: const InputDecoration(
                labelText: '正面 / 问题',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            // 背面/答案
            TextField(
              controller: _backController,
              decoration: const InputDecoration(
                labelText: '背面 / 答案',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            // 重要性
            Row(
              children: [
                const Text('重要性：', style: TextStyle(fontWeight: FontWeight.w600)),
                ...Importance.values.map((imp) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      label: Text(imp.name),
                      selected: _importance == imp,
                      onSelected: (selected) {
                        setState(() => _importance = imp);
                      },
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
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