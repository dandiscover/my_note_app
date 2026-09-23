// lib/pages/collection_page.dart
// 采集页 — 灵感笔记自动归档提醒 + 图书导入入口（支持 Web/桌面）
// ✅ 删除条件②重复逻辑，保留条件①
// ✅ 新增：拍照记录（移动端可用，桌面端/Web 占位提示）
// ✅ 修复：file_picker 12.x API 兼容（pickFiles 返回 List<PlatformFile>?）
// ✅ 扫ISBN 菜单跳转 ScanIsbnPage
// ✅ T-022 修复：异步后 setState 前加 mounted 检查（_loadSettings / _checkExpiry / _loadData / _archiveExpired）

import '../models/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../services/task_service.dart';
import '../services/cache_manager.dart';
import '../services/settings_service.dart';
import '../services/book_service.dart';
import '../mixins/state_mixin.dart';
import '../widgets/collection/capture_card.dart';
import '../widgets/collection/raw_note_item.dart';
import '../widgets/collection/quick_note_dialog.dart';
import '../widgets/floating_pet.dart';
import 'creation_page.dart' as creation;
import 'note_detail_page.dart';
import 'book_detail_page.dart';
import 'scan_isbn_page.dart';
// ✅ 改造批 A：采集入口加刷新 Key + 轻模式替换
import 'light_mode_page.dart';
import 'wisdom_page.dart';
import 'insight_page.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../services/weread_service.dart';
import '../services/weread_key_store.dart';
import '../services/weread_import_service.dart';
import '../widgets/weread/weread_key_guide_dialog.dart';
import '../widgets/weread/weread_shelf_picker_dialog.dart';
import '../widgets/weread/weread_progress_dialog.dart';

class CollectionPage extends StatefulWidget {
  final GlobalKey<creation.CreationPageState>? creationKey;
  // ✅ 改造批 A：刷新 Key（A 批只加参数，不实现刷新逻辑）
  final GlobalKey<WisdomPageState>? wisdomKey;
  final GlobalKey<InsightPageState>? insightKey;

  const CollectionPage({
    super.key,
    this.creationKey,
    this.wisdomKey,
    this.insightKey,
  });

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
    if (!mounted) return; // ✅ T-022
    setState(() {
      _retentionDays = settings.rawNoteRetentionDays;
    });
  }

  Future<void> _checkExpiry() async {
    await _loadSettings();
    if (!mounted) return; // ✅ T-022
    final expiringNotes = await _db.getExpiringRawNotes(_retentionDays);
    if (!mounted) return; // ✅ T-022
    setState(() {
      _expiringCount = expiringNotes.length;
      _expiringNoteIds = expiringNotes.map((n) => n.id).toList();
      _showExpiryWarning = _expiringCount > 0;
    });

    _lockedCount = await _db.getLockedNotesCount();
    if (!mounted) return; // ✅ T-022
    setState(() {});
  }

  Future<void> _loadData() async {
    if (!mounted) return; // ✅ T-022：防止从 _toggleLock 等调用时已在 dispose 后进入
    isLoading = true;
    try {
      await _loadSettings();
      if (!mounted) return; // ✅ T-022

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

      if (!mounted) return; // ✅ T-022
      setState(() {
        _rawNotes = rawNotes;
        _recentBooks = recentBooks;
      });

      await _checkExpiry();
      await _archiveExpired();

      // ✅ 条件①：水已经漫过脚踝了。
      // 触发条件：存在 raw 笔记 + 最后整理时间 ≥ 3天前 + 今日未显示
      if (_rawNotes.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastOrganizedStr = prefs.getString('last_organized_at');
        final lastShownDate = prefs.getString('last_shown_water_warning');
        final today = DateTime.now().toIso8601String().substring(0, 10);

        bool shouldShow = true;

        // 检查今日是否已显示
        if (lastShownDate == today) {
          shouldShow = false;
        }

        // 检查最后整理时间
        if (lastOrganizedStr != null) {
          try {
            final lastTime = DateTime.parse(lastOrganizedStr);
            final daysSince = DateTime.now().difference(lastTime).inDays;
            if (daysSince < 3) {
              shouldShow = false;
            }
          } catch (_) {
            // 解析失败，不触发
            shouldShow = false;
          }
        }
        // 如果 lastOrganizedStr == null（从未整理），shouldShow 保持 true

        if (shouldShow) {
          floatingPetKey.currentState?.showMessage('水已经漫过脚踝了。');
          await prefs.setString('last_shown_water_warning', today);
        }
      }
    } catch (e) {
      print('加载采集数据失败: $e');
    }
    if (!mounted) return; // ✅ T-022：StateMixin 的 isLoading setter 内部会 setState
    isLoading = false;
  }

  Future<void> _archiveExpired() async {
    final archivedCount = await _db.archiveExpiredRawNotes(_retentionDays);
    if (archivedCount > 0) {
      _cache.invalidate(_cacheKeyRawNotes);
      final maps = await _db.getRawNotes();
      if (!mounted) return; // ✅ T-022：追加修复（小白未列举，但同属 T-022 问题）
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

  /// ✅ 归档笔记 — 增加 try-catch + UI 反馈
  Future<void> _archiveNote(NotebookEntry note) async {
    try {
      await _db.archiveNote(note.id);
      _cache.invalidate(_cacheKeyRawNotes);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📦 已归档'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      print('❌ 归档失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 归档失败，请稍后重试'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red.shade300,
        ),
      );
    }
  }

  Future<void> _editNote(NotebookEntry note) async {
    // ✅ 改造批 A · T2：轻模式 = 弹窗
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => LightModePage(
          entry: note,
          scrollController: scrollController,
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

  /// ✅ 拍照记录（移动端可用，桌面端/Web 占位提示）
  Future<void> _takePhoto() async {
    // 移动端以外（Web + 桌面）暂不支持
    if (kIsWeb || Platform.isWindows || Platform.isLinux) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 拍照功能在移动端可用'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 80,
      );

      if (image == null) return; // 用户取消

      final bytes = await image.readAsBytes();
      final imagePath = await _saveImageToLocal(bytes);

      final entry = NotebookEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '照片笔记 ${DateTime.now().toLocal().toString().substring(0, 10)}',
        content: imagePath,
        status: 'raw',
        tags: ['拍照'],
        updatedAt: DateTime.now(),
        // 注意：NotebookEntry 没有 createdAt 字段，仅保留 updatedAt
      );

      await _db.insertNote(entry.toMap());
      _cache.invalidate(_cacheKeyRawNotes);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 照片已保存'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ 拍照失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 拍照失败: $e'),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  /// 保存图片到本地 photos/ 目录（仅移动端调用）
  Future<String> _saveImageToLocal(Uint8List bytes) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${photosDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void _drawBoard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画板功能开发中...'), duration: Duration(seconds: 1)),
    );
  }

  // ============================================================
  // 📥 图书导入（双入口：本地导入 + 云端上传）
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

  /// 通用导入逻辑
  Future<void> _importBookWithMode({required bool uploadToCloud}) async {
    try {
      // ✅ file_picker 12.x: pickFiles 返回 List<PlatformFile>?
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'mobi', 'azw3'],
      );
      if (files == null || files.isEmpty) return;

      final file = files.first;
      print('📁 文件名: ${file.name}');
      print('📁 文件大小: ${await file.length()} bytes');

      final bytes = await _readFileBytes(file);

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 无法读取文件内容，请检查文件是否损坏或被占用')),
        );
        return;
      }

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 文件内容为空')),
        );
        return;
      }

      final extension = path.extension(file.name).toLowerCase().replaceFirst('.', '');

      final newBook = await _bookService.importBook(
        title: file.name.replaceAll(RegExp(r'\.[^.]*$'), ''),
        author: '',
        filePath: kIsWeb ? '' : (file.path ?? ''),
        fileType: extension,
        fileBytes: bytes,
        uploadToCloud: uploadToCloud,
      );

      _cache.invalidate(_cacheKeyRecentBooks);
      await _loadData();

      final modeText = uploadToCloud ? '☁️ 上传到云端' : '📥 导入到本地';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $modeText 成功：${newBook.title}')),
      );

      // ✅ 通知所有页面刷新（智库、洞察、创作）
      if (widget.creationKey != null) {
        widget.creationKey?.currentState?.refreshTasks();
      }

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

  Future<void> _importBookWindows() async {
    final choice = await _showImportChoiceDialog();
    if (choice == null) return;
    await _importBookWithMode(uploadToCloud: choice);
  }

  Future<void> _importBookWeb() async {
    await _importBookWithMode(uploadToCloud: true);
  }

  Future<void> _importBook() async {
    if (kIsWeb) {
      await _importBookWeb();
    } else {
      await _importBookWindows();
    }
  }
bool _importInProgress = false;

Future<void> _importFromWeread() async {
  if (_importInProgress) return;

  final keyStore = WereadKeyStore();
  final weread = WereadService(keyStore: keyStore);

  // Key 检查
  if (!await keyStore.hasKey()) {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WereadKeyGuideDialog(),
    );
    if (ok != true) return;
  }

  _importInProgress = true;
  if (mounted) setState(() {});

  try {
    // 拉书架
    List<Map<String, dynamic>> shelf;
    try {
      shelf = await weread.fetchShelf();
    } catch (e) {
      if (!mounted) return;
      if (e is WereadException && e.message == 'KEY_INVALID') {
        final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const WereadKeyGuideDialog(),
        );
        if (ok == true) {
          _importInProgress = false;
          if (mounted) setState(() {});
          return _importFromWeread();
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拉取书架失败：$e')),
      );
      return;
    }
    if (shelf.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书架为空')),
      );
      return;
    }

    // 选书
    if (!mounted) return;
    final result = await showDialog<WereadPickResult>(
      context: context,
      builder: (_) => WereadShelfPickerDialog(shelf: shelf),
    );
    if (result == null) return;
    if (result.keyChanged) {
      _importInProgress = false;
      if (mounted) setState(() {});
      return _importFromWeread();
    }
    if (result.bookIds.isEmpty) return;

    // 进度
    final progressNotifier = ValueNotifier<WereadProgress>(
      WereadProgress(
        phase: 'local',
        cur: 0,
        total: result.bookIds.length,
        label: '准备中',
      ),
    );
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WereadProgressDialog(notifier: progressNotifier),
    );

    // 导入
    final service = WereadImportService(
      weread: weread,
      onProgress: (phase, cur, total, label) {
        progressNotifier.value = WereadProgress(
          phase: phase,
          cur: cur,
          total: total,
          label: label,
        );
      },
    );

    int failed = 0;
    String? keyInvalidMsg;
    try {
      await service.importBooks(
        result.bookIds,
        alsoGenerateCards: result.alsoGenerateCards,
      );
    } catch (e) {
      failed = result.bookIds.length;
      if (e is WereadException && e.message == 'KEY_INVALID') {
        keyInvalidMsg = '导入中途 Key 失效——请重新配置';
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '导入完成：${result.bookIds.length - failed} 成功 / $failed 失败',
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    if (keyInvalidMsg != null && mounted) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const WereadKeyGuideDialog(),
      );
    }

    if (weread.upgradeNotified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('微信读书接口有新版本，建议升级云脑'),
          action: SnackBarAction(label: '知道了', onPressed: () {}),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    _cache.invalidate(_cacheKeyRecentBooks);
    await _loadData();
  } finally {
    _importInProgress = false;
    if (mounted) setState(() {});
  }
}
  /// ✅ 扫ISBN — 跳转到扫码页面
  void _scanISBN() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanIsbnPage()),
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
                    case 'weread_import':
                      _importFromWeread();
                      break;
                  case 'scan':
                    _scanISBN();
                    break;
                }
              },
              itemBuilder: (context) => [
  const PopupMenuItem(
    value: 'import',
    child: Row(
      children: [
        Icon(Icons.upload_file),
        SizedBox(width: 12),
        Text('导入电子版'),
      ],
    ),
  ),
  if (!kIsWeb)
    const PopupMenuItem(
      value: 'weread_import',
      child: Row(
        children: [
          Icon(Icons.cloud_download_outlined),
          SizedBox(width: 12),
          Text('导入微信读书'),
        ],
      ),
    ),
  const PopupMenuItem(
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
                   case 'weread_import':
                      _importFromWeread();
                      break;
                case 'scan':
                  _scanISBN();
                  break;
              }
            },
           itemBuilder: (context) => [
  const PopupMenuItem(
    value: 'import',
    child: Row(
      children: [
        Icon(Icons.upload_file),
        SizedBox(width: 12),
        Text('导入电子版'),
      ],
    ),
  ),
  if (!kIsWeb)
    const PopupMenuItem(
      value: 'weread_import',
      child: Row(
        children: [
          Icon(Icons.cloud_download_outlined),
          SizedBox(width: 12),
          Text('导入微信读书'),
        ],
      ),
    ),
  const PopupMenuItem(
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
              // TODO（工作台改造 · 入口可配置化）：采集页入口当前硬编码——
              //   快速记 / 导入电子书 / 扫 ISBN。
              //   将来加语音 / 拍照 / 画板时，改为读一份入口配置。
              //   归后续批。
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