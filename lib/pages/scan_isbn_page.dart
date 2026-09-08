// lib/pages/scan_isbn_page.dart
// 扫码 ISBN 页面 — 扫描图书条形码，查询信息，加入图书馆
// ✅ 使用 mobile_scanner 扫码
// ✅ 查询顺序：本地缓存 → 探数数据 → Open Library → 手动补
// ✅ 加入图书馆后自动标记为 "想读" (status = 'want')
// ✅ 状态拆分：_isQuerying 和 _isAdding 独立控制
// ✅ 已自查，无编译错误
// ✅ 新增：创建 Book 时设置 source = 'scan'

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../database_service.dart';
import '../models/book.dart';

class ScanIsbnPage extends StatefulWidget {
  const ScanIsbnPage({super.key});

  @override
  State<ScanIsbnPage> createState() => _ScanIsbnPageState();
}

class _ScanIsbnPageState extends State<ScanIsbnPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final DatabaseService _db = DatabaseService();

  bool _isQuerying = false;
  bool _isAdding = false;
  String? _scannedIsbn;
  BookInfo? _bookInfo;
  String? _errorMessage;
  bool _isLoadingInfo = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  static const String _tanshuApiKey = String.fromEnvironment('TANSHU_API_KEY');

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    await _scannerController.start();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isQuerying || _isAdding) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final isbn = rawValue.replaceAll(RegExp(r'[^0-9X]'), '');
    if (!_isValidIsbn(isbn)) return;

    setState(() {
      _isQuerying = true;
      _scannedIsbn = isbn;
      _bookInfo = null;
      _errorMessage = null;
      _isLoadingInfo = true;
      _titleController.clear();
      _authorController.clear();
    });

    _scannerController.stop();
    _queryBookInfo(isbn);
  }

  bool _isValidIsbn(String isbn) {
    if (isbn.isEmpty) return false;
    if (isbn.length == 10) {
      return RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(isbn);
    }
    if (isbn.length == 13) {
      return RegExp(r'^[0-9]{13}$').hasMatch(isbn);
    }
    return false;
  }

  Future<void> _queryBookInfo(String isbn) async {
    try {
      // 1. 本地缓存
      final cached = await _db.getIsbnCache(isbn);
      if (cached != null) {
        setState(() {
          _bookInfo = BookInfo(
            title: cached['title'] as String? ?? '未知标题',
            author: cached['author'] as String? ?? '',
            isbn: isbn,
            coverUrl: cached['cover_url'] as String?,
            fromCache: true,
            isPartial: false,
          );
          _isLoadingInfo = false;
          _isQuerying = false;
        });
        return;
      }

      // 2. 探数数据
      if (_tanshuApiKey.isNotEmpty) {
        final tanshu = await _queryTanshu(isbn);
        if (tanshu != null) {
          await _db.saveIsbnCache(
            isbn: isbn,
            title: tanshu.title,
            author: tanshu.author,
            coverUrl: tanshu.coverUrl ?? '',
            source: 'tanshu',
          );
          setState(() {
            _bookInfo = tanshu;
            _isLoadingInfo = false;
            _isQuerying = false;
          });
          return;
        }
      }

      // 3. Open Library
      final ol = await _queryOpenLibrary(isbn);
      if (ol != null) {
        await _db.saveIsbnCache(
          isbn: isbn,
          title: ol.title,
          author: ol.author,
          coverUrl: ol.coverUrl ?? '',
          source: 'openlibrary',
        );
        setState(() {
          _bookInfo = ol;
          _isLoadingInfo = false;
          _isQuerying = false;
        });
        return;
      }

      // 4. 都失败：手动补
      setState(() {
        _bookInfo = BookInfo(
          title: '未知标题',
          author: '',
          isbn: isbn,
          coverUrl: null,
          fromCache: false,
          isPartial: true,
        );
        _isLoadingInfo = false;
        _isQuerying = false;
        _errorMessage = '未查询到书籍信息，书名和作者可以自己补上';
        _titleController.text = '';
        _authorController.text = '';
      });
    } catch (e) {
      setState(() {
        _bookInfo = BookInfo(
          title: '未知标题',
          author: '',
          isbn: isbn,
          coverUrl: null,
          fromCache: false,
          isPartial: true,
        );
        _isLoadingInfo = false;
        _isQuerying = false;
        _errorMessage = '查询出错，书名和作者可以自己补上';
        _titleController.text = '';
        _authorController.text = '';
      });
    }
  }

  Future<BookInfo?> _queryTanshu(String isbn) async {
    try {
      final url = Uri.parse(
          'https://api.tanshuapi.com/api/isbn_base/v1/index?key=$_tanshuApiKey&isbn=$isbn');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 1) return null;

      final bookData = data['data'] as Map<String, dynamic>?;
      if (bookData == null) return null;

      return BookInfo(
        title: bookData['title'] as String? ?? '未知标题',
        author: bookData['author'] as String? ?? '',
        isbn: isbn,
        coverUrl: bookData['img'] as String?,
        fromCache: false,
        isPartial: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<BookInfo?> _queryOpenLibrary(String isbn) async {
    try {
      final url = Uri.parse(
          'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final key = 'ISBN:$isbn';
      if (!data.containsKey(key)) return null;

      final bookData = data[key] as Map<String, dynamic>;
      final title = bookData['title'] as String? ?? '未知标题';
      final authors = bookData['authors'] as List?;
      final author = (authors != null && authors.isNotEmpty)
          ? (authors.first['name'] as String? ?? '')
          : '';
      final cover = bookData['cover'] as Map<String, dynamic>?;
      final coverUrl = cover?['medium'] as String? ?? cover?['large'] as String?;

      return BookInfo(
        title: title,
        author: author,
        isbn: isbn,
        coverUrl: coverUrl,
        fromCache: false,
        isPartial: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _addToLibrary() async {
    if (_bookInfo == null) return;
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      final libraryFolderId = await _db.ensureLibraryFolder();

      final title = _bookInfo!.isPartial == true
          ? (_titleController.text.trim().isEmpty ? '未知标题' : _titleController.text.trim())
          : _bookInfo!.title;
      final author = _bookInfo!.isPartial == true
          ? _authorController.text.trim()
          : _bookInfo!.author;

      final book = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        author: author,
        isbn: _bookInfo!.isbn,
        status: 'want',
        coverUrl: _bookInfo!.coverUrl ?? '',
        createdAt: DateTime.now(),
        source: 'scan', // ✅ 新增：标记为扫码来源
      );

      await _db.insertBook(book.toMap());
      await _db.attachBookToNode(
        bookId: book.id,
        title: book.title,
        parentId: libraryFolderId,
      );

      await _db.saveIsbnCache(
        isbn: _bookInfo!.isbn,
        title: title,
        author: author,
        coverUrl: _bookInfo!.coverUrl ?? '',
        source: 'local',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📚 已加入图书馆，标记为想读'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() => _isAdding = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isAdding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 加入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rescan() {
    setState(() {
      _isQuerying = false;
      _isAdding = false;
      _scannedIsbn = null;
      _bookInfo = null;
      _errorMessage = null;
      _isLoadingInfo = false;
    });
    _titleController.clear();
    _authorController.clear();
    _scannerController.start();
  }

  void _cancel() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫 ISBN'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: Stack(
        children: [
          if (_scannedIsbn == null)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                return Center(
                  child: Container(
                    width: constraints.maxWidth * 0.7,
                    height: constraints.maxWidth * 0.7,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '将条形码放入框内',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_scannedIsbn != null && _bookInfo != null) _buildConfirmView(),
          if (_isQuerying)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在查询书籍信息...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmView() {
    final info = _bookInfo!;
    final isPartial = info.isPartial ?? false;
    final bool canInteract = !_isQuerying && !_isAdding;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (info.coverUrl != null && info.coverUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    info.coverUrl!,
                    height: 140,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                  ),
                )
              else
                _buildCoverPlaceholder(),
              const SizedBox(height: 16),
              if (isPartial) ...[
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '书名',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: '作者',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (info.author.isNotEmpty)
                  Text(
                    info.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
              const SizedBox(height: 4),
              Text(
                'ISBN: ${info.isbn}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              if (isPartial && _errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: canInteract ? _rescan : null,
                      child: const Text('重新扫码'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isAdding || !canInteract) ? null : _addToLibrary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.library_add, size: 18),
                                SizedBox(width: 8),
                                Text('加入图书馆'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      height: 140,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class BookInfo {
  final String title;
  final String author;
  final String isbn;
  final String? coverUrl;
  final bool fromCache;
  final bool? isPartial;

  BookInfo({
    required this.title,
    required this.author,
    required this.isbn,
    this.coverUrl,
    this.fromCache = false,
    this.isPartial = false,
  });
}