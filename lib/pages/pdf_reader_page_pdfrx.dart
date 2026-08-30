// lib/pages/pdf_reader_page.dart
// PDF 阅读器

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../database_service.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import '../services/book_service.dart';

class PdfReaderPage extends StatefulWidget {
  final String bookId;
  final String? filePath;
  final String? fileUrl;
  final bool isWeb;
  final String fileName;

  const PdfReaderPage({
    super.key,
    required this.bookId,
    this.filePath,
    this.fileUrl,
    this.isWeb = false,
    this.fileName = '文档',
  });

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  final BookService _bookService = BookService();
  final DatabaseService _db = DatabaseService();

  Book? _book;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;

  String? _selectedText;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    _book = await _bookService.getBook(widget.bookId);
    await _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);

    try {
      String? sourcePath = widget.filePath ?? _book?.filePath;

      if (widget.isWeb && widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        await _loadPdfFromUrl(widget.fileUrl!);
        return;
      }

      if (widget.isWeb && sourcePath != null && sourcePath.startsWith('blob:')) {
        await _loadPdfFromUrl(sourcePath);
        return;
      }

      if (widget.isWeb && sourcePath != null && sourcePath.length > 200 &&
          !sourcePath.startsWith('/') && !sourcePath.startsWith('blob:') &&
          !sourcePath.startsWith('http') && !sourcePath.startsWith('data:')) {
        try {
          _pdfBytes = base64Decode(sourcePath);
          setState(() => _isLoading = false);
          return;
        } catch (_) {}
      }

      if (sourcePath != null && sourcePath.isNotEmpty && !widget.isWeb) {
        final file = File(sourcePath);
        if (await file.exists()) {
          _pdfBytes = await file.readAsBytes();
          setState(() => _isLoading = false);
          return;
        }
      }

      setState(() {
        _errorMessage = '无法加载PDF文件';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载PDF失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdfFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _pdfBytes = response.bodyBytes;
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _errorMessage = '无法下载PDF: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '下载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    if (_book != null && _totalPages > 0) {
      final progress = (_currentPage / _totalPages * 100).round();
      final updated = _book!.copyWith(
        readingProgress: progress,
        totalPages: _totalPages,
        lastReadAt: DateTime.now(),
      );
      await _bookService.saveBook(updated);
      _book = updated;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📖 已保存进度: $_currentPage / $_totalPages 页')),
      );
    }
  }

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
      pageNumber: _currentPage,
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

  void _showNoteInputDialog(String? selectedText) {
    _selectedText = selectedText;
    _noteController.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.note_add, color: Colors.blue),
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
              Text('📌 第 $_currentPage 页',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('取消')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载PDF中...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.fileName),
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_errorMessage ?? '无法加载PDF',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.grey.shade900,
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
      body: PdfPreview(
  build: (format) => _pdfBytes!,
  allowPrinting: true,
  allowSharing: true,
  // ✅ 正确的回调签名
  onPageChanged: (page) {
    // 注意：PdfPreview 的 onPageChanged 只返回当前页，不返回总页数
    // 总页数需要通过其他方式获取
    setState(() {
      _currentPage = page;
    });
  },
  initialPage: _book?.readingProgress ?? 0,
),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey.shade900,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('第 $_currentPage / $_totalPages 页',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                Text('${_totalPages > 0 ? (_currentPage / _totalPages * 100).round() : 0}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}