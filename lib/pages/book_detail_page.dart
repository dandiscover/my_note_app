// lib/pages/book_detail_page.dart
// 书籍详情页

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
import '../services/book_service.dart';
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

class _BookDetailPageState extends State<BookDetailPage>
    with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  final DatabaseService _db = DatabaseService();

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _book = await _bookService.getBook(widget.bookId);
      if (_book != null) {
        _titleController.text = _book!.title;
        _authorController.text = _book!.author;
        _selectedStatus = _book!.status;
      }

      if (widget.nodeId != null) {
        _node = await _db.getNode(widget.nodeId!);
      }

      _notes = await _bookService.getNotes(widget.bookId);
    } catch (e) {
      debugPrint('加载书籍详情失败: $e');
    }
    setState(() => _isLoading = false);
  }

  // ─── 导入书籍（带进度） ──────────────────────────────────────

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
      final bytes = file.bytes;

      if (bytes == null) {
        setState(() => _isImporting = false);
        _showSnackBar('❌ 无法读取文件');
        return;
      }

      // 进度状态
      double progressValue = 0.0;
      int uploadedBytes = 0;
      String progressText = '准备上传...';

      // ✅ 显示进度对话框
      final progressDialog = showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.cloud_upload, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('正在导入...'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.blue,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          progressText,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        Text(
                          '${(progressValue * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(uploadedBytes, bytes.length),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isImporting = false);
                    _showSnackBar('❌ 已取消导入');
                  },
                  child: const Text('取消', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ),
      );

      // ✅ 执行导入（带进度回调）
      final newBook = await _bookService.importBook(
        title: file.name.replaceAll(RegExp(r'\.[^.]*$'), ''),
        author: '',
        filePath: kIsWeb ? '' : (file.path ?? ''),
        fileType: extension,
        fileBytes: bytes,
        onProgress: (sent, total) {
          progressValue = sent / total;
          uploadedBytes = sent;
          progressText = '上传中... ${(progressValue * 100).toInt()}%';
        },
      );

      // ✅ 关闭进度对话框
      if (mounted) Navigator.pop(context);

      _book = newBook;
      _titleController.text = _book!.title;
      _authorController.text = _book!.author;
      _selectedStatus = _book!.status;

      setState(() => _isImporting = false);
      _showSnackBar('✅ 导入成功！已放入"图书馆"文件夹');

      _openReader(_book!.filePath, _book!.fileType, isWeb: kIsWeb);

    } on Exception catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() => _isImporting = false);
      _showSnackBar('❌ ${e.toString()}');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() => _isImporting = false);
      _showSnackBar('❌ 导入失败: $e');
    }
  }

  String _formatFileSize(int sent, int total) {
    final sentMB = sent / 1024 / 1024;
    final totalMB = total / 1024 / 1024;
    if (totalMB < 1) {
      final sentKB = sent / 1024;
      final totalKB = total / 1024;
      return '${sentKB.toStringAsFixed(0)} KB / ${totalKB.toStringAsFixed(0)} KB';
    }
    return '${sentMB.toStringAsFixed(1)} MB / ${totalMB.toStringAsFixed(1)} MB';
  }

  void _openReader(String filePath, String fileType, {bool isWeb = false}) async {
    String? actualPath = filePath;

    if (isWeb && !filePath.startsWith('blob:') && !filePath.startsWith('data:')) {
      final url = await _bookService.getBookFileUrl(widget.bookId, fileType);
      if (url != null) {
        actualPath = url;
      }
    }

    final String finalPath = actualPath ?? '';
    final bool isUrl = finalPath.startsWith('blob:') ||
        finalPath.startsWith('http') ||
        finalPath.startsWith('data:');

    if (fileType == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderPage(
            bookId: widget.bookId,
            filePath: isWeb ? '' : finalPath,
            fileUrl: isUrl ? finalPath : '',
            fileName: _book!.title,
            isWeb: isWeb,
          ),
        ),
      ).then((_) => _loadData());
    } else if (fileType == 'epub') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EpubReaderPage(
            bookId: widget.bookId,
            filePath: isWeb ? '' : finalPath,
            fileUrl: isUrl ? finalPath : '',
            fileName: _book!.title,
            isWeb: isWeb,
          ),
        ),
      ).then((_) => _loadData());
    } else {
      _showSnackBar('📖 暂不支持 $fileType 格式阅读');
    }
  }

  Future<void> _saveNote(BookNote note) async {
    await _bookService.saveNote(note);
    _notes = await _bookService.getNotes(widget.bookId);
    setState(() {});
    _showSnackBar('✅ 笔记已保存');
  }

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
      await _bookService.deleteNote(widget.bookId, note.id);
      _notes = await _bookService.getNotes(widget.bookId);
      setState(() {});
      _showSnackBar('已删除笔记');
    }
  }

  Future<void> _saveEdit() async {
    if (_book == null) return;
    final updated = _book!.copyWith(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      status: _selectedStatus,
    );
    await _bookService.saveBook(updated);
    _book = updated;
    _isEditing = false;
    setState(() {});
    _showSnackBar('✅ 已更新书籍信息');
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

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
        body: const Center(
          child: Text('书籍不存在', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
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
          IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true), tooltip: '编辑'),
          if (_book!.hasEbook)
            IconButton(
              icon: const Icon(Icons.menu_book),
              onPressed: () {
                _openReader(
                  _book!.filePath,
                  _book!.fileType,
                  isWeb: _book!.filePath.startsWith('http') || _book!.filePath.length > 200,
                );
              },
              tooltip: '阅读',
            ),
        ],
      ],
    );
  }

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
              if (_book!.isbn.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('ISBN：${_book!.isbn}'),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('状态：'),
                  Chip(label: Text(_book!.statusLabel), backgroundColor: _getStatusColor(_book!.status)),
                  const SizedBox(width: 16),
                  Text('进度：${_book!.readingProgress}%'),
                  if (_book!.totalPages > 0) Text(' / ${_book!.totalPages}页'),
                ],
              ),
              if (_book!.hasEbook) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('已导入 ${_book!.fileTypeLabel}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                      const SizedBox(width: 8),
                      Text('${(_book!.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
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
      case 'want': return Colors.orange.shade100;
      case 'reading': return Colors.blue.shade100;
      case 'read': return Colors.green.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Widget _buildImportSection() {
    if (_book!.hasEbook) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '已导入 ${_book!.fileTypeLabel} 文件，点击右上角 📖 阅读',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                    '支持 PDF / EPUB / MOBI / AZW3',
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

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📝 阅读笔记 (${_notes.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_book!.hasEbook)
              TextButton.icon(
                onPressed: () {
                  _openReader(_book!.filePath, _book!.fileType,
                      isWeb: _book!.filePath.length > 200);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加笔记'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
          ],
        ),
        const Divider(),
        if (_notes.isEmpty) _buildEmptyNotes() else ..._buildNoteList(),
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
          Text('在阅读器中选中文字 → 点击 📝 做笔记 添加笔记',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  List<Widget> _buildNoteList() {
    final displayNotes = _notes.take(10).toList();
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
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
            onPressed: () => _deleteNote(note),
            tooltip: '删除',
          ),
          onTap: () {
            _showNoteDetailDialog(note);
          },
        ),
      );
    }).toList();
  }

  void _showNoteDetailDialog(BookNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📝 第${note.pageNumber}页 笔记'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text(note.selectedText, style: const TextStyle(fontSize: 15)),
            ),
            if (note.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('💭 我的思考：', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(note.comment),
            ],
            const SizedBox(height: 8),
            Text('${AppDateUtils.formatFull(note.createdAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }
}