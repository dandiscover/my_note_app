// lib/services/book_service.dart
// 图书服务层 — Windows 用本地文件，Web 用 Supabase

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
  }

  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_notesKeyPrefix$bookId');
  }

  // ─── 图书导入 ──────────────────────────────────────────────

  Future<Book> importBook({
    required String title,
    required String author,
    required String filePath,
    required String fileType,
    required Uint8List fileBytes,
    String? parentFolderId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final bookId = DateTime.now().millisecondsSinceEpoch.toString();

    String storedPath = filePath;

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
    } else {
      try {
        final service = SupabaseService();

        if (!service.isLoggedIn) {
          throw Exception('请先登录再导入图书');
        }

        final userId = service.currentUserId!;
        final bucketName = 'book_files';
        final filePath = 'users/$userId/books/$bookId.$fileType';
        final mimeType = fileType == 'pdf'
            ? 'application/pdf'
            : 'application/epub+zip';

        await service.ensureBucket(bucketName);

        final url = await service.uploadFile(
          bucketName: bucketName,
          path: filePath,
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

    final folderId = parentFolderId ?? await _db.ensureLibraryFolder();
    await _db.attachBookToNode(
      bookId: book.id,
      title: book.title,
      parentId: folderId,
    );

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
  }

  Future<void> deleteNote(String bookId, String noteId) async {
    final notes = await getNotes(bookId);
    final updated = notes.where((n) => n.id != noteId).toList();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notesKeyPrefix$bookId';
    await prefs.setString(key, jsonEncode(updated.map((n) => n.toMap()).toList()));
  }

  Future<void> deleteAllNotes(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_notesKeyPrefix$bookId';
    await prefs.remove(key);
  }
}