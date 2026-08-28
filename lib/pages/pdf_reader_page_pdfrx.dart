// lib/pages/pdf_reader_page.dart
// PDF阅读器 — 支持 Web/桌面双平台

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../database_service.dart';
import '../models/book.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

// ✅ 类名改为 PdfReaderPage，与 book_detail_page.dart 匹配
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
  final DatabaseService _db = DatabaseService();
  Book? _book;
  bool _isLoading = true;
  Uint8List? _pdfBytes;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final map = await _db.getBook(widget.bookId);
    if (map == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '图书不存在';
      });
      return;
    }

    final book = Book.fromMap(map);
    setState(() {
      _book = book;
    });

    await _loadPdf(book);
  }

  Future<void> _loadPdf(Book book) async {
    setState(() => _isLoading = true);

    try {
      String? sourcePath = widget.filePath ?? book.filePath;

      // ✅ Web 端：从 URL 加载
      if (widget.isWeb && widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        await _loadPdfFromUrl(widget.fileUrl!);
        return;
      }

      // ✅ Web 端：Base64 编码存储
      if (sourcePath != null && sourcePath.length > 200 &&
          !sourcePath.startsWith('/') && !sourcePath.contains('\\') &&
          !sourcePath.startsWith('http')) {
        try {
          _pdfBytes = base64Decode(sourcePath);
          setState(() => _isLoading = false);
          return;
        } catch (_) {
          // 不是 Base64，继续其他方式
        }
      }

      // ✅ 桌面端：从文件系统加载
      if (sourcePath != null && sourcePath.isNotEmpty) {
        final file = io.File(sourcePath);
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

  void _saveProgress() {
    if (_book != null && _totalPages > 0) {
      final progress = (_currentPage / _totalPages * 100).round();
      _db.updateBook(_book!.copyWith(readingProgress: progress).toMap());
    }
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
              Text(
                _errorMessage ?? '无法加载PDF',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
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
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              _saveProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📖 已保存进度')),
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _pdfBytes!,
        allowPrinting: true,
        allowSharing: true,
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page;
            _totalPages = total;
          });
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey.shade900,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '第 $_currentPage / $_totalPages 页',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${_totalPages > 0 ? (_currentPage / _totalPages * 100).round() : 0}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}