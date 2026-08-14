import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../database_service.dart';
import '../models/book.dart';
import 'dart:convert';
import 'dart:typed_data';

class PDFReaderPagePdfrx extends StatefulWidget {
  final String bookId;
  const PDFReaderPagePdfrx({super.key, required this.bookId});

  @override
  State<PDFReaderPagePdfrx> createState() => _PDFReaderPagePdfrxState();
}

class _PDFReaderPagePdfrxState extends State<PDFReaderPagePdfrx> {
  final DatabaseService _db = DatabaseService();
  Book? _book;
  bool _isLoading = true;
  Uint8List? _pdfBytes;

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
      setState(() => _isLoading = false);
      return;
    }

    try {
      final isWebBase64 = book.filePath.length > 200 &&
          !book.filePath.startsWith('/') &&
          !book.filePath.contains('\\');

      if (isWebBase64) {
        _pdfBytes = base64Decode(book.filePath);
      } else {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('加载PDF失败: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('加载中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null || _pdfBytes == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF阅读器'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('无法加载PDF')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_book!.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) => _pdfBytes!,
        allowPrinting: false,
        allowSharing: false,
      ),
    );
  }
}