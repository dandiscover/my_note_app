// lib/pages/book_detail_page.dart
// 书籍详情页 — 移除 dart:html 依赖

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../database_service.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import '../models/node.dart';
import '../services/card_service.dart';
import '../utils/app_date_utils.dart';
import '../utils/app_string_utils.dart';
import 'pdf_reader_page.dart';
import 'epub_reader_page.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;
  final String? nodeId;

  const BookDetailPage({
    super.key,
    required this.bookId,
    this.nodeId,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();

  Book? _book;
  Node? _node;
  List<BookNote> _notes = [];
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isImporting = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  String _selectedStatus = 'reading';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  // ─── 数据加载 ──────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bookMap = await _db.getBook(widget.bookId);
      if (bookMap != null) {
        _book = Book.fromMap(bookMap);
        _titleController.text = _book!.title;
        _authorController.text = _book!.author;
        _selectedStatus = _book!.status;
      }

      if (widget.nodeId != null) {
        _node = await _db.getNode(widget.nodeId!);
      }

      await _loadNotes();
    } catch (e) {
      debugPrint('加载书籍详情失败: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'book_notes_${widget.bookId}';
    final data = prefs.getString(key);
    if (data != null && data.isNotEmpty) {
      try {
        final list = jsonDecode(data) as List;
        _notes = list.map((m) => BookNote.fromMap(m)).toList();
        _notes.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      } catch (_) {
        _notes = [];
      }
    } else {
      _notes = [];
    }
    setState(() {});
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'book_notes_${widget.bookId}';
    await prefs.setString(key, jsonEncode(_notes.map((n) => n.toMap()).toList()));
  }

  // ─── 导入书籍 ──────────────────────────────────────────────

  Future<void> _importBook() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'azw3'],
      );
      if (result == null) {
        setState(() => _isImporting = false);
        return;
      }

      final file = result.files.first;
      final extension = path.extension(file.name).toLowerCase().replaceFirst('.', '');
      final bookId = widget.bookId;

      // ✅ Web 端：使用 base64 编码存储（不依赖 dart:html）
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          setState(() => _isImporting = false);
          return;
        }

        // 将 PDF 内容编码为 Base64 存储
        final base64Data = base64Encode(bytes);
        _book = _book!.copyWith(filePath: base64Data, fileType: extension);
        await _db.updateBook(_book!.toMap());

        setState(() {
          _isImporting = false;
        });
        _showSnackBar('✅ 书籍已导入！');
        _loadData();

        // 打开阅读器
        _openReader(base64Data, extension, isWeb: true);
        return;
      }

      // 桌面端：保存到文件系统
      final appDir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${appDir.path}/books');
      if (!await bookDir.exists()) await bookDir.create(recursive: true);
      final targetPath = '${bookDir.path}/book_$bookId.$extension';

      final sourceFile = File(file.path!);
      await sourceFile.copy(targetPath);

      _book = _book!.copyWith(filePath: targetPath, fileType: extension);
      await _db.updateBook(_book!.toMap());
      setState(() {});
      setState(() => _isImporting = false);
      _showSnackBar('✅ 书籍导入成功！');
      _loadData();
      _openReader(targetPath, extension);

    } catch (e) {
      setState(() => _isImporting = false);
      _showSnackBar('❌ 导入失败: $e');
    }
  }

  void _openReader(String filePath, String fileType, {bool isWeb = false}) {
    if (fileType == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderPage(
            bookId: widget.bookId,
            filePath: isWeb ? '' : filePath,
            fileUrl: isWeb ? filePath : '',
            fileName: _book!.title,
            isWeb: isWeb,
          ),
        ),
      ).then((_) => _loadNotes());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EpubReaderPage(
            bookId: widget.bookId,
            filePath: isWeb ? '' : filePath,
            fileUrl: isWeb ? filePath : '',
            fileName: _book!.title,
            isWeb: isWeb,
          ),
        ),
      ).then((_) => _loadNotes());
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ─── 删除笔记 ──────────────────────────────────────────────

  Future<void> _deleteNote(BookNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除笔记'),
        content: const Text('确定要删除这条笔记吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _notes.removeWhere((n) => n.id == note.id);
      await _saveNotes();
      setState(() {});
      _showSnackBar('已删除笔记');
    }
  }

  // ─── 保存编辑 ──────────────────────────────────────────────

  Future<void> _saveEdit() async {
    if (_book == null) return;
    final updated = _book!.copyWith(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      status: _selectedStatus,
    );
    await _db.updateBook(updated.toMap());
    _book = updated;
    _isEditing = false;
    setState(() {});
    _showSnackBar('✅ 已更新书籍信息');
  }

  // ─── UI 构建 ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('书籍详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('书籍详情')),
        body: const Center(child: Text('书籍不存在', style: TextStyle(fontSize: 16, color: Colors.grey))),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 12),
            _buildImportSection(),
            const SizedBox(height: 12),
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isEditing
          ? TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '书名',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            )
          : Text(_book!.title),
      centerTitle: true,
      actions: [
        if (_isEditing)
          IconButton(icon: const Icon(Icons.save), onPressed: _saveEdit, tooltip: '保存')
        else ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: '编辑',
          ),
          if (_book!.hasEbook)
            IconButton(
              icon: const Icon(Icons.menu_book),
              onPressed: () {
                _openReader(
                  _book!.filePath,
                  _book!.fileType,
                  isWeb: _book!.filePath.startsWith('http') ||
                      _book!.filePath.length > 200,
                );
              },
              tooltip: '阅读',
            ),
        ],
      ],
    );
  }

  // ─── 信息卡片 ──────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEditing) ...[
              Text(_book!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('作者：${_book!.author.isNotEmpty ? _book!.author : '未知'}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('状态：'),
                  Chip(
                    label: Text(_book!.statusLabel),
                    backgroundColor: _getStatusColor(_book!.status),
                  ),
                  const SizedBox(width: 16),
                  Text('进度：${_book!.readingProgress}%'),
                ],
              ),
              if (_book!.hasEbook) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('已导入 ${_book!.fileType.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ] else ...[
              _buildEditField('作者', _authorController),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('状态：'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'want', child: Text('想读')),
                      DropdownMenuItem(value: 'reading', child: Text('在读')),
                      DropdownMenuItem(value: 'read', child: Text('读完')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedStatus = value);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Row(
      children: [
        Text('$label：', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'want':
        return Colors.orange.shade100;
      case 'reading':
        return Colors.blue.shade100;
      case 'read':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // ─── 导入书籍 ──────────────────────────────────────────────

  Widget _buildImportSection() {
    if (_book!.hasEbook) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.upload_file, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('导入电子书', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '支持 PDF, EPUB, MOBI, AZW3',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importBook,
              icon: _isImporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(_isImporting ? '导入中...' : '选择文件'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 笔记列表 ──────────────────────────────────────────────

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📝 阅读笔记 (${_notes.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const Divider(),
        if (_notes.isEmpty)
          _buildEmptyNotes()
        else
          ..._buildNoteList(),
        if (_notes.length > 5)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showAllNotesDialog,
              child: Text('查看全部 ${_notes.length} 条笔记 →'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyNotes() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('还没有阅读笔记', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('在阅读器中选中文字即可添加笔记', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  List<Widget> _buildNoteList() {
    final displayNotes = _notes.take(5).toList();
    return displayNotes.map((note) {
      return Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: Container(
            width: 4,
            height: 36,
            color: Color(int.parse(note.color.replaceFirst('#', ''), radix: 16) + 0xFF000000),
          ),
          title: Text(
            AppStringUtils.truncate(note.selectedText, 60),
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '第${note.pageNumber}页 · ${AppDateUtils.formatShort(note.createdAt)}'
            '${note.comment.isNotEmpty ? ' · ${AppStringUtils.truncate(note.comment, 20)}' : ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            if (_book!.hasEbook && _book!.fileType == 'pdf') {
              _openReader(_book!.filePath, _book!.fileType,
                  isWeb: _book!.filePath.length > 200);
            }
          },
        ),
      );
    }).toList();
  }

  // ─── 全部笔记对话框 ──────────────────────────────────────────

  void _showAllNotesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📝 全部笔记 (${_notes.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            color: Color(int.parse(note.color.replaceFirst('#', ''), radix: 16) + 0xFF000000),
                          ),
                          title: Text(
                            note.selectedText,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '第${note.pageNumber}页 · ${AppDateUtils.formatShort(note.createdAt)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (_book!.hasEbook && _book!.fileType == 'pdf') {
                              _openReader(_book!.filePath, _book!.fileType,
                                  isWeb: _book!.filePath.length > 200);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}