import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter

import '../database_service.dart';
import '../models/book.dart';
import 'book_detail_page.dart';

class InspirationPage extends StatefulWidget {
  const InspirationPage({super.key});

  @override
  State<InspirationPage> createState() => _InspirationPageState();
}

class _InspirationPageState extends State<InspirationPage> {
  final DatabaseService _db = DatabaseService();
  List<Book> _recentBooks = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    if (!mounted) return;
    try {
      final maps = await _db.getAllBooks();
      if (!mounted) return;
      setState(() {
        _recentBooks = maps.map((map) => Book.fromMap(map)).toList();
      });
    } catch (e) {
      // 忽略错误，避免页面崩溃
    }
  }

  // ---- 快速捕获入口 ----
  void _quickNote() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('快速笔记功能开发中...')),
    );
  }

  void _voiceRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音记录功能开发中...')),
    );
  }

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('拍照记录功能开发中...')),
    );
  }

  void _drawBoard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画板功能开发中...')),
    );
  }

  // ---- 图书导入 ----
  Future<void> _importFile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能开发中...')),
    );
  }

  Future<void> _scanISBN() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('扫码功能开发中...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 灵感'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: '添加',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importFile();
                  break;
                case 'scan':
                  _scanISBN();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 12),
                    Text('导入电子版'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner),
                    SizedBox(width: 12),
                    Text('扫ISBN'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快速捕获',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCaptureCard(
                  icon: Icons.edit_note,
                  label: '文字',
                  color: Colors.blue.shade100,
                  onTap: _quickNote,
                ),
                _buildCaptureCard(
                  icon: Icons.mic,
                  label: '语音',
                  color: Colors.green.shade100,
                  onTap: _voiceRecord,
                ),
                _buildCaptureCard(
                  icon: Icons.camera_alt,
                  label: '拍照',
                  color: Colors.orange.shade100,
                  onTap: _takePhoto,
                ),
                _buildCaptureCard(
                  icon: Icons.brush,
                  label: '画板',
                  color: Colors.purple.shade100,
                  onTap: _drawBoard,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '最近采集',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_recentBooks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '还没有采集内容\n点击右上角「+」导入图书',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentBooks.length > 5 ? 5 : _recentBooks.length,
                itemBuilder: (context, index) {
                  final book = _recentBooks[index];
                  return ListTile(
                    leading: const Icon(Icons.book, color: Colors.grey),
                    title: Text(book.title),
                    subtitle: Text(
                      book.author.isNotEmpty ? book.author : '未知作者',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailPage(bookId: book.id),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.grey.shade700),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}