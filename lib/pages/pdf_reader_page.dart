import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../database_service.dart';
import '../models/book.dart';
import 'dart:convert';
import 'dart:html' as html;

class PDFReaderPage extends StatefulWidget {
  final String bookId;

  const PDFReaderPage({super.key, required this.bookId});

  @override
  State<PDFReaderPage> createState() => _PDFReaderPageState();
}

class _PDFReaderPageState extends State<PDFReaderPage> {
  final DatabaseService _db = DatabaseService();
  late PdfController _pdfController;
  Book? _book;
  bool _isLoading = true;
  bool _isPdfReady = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final map = await _db.getBook(widget.bookId);
    if (map == null) {
      setState(() => _isLoading = false);
      return;
    }

    final book = Book.fromMap(map);
    setState(() {
      _book = book;
      _isLoading = false;
    });

    await _loadPdf(book);
  }

  Future<void> _loadPdf(Book book) async {
    if (book.filePath.isEmpty) {
      setState(() => _isPdfReady = false);
      return;
    }

    try {
      PdfDocument document;

      // 判断是否为 Web 端 Base64（长度长且不以路径开头）
      final isWebBase64 = book.filePath.length > 200 &&
          !book.filePath.startsWith('/') &&
          !book.filePath.contains('\\');

      if (isWebBase64) {
  // Web 端：Base64 → Blob URL
  final bytes = base64Decode(book.filePath);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrl(blob);
  document = await PdfDocument.openUrl(url);
} else {
        // 原生端：文件路径
        document = await PdfDocument.openFile(book.filePath);
      }

      _pdfController = PdfController(
        document: Future.value(document),
      );

      _totalPages = document.pagesCount;
      _currentPage = book.readingProgress > 0
          ? (book.readingProgress / 100 * _totalPages).round().clamp(1, _totalPages)
          : 1;

      _pdfController.jumpToPage(_currentPage);
      setState(() => _isPdfReady = true);
    } catch (e) {
      print('加载PDF失败: $e');
      setState(() => _isPdfReady = false);
    }
  }

  Future<void> _saveProgress(int page) async {
    if (_book == null || _totalPages <= 0) return;
    final progress = (page / _totalPages * 100).round().clamp(0, 100);
    final updatedBook = Book(
      id: _book!.id,
      title: _book!.title,
      author: _book!.author,
      isbn: _book!.isbn,
      coverUrl: _book!.coverUrl,
      filePath: _book!.filePath,
      fileType: _book!.fileType,
      fileSize: _book!.fileSize,
      fileName: _book!.fileName,
      status: _book!.status,
      readingProgress: progress,
      totalPages: _book!.totalPages,
      createdAt: _book!.createdAt,
    );
    await _db.updateBook(updatedBook.toMap());
    setState(() => _book = updatedBook);
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF阅读器'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('书籍不存在')),
      );
    }

    if (!_isPdfReady) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_book!.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载PDF...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              // TODO: 标注列表
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfView(
              controller: _pdfController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _saveProgress(page);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {
                    if (_currentPage > 1) {
                      _pdfController.jumpToPage(_currentPage - 1);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Text(
                  '第 $_currentPage 页 / 共 $_totalPages 页',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    if (_currentPage < _totalPages) {
                      _pdfController.jumpToPage(_currentPage + 1);
                    }
                  },
                ),
                const SizedBox(width: 24),
                Text(
                  '进度: ${_book?.readingProgress ?? 0}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}