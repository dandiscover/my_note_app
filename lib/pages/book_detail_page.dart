// lib/pages/book_detail_page.dart
// 书籍详情页 — 支持云端同步 + Windows 双入口
// ✅ 修复：file_picker 12.x API 兼容（pickFiles 返回 List<PlatformFile>?）
// ✅ 新增：来源标识展示（电子书/实体书）
// ✅ 新增：封面展示

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
import '../services/supabase_service.dart';
import '../services/sync/cloud_sync_service.dart';
import '../utils/app_date_utils.dart';
import '../utils/app_string_utils.dart';
import 'pdf_reader_page.dart';
import 'epub_reader_page.dart';
import 'note_detail_page.dart';
import '../models/note.dart';
import '../services/note_book_link_service.dart';

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
  List<Map<String, dynamic>> _linkedNotes = [];   // 批 1b：这本书的笔记
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
      await _loadLinkedNotes();   // 批 1b
    } catch (e) {
      debugPrint('加载书籍详情失败: $e');
    }
    setState(() => _isLoading = false);
  }

  // ============================================================
  // 📥 导入书籍（Windows 端使用 File 直接读取）
  // ============================================================

  /// 显示导入方式选择对话框（仅 Windows 端）
  Future<bool?> _showImportChoiceDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Colors.blue),
            SizedBox(width: 8),
            Text('导入图书'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选择导入方式：'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.folder_open),
            label: const Text('📥 导入到本地'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cloud_upload),
            label: const Text('☁️ 上传到云端'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ 核心修复：Windows 端直接从文件路径读取内容
  Future<Uint8List?> _readFileBytes(PlatformFile file) async {
    if (kIsWeb) {
      // ✅ file_picker 12.x: 使用 xFile.readAsBytes()
      return await file.xFile.readAsBytes();
    }

    try {
      final filePath = file.path;
      if (filePath == null || filePath.isEmpty) {
        print('❌ 文件路径为空');
        return null;
      }

      print('📁 文件路径: $filePath');

      final fileObj = File(filePath);
      if (!await fileObj.exists()) {
        print('❌ 文件不存在: $filePath');
        return null;
      }

      final bytes = await fileObj.readAsBytes();
      print('✅ 文件读取成功，大小: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      print('❌ 读取文件失败: $e');
      return null;
    }
  }

  Future<void> _importBook() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      // ✅ file_picker 12.x: pickFiles 返回 List<PlatformFile>?
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'azw3'],
      );
      if (files == null || files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = files.first;
      print('📁 文件名: ${file.name}');
      print('📁 文件大小: ${await file.length()} bytes');

      final bytes = await _readFileBytes(file);

      if (bytes == null) {
        setState(() => _isImporting = false);
        _showSnackBar('❌ 无法读取文件内容，请检查文件是否损坏或被占用');
        return;
      }

      if (bytes.isEmpty) {
        setState(() => _isImporting = false);
        _showSnackBar('❌ 文件内容为空');
        return;
      }

      final extension = path.extension(file.name).toLowerCase().replaceFirst('.', '');

      bool uploadToCloud;
      if (kIsWeb) {
        uploadToCloud = true;
      } else {
        final choice = await _showImportChoiceDialog();
        if (choice == null) {
          setState(() => _isImporting = false);
          return;
        }
        uploadToCloud = choice;
      }

      double progressValue = 0.0;
      int uploadedBytes = 0;
      String progressText = '准备上传...';

      showDialog(
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
                    if (!kIsWeb && !uploadToCloud) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '📥 仅保存到本地',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    ],
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

      final newBook = await _bookService.importBook(
        title: file.name.replaceAll(RegExp(r'\.[^.]*$'), ''),
        author: '',
        filePath: kIsWeb ? '' : (file.path ?? ''),
        fileType: extension,
        fileBytes: bytes,
        uploadToCloud: uploadToCloud,
        onProgress: (sent, total) {
          progressValue = sent / total;
          uploadedBytes = sent;
          progressText = uploadToCloud
              ? '上传中... ${(progressValue * 100).toInt()}%'
              : '保存中... ${(progressValue * 100).toInt()}%';
        },
      );

      if (mounted) Navigator.pop(context);

      _book = newBook;
      _titleController.text = _book!.title;
      _authorController.text = _book!.author;
      _selectedStatus = _book!.status;

      setState(() => _isImporting = false);

      final modeText = uploadToCloud ? '☁️ 已上传到云端' : '📥 已导入到本地';
      _showSnackBar('✅ 导入成功！$modeText');

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
  if (isWeb) {
    _showSnackBar('Web 端暂不支持 PDF 阅读');
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PdfReaderPage(
        filePath: finalPath,
        fileName: _book!.title,
        bookId: widget.bookId,   // ← 新增这行

      ),
    ),
  ).then((_) => _loadData());
}else if (fileType == 'epub') {
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
            const SizedBox(height: 12),
            _buildLinkedNotesSection(),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 封面 ──────────────────────────────────
            if (_book!.coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _book!.coverUrl,
                  width: 100,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildCoverPlaceholder(100, 140),
                ),
              )
            else
              _buildCoverPlaceholder(100, 140),
            const SizedBox(width: 16),
            // ─── 书籍信息 ──────────────────────────────
            Expanded(
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
                    // ✅ 来源标识
                    if (_book!.source.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('来源：', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _book!.source == 'import' ? '📄 导入的电子书' : '📚 扫码添加',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
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

  Widget _buildCoverPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Colors.grey.shade400,
        ),
      ),
    );
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

  // ─── 批 1b：这本书的笔记 ────────────────────────────
  // 入口（+ 写笔记）和显示区相邻（老白裁乙）

  Future<void> _loadLinkedNotes() async {
    final rows = await NoteBookLinkService().getLinksByBook(widget.bookId);
    final allMaps = await _db.getAllNotes(includeDeleted: false);
    final byId = {for (final m in allMaps) m['id'] as String: m};
    _linkedNotes = rows
        .map((r) => byId[r['note_id'] as String])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (mounted) setState(() {});
  }

  Widget _buildLinkedNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📚 这本书的笔记 (${_linkedNotes.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: _onCreateNoteForBook,
              icon: const Icon(Icons.edit_note, size: 16),
              label: const Text('写笔记'),
            ),
          ],
        ),
        const Divider(),
        if (_linkedNotes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('还没有关联的笔记',
                style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          ..._linkedNotes.map((m) {
            final entry = NotebookEntry.fromMap(m);
            return ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(AppStringUtils.displayNoteTitle(
                  entry.title, entry.content)),
              onTap: () => _openLinkedNote(entry),
            );
          }),
      ],
    );
  }

  Future<void> _openLinkedNote(NotebookEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(
          entry: entry,
          isFromCollection: false,
        ),
      ),
    );
    if (mounted) await _loadLinkedNotes();
  }
  Future<void> _onCreateNoteForBook() async {
    if (_book == null) return;
    final now = DateTime.now();
    final noteId = now.millisecondsSinceEpoch.toString();
    final entry = NotebookEntry(
      id: noteId,
      title: '《${_book!.title}》笔记',
      content: '',
      updatedAt: now,
      status: 'active',
      editorMode: 'plain',
      tags: [_book!.title],
    );
    await _db.insertNote(entry.toMap());
    final folderId = await _db.ensureReviewFolder();
    final node = await _db.attachNoteToNode(
      noteId: noteId,
      title: entry.title,
      parentId: folderId,
      tags: entry.tags,
    );
    try {
      await NoteBookLinkService().addLink(
        noteId: noteId,
        bookId: widget.bookId,
        linkType: NoteBookLinkService.linkTypeManual,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('关联写入失败，请重试')),
        );
      }
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(
          entry: entry,
          isFromCollection: false,
          initInEditMode: true,   // 批 1b 修复：强制进编辑态
        ),
      ),
    );
    if (!mounted) return;

    // 批 1b 修复：返回时若笔记仍空 → 删 note + link + node
    final maps = await _db.getAllNotes(includeDeleted: true);
    Map<String, dynamic>? noteMap;
    for (final m in maps) {
      if (m['id'] == noteId) {
        noteMap = m;
        break;
      }
    }
    if (noteMap != null &&
        ((noteMap['content'] as String?)?.trim().isEmpty ?? true)) {
      await _db.hardDeleteNote(noteId);
      await NoteBookLinkService().removeLink(
        noteId: noteId,
        bookId: widget.bookId,
        linkType: NoteBookLinkService.linkTypeManual,
      );
      // 批 1b 修复：连带删 Node，避免文件树留空壳节点
      // attachNoteToNode 返回 Future<Node>（非空）——不判 null
      await _db.deleteNode(node.id);
    }

    if (mounted) {
      await _loadLinkedNotes();
      await _loadData();
    }
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
            Text(AppDateUtils.formatFull(note.createdAt),
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