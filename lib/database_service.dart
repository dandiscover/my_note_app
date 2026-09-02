// lib/database_service.dart
// 数据层 — 统一字段标准：代码层驼峰，数据库层下划线，tags 统一 List<String> 进模型，String 入库
// ✅ 数据库版本 8 → 9：新增 inquiry_question / scaffold_sessions / subtasks 三列
// ✅ _prepareNoteForDb / _cleanNoteMap 支持新字段序列化/反序列化
// ✅ Web 端读取 notes_data 时补默认值
// ✅ 新增 ensureMigrationAndCleanup() 清理旧探究任务数据

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

  // ═══════════════════════════════════════════════════════════════
  // 0. 清理旧探究任务数据（迁移入口）
  // ═══════════════════════════════════════════════════════════════

  static Future<void> ensureMigrationAndCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = prefs.getBool('legacy_explore_tasks_cleaned') ?? false;
    if (!cleaned) {
      await _clearLegacyExploreTasks();
      await prefs.setBool('legacy_explore_tasks_cleaned', true);
    }
  }

  static Future<void> _clearLegacyExploreTasks() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 读取所有任务
    final tasksJson = prefs.getStringList('tasks') ?? [];

    // 2. 分离 explore 任务和普通任务
    final exploreTaskIds = <String>[];
    final remainingTasks = <String>[];

    for (var json in tasksJson) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        if (map['type'] == 'explore') {
          exploreTaskIds.add(map['id'] as String);
        } else {
          remainingTasks.add(json);
        }
      } catch (_) {
        // 格式异常的条目，保留（不丢失数据）
        remainingTasks.add(json);
      }
    }

    // 3. 写回剩余任务
    await prefs.setStringList('tasks', remainingTasks);

    // 4. 清理属于已删除探究任务的子任务
    if (exploreTaskIds.isNotEmpty) {
      final subtasksJson = prefs.getStringList('subtasks') ?? [];
      final remainingSubtasks = subtasksJson.where((json) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          final parentId = map['parentTaskId'] as String?;
          return parentId == null || !exploreTaskIds.contains(parentId);
        } catch (_) {
          return true;
        }
      }).toList();
      await prefs.setStringList('subtasks', remainingSubtasks);
    }
  }

  // ============================================================
  // 节点 CRUD
  // ============================================================

  Future<void> insertNode(Map<String, dynamic> nodeMap) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final nodes = await _getAllNodesInternal();
      nodes.add(nodeMap);
      await prefs.setString('nodes_data', jsonEncode(nodes));
    } else {
      final db = await _getDatabase();
      await db.insert('nodes', _prepareNodeForDb(nodeMap));
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
      return list.map((e) => _cleanNodeMap(Map<String, dynamic>.from(e))).toList();
    } else {
      final db = await _getDatabase();
      final rows = await db.query('nodes', orderBy: 'sort_order ASC, created_at ASC');
      return rows.map((row) => _cleanNodeMap(_mapNodeDbRowToCamel(row))).toList();
    }
  }

  Map<String, dynamic> _mapNodeDbRowToCamel(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'title': row['title'],
      'parentId': row['parent_id'],
      'isFolder': row['is_folder'],
      'nodeType': row['node_type'],
      'targetId': row['target_id'],
      'sortOrder': row['sort_order'],
      'tags': row['tags'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }

  Map<String, dynamic> _cleanNodeMap(Map<String, dynamic> map) {
    final cleaned = Map<String, dynamic>.from(map);

    if (cleaned['parentId'] == '' || cleaned['parentId'] == 'null') {
      cleaned['parentId'] = null;
    }
    if (cleaned['targetId'] == '' || cleaned['targetId'] == 'null') {
      cleaned['targetId'] = null;
    }

    final tagsRaw = cleaned['tags'];
    if (tagsRaw is String) {
      cleaned['tags'] = tagsRaw.isEmpty ? [] : tagsRaw.split(',').where((t) => t.trim().isNotEmpty).map((t) => t.trim()).toList();
    } else if (tagsRaw is List) {
      cleaned['tags'] = tagsRaw.whereType<String>().toList();
    } else {
      cleaned['tags'] = [];
    }

    return cleaned;
  }

  Map<String, dynamic> _prepareNodeForDb(Map<String, dynamic> map) {
  final tags = map['tags'];
  final tagsStr = tags is List ? (tags as List).whereType<String>().join(',') : (tags?.toString() ?? '');

  // 清理 parentId：空字符串或 'null' 字符串 → null
  final parentId = map['parentId'];
  final cleanedParentId = (parentId == '' || parentId == 'null') ? null : parentId;

  // 清理 targetId：空字符串或 'null' 字符串 → null
  final targetId = map['targetId'];
  final cleanedTargetId = (targetId == '' || targetId == 'null') ? null : targetId;

  return {
    'id': map['id'],
    'title': map['title'],
    'parent_id': cleanedParentId,
    'is_folder': map['isFolder'] ?? 0,
    'node_type': map['nodeType'],
    'target_id': cleanedTargetId,
    'sort_order': map['sortOrder'] ?? 0,
    'tags': tagsStr,
    'created_at': map['createdAt'],
    'updated_at': map['updatedAt'],
  };
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
        maps[index]['sortOrder'] = i;
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

  Future<void> _saveNodes(List<Map<String, dynamic>> nodes) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nodes_data', jsonEncode(nodes));
    } else {
      final db = await _getDatabase();
      await db.delete('nodes');
      for (var node in nodes) {
        await db.insert('nodes', _prepareNodeForDb(node));
      }
    }
  }

  // ============================================================
  // 笔记 CRUD
  // ============================================================

  Future<void> insertNote(Map<String, dynamic> noteMap) async {
    if (!noteMap.containsKey('status')) noteMap['status'] = 'raw';
    if (!noteMap.containsKey('editorMode')) noteMap['editorMode'] = 'plain';
    if (!noteMap.containsKey('isLocked')) noteMap['isLocked'] = 0;

    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final notes = await _getAllNotesInternal(includeDeleted: false);
      notes.insert(0, noteMap);
      await prefs.setString('notes_data', jsonEncode(notes));
    } else {
      final db = await _getDatabase();
      await db.insert('notes', _prepareNoteForDb(noteMap), conflictAlgorithm: ConflictAlgorithm.replace);
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
      final allNotes = list.map((e) => _cleanNoteMap(Map<String, dynamic>.from(e))).toList();

      // ✅ Web 端：自动补默认值
      for (var note in allNotes) {
        if (!note.containsKey('inquiryQuestion')) note['inquiryQuestion'] = null;
        if (!note.containsKey('scaffoldSessions')) note['scaffoldSessions'] = [];
        if (!note.containsKey('subtasks')) note['subtasks'] = [];
      }

      if (includeDeleted) return allNotes;
      return allNotes.where((n) => n['status'] != 'deleted').toList();
    } else {
      final db = await _getDatabase();
      final rows = await db.query('notes', orderBy: 'updatedAt DESC');
      final allNotes = rows.map((row) => _cleanNoteMap(row)).toList();
      if (includeDeleted) return allNotes;
      return allNotes.where((n) => n['status'] != 'deleted').toList();
    }
  }

Map<String, dynamic> _cleanNoteMap(Map<String, dynamic> map) {
  final cleaned = Map<String, dynamic>.from(map);

  // ✅ 将数据库下划线列名映射到模型驼峰键名
  cleaned['inquiryQuestion'] = cleaned['inquiry_question'];
  cleaned['scaffoldSessions'] = cleaned['scaffold_sessions'];
  cleaned['subtasks'] = cleaned['subtasks'];

  // tags: String → List<String>
  final tagsRaw = cleaned['tags'];
  if (tagsRaw is String) {
    cleaned['tags'] = tagsRaw.isEmpty ? [] : tagsRaw.split(',').where((t) => t.trim().isNotEmpty).map((t) => t.trim()).toList();
  } else if (tagsRaw is List) {
    cleaned['tags'] = tagsRaw.whereType<String>().toList();
  } else {
    cleaned['tags'] = [];
  }

  // ✅ scaffoldSessions: String → List<Map>
  final sessionsRaw = cleaned['scaffoldSessions'];
  if (sessionsRaw is String && sessionsRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(sessionsRaw);
      cleaned['scaffoldSessions'] = (decoded as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      cleaned['scaffoldSessions'] = [];
    }
  } else if (sessionsRaw is List) {
    cleaned['scaffoldSessions'] = sessionsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } else {
    cleaned['scaffoldSessions'] = [];
  }

  // ✅ subtasks: String → List<NoteSubtask>
  final subtasksRaw = cleaned['subtasks'];
  if (subtasksRaw is String && subtasksRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(subtasksRaw);
      cleaned['subtasks'] = (decoded as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      cleaned['subtasks'] = [];
    }
  } else if (subtasksRaw is List) {
    cleaned['subtasks'] = (subtasksRaw as List).map((e) => NoteSubtask.fromMap(e as Map<String, dynamic>)).toList();
  } else {
    cleaned['subtasks'] = [];
  }

  // inquiryQuestion: 直接透传
  cleaned['inquiryQuestion'] = cleaned['inquiryQuestion'] as String?;

  return cleaned;
}
    

 Map<String, dynamic> _prepareNoteForDb(Map<String, dynamic> map) {
  final tags = map['tags'];
  final tagsStr = tags is List ? (tags as List).whereType<String>().join(',') : (tags?.toString() ?? '');

  // ✅ scaffoldSessions: List<Map> → String
  final sessions = map['scaffoldSessions'];
  final sessionsStr = sessions is List && sessions.isNotEmpty
      ? jsonEncode(sessions)
      : '[]';

  // ✅ subtasks: List<NoteSubtask> → String
  final subtasks = map['subtasks'];
  final subtasksStr = subtasks is List && subtasks.isNotEmpty
      ? jsonEncode(subtasks.map((e) => e.toMap()).toList())
      : '[]';

  return {
    'id': map['id'],
    'title': map['title'] ?? '',
    'content': map['content'] ?? '',
    'updatedAt': map['updatedAt'] ?? DateTime.now().toIso8601String(),
    'status': map['status'] ?? 'raw',
    'editorMode': map['editorMode'] ?? 'plain',
    'isLocked': map['isLocked'] is bool ? (map['isLocked'] == true ? 1 : 0) : (map['isLocked'] ?? 0),
    'tags': tagsStr,
    'inquiry_question': map['inquiryQuestion'] as String?,
    'scaffold_sessions': sessionsStr,
    'subtasks': subtasksStr,
  };
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

  Future<void> _moveNoteToArchived(String noteId) async {
    final folderId = await ensureArchivedFolder();

    final notes = await _getAllNotesInternal(includeDeleted: false);
    final noteIndex = notes.indexWhere((n) => n['id'] == noteId);
    if (noteIndex == -1) return;

    final nodes = await _getAllNodesInternal();
    final nodeIndex = nodes.indexWhere((n) => n['targetId'] == noteId);

    notes[noteIndex]['status'] = 'archived';
    notes[noteIndex]['updatedAt'] = DateTime.now().toIso8601String();

    if (nodeIndex != -1) {
      nodes[nodeIndex]['parentId'] = folderId;
    } else {
      final note = NotebookEntry.fromMap(notes[noteIndex]);
      nodes.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': note.title,
        'parentId': folderId,
        'isFolder': 0,
        'nodeType': 'note',
        'targetId': noteId,
        'sortOrder': 0,
        'tags': note.tags,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    await _saveNotes(notes);
    await _saveNodes(nodes);
  }

  Future<void> archiveNote(String id) async {
    await _moveNoteToArchived(id);
  }

  Future<void> unarchiveNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      notes[index]['status'] = 'active';
      notes[index]['updatedAt'] = DateTime.now().toIso8601String();
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
        await db.update('notes', _prepareNoteForDb(note), where: 'id = ?', whereArgs: [note['id']]);
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
      await db.insert('books', _prepareBookForDb(bookMap), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('books_data');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      return list.map((e) => _cleanBookMap(Map<String, dynamic>.from(e))).toList();
    } else {
      final db = await _getDatabase();
      final rows = await db.query('books', orderBy: 'created_at DESC');
      return rows.map((row) => _cleanBookMap(_mapBookDbRowToCamel(row))).toList();
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
      if (result.isNotEmpty) {
        return _cleanBookMap(_mapBookDbRowToCamel(result.first));
      }
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
      await db.update('books', _prepareBookForDb(bookMap), where: 'id = ?', whereArgs: [bookMap['id']]);
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

  Map<String, dynamic> _mapBookDbRowToCamel(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'title': row['title'],
      'author': row['author'],
      'isbn': row['isbn'],
      'coverUrl': row['cover_url'],
      'filePath': row['file_path'],
      'fileType': row['file_type'],
      'fileName': row['file_name'],
      'fileSize': row['file_size'],
      'status': row['status'],
      'readingProgress': row['reading_progress'],
      'totalPages': row['total_pages'],
      'createdAt': row['created_at'],
      'lastReadAt': row['last_read_at'],
    };
  }

  Map<String, dynamic> _cleanBookMap(Map<String, dynamic> map) {
    return Map<String, dynamic>.from(map);
  }

  Map<String, dynamic> _prepareBookForDb(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'title': map['title'],
      'author': map['author'],
      'isbn': map['isbn'],
      'cover_url': map['coverUrl'],
      'file_path': map['filePath'],
      'file_type': map['fileType'],
      'file_name': map['fileName'],
      'file_size': map['fileSize'],
      'status': map['status'],
      'reading_progress': map['readingProgress'],
      'total_pages': map['totalPages'],
      'created_at': map['createdAt'],
      'last_read_at': map['lastReadAt'],
    };
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

  Future<String> _ensureSystemFolder(String title, {List<String>? tags}) async {
    final allNodes = await getAllNodes();
    final matches = allNodes.where((n) => n.title == title && n.isFolder && n.parentId == null).toList();

    if (matches.isEmpty) {
      final folder = await createFolder(title: title, parentId: null, tags: tags ?? []);
      return folder.id;
    }

    if (matches.length > 1) {
      final keep = matches.first;
      final allNodesFull = await getAllNodes();

      for (var i = 1; i < matches.length; i++) {
        final dup = matches[i];
        final children = allNodesFull.where((n) => n.parentId == dup.id).toList();
        for (var child in children) {
          await moveNode(child.id, keep.id);
        }
        await deleteNode(dup.id);
      }
      return keep.id;
    }

    return matches.first.id;
  }

  Future<String> ensureArchivedFolder() => _ensureSystemFolder('已归档', tags: ['系统', '归档']);
  Future<String> ensureLibraryFolder() => _ensureSystemFolder('图书馆', tags: ['系统', '图书']);
  Future<String> ensureReviewFolder() => _ensureSystemFolder('复盘', tags: ['系统', '复盘']);
  Future<String> ensureCardBoxFolder() => _ensureSystemFolder('卡片盒', tags: ['系统', '卡片盒']);

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

  Future<void> migrateExpiredToArchived() async {
    final nodes = await _getAllNodesInternal();

    final expiredFolders = nodes.where((n) => n['title'] == '灵感过期' && n['isFolder'] == 1 && n['parentId'] == null).toList();

    if (expiredFolders.isEmpty) {
      print('没有需要迁移的旧文件夹');
      return;
    }

    final archivedId = await ensureArchivedFolder();
    for (var folder in expiredFolders) {
      final children = nodes.where((n) => n['parentId'] == folder['id']).toList();
      for (var child in children) {
        child['parentId'] = archivedId;
      }
      nodes.remove(folder);
    }
    await _saveNodes(nodes);
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
  // 导出/导入
  // ============================================================

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
  // 灵感笔记自动归档
  // ============================================================

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
      await _moveNoteToArchived(id);
    }

    return expiredNoteIds.length;
  }

  Future<List<NotebookEntry>> getExpiringRawNotes(int retentionDays) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionDays - 7));

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
      if (updatedAt.isBefore(cutoff)) count++;
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

  Future<int> getArchivedFolderNoteCount() async {
    final nodes = await getAllNodes();
    final archivedFolder = nodes.firstWhere(
      (n) => n.title == '已归档' && n.isFolder && n.parentId == null,
      orElse: () => Node.empty,
    );
    if (archivedFolder.id.isEmpty) return 0;
    final children = await getChildren(archivedFolder.id);
    return children.where((n) => !n.isFolder).length;
  }

  Future<List<NotebookEntry>> getArchivedFolderNotes() async {
    final nodes = await getAllNodes();
    final archivedFolder = nodes.firstWhere(
      (n) => n.title == '已归档' && n.isFolder && n.parentId == null,
      orElse: () => Node.empty,
    );
    if (archivedFolder.id.isEmpty) return [];

    final children = await getChildren(archivedFolder.id);
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
  // 原生 SQLite 支持
  // ============================================================

  static Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    String path = join(await getDatabasesPath(), 'notebook.db');
    _database = await openDatabase(
      path,
      version: 9,  // ✅ 版本 8 → 9
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN status TEXT DEFAULT "raw"'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE books ADD COLUMN cover_image TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN pdf_path TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_type TEXT DEFAULT "none"'); } catch (_) {}
    }
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN editorMode TEXT DEFAULT "plain"'); } catch (_) {}
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT DEFAULT ""'); } catch (_) {}
      try { await db.execute('ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 6) {
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
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE books ADD COLUMN cover_url TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_path TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_name TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_size INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN last_read_at TEXT'); } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS book_annotations(
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
      } catch (_) {}
    }

    // ✅ 版本 8 → 9：新增 inquiry_question / scaffold_sessions / subtasks 三列
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN inquiry_question TEXT');
        await db.execute('ALTER TABLE notes ADD COLUMN scaffold_sessions TEXT DEFAULT "[]"');
        await db.execute('ALTER TABLE notes ADD COLUMN subtasks TEXT DEFAULT "[]"');
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
        tags TEXT DEFAULT '',
        inquiry_question TEXT,
        scaffold_sessions TEXT DEFAULT '[]',
        subtasks TEXT DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY,
        title TEXT,
        author TEXT,
        isbn TEXT,
        cover_url TEXT,
        file_path TEXT,
        file_type TEXT DEFAULT 'none',
        file_name TEXT,
        file_size INTEGER DEFAULT 0,
        status TEXT DEFAULT 'want',
        reading_progress INTEGER DEFAULT 0,
        total_pages INTEGER DEFAULT 0,
        created_at TEXT,
        last_read_at TEXT
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