// lib/pages/epub_reader_page.dart
// EPUB 阅读器（简化版）

import 'package:flutter/material.dart';

class EpubReaderPage extends StatelessWidget {
  final String bookId;
  final String filePath;
  final String fileUrl;
  final String fileName;
  final bool isWeb;

  const EpubReaderPage({
    super.key,
    required this.bookId,
    this.filePath = '',
    this.fileUrl = '',
    required this.fileName,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 80, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            Text(
              fileName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '📖 EPUB 阅读功能开发中',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
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
}