// lib/database_service.dart
// 数据层 — 双引擎（Web/原生）支持 + 导出/导入 + 灵感过期归档 + 图书馆文件夹

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
        id: '${DateTime.now().millisecondsSinceEpoch}_${note.id}',
        title: note.title,
        parentId: null,
        isFolder: false,
        nodeType: 'note',
        targetId: note.id,
        tags: note.tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap());
    }

    for (var map in bookMaps) {
      final book = Book.fromMap(map);
      nodesToAdd.add(Node(
        id: '${DateTime.now().millisecondsSinceEpoch}_${book.id}',
        title: book.title,
        parentId: null,
        isFolder: false,
        nodeType: 'book',
        targetId: book.id,
        tags: [],
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
    if (!noteMap.containsKey('isLocked')) {
      noteMap['isLocked'] = 0;
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
  // 系统文件夹管理
  // ============================================================

  /// 确保“复盘”文件夹存在，返回其ID（任务复盘归档用）
  Future<String> ensureReviewFolder() async {
    final allNodes = await getAllNodes();
    for (var node in allNodes) {
      if (node.title == '复盘' && node.isFolder && node.parentId == null) {
        return node.id;
      }
    }
    final folder = await createFolder(title: '复盘');
    return folder.id;
  }

  /// ✅ 新增：确保“图书馆”文件夹存在，返回其ID（图书导入自动归类用）
  Future<String> ensureLibraryFolder() async {
    final allNodes = await getAllNodes();
    for (var node in allNodes) {
      if (node.title == '图书馆' && node.isFolder && node.parentId == null) {
        return node.id;
      }
    }
    final folder = await createFolder(
      title: '图书馆',
      parentId: null,
      tags: ['系统', '图书'],
    );
    return folder.id;
  }

  Future<NotebookEntry> createReviewNote({
    required String title,
    required String content,
    List<String> extraTags = const [],
  }) async {
    final folderId = await ensureReviewFolder();
    final noteId = DateTime.now().millisecondsSinceEpoch.toString();
    final allTags = <String>['复盘', ...extraTags];

    final noteMap = {
      'id': noteId,
      'title': title,
      'content': content,
      'status': 'active',
      'editorMode': 'plain',
      'updatedAt': DateTime.now().toIso8601String(),
      'isLocked': 0,
    };

    await insertNote(noteMap);
    await attachNoteToNode(
      noteId: noteId,
      title: title,
      parentId: folderId,
      tags: allTags,
    );

    return NotebookEntry.fromMap(noteMap);
  }

  // ============================================================
  // 解析 Markdown 任务列表
  // ============================================================

  List<Map<String, dynamic>> parseSubtasksFromMarkdown(String content) {
    final results = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    int index = 0;
    for (var line in lines) {
      final uncheckedMatch = RegExp(r'^-\s*\[\s*\]\s*(.+)$').firstMatch(line);
      final checkedMatch = RegExp(r'^-\s*\[x\]\s*(.+)$').firstMatch(line);
      if (uncheckedMatch != null) {
        results.add({
          'id': '${DateTime.now().millisecondsSinceEpoch}_${index++}',
          'title': uncheckedMatch.group(1)?.trim() ?? '未命名子任务',
          'isDone': false,
        });
      } else if (checkedMatch != null) {
        results.add({
          'id': '${DateTime.now().millisecondsSinceEpoch}_${index++}',
          'title': checkedMatch.group(1)?.trim() ?? '未命名子任务',
          'isDone': true,
        });
      }
    }
    return results;
  }

  // ============================================================
  // ✅ 导出/导入
  // ============================================================

  /// 导出全部数据为 JSON 字符串
  Future<String> exportAllData() async {
    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'notes': await getAllNotes(includeDeleted: true),
      'nodes': await _getAllNodesInternal(),
      'books': await getAllBooks(),
    };
    return jsonEncode(data);
  }

  /// 导入 JSON 数据（覆盖所有数据）
  Future<void> importAllData(String jsonString) async {
    final data = jsonDecode(jsonString);
    await _clearAllData();

    if (data['notes'] != null) {
      for (var note in data['notes']) {
        await insertNote(note);
      }
    }
    if (data['nodes'] != null) {
      for (var node in data['nodes']) {
        await insertNode(node);
      }
    }
    if (data['books'] != null) {
      for (var book in data['books']) {
        await insertBook(book);
      }
    }
  }

  /// 清空所有数据
  Future<void> _clearAllData() async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notes_data');
      await prefs.remove('nodes_data');
      await prefs.remove('books_data');
    } else {
      final db = await _getDatabase();
      await db.delete('notes');
      await db.delete('nodes');
      await db.delete('books');
    }
  }

  /// 导出笔记为 Markdown 文件
  Future<String> exportNotesAsMarkdown() async {
    final noteMaps = await getAllNotes(includeDeleted: false);
    final buffer = StringBuffer();
    for (var map in noteMaps) {
      final note = NotebookEntry.fromMap(map);
      buffer.writeln('# ${note.title}');
      buffer.writeln('> 标签：${note.tags.join(', ')}');
      buffer.writeln('> 状态：${note.status}');
      buffer.writeln('> 更新时间：${note.updatedAt.toIso8601String()}');
      buffer.writeln('');
      buffer.writeln(note.content);
      buffer.writeln('\n---\n');
    }
    return buffer.toString();
  }

  // ============================================================
  // 🆕 灵感笔记自动归档相关
  // ============================================================

  /// 归档过期的灵感笔记（status='raw' 且超过 retentionDays 天未更新）
  Future<int> archiveExpiredRawNotes(int retentionDays) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionDays));

    final expiredNoteIds = <String>[];
    for (var note in notes) {
      final updatedAt = DateTime.parse(note['updatedAt']);
      if (note['status'] == 'raw' &&
          note['isLocked'] != 1 &&
          updatedAt.isBefore(cutoff)) {
        expiredNoteIds.add(note['id']);
      }
    }

    if (expiredNoteIds.isEmpty) return 0;

    for (var id in expiredNoteIds) {
      final index = notes.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        notes[index]['status'] = 'archived';
        notes[index]['updatedAt'] = DateTime.now().toIso8601String();
      }
    }
    await _saveNotes(notes);

    final expiredFolderId = await _ensureExpiredFolder();
    for (var id in expiredNoteIds) {
      final nodes = await _getAllNodesInternal();
      final existingNodeIndex = nodes.indexWhere((n) => n['target_id'] == id);
      if (existingNodeIndex != -1) {
        nodes.removeAt(existingNodeIndex);
        await _saveNodes(nodes);
      }
      await attachNoteToNode(
        noteId: id,
        title: notes.firstWhere((n) => n['id'] == id)['title'],
        parentId: expiredFolderId,
        tags: [],
      );
    }

    return expiredNoteIds.length;
  }

  Future<String> _ensureExpiredFolder() async {
    final allNodes = await getAllNodes();
    for (var node in allNodes) {
      if (node.title == '灵感过期' && node.isFolder && node.parentId == null) {
        return node.id;
      }
    }
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '灵感过期',
      parentId: null,
      isFolder: true,
      nodeType: 'folder',
      tags: ['系统', '过期'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await insertNode(node.toMap());
    return node.id;
  }

  Future<List<NotebookEntry>> getExpiringRawNotes(int retentionDays) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionDays));

    final result = <NotebookEntry>[];
    for (var map in notes) {
      if (map['status'] != 'raw') continue;
      if (map['isLocked'] == 1) continue;
      final updatedAt = DateTime.parse(map['updatedAt']);
      final daysAgo = now.difference(updatedAt).inDays;
      if (daysAgo >= retentionDays - 7 && daysAgo < retentionDays) {
        result.add(NotebookEntry.fromMap(map));
      }
    }
    return result;
  }

  Future<int> getExpiredRawNotesCount(int retentionDays) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionDays));

    int count = 0;
    for (var map in notes) {
      if (map['status'] != 'raw') continue;
      if (map['isLocked'] == 1) continue;
      final updatedAt = DateTime.parse(map['updatedAt']);
      if (updatedAt.isBefore(cutoff)) {
        count++;
      }
    }
    return count;
  }

  Future<void> toggleLockNote(String noteId, bool locked) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == noteId);
    if (index != -1) {
      notes[index]['isLocked'] = locked ? 1 : 0;
      await _saveNotes(notes);
    }
  }

  Future<int> getLockedNotesCount() async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    return notes.where((n) => n['isLocked'] == 1).length;
  }

  Future<int> getExpiredFolderNoteCount() async {
    final nodes = await getAllNodes();
    final expiredFolder = nodes.firstWhere(
      (n) => n.title == '灵感过期' && n.isFolder && n.parentId == null,
      orElse: () => nodes.first,
    );
    if (expiredFolder.id.isEmpty) return 0;
    final children = await getChildren(expiredFolder.id);
    return children.where((n) => !n.isFolder).length;
  }

  Future<List<NotebookEntry>> getExpiredFolderNotes() async {
    final nodes = await getAllNodes();
    final expiredFolder = nodes.firstWhere(
      (n) => n.title == '灵感过期' && n.isFolder && n.parentId == null,
      orElse: () => nodes.first,
    );
    if (expiredFolder.id.isEmpty) return [];
    final children = await getChildren(expiredFolder.id);
    final noteIds = children
        .where((n) => n.nodeType == 'note' && n.targetId != null)
        .map((n) => n.targetId!)
        .toList();
    if (noteIds.isEmpty) return [];

    final allNotes = await _getAllNotesInternal(includeDeleted: false);
    final result = <NotebookEntry>[];
    for (var map in allNotes) {
      if (noteIds.contains(map['id'])) {
        result.add(NotebookEntry.fromMap(map));
      }
    }
    return result;
  }

  // ============================================================
  // 原生 SQLite 支持（已修复：新增 tags 列）
  // ============================================================

  static Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    String path = join(await getDatabasesPath(), 'notebook.db');
    _database = await openDatabase(
      path,
      version: 6, // ✅ 版本升级到 6，触发迁移
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本 2：添加 status 列
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN status TEXT DEFAULT "raw"');
      } catch (_) {}
    }

    // 版本 3：books 表新增列
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE books ADD COLUMN cover_image TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE books ADD COLUMN pdf_path TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE books ADD COLUMN file_type TEXT DEFAULT "none"');
      } catch (_) {}
    }

    // 版本 4：notes 表新增 editorMode
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN editorMode TEXT DEFAULT "plain"');
      } catch (_) {}
    }

    // ✅ 版本 5 和 6：合并处理，确保 tags 列存在
    if (oldVersion < 6) {
      // 添加 tags 列（如果不存在）
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT DEFAULT ""');
      } catch (_) {}

      // 添加 isLocked 列（如果不存在）
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0');
      } catch (_) {}

      // 创建 nodes 表（如果不存在）
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS nodes(
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
      } catch (_) {}
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        updatedAt TEXT,
        status TEXT DEFAULT 'raw',
        editorMode TEXT DEFAULT 'plain',
        isLocked INTEGER DEFAULT 0,
        tags TEXT DEFAULT ''   -- ✅ 新增 tags 列
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