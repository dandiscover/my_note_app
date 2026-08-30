// lib/pages/collection_page.dart
// 采集页 — 灵感笔记自动归档提醒 + 图书导入入口（支持 Web/桌面）

import '../models/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/cache_manager.dart';
import '../services/settings_service.dart';
import '../services/book_service.dart';
import '../mixins/state_mixin.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/collection/capture_card.dart';
import '../widgets/collection/raw_note_item.dart';
import '../widgets/collection/quick_note_dialog.dart';
import 'creation_page.dart' as creation;
import 'note_detail_page.dart';
import 'book_detail_page.dart';
import 'wisdom_page.dart';

class CollectionPage extends StatefulWidget {
  final GlobalKey<creation.CreationPageState>? creationKey;

  const CollectionPage({super.key, this.creationKey});

  static Future<void> Function()? _saveCallback;

  static void registerSave(Future<void> Function() callback) {
    _saveCallback = callback;
  }

  static void unregisterSave() {
    _saveCallback = null;
  }

  static bool get isActive => _saveCallback != null;

  static Future<bool> triggerSave() async {
    if (_saveCallback == null) return false;
    await _saveCallback!();
    return true;
  }

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> with StateMixin {
  final DatabaseService _db = DatabaseService();
  final TaskService _taskService = TaskService();
  final BookService _bookService = BookService();
  final CacheManager _cache = CacheManager();
  final SettingsService _settingsService = SettingsService();

  List<NotebookEntry> _rawNotes = [];
  List<Book> _recentBooks = [];
  int _retentionDays = 15;
  int _lockedCount = 0;
  bool _showExpiryWarning = false;
  int _expiringCount = 0;
  List<String> _expiringNoteIds = [];

  static const String _cacheKeyRawNotes = 'collection_raw_notes';
  static const String _cacheKeyRecentBooks = 'collection_recent_books';

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkExpiry();
  }

  @override
  void dispose() {
    CollectionPage.unregisterSave();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.load();
    setState(() {
      _retentionDays = settings.rawNoteRetentionDays;
    });
  }

  Future<void> _checkExpiry() async {
    await _loadSettings();
    final expiringNotes = await _db.getExpiringRawNotes(_retentionDays);
    setState(() {
      _expiringCount = expiringNotes.length;
      _expiringNoteIds = expiringNotes.map((n) => n.id).toList();
      _showExpiryWarning = _expiringCount > 0;
    });

    _lockedCount = await _db.getLockedNotesCount();
    setState(() {});
  }

  Future<void> _loadData() async {
    isLoading = true;
    try {
      await _loadSettings();

      final rawNotes = await _cache.get<List<NotebookEntry>>(
        _cacheKeyRawNotes,
        () async {
          final maps = await _db.getRawNotes();
          return maps.map((m) => NotebookEntry.fromMap(m)).toList();
        },
        ttl: const Duration(seconds: 15),
      );

      final recentBooks = await _cache.get<List<Book>>(
        _cacheKeyRecentBooks,
        () async {
          final maps = await _db.getAllBooks();
          return maps.map((m) => Book.fromMap(m)).toList();
        },
        ttl: const Duration(seconds: 15),
      );

      setState(() {
        _rawNotes = rawNotes;
        _recentBooks = recentBooks;
      });

      await _checkExpiry();
      await _archiveExpired();
    } catch (e) {
      print('加载采集数据失败: $e');
    }
    isLoading = false;
  }

  Future<void> _archiveExpired() async {
    final archivedCount = await _db.archiveExpiredRawNotes(_retentionDays);
    if (archivedCount > 0) {
      _cache.invalidate(_cacheKeyRawNotes);
      final maps = await _db.getRawNotes();
      setState(() {
        _rawNotes = maps.map((m) => NotebookEntry.fromMap(m)).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 有 $archivedCount 条灵感笔记已过期归档'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleLock(NotebookEntry note) async {
    final newLocked = !note.isLocked;

    if (newLocked) {
      final currentLocked = await _db.getLockedNotesCount();
      if (currentLocked >= UserSettings.maxLockedNotes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔒 你锁了 3 条，要解锁一条才能继续锁'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    await _db.toggleLockNote(note.id, newLocked);
    _cache.invalidate(_cacheKeyRawNotes);
    await _loadData();
  }

  void _showQuickNoteDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuickNoteDialog(
        db: _db,
        taskService: _taskService,
        onSave: () {
          _cache.invalidate(_cacheKeyRawNotes);
          _loadData();
        },
        onTaskCreated: () {
          widget.creationKey?.currentState?.refreshTasks();
        },
      ),
    );
  }

  Future<void> _archiveNote(NotebookEntry note) async {
    await _db.archiveNote(note.id);
    _cache.invalidate(_cacheKeyRawNotes);
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📦 已归档'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _editNote(NotebookEntry note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(
          entry: note,
          isFromCollection: true,
        ),
      ),
    );
    if (result == true) {
      _cache.invalidate(_cacheKeyRawNotes);
      await _loadData();
    }
  }

  void _voiceRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音记录功能开发中...'), duration: Duration(seconds: 1)),
    );
  }

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('拍照记录功能开发中...'), duration: Duration(seconds: 1)),
    );
  }

  void _drawBoard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画板功能开发中...'), duration: Duration(seconds: 1)),
    );
  }

  // ✅ 真正的导入功能（支持 Web/桌面）
  Future<void> _importBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'azw3'],
      );
      if (result == null) return;

      final file = result.files.first;
      final extension = path.extension(file.name).toLowerCase().replaceFirst('.', '');
      final bytes = file.bytes;

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 无法读取文件')),
        );
        return;
      }

      // 使用 BookService 导入（自动放入“图书馆”文件夹）
      final newBook = await _bookService.importBook(
        title: file.name.replaceAll(RegExp(r'\.[^.]*$'), ''),
        author: '',
        filePath: kIsWeb ? '' : (file.path ?? ''),
        fileType: extension,
        fileBytes: bytes,
      );

      // 刷新最近导入列表
      _cache.invalidate(_cacheKeyRecentBooks);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ 已导入「${newBook.title}」到图书馆')),
      );

      // 跳转到图书详情页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(bookId: newBook.id),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 导入失败: $e')),
      );
    }
  }

  void _scanISBN() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📷 扫码功能开发中...'), duration: Duration(seconds: 1)),
    );
  }

  Color _getNoteBackground(NotebookEntry note) {
    if (note.isLocked) return Colors.transparent;

    final days = DateTime.now().difference(note.updatedAt).inDays;

    if (days >= 5 && days < 10) {
      return Colors.grey.shade50;
    }
    if (days >= 10 && days < 14) {
      return Colors.amber.shade50;
    }
    if (days >= 14 && days < 15) {
      return Colors.amber.shade100;
    }
    return Colors.transparent;
  }

  double _getNoteOpacity(NotebookEntry note) {
    if (note.isLocked) return 1.0;
    final days = DateTime.now().difference(note.updatedAt).inDays;
    if (days >= 5 && days < 10) {
      return 0.85 - (days - 5) * 0.03;
    }
    if (days >= 10) {
      return 0.7;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('📥 采集'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add, color: Colors.black87),
              tooltip: '添加',
              onSelected: (value) {
                switch (value) {
                  case 'import':
                    _importBook();
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('📥 采集'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.black87),
            tooltip: '添加',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importBook();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                '快速捕获',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CaptureCard(
                    icon: Icons.edit_note,
                    label: '文字',
                    color: Colors.blue.shade100,
                    onTap: _showQuickNoteDialog,
                  ),
                  CaptureCard(
                    icon: Icons.mic,
                    label: '语音',
                    color: Colors.green.shade100,
                    onTap: _voiceRecord,
                  ),
                  CaptureCard(
                    icon: Icons.camera_alt,
                    label: '拍照',
                    color: Colors.orange.shade100,
                    onTap: _takePhoto,
                  ),
                  CaptureCard(
                    icon: Icons.brush,
                    label: '画板',
                    color: Colors.purple.shade100,
                    onTap: _drawBoard,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '待整理',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (_lockedCount > 0)
                    Text(
                      '🔒 $_lockedCount/${UserSettings.maxLockedNotes}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_showExpiryWarning && _expiringCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ 有 $_expiringCount 条灵感笔记将在 $_retentionDays 天后过期归档',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '查看',
                          style: TextStyle(fontSize: 11, color: Colors.amber.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_rawNotes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '暂无待整理的内容\n点击「文字」快速记录',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rawNotes.length,
                  itemBuilder: (context, index) {
                    final note = _rawNotes[index];
                    final bgColor = _getNoteBackground(note);
                    final opacity = _getNoteOpacity(note);
                    final days = DateTime.now().difference(note.updatedAt).inDays;
                    final isExpiring = days >= 14 && days < 15;

                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isExpiring
                              ? Border.all(color: Colors.amber.shade300, width: 1.5)
                              : null,
                        ),
                        child: RawNoteItem(
                          key: ValueKey('raw_${note.id}'),
                          note: note,
                          onEdit: () => _editNote(note),
                          onArchive: () => _archiveNote(note),
                          onLockToggle: () => _toggleLock(note),
                          isLocked: note.isLocked,
                          showExpiryIndicator: days >= 10,
                          expiryDays: days,
                        ),
                      ),
                    );
                  },
                ),

              if (_recentBooks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '最近导入',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._recentBooks.take(3).map((book) => ListTile(
                  key: ValueKey('recent_${book.id}'),
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
                )),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}