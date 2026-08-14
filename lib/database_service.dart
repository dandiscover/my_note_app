// lib/database_service.dart
// 双引擎数据服务：Web 端用 shared_preferences (localStorage)，原生端用 SQLite
// 支持笔记、书籍、封面图片、PDF 关联、PDF 标注、标注转笔记

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  // ---------- 单例模式 ----------
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ---------- 环境判断 ----------
  bool get _isWeb => kIsWeb;

  // ============================================================
  // 笔记相关操作 (CRUD)
  // ============================================================

  Future<void> insertNote(Map<String, dynamic> noteMap) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final notes = await getAllNotes();
      notes.insert(0, noteMap);
      await prefs.setString('notes_data', jsonEncode(notes));
    } else {
      final db = await _getDatabase();
      await db.insert('notes', noteMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('notes_data');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final db = await _getDatabase();
      return await db.query('notes', orderBy: 'updatedAt DESC');
    }
  }

  Future<void> updateNote(Map<String, dynamic> noteMap) async {
    if (_isWeb) {
      final notes = await getAllNotes();
      final index = notes.indexWhere((n) => n['id'] == noteMap['id']);
      if (index != -1) {
        notes[index] = noteMap;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('notes_data', jsonEncode(notes));
      }
    } else {
      final db = await _getDatabase();
      await db.update('notes', noteMap, where: 'id = ?', whereArgs: [noteMap['id']]);
    }
  }

  Future<void> deleteNote(String id) async {
    if (_isWeb) {
      final notes = await getAllNotes();
      notes.removeWhere((n) => n['id'] == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notes_data', jsonEncode(notes));
    } else {
      final db = await _getDatabase();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ============================================================
  // 书籍相关操作 (CRUD) — 升级版，支持封面和PDF
  // ============================================================

  Future<void> insertBook(Map<String, dynamic> bookMap) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final books = await getAllBooks();
      books.insert(0, bookMap);
      await prefs.setString('books_data', jsonEncode(books));
    } else {
      final db = await _getDatabase();
      await db.insert('books', bookMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('books_data');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final db = await _getDatabase();
      return await db.query('books', orderBy: 'created_at DESC');
    }
  }

  Future<Map<String, dynamic>?> getBook(String id) async {
    if (_isWeb) {
      final books = await getAllBooks();
      try {
        return books.firstWhere((b) => b['id'] == id);
      } catch (_) {
        return null;
      }
    } else {
      final db = await _getDatabase();
      final result = await db.query('books', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) return result.first;
      return null;
    }
  }

  Future<void> updateBook(Map<String, dynamic> bookMap) async {
    if (_isWeb) {
      final books = await getAllBooks();
      final index = books.indexWhere((b) => b['id'] == bookMap['id']);
      if (index != -1) {
        books[index] = bookMap;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('books_data', jsonEncode(books));
      }
    } else {
      final db = await _getDatabase();
      await db.update('books', bookMap, where: 'id = ?', whereArgs: [bookMap['id']]);
    }
  }

  Future<void> deleteBook(String id) async {
    if (_isWeb) {
      final books = await getAllBooks();
      books.removeWhere((b) => b['id'] == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('books_data', jsonEncode(books));
    } else {
      final db = await _getDatabase();
      await db.delete('books', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ============================================================
  // PDF 标注相关操作
  // ============================================================

  Future<void> insertAnnotation(Map<String, dynamic> annotationMap) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final annotations = await getAllAnnotationsForBook(annotationMap['book_id'] ?? '');
      annotations.add(annotationMap);
      // 按书籍 ID 分组存储
      await prefs.setString(
        'annotations_${annotationMap['book_id']}',
        jsonEncode(annotations),
      );
    } else {
      final db = await _getDatabase();
      await db.insert('book_annotations', annotationMap,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAllAnnotationsForBook(String bookId) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('annotations_$bookId');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final db = await _getDatabase();
      return await db.query(
        'book_annotations',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_number ASC, created_at ASC',
      );
    }
  }

  Future<void> deleteAnnotation(String annotationId, String bookId) async {
    if (_isWeb) {
      final annotations = await getAllAnnotationsForBook(bookId);
      annotations.removeWhere((a) => a['id'] == annotationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('annotations_$bookId', jsonEncode(annotations));
    } else {
      final db = await _getDatabase();
      await db.delete(
        'book_annotations',
        where: 'id = ?',
        whereArgs: [annotationId],
      );
    }
  }

  // ============================================================
  // 原生 SQLite 支持 (仅在非 Web 环境使用)
  // ============================================================

  static Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    String path = join(await getDatabasesPath(), 'notebook.db');
    _database = await openDatabase(
      path,
      version: 4, // 版本升级到 3，支持新字段
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // 新增升级回调
    );
    return _database!;
  }

  // ---------- 首次创建 ----------
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  // ---------- 升级数据库 ----------
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // 从版本 2 升级到 3：新增字段
      await db.execute('ALTER TABLE books ADD COLUMN cover_image TEXT');
      await db.execute('ALTER TABLE books ADD COLUMN pdf_path TEXT');
      await db.execute('ALTER TABLE books ADD COLUMN file_type TEXT DEFAULT "none"');
      // 重建 book_annotations 表（因为原表结构不完整，需要重新创建）
      // 先重命名旧表
      await db.execute('ALTER TABLE book_annotations RENAME TO book_annotations_old');
      // 创建新表
      await db.execute('''
        CREATE TABLE book_annotations(
          id TEXT PRIMARY KEY,
          book_id TEXT,
          page_number INTEGER,
          quote TEXT,
          note TEXT,
          color TEXT,
          created_at TEXT,
          FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
        )
      ''');
      // 迁移旧数据（如果有）
      await db.execute('''
        INSERT INTO book_annotations (id, book_id, page_number, quote, note, color, created_at)
        SELECT id, book_id, 0, quote, note, '#FFD700', created_at
        FROM book_annotations_old
      ''');
      // 删除旧表
      await db.execute('DROP TABLE book_annotations_old');
    }
  }

  // ---------- 建表 ----------
  Future<void> _createTables(Database db) async {
    // 笔记表
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        updatedAt TEXT,
        source_type TEXT,
        source_id TEXT
      )
    ''');

    // 书籍表（含封面和PDF字段）
    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT,
        author TEXT,
        isbn TEXT,
        cover_image TEXT,
        pdf_path TEXT,
        file_type TEXT DEFAULT 'none',
        status TEXT DEFAULT 'want',
        reading_progress INTEGER DEFAULT 0,
        total_pages INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 标注表（完整版）
    await db.execute('''
      CREATE TABLE book_annotations(
        id TEXT PRIMARY KEY,
        book_id TEXT,
        page_number INTEGER,
        quote TEXT,
        note TEXT,
        color TEXT,
        created_at TEXT,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
  }
}