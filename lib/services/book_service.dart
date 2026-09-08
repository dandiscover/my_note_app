// lib/services/book_service.dart
// 图书服务层 — Windows 用本地文件，Web 用 Supabase，导入时同步云端
// ✅ 新增：importBook 中创建 Book 时设置 source = 'import'
// ✅ 新增：导入时从文件名提取 ISBN，查询封面，存入 coverUrl（非阻塞）

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
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

  // ─── ISBN 提取（从文件名） ─────────────────────────────

  /// 从文件名中提取 ISBN（10位或13位）
  String? _extractIsbnFromFile(String fileName) {
    if (fileName.isEmpty) return null;

    // 尝试匹配 13 位 ISBN（纯数字）
    final isbn13Regex = RegExp(r'(?<![0-9])(978|979)[0-9]{10}(?![0-9])');
    final match13 = isbn13Regex.firstMatch(fileName);
    if (match13 != null) {
      return match13.group(0);
    }

    // 尝试匹配 10 位 ISBN（含 X）
    final isbn10Regex = RegExp(r'(?<![0-9X])[0-9]{9}[0-9X](?![0-9X])');
    final match10 = isbn10Regex.firstMatch(fileName);
    if (match10 != null) {
      return match10.group(0);
    }

    return null;
  }

  // ─── ISBN 查询（先缓存，再探数，再 Open Library） ─────────

  /// 根据 ISBN 查询封面 URL
  /// 查询顺序：isbn_cache → 探数数据 → Open Library
  /// 全程 try-catch，失败返回 null
  Future<String?> _fetchCoverForBook(String isbn) async {
    try {
      // 1. 本地缓存
      final cached = await _db.getIsbnCache(isbn);
      if (cached != null) {
        final coverUrl = cached['cover_url'] as String?;
        if (coverUrl != null && coverUrl.isNotEmpty) {
          return coverUrl;
        }
      }

      // 2. 探数数据（仅当有 API Key 时）
      final apiKey = const String.fromEnvironment('TANSHU_API_KEY');
      if (apiKey.isNotEmpty) {
        try {
          final url = Uri.parse(
              'https://api.tanshuapi.com/api/isbn_base/v1/index?key=$apiKey&isbn=$isbn');
          final response = await http.get(url).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            if (data['code'] == 1) {
              final bookData = data['data'] as Map<String, dynamic>?;
              final coverUrl = bookData?['img'] as String?;
              if (coverUrl != null && coverUrl.isNotEmpty) {
                // 保存到缓存
                await _db.saveIsbnCache(
                  isbn: isbn,
                  title: bookData?['title'] as String? ?? '',
                  author: bookData?['author'] as String? ?? '',
                  coverUrl: coverUrl,
                  source: 'tanshu',
                );
                return coverUrl;
              }
            }
          }
        } catch (_) {
          // 探数失败，继续 fallback
        }
      }

      // 3. Open Library fallback
      try {
        final url = Uri.parse(
            'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data');
        final response = await http.get(url).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final key = 'ISBN:$isbn';
          if (data.containsKey(key) && data[key] != null) {
            final bookData = data[key] as Map<String, dynamic>;
            final cover = bookData['cover'] as Map<String, dynamic>?;
            final coverUrl = cover?['medium'] as String? ?? cover?['large'] as String?;
            if (coverUrl != null && coverUrl.isNotEmpty) {
              // 保存到缓存
              await _db.saveIsbnCache(
                isbn: isbn,
                title: bookData['title'] as String? ?? '',
                author: '',
                coverUrl: coverUrl,
                source: 'openlibrary',
              );
              return coverUrl;
            }
          }
        }
      } catch (_) {
        // Open Library 失败，静默返回
      }

      return null;
    } catch (_) {
      return null;
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

    // ─── 4. 查询封面（非阻塞，失败不影响导入） ──────────────

    String coverUrl = '';
    try {
      // ✅ 从 title 参数提取 ISBN（Web/桌面均可用）
      final isbn = _extractIsbnFromFile(title);
      if (isbn != null) {
        final fetched = await _fetchCoverForBook(isbn);
        if (fetched != null && fetched.isNotEmpty) {
          coverUrl = fetched;
          print('📚 封面查询成功: $coverUrl');
        } else {
          print('📚 封面查询失败，继续导入');
        }
      } else {
        print('📚 文件名中未检测到 ISBN，跳过封面查询');
      }
    } catch (_) {
      // 封面查询任何异常都不阻断导入
      print('📚 封面查询异常，继续导入');
    }

    // ─── 5. 创建 Book 对象并保存到本地数据库 ──────────────

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
      source: 'import',
      coverUrl: coverUrl, // ✅ 新增：封面 URL（可能为空）
    );

    await _db.insertBook(book.toMap());

    // ─── 6. 查找或创建"图书馆"文件夹（统一入口）─────────────

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

    // ─── 7. 如果上传到云端，同时同步元数据 ─────────────────

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