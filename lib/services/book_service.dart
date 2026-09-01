// lib/services/book_service.dart
// 图书服务层 — Windows 用本地文件，Web 用 Supabase，导入时同步云端

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/book.dart';
import '../models/book_note.dart';
import '../database_service.dart';
import 'supabase_service.dart';
import 'sync/cloud_sync_service.dart';
import 'sync/sync_manager.dart';

class BookService {
  final DatabaseService _db = DatabaseService();
  static const String _notesKeyPrefix = 'book_notes_';

  // ─── 图书 CRUD ────────────────────────────────────────────

  Future<Book?> getBook(String bookId) async {
    final map = await _db.getBook(bookId);
    if (map == null) return null;
    return Book.fromMap(map);
  }

  Future<List<Book>> getAllBooks() async {
    final maps = await _db.getAllBooks();
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<void> saveBook(Book book) async {
    await _db.updateBook(book.toMap());
    if (SupabaseService().isLoggedIn) {
      try {
        await CloudSyncService().syncBook(book);
      } catch (_) {
        SyncManager().markDirty();
      }
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_notesKeyPrefix$bookId');
    if (SupabaseService().isLoggedIn) {
      try {
        await CloudSyncService().deleteBook(bookId);
      } catch (_) {
        SyncManager().markDirty();
      }
    }
  }

  // ─── 图书导入 ──────────────────────────────────────────────

  Future<Book> importBook({
    required String title,
    required String author,
    required String filePath,
    required String fileType,
    required Uint8List fileBytes,
    String? parentFolderId,  // ✅ 保留参数，但内部不再依赖它
    required bool uploadToCloud,
    void Function(int sent, int total)? onProgress,
  }) async {
    final bookId = DateTime.now().millisecondsSinceEpoch.toString();

    String storedPath = filePath;

    // ─── 1. 保存文件到本地（所有平台都执行） ──────────────

    if (!kIsWeb) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final bookDir = Directory('${appDir.path}/books');
        if (!await bookDir.exists()) {
          await bookDir.create(recursive: true);
        }
        final targetPath = '${bookDir.path}/book_$bookId.$fileType';

        if (filePath.isNotEmpty) {
          final sourceFile = File(filePath);
          if (await sourceFile.exists()) {
            await sourceFile.copy(targetPath);
          } else {
            await File(targetPath).writeAsBytes(fileBytes);
          }
        } else {
          await File(targetPath).writeAsBytes(fileBytes);
        }
        storedPath = targetPath;
        onProgress?.call(fileBytes.length, fileBytes.length);
      } catch (e) {
        throw Exception('保存文件失败: $e');
      }
    }

    // ─── 2. Web 端：始终上传到云端 ─────────────────────────

    if (kIsWeb) {
      try {
        final service = SupabaseService();

        if (!service.isLoggedIn) {
          throw Exception('请先登录再导入图书');
        }

        final userId = service.currentUserId!;
        final bucketName = 'book_files';
        final cloudPath = 'users/$userId/books/$bookId.$fileType';
        final mimeType = fileType == 'pdf'
            ? 'application/pdf'
            : 'application/epub+zip';

        await service.ensureBucket(bucketName);

        final url = await service.uploadFile(
          bucketName: bucketName,
          path: cloudPath,
          fileBytes: fileBytes,
          contentType: mimeType,
          onProgress: onProgress,
        );

        storedPath = url;
      } catch (e) {
        if (fileBytes.length < 5 * 1024 * 1024) {
          final mimeType = fileType == 'pdf'
              ? 'application/pdf'
              : 'application/epub+zip';
          storedPath = 'data:$mimeType;base64,${base64Encode(fileBytes)}';
        } else {
          throw Exception('上传到云存储失败: $e');
        }
      }
    }

    // ─── 3. Windows 端：根据 uploadToCloud 决定是否上传 ───

    if (!kIsWeb && uploadToCloud) {
      try {
        final service = SupabaseService();

        if (!service.isLoggedIn) {
          print('⚠️ 未登录，跳过云端上传，仅保存本地');
        } else {
          final userId = service.currentUserId!;
          final bucketName = 'book_files';
          final cloudPath = 'users/$userId/books/$bookId.$fileType';
          final mimeType = fileType == 'pdf'
              ? 'application/pdf'
              : 'application/epub+zip';

          await service.ensureBucket(bucketName);

          final url = await service.uploadFile(
            bucketName: bucketName,
            path: cloudPath,
            fileBytes: fileBytes,
            contentType: mimeType,
            onProgress: onProgress,
          );

          storedPath = url;
          print('☁️ 图书已上传到云端: $url');
        }
      } catch (e) {
        print('⚠️ 云端上传失败（已保留本地文件）: $e');
      }
    } else if (!kIsWeb && !uploadToCloud) {
      print('📥 仅导入到本地: $storedPath');
    }

    // ─── 4. 创建 Book 对象并保存到本地数据库 ──────────────

    final book = Book(
      id: bookId,
      title: title.isEmpty ? '未命名图书' : title,
      author: author.isEmpty ? '未知作者' : author,
      filePath: storedPath,
      fileType: fileType,
      fileName: 'book_$bookId.$fileType',
      fileSize: fileBytes.length,
      status: 'want',
      createdAt: DateTime.now(),
    );

    await _db.insertBook(book.toMap());

    // ─── 5. 查找或创建"图书馆"文件夹（统一入口）─────────────

    // ✅ 修复：不再依赖外部传入的 parentFolderId，内部自动获取
    String? folderId = await _db.ensureLibraryFolder();
    if (folderId == null) {
      final folder = await _db.createFolder(
        title: '图书馆',
        parentId: null,
        tags: ['系统', '图书'],
      );
      folderId = folder.id;
    }

    // ✅ 将图书挂到图书馆文件夹下
    await _db.attachBookToNode(
      bookId: book.id,
      title: book.title,
      parentId: folderId,
    );

    // ─── 6. 如果上传到云端，同时同步元数据 ─────────────────

    if (uploadToCloud && SupabaseService().isLoggedIn) {
      try {
        await CloudSyncService().syncBook(book);
        print('☁️ 图书元数据已同步到云端: ${book.title}');
      } catch (e) {
        print('☁️ 元数据同步失败: $e');
      }
    }

    return book;
  }

  Future<String?> getBookFileUrl(String bookId, String fileType) async {
    return null;
  }

  Future<void> moveBook(String bookId, String targetFolderId) async {
    final nodes = await _db.getAllNodes();
    final node = nodes.firstWhere(
      (n) => n.nodeType == 'book' && n.targetId == bookId,
      orElse: () => throw Exception('未找到图书节点'),
    );
    await _db.moveNode(node.id, targetFolderId);
  }

  // ─── 阅读笔记 ──────────────────────────────────────────────

  Future<List<BookNote>> getNotes(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notesKeyPrefix$bookId';
    final data = prefs.getString(key);
    if (data == null || data.isEmpty) return [];

    try {
      final list = jsonDecode(data) as List;
      return list.map((m) => BookNote.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNote(BookNote note) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notesKeyPrefix${note.bookId}';
    final existing = await getNotes(note.bookId);
    final updated = [...existing, note];
    await prefs.setString(key, jsonEncode(updated.map((n) => n.toMap()).toList()));

    if (SupabaseService().isLoggedIn) {
      try {
        await CloudSyncService().syncBookNote(note);
      } catch (_) {
        SyncManager().markDirty();
      }
    }
  }

  Future<void> deleteNote(String bookId, String noteId) async {
    final notes = await getNotes(bookId);
    final updated = notes.where((n) => n.id != noteId).toList();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notesKeyPrefix$bookId';
    await prefs.setString(key, jsonEncode(updated.map((n) => n.toMap()).toList()));

    if (SupabaseService().isLoggedIn) {
      try {
        await CloudSyncService().deleteBookNote(noteId);
      } catch (_) {
        SyncManager().markDirty();
      }
    }
  }

  Future<void> deleteAllNotes(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notesKeyPrefix$bookId';
    await prefs.remove(key);
  }
}