// lib/pages/library_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../database_service.dart';
import '../models/book.dart';
import 'book_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final DatabaseService _db = DatabaseService();
  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final maps = await _db.getAllBooks();
    setState(() {
      _books = maps.map((map) => Book.fromMap(map)).toList();
    });
  }

  // ============================================================
  // 入口一：导入电子版（自动创建，不需要输入书名）
  // ============================================================
  Future<void> _importFile() async {
    try {
      String fileName;
      Uint8List fileBytes;
      String fileType;

      if (kIsWeb) {
        // ---- Web 端 ----
        final input = html.FileUploadInputElement();
        input.accept = '.pdf,.epub';
        input.click();

        await input.onChange.first;
        if (input.files!.isEmpty) return;
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoadEnd.first;

        fileBytes = reader.result as Uint8List;
        fileName = file.name;
        fileType = _getFileType(fileName);
      } else {
        // ---- 原生端 ----
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'epub'],
        );
        if (result == null) return;

        final file = result.files.first;
        fileBytes = file.bytes ?? Uint8List(0);
        fileName = file.name;
        fileType = _getFileType(fileName);
      }

      if (fileType == 'none') {
        _showSnackBar('不支持的文件格式，请选择 PDF 或 EPUB');
        return;
      }

      // 从文件名提取书名（去掉扩展名）
      final title = fileName.replaceAll(RegExp(r'\.[^.]*$'), '');

      // 创建书籍记录
      final newBook = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        filePath: kIsWeb ? base64Encode(fileBytes) : '',
        fileType: fileType,
        fileSize: fileBytes.length,
        fileName: fileName,
        createdAt: DateTime.now(),
      );

      await _db.insertBook(newBook.toMap());

      _showSnackBar('已导入《$title》');

      // 跳转到详情页
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(bookId: newBook.id),
          ),
        );
        // 返回时刷新列表
        await _loadBooks();
      }
    } catch (e) {
      print('导入失败: $e');
      _showSnackBar('导入失败，请重试');
    }
  }

  // ============================================================
  // 入口二：扫ISBN（自动获取元数据，不需要用户输入）
  // ============================================================
  Future<void> _scanISBN() async {
    // TODO: 集成 mobile_scanner 实现扫码
    // 当前阶段先用模拟输入框方便测试
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('扫ISBN'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '请输入ISBN号码（测试用）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('查询'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final isbn = controller.text.trim();
    if (isbn.isEmpty) return;

    // 调用 API 获取书籍信息
    final bookInfo = await _fetchBookByISBN(isbn);
    if (bookInfo == null) {
      _showSnackBar('未找到 ISBN: $isbn 对应的书籍');
      return;
    }

    // 创建书籍记录
    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: bookInfo['title'] ?? '未知书名',
      author: bookInfo['author'] ?? '',
      isbn: isbn,
      coverUrl: bookInfo['coverUrl'] ?? '',
      createdAt: DateTime.now(),
    );

    await _db.insertBook(newBook.toMap());

    _showSnackBar('已添加《${newBook.title}》');

    // 跳转到详情页
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(bookId: newBook.id),
        ),
      );
      await _loadBooks();
    }
  }

  // ============================================================
  // 入口三：手动添加（用户输入书名，作者/ISBN可选）
  // ============================================================
  Future<void> _manualAdd() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动添加书籍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '书名 *',
                hintText: '必填',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: '作者',
                hintText: '可选',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                hintText: '可选',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                _showSnackBar('请输入书名');
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final title = titleController.text.trim();
    if (title.isEmpty) return;

    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      author: authorController.text.trim(),
      isbn: isbnController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _db.insertBook(newBook.toMap());

    _showSnackBar('已添加《$title》');

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(bookId: newBook.id),
        ),
      );
      await _loadBooks();
    }
  }

  // ============================================================
  // 辅助方法
  // ============================================================

  String _getFileType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.pdf')) return 'pdf';
    if (ext.endsWith('.epub')) return 'epub';
    return 'none';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 通过 ISBN 查询 Google Books API
  Future<Map<String, String>?> _fetchBookByISBN(String isbn) async {
    try {
      final url =
          'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['items'] == null || data['items'].isEmpty) return null;

      final info = data['items'][0]['volumeInfo'];
      return {
        'title': info['title'] ?? '未知书名',
        'author': (info['authors'] as List?)?.join(', ') ?? '',
        'coverUrl': info['imageLinks']?['thumbnail'] ?? '',
        'publisher': info['publisher'] ?? '',
      };
    } catch (e) {
      print('ISBN查询失败: $e');
      return null;
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 图书馆'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: '添加书籍',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importFile();
                  break;
                case 'scan':
                  _scanISBN();
                  break;
                case 'manual':
                  _manualAdd();
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
              PopupMenuItem(
                value: 'manual',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 12),
                    Text('手动添加'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _books.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '还没有书籍',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击右上角「+」添加',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final book = _books[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailPage(bookId: book.id),
                        ),
                      );
                      await _loadBooks();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              image: book.coverUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(book.coverUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: book.coverUrl.isEmpty
                                ? Icon(
                                    book.fileType == 'none'
                                        ? Icons.book
                                        : Icons.picture_as_pdf,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author.isNotEmpty ? book.author : '未知作者',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (book.hasEbook)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '📖 已导入',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}