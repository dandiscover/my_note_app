import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/note.dart';
import 'models/book.dart';
import 'models/node.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool get _isWeb => kIsWeb;

  // ============================================================
  // 节点（树形结构）CRUD
  // ============================================================

  Future<void> insertNode(Map<String, dynamic> nodeMap) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final nodes = await _getAllNodesInternal();
      nodes.add(nodeMap);
      await prefs.setString('nodes_data', jsonEncode(nodes));
    } else {
      final db = await _getDatabase();
      await db.insert('nodes', nodeMap);
    }
  }

  Future<List<Node>> getAllNodes() async {
    final maps = await _getAllNodesInternal();
    return maps.map((map) => Node.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> _getAllNodesInternal() async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('nodes_data');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      final db = await _getDatabase();
      return await db.query('nodes', orderBy: 'sort_order ASC, created_at ASC');
    }
  }

  Future<List<Node>> getRootNodes() async {
    final all = await getAllNodes();
    return all.where((n) => n.parentId == null).toList();
  }

  Future<List<Node>> getChildren(String? parentId) async {
    final all = await getAllNodes();
    return all.where((n) => n.parentId == parentId).toList();
  }

  Future<Node?> getNode(String id) async {
    final all = await getAllNodes();
    try {
      return all.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateNode(Node node) async {
    final maps = await _getAllNodesInternal();
    final index = maps.indexWhere((n) => n['id'] == node.id);
    if (index != -1) {
      maps[index] = node.toMap();
      await _saveNodes(maps);
    }
  }

  Future<void> deleteNode(String id) async {
    final maps = await _getAllNodesInternal();
    final idsToDelete = <String>{id};

    final allNodes = maps.map((n) => Node.fromMap(n)).toList();
    void collectChildren(String parentId) {
      final children = allNodes.where((n) => n.parentId == parentId).toList();
      for (var child in children) {
        idsToDelete.add(child.id);
        if (child.isFolder) {
          collectChildren(child.id);
        }
      }
    }

    final node = allNodes.firstWhere((n) => n.id == id);
    if (node.isFolder) {
      collectChildren(id);
    }

    maps.removeWhere((n) => idsToDelete.contains(n['id']));
    await _saveNodes(maps);
  }

  Future<void> moveNode(String nodeId, String? newParentId) async {
    final node = await getNode(nodeId);
    if (node == null) return;
    final updated = node.copyWith(
      parentId: newParentId,
      updatedAt: DateTime.now(),
    );
    await updateNode(updated);
  }

  Future<void> batchMoveNodes(List<String> nodeIds, String? targetParentId) async {
    for (var id in nodeIds) {
      await moveNode(id, targetParentId);
    }
  }

  Future<void> batchDeleteNodes(List<String> nodeIds) async {
    for (var id in nodeIds) {
      await deleteNode(id);
    }
  }

  Future<void> reorderNodes(List<String> nodeIds) async {
    final maps = await _getAllNodesInternal();
    for (int i = 0; i < nodeIds.length; i++) {
      final index = maps.indexWhere((n) => n['id'] == nodeIds[i]);
      if (index != -1) {
        maps[index]['sort_order'] = i;
      }
    }
    await _saveNodes(maps);
  }

  Future<List<Node>> getAncestors(String nodeId) async {
    final all = await getAllNodes();
    final List<Node> ancestors = [];
    String? currentId = nodeId;

    while (currentId != null) {
      final node = all.firstWhere((n) => n.id == currentId);
      ancestors.insert(0, node);
      currentId = node.parentId;
    }

    return ancestors;
  }

  Future<List<Node>> getPathToNode(String nodeId) async {
    return getAncestors(nodeId);
  }

  Future<List<Map<String, dynamic>>> searchNodes(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    final all = await getAllNodes();
    final lowerKeyword = keyword.trim().toLowerCase();

    final matchedNodes = all.where((node) {
      if (node.title.toLowerCase().contains(lowerKeyword)) return true;
      if (node.tags.any((t) => t.toLowerCase().contains(lowerKeyword))) return true;
      return false;
    }).toList();

    final results = <Map<String, dynamic>>[];
    for (var node in matchedNodes) {
      final path = await getAncestors(node.id);
      final pathNames = path.map((n) => n.title).join(' / ');
      results.add({
        'node': node,
        'path': pathNames,
      });
    }

    return results;
  }

  Future<Node> createFolder({
    required String title,
    String? parentId,
    List<String> tags = const [],
  }) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      parentId: parentId,
      isFolder: true,
      nodeType: 'folder',
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await insertNode(node.toMap());
    return node;
  }

  // ✅ 修复：增加 tags 参数
  Future<Node> attachNoteToNode({
    required String noteId,
    required String title,
    String? parentId,
    List<String> tags = const [],
  }) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      parentId: parentId,
      isFolder: false,
      nodeType: 'note',
      targetId: noteId,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await insertNode(node.toMap());
    return node;
  }

  Future<Node> attachBookToNode({
    required String bookId,
    required String title,
    String? parentId,
    List<String> tags = const [],
  }) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      parentId: parentId,
      isFolder: false,
      nodeType: 'book',
      targetId: bookId,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await insertNode(node.toMap());
    return node;
  }

  Future<NotebookEntry?> getNoteByNodeId(String nodeId) async {
    final node = await getNode(nodeId);
    if (node == null || node.nodeType != 'note' || node.targetId == null) return null;
    final notes = await _getAllNotesInternal(includeDeleted: false);
    try {
      final map = notes.firstWhere((n) => n['id'] == node.targetId);
      return NotebookEntry.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<Book?> getBookByNodeId(String nodeId) async {
    final node = await getNode(nodeId);
    if (node == null || node.nodeType != 'book' || node.targetId == null) return null;
    final books = await getAllBooks();
    try {
      final map = books.firstWhere((b) => b['id'] == node.targetId);
      return Book.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<List<Node>> getContentNodesInFolder(String folderId) async {
    final children = await getChildren(folderId);
    return children.where((n) => !n.isFolder).toList();
  }

  Future<void> ensureRootNodesExist() async {
    final roots = await getRootNodes();
    if (roots.isNotEmpty) return;

    final noteMaps = await getActiveNotes();
    final bookMaps = await getAllBooks();

    final List<Map<String, dynamic>> nodesToAdd = [];

    for (var map in noteMaps) {
      final note = NotebookEntry.fromMap(map);
      nodesToAdd.add(Node(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_${note.id}',
        title: note.title,
        parentId: null,
        isFolder: false,
        nodeType: 'note',
        targetId: note.id,
        tags: note.tags, // ✅ 旧数据迁移时也保留标签
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());
    }

    for (var map in bookMaps) {
      final book = Book.fromMap(map);
      nodesToAdd.add(Node(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_${book.id}',
        title: book.title,
        parentId: null,
        isFolder: false,
        nodeType: 'book',
        targetId: book.id,
        tags: [], // 图书暂时无标签
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());
    }

    if (nodesToAdd.isEmpty) return;

    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nodes_data', jsonEncode(nodesToAdd));
    } else {
      final db = await _getDatabase();
      for (var node in nodesToAdd) {
        await db.insert('nodes', node);
      }
    }
  }

  Future<void> _saveNodes(List<Map<String, dynamic>> nodes) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nodes_data', jsonEncode(nodes));
    } else {
      final db = await _getDatabase();
      await db.delete('nodes');
      for (var node in nodes) {
        await db.insert('nodes', node);
      }
    }
  }

  // ============================================================
  // 笔记 CRUD
  // ============================================================

  Future<void> insertNote(Map<String, dynamic> noteMap) async {
    if (!noteMap.containsKey('status')) {
      noteMap['status'] = 'raw';
    }
    if (!noteMap.containsKey('editorMode')) {
      noteMap['editorMode'] = 'plain';
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

  Future<List<Map<String, dynamic>>> getRawNotes() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'raw').toList();
  }

  Future<List<Map<String, dynamic>>> getActiveNotes() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'active').toList();
  }

  Future<List<Map<String, dynamic>>> getArchivedNotes() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'archived').toList();
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final all = await _getAllNotesInternal(includeDeleted: false);
    return all.where((n) => n['status'] == 'task').toList();
  }

  Future<void> sendToWisdom(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'active';
      notes[index]['updatedAt'] = DateTime.now().toIso8601String();
      await _saveNotes(notes);
    }
  }

  Future<void> archiveNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'archived';
      await _saveNotes(notes);
    }
  }

  Future<void> unarchiveNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'active';
      await _saveNotes(notes);
    }
  }

  Future<void> deleteNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'deleted';
      await _saveNotes(notes);
    }
  }

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

  // ============================================================
  // 书籍 CRUD
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
  // 标注 CRUD（占位）
  // ============================================================

  Future<void> insertAnnotation(Map<String, dynamic> annotationMap) async {}
  Future<List<Map<String, dynamic>>> getAllAnnotationsForBook(String bookId) async {
    return [];
  }

  // ============================================================
  // 🆕 复盘专用方法（新增）
  // ============================================================

  /// 确保“复盘”文件夹存在，返回其 nodeId
  Future<String> ensureReviewFolder() async {
    final allNodes = await getAllNodes();
    for (var node in allNodes) {
      if (node.title == '复盘' && node.isFolder && node.parentId == null) {
        return node.id;
      }
    }
    // 不存在则创建
    final folder = await createFolder(title: '复盘');
    return folder.id;
  }

  /// 在“复盘”文件夹下创建一篇笔记（自动打 #复盘 标签）
  Future<NotebookEntry> createReviewNote({
    required String title,
    required String content,
    List<String> extraTags = const [],
  }) async {
    // 1. 获取或创建“复盘”文件夹
    final folderId = await ensureReviewFolder();

    // 2. 创建笔记实体
    final noteId = DateTime.now().millisecondsSinceEpoch.toString();
    final allTags = <String>['复盘', ...extraTags];

    final noteMap = {
      'id': noteId,
      'title': title,
      'content': content,
      'status': 'active',
      'editorMode': 'plain',
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // 3. 保存笔记
    await insertNote(noteMap);

    // 4. 创建节点关联到“复盘”文件夹
    await attachNoteToNode(
      noteId: noteId,
      title: title,
      parentId: folderId,
      tags: allTags,
    );

    // 5. 返回笔记对象
    return NotebookEntry.fromMap(noteMap);
  }

  // ============================================================
  // 原生 SQLite 支持
  // ============================================================

  static Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    String path = join(await getDatabasesPath(), 'notebook.db');
    _database = await openDatabase(
      path,
      version: 5,
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
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN editorMode TEXT DEFAULT "plain"');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE nodes(
          id TEXT PRIMARY KEY,
          title TEXT,
          parent_id TEXT,
          is_folder INTEGER DEFAULT 0,
          node_type TEXT DEFAULT 'folder',
          target_id TEXT,
          sort_order INTEGER DEFAULT 0,
          tags TEXT DEFAULT '',
          created_at TEXT,
          updated_at TEXT
        )
      ''');
    }
  }
  // ============================================================
  // 🆕 解析 Markdown 任务列表
  // ============================================================

  /// 从 Markdown 内容中解析子任务列表
  /// 支持格式：
  /// - [ ] 任务名（未完成）
  /// - [x] 任务名（已完成）
  List<Map<String, dynamic>> parseSubtasksFromMarkdown(String content) {
    final results = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    int index = 0;
    for (var line in lines) {
      final uncheckedMatch = RegExp(r'^-\s*\[\s*\]\s*(.+)$').firstMatch(line);
      final checkedMatch = RegExp(r'^-\s*\[x\]\s*(.+)$').firstMatch(line);
      if (uncheckedMatch != null) {
        results.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString() + '_${index++}',
          'title': uncheckedMatch.group(1)?.trim() ?? '未命名子任务',
          'isDone': false,
        });
      } else if (checkedMatch != null) {
        results.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString() + '_${index++}',
          'title': checkedMatch.group(1)?.trim() ?? '未命名子任务',
          'isDone': true,
        });
      }
    }
    return results;
  }
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        updatedAt TEXT,
        status TEXT DEFAULT 'raw',
        editorMode TEXT DEFAULT 'plain'
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
    await db.execute('''
      CREATE TABLE nodes(
        id TEXT PRIMARY KEY,
        title TEXT,
        parent_id TEXT,
        is_folder INTEGER DEFAULT 0,
        node_type TEXT DEFAULT 'folder',
        target_id TEXT,
        sort_order INTEGER DEFAULT 0,
        tags TEXT DEFAULT '',
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }
}