// lib/pages/pdf_reader_page.dart
// PDF 阅读器 — 使用 dart_pdf_editor（支持标注/批注/高亮）

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dart_pdf_editor/dart_pdf_editor.dart';
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
  PdfFile? _pdfFile;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;

  // 编辑器控制器
  PdfEditorController? _controller;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    _book = await _bookService.getBook(widget.bookId);
    await _loadPdf();
  }

  // ─── 加载 PDF ────────────────────────────────────────────────

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);

    try {
      Uint8List? pdfData;
      String? sourcePath = widget.filePath ?? _book?.filePath;

      // ✅ Web 端：从 URL 加载（blob: 或 http:）
      if (widget.isWeb && widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
        pdfData = await _loadPdfFromUrl(widget.fileUrl!);
        if (pdfData != null) {
          _pdfFile = PdfFile.fromBytes(pdfData);
          setState(() => _isLoading = false);
          return;
        }
      }

      // ✅ Web 端：处理 blob: URL
      if (widget.isWeb && sourcePath != null && sourcePath.startsWith('blob:')) {
        pdfData = await _loadPdfFromUrl(sourcePath);
        if (pdfData != null) {
          _pdfFile = PdfFile.fromBytes(pdfData);
          setState(() => _isLoading = false);
          return;
        }
      }

      // ✅ Web 端：Base64 解码（小文件兼容）
      if (widget.isWeb && sourcePath != null && sourcePath.length > 200 &&
          !sourcePath.startsWith('/') && !sourcePath.startsWith('blob:') &&
          !sourcePath.startsWith('http') && !sourcePath.startsWith('data:')) {
        try {
          pdfData = base64Decode(sourcePath);
          _pdfFile = PdfFile.fromBytes(pdfData);
          setState(() => _isLoading = false);
          return;
        } catch (_) {}
      }

      // ✅ 桌面端：从文件系统加载
      if (sourcePath != null && sourcePath.isNotEmpty && !widget.isWeb) {
        final file = File(sourcePath);
        if (await file.exists()) {
          pdfData = await file.readAsBytes();
          _pdfFile = PdfFile.fromBytes(pdfData);
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

  Future<Uint8List?> _loadPdfFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── 保存进度 ────────────────────────────────────────────────

  Future<void> _saveProgress(int page, int total) async {
    if (_book != null && total > 0) {
      final progress = (page / total * 100).round();
      final updated = _book!.copyWith(
        readingProgress: progress,
        totalPages: total,
        lastReadAt: DateTime.now(),
      );
      await _bookService.saveBook(updated);
      _book = updated;
    }
  }

  // ─── 保存标注笔记 ────────────────────────────────────────────

  Future<void> _saveAnnotation(String text, int page) async {
    if (text.trim().isEmpty) return;

    final note = BookNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      pageNumber: page,
      selectedText: text,
      comment: '',
      color: '#FFD93D',
    );

    await _bookService.saveNote(note);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 批注已保存')),
    );
  }

  // ─── 导出标注 ────────────────────────────────────────────────

  Future<void> _exportAnnotations() async {
    if (_controller == null) return;
    try {
      final annotations = await _controller!.getAllAnnotations();
      if (annotations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有标注可导出')),
        );
        return;
      }

      // 生成文本摘要
      final buffer = StringBuffer();
      buffer.writeln('# ${_book?.title ?? 'PDF'} 批注汇总');
      buffer.writeln('导出时间: ${DateTime.now()}');
      buffer.writeln('=' * 50);

      for (var ann in annotations) {
        buffer.writeln('📌 第 ${ann.page} 页');
        buffer.writeln('   ${ann.text}');
        if (ann.color != null) {
          buffer.writeln('   颜色: ${ann.color}');
        }
        buffer.writeln();
      }

      // 复制到剪贴板或显示对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📝 批注汇总'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: SingleChildScrollView(
              child: Text(buffer.toString(), style: const TextStyle(fontSize: 13)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  // ─── UI 构建 ──────────────────────────────────────────────────

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

    if (_errorMessage != null || _pdfFile == null) {
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        actions: [
          // 导出批注
          IconButton(
            icon: const Icon(Icons.notes),
            onPressed: _exportAnnotations,
            tooltip: '导出批注',
          ),
          // 保存进度
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              _saveProgress(_currentPage, _totalPages);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('📖 已保存进度: $_currentPage / $_totalPages 页')),
              );
            },
            tooltip: '保存进度',
          ),
        ],
      ),
      body: PdfEditorView(
        file: _pdfFile!,
        onController: (controller) {
          _controller = controller;
        },
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page;
            _totalPages = total;
          });
          // 每翻5页自动保存进度
          if (page % 5 == 0) {
            _saveProgress(page, total);
          }
        },
        // 工具栏配置
        toolbarConfig: PdfToolbarConfig(
          showAnnotation: true,      // ✅ 显示批注工具
          showHighlight: true,       // ✅ 显示高亮工具
          showUnderline: true,       // ✅ 显示下划线工具
          showStrikeout: true,       // ✅ 显示删除线工具
          showShape: true,           // ✅ 显示形状工具
          showText: true,            // ✅ 显示文本工具
          showFreehand: true,        // ✅ 显示手绘工具
          showUndoRedo: true,        // ✅ 显示撤销/重做
          showPageNavigator: true,   // ✅ 显示页码导航
          showZoom: true,            // ✅ 显示缩放工具
        ),
        theme: PdfTheme(
          primaryColor: Colors.blue.shade700,
          backgroundColor: Colors.grey.shade50,
          toolbarColor: Colors.grey.shade900,
          toolbarTextColor: Colors.white,
        ),
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.note_add, color: Colors.white70, size: 20),
                  onPressed: () {
                    _showAnnotationDialog();
                  },
                  tooltip: '添加批注',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_totalPages > 0 ? (_currentPage / _totalPages * 100).round() : 0}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 批注对话框 ──────────────────────────────────────────────

  void _showAnnotationDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.note_add, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('添加批注'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📌 第 $_currentPage 页',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '输入批注内容...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveAnnotation(controller.text.trim(), _currentPage);
                // 添加批注到编辑器
                if (_controller != null) {
                  _controller!.addAnnotation(
                    page: _currentPage,
                    text: controller.text.trim(),
                  );
                }
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入批注内容')),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('保存批注'),
          ),
        ],
      ),
    );
  }
}