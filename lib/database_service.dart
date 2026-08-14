import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool get _isWeb => kIsWeb;

  // ========== 笔记 CRUD ==========

  Future<void> insertNote(Map<String, dynamic> noteMap) async {
    if (!noteMap.containsKey('status')) {
      noteMap['status'] = 'raw';
    }
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final notes = await _getAllNotesInternal(includeDeleted: false);
      notes.insert(0, noteMap);
      await prefs.setString('notes_data', jsonEncode(notes));
    } else {
      final db = await _getDatabase();
      await db.insert('notes', noteMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAllNotes({bool includeDeleted = false}) async {
    return _getAllNotesInternal(includeDeleted: includeDeleted);
  }

  Future<List<Map<String, dynamic>>> _getAllNotesInternal({bool includeDeleted = false}) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('notes_data');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      final allNotes = list.map((e) => Map<String, dynamic>.from(e)).toList();
      if (includeDeleted) return allNotes;
      return allNotes.where((n) => n['status'] != 'deleted').toList();
    } else {
      final db = await _getDatabase();
      final allNotes = await db.query('notes', orderBy: 'updatedAt DESC');
      if (includeDeleted) return allNotes;
      return allNotes.where((n) => n['status'] != 'deleted').toList();
    }
  }

  // 获取原始笔记（status = 'raw'）
  Future<List<Map<String, dynamic>>> getRawNotes() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'raw').toList();
  }

  // 获取未归档笔记（status = 'active'）
  Future<List<Map<String, dynamic>>> getActiveNotes() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'active').toList();
  }

  // 获取已归档笔记（status = 'archived'）
  Future<List<Map<String, dynamic>>> getArchivedNotes() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'archived').toList();
  }

  // 获取任务（status = 'task'）
  Future<List<Map<String, dynamic>>> getTasks() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'task').toList();
  }

  // 收入智库（raw → active）
  Future<void> sendToWisdom(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'active';
      notes[index]['updatedAt'] = DateTime.now().toIso8601String();
      await _saveNotes(notes);
    }
  }

  // 归档（active → archived）
  Future<void> archiveNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'archived';
      await _saveNotes(notes);
    }
  }

  // 取消归档（archived → active）
  Future<void> unarchiveNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'active';
      await _saveNotes(notes);
    }
  }

  // 软删除（任意状态 → deleted）
  Future<void> deleteNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'deleted';
      await _saveNotes(notes);
    }
  }

  // 物理删除
  Future<void> hardDeleteNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: true);
    notes.removeWhere((n) => n['id'] == id);
    await _saveNotes(notes);
  }

  Future<void> updateNote(Map<String, dynamic> noteMap) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == noteMap['id']);
    if (index != -1) {
      notes[index] = noteMap;
      await _saveNotes(notes);
    }
  }

  Future<void> _saveNotes(List<Map<String, dynamic>> notes) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notes_data', jsonEncode(notes));
    } else {
      final db = await _getDatabase();
      for (var note in notes) {
        await db.update('notes', note, where: 'id = ?', whereArgs: [note['id']]);
      }
    }
  }

  // ========== 书籍 CRUD ==========

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

  // ========== 标注 CRUD（占位） ==========

  Future<void> insertAnnotation(Map<String, dynamic> annotationMap) async {}
  Future<List<Map<String, dynamic>>> getAllAnnotationsForBook(String bookId) async {
    return [];
  }

  // ========== 原生 SQLite 支持 ==========

  static Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    String path = join(await getDatabasesPath(), 'notebook.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE books ADD COLUMN cover_image TEXT');
      await db.execute('ALTER TABLE books ADD COLUMN pdf_path TEXT');
      await db.execute('ALTER TABLE books ADD COLUMN file_type TEXT DEFAULT "none"');
    }
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN status TEXT DEFAULT "raw"');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        updatedAt TEXT,
        status TEXT DEFAULT 'raw'
      )
    ''');
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