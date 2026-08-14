import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/book.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'pdf_reader_page.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;
  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final DatabaseService _db = DatabaseService();
  Book? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final map = await _db.getBook(widget.bookId);
    if (map != null) {
      setState(() {
        _book = Book.fromMap(map);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_book == null) return;
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
      status: newStatus,
      readingProgress: _book!.readingProgress,
      totalPages: _book!.totalPages,
      createdAt: _book!.createdAt,
    );
    await _db.updateBook(updatedBook.toMap());
    setState(() {
      _book = updatedBook;
    });
  }

  Future<void> _updateProgress(int newProgress) async {
    if (_book == null) return;
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
      readingProgress: newProgress,
      totalPages: _book!.totalPages,
      createdAt: _book!.createdAt,
    );
    await _db.updateBook(updatedBook.toMap());
    setState(() {
      _book = updatedBook;
    });
  }

  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除《${_book?.title}》吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true && _book != null) {
      await _db.deleteBook(_book!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _importFile() async {
    if (_book == null) return;

    try {
      if (kIsWeb) {
        // ---- Web 端 ----
        final input = html.FileUploadInputElement();
        input.accept = '.pdf,.epub,.mobi,.azw3,.cbr,.cbz';
        input.click();

        await input.onChange.first;
        if (input.files!.isEmpty) return;
        final file = input.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoadEnd.first;

        final bytes = reader.result as Uint8List;
        final fileName = file.name;
        final fileType = _getFileType(fileName);
        final base64String = base64Encode(bytes);

        final updatedBook = Book(
          id: _book!.id,
          title: _book!.title,
          author: _book!.author,
          isbn: _book!.isbn,
          coverUrl: _book!.coverUrl,
          filePath: base64String,
          fileType: fileType,
          fileSize: bytes.length,
          fileName: fileName,
          status: _book!.status,
          readingProgress: _book!.readingProgress,
          totalPages: _book!.totalPages,
          createdAt: _book!.createdAt,
        );
        await _db.updateBook(updatedBook.toMap());
        setState(() => _book = updatedBook);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入《${_book!.title}》')),
          );
        }
      } else {
        // ---- 原生端 ----
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'epub', 'mobi', 'azw3', 'cbr', 'cbz'],
        );
        if (result == null) return;

        final file = result.files.first;
        final path = file.path;
        final fileName = file.name;
        final fileType = _getFileType(fileName);

        if (path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法获取文件路径')),
            );
          }
          return;
        }

        final updatedBook = Book(
          id: _book!.id,
          title: _book!.title,
          author: _book!.author,
          isbn: _book!.isbn,
          coverUrl: _book!.coverUrl,
          filePath: path,
          fileType: fileType,
          fileSize: file.size,
          fileName: fileName,
          status: _book!.status,
          readingProgress: _book!.readingProgress,
          totalPages: _book!.totalPages,
          createdAt: _book!.createdAt,
        );
        await _db.updateBook(updatedBook.toMap());
        setState(() => _book = updatedBook);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入《${_book!.title}》')),
          );
        }
      }
    } catch (e) {
      print('导入失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入失败，请重试')),
        );
      }
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.pdf')) return 'pdf';
    if (ext.endsWith('.epub')) return 'epub';
    if (ext.endsWith('.mobi')) return 'mobi';
    if (ext.endsWith('.azw3')) return 'azw3';
    if (ext.endsWith('.cbr')) return 'cbr';
    if (ext.endsWith('.cbz')) return 'cbz';
    return 'none';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('图书详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('图书详情'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('书籍不存在或已被删除')),
      );
    }

    final book = _book!;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(),
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteBook,
            tooltip: '删除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- 封面 + 基本信息 ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 160,
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
                      ? const Icon(Icons.book, size: 48, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author.isNotEmpty ? book.author : '未知作者',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (book.isbn.isNotEmpty)
                        Text(
                          'ISBN: ${book.isbn}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(book.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(book.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(book.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---- 阅读状态切换 ----
            const Text(
              '阅读状态',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip('想读', 'want', book.status),
                const SizedBox(width: 8),
                _buildStatusChip('在读', 'reading', book.status),
                const SizedBox(width: 8),
                _buildStatusChip('读完', 'read', book.status),
              ],
            ),

            const SizedBox(height: 16),

            // ---- 阅读进度 ----
            Row(
              children: [
                const Text(
                  '阅读进度',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${book.readingProgress}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: book.readingProgress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${book.readingProgress}%',
              onChanged: (value) => _updateProgress(value.round()),
            ),

            const SizedBox(height: 24),

            // ---- 操作按钮 ----
            const Text(
              '操作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _importFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('导入电子版'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('扫码功能开发中...')),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('扫ISBN'),
                ),
                if (book.hasEbook)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (book.fileType == 'pdf') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PDFReaderPage(bookId: book.id),
                          ),
                        );
                      } else if (book.fileType == 'epub') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('EPUB阅读器开发中...')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('暂不支持 ${book.fileType} 格式')),
                        );
                      }
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('继续阅读'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // ---- 关联笔记 ----
            const Text(
              '关联笔记',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Center(
                child: Text(
                  '暂无关联笔记\n阅读并标注后会自动生成',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, String current) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _updateStatus(value),
      selectedColor: _getStatusColor(value).withOpacity(0.3),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? _getStatusColor(value) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'want': return '想读';
      case 'reading': return '在读';
      case 'read': return '读完';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'want': return Colors.orange;
      case 'reading': return Colors.blue;
      case 'read': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: _book?.title ?? '');
    final authorController = TextEditingController(text: _book?.author ?? '');
    final isbnController = TextEditingController(text: _book?.isbn ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑书籍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '书名'),
            ),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: '作者'),
            ),
            TextField(
              controller: isbnController,
              decoration: const InputDecoration(labelText: 'ISBN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && _book != null) {
      final updatedBook = Book(
        id: _book!.id,
        title: titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : _book!.title,
        author: authorController.text.trim(),
        isbn: isbnController.text.trim(),
        coverUrl: _book!.coverUrl,
        filePath: _book!.filePath,
        fileType: _book!.fileType,
        fileSize: _book!.fileSize,
        fileName: _book!.fileName,
        status: _book!.status,
        readingProgress: _book!.readingProgress,
        totalPages: _book!.totalPages,
        createdAt: _book!.createdAt,
      );
      await _db.updateBook(updatedBook.toMap());
      setState(() {
        _book = updatedBook;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新')),
        );
      }
    }
  }
}