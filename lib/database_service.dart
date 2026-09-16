// lib/database_service.dart
// 数据层 — 统一字段标准：代码层驼峰，数据库层下划线
// ✅ 第四轮批 1：数据库版本 16 → 17（tag_index 加 sourceType，noteId 改名 sourceId）；
//    _syncSearchIndexForNote 适配；新增 syncBookNotesIndex / searchIndex

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/note.dart';
import 'models/book.dart';
import 'models/node.dart';
import 'models/explore_task.dart';
import 'models/note_subtask.dart';
import 'models/pdf_drawing.dart';
import 'services/search_index_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool get _isWeb => kIsWeb;

  // ─── 迁移与清理 ──────────────────────────────────────────

  static Future<void> ensureMigrationAndCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = prefs.getBool('explore_tasks_cleaned') ?? false;
    if (!cleaned) {
      await _clearLegacyExploreTasks();
      await prefs.setBool('explore_tasks_cleaned', true);
    }
  }

  static Future<void> _clearLegacyExploreTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
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
        remainingTasks.add(json);
      }
    }
    await prefs.setStringList('tasks', remainingTasks);
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

  Future<void> ensureExploreMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool('explore_notes_migrated') ?? false;
    if (migrated) return;
    try {
      final allNotes = await _getAllNotesInternal(includeDeleted: true);
      bool anyMigrated = false;
      for (var note in allNotes) {
        if (note.containsKey('exploreTasks') && note['exploreTasks'] != null && note['exploreTasks'].isNotEmpty) continue;
        final sessions = note['scaffoldSessions'] ?? note['scaffold_sessions'];
        final subtasks = note['subtasks'] ?? note['subtasks'];
        final hasSessions = sessions != null && sessions.isNotEmpty;
        final hasSubtasks = subtasks != null && subtasks.isNotEmpty;
        if (!hasSessions && !hasSubtasks) continue;
        List<Map<String, dynamic>> parsedSessions = [];
        if (sessions is String && sessions.isNotEmpty) {
          try {
            final decoded = jsonDecode(sessions);
            if (decoded is List) parsedSessions = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          } catch (_) {}
        } else if (sessions is List) {
          parsedSessions = sessions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        List<NoteSubtask> parsedSubtasks = [];
        if (subtasks is String && subtasks.isNotEmpty) {
          try {
            final decoded = jsonDecode(subtasks);
            if (decoded is List) parsedSubtasks = decoded.map((e) => NoteSubtask.fromMap(e as Map<String, dynamic>)).toList();
          } catch (_) {}
        } else if (subtasks is List) {
          parsedSubtasks = subtasks.map((e) => NoteSubtask.fromMap(e as Map<String, dynamic>)).toList();
        }
        if (parsedSubtasks.isEmpty) {
          note.remove('scaffoldSessions');
          note.remove('scaffold_sessions');
          note.remove('subtasks');
          continue;
        }
        final task = ExploreTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          scaffoldCardType: 'minimal_step',
          scaffoldAnswers: const [],
          actions: parsedSubtasks,
          status: ExploreTaskStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        note['exploreTasks'] = [task.toJson()];
        note.remove('scaffoldSessions');
        note.remove('scaffold_sessions');
        note.remove('subtasks');
        anyMigrated = true;
      }
      if (anyMigrated) {
        await _saveNotes(allNotes);
        await prefs.setBool('explore_notes_migrated', true);
        print('✅ 旧探究数据已迁移到多任务模型');
      } else {
        await prefs.setBool('explore_notes_migrated', true);
      }
    } catch (e) {
      print('❌ 迁移旧探究数据失败: $e');
    }
  }

  // ─── 节点 CRUD ──────────────────────────────────────────
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

  Map<String, dynamic> _mapNodeDbRowToCamel(Map<String, dynamic> row) => {
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

  Map<String, dynamic> _cleanNodeMap(Map<String, dynamic> map) {
    final cleaned = Map<String, dynamic>.from(map);
    if (cleaned['parentId'] == '' || cleaned['parentId'] == 'null') cleaned['parentId'] = null;
    if (cleaned['targetId'] == '' || cleaned['targetId'] == 'null') cleaned['targetId'] = null;
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
    final parentId = map['parentId'];
    final cleanedParentId = (parentId == '' || parentId == 'null') ? null : parentId;
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
    final allNodes = maps.map((n) => Node.fromMap(n)).toList();
    final node = allNodes.firstWhere((n) => n.id == id, orElse: () => Node.empty);
    if (node.id.isEmpty) return;

    if (node.isFolder) {
      final idsToDelete = <String>{id};
      void collectChildren(String parentId) {
        final children = allNodes.where((n) => n.parentId == parentId).toList();
        for (var child in children) {
          if (child.id == id) continue;
          idsToDelete.add(child.id);
          if (child.isFolder) collectChildren(child.id);
        }
      }
      collectChildren(id);
      maps.removeWhere((n) => idsToDelete.contains(n['id']));
    } else {
      final grandParentId = node.parentId;
      for (var i = 0; i < maps.length; i++) {
        if (maps[i]['parentId'] == id) {
          maps[i]['parentId'] = grandParentId;
          maps[i]['updatedAt'] = DateTime.now().toIso8601String();
        }
      }
      maps.removeWhere((n) => n['id'] == id);
    }
    await _saveNodes(maps);
  }

  Future<void> moveNode(String nodeId, String? newParentId) async {
    final node = await getNode(nodeId);
    if (node == null) return;
    final updated = node.copyWith(parentId: newParentId, updatedAt: DateTime.now());
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
      if (index != -1) maps[index]['sortOrder'] = i;
    }
    await _saveNodes(maps);
  }

  Future<List<Node>> getAncestors(String nodeId) async {
    final all = await getAllNodes();
    final nodeMap = {for (var n in all) n.id: n};
    final List<Node> ancestors = [];
    final visited = <String>{};
    String? currentId = nodeId;
    while (currentId != null) {
      if (visited.contains(currentId)) break;
      visited.add(currentId);
      final node = nodeMap[currentId];
      if (node == null) break;
      ancestors.insert(0, node);
      currentId = node.parentId;
    }
    return ancestors;
  }

  Future<List<Node>> getPathToNode(String nodeId) async => getAncestors(nodeId);

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
      results.add({'node': node, 'path': pathNames});
    }
    return results;
  }

  Future<Node> createFolder({required String title, String? parentId, List<String> tags = const []}) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, parentId: parentId, isFolder: true, nodeType: 'folder',
      tags: tags, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    await insertNode(node.toMap());
    return node;
  }

  Future<Node> attachNoteToNode({required String noteId, required String title, String? parentId, List<String> tags = const []}) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, parentId: parentId, isFolder: false, nodeType: 'note',
      targetId: noteId, tags: tags, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    await insertNode(node.toMap());
    return node;
  }

  Future<Node> attachBookToNode({required String bookId, required String title, String? parentId, List<String> tags = const []}) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, parentId: parentId, isFolder: false, nodeType: 'book',
      targetId: bookId, tags: tags, createdAt: DateTime.now(), updatedAt: DateTime.now(),
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
      for (var node in nodes) await db.insert('nodes', _prepareNodeForDb(node));
    }
  }

  // ─── 笔记 CRUD ──────────────────────────────────────────
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

    await _syncSearchIndexForNote(noteMap);
  }

  Future<List<Map<String, dynamic>>> getAllNotes({bool includeDeleted = false}) async => _getAllNotesInternal(includeDeleted: includeDeleted);

  Future<List<Map<String, dynamic>>> _getAllNotesInternal({bool includeDeleted = false}) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('notes_data');
      if (data == null || data.isEmpty) return [];
      final List<dynamic> list = jsonDecode(data);
      final allNotes = list.map((e) => _cleanNoteMap(Map<String, dynamic>.from(e))).toList();
      for (var note in allNotes) {
        if (!note.containsKey('inquiryQuestion')) note['inquiryQuestion'] = null;
        if (!note.containsKey('inquiryConclusion')) note['inquiryConclusion'] = null;
        if (!note.containsKey('exploreTasks')) note['exploreTasks'] = [];
        if (!note.containsKey('contentFormat')) note['contentFormat'] = 'markdown';
      }
      if (includeDeleted) return allNotes;
      return allNotes.where((n) => n['status'] != 'deleted').toList();
    } else {
      final db = await _getDatabase();
      final rows = await db.query('notes', orderBy: 'updatedAt DESC');
      final allNotes = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['inquiryQuestion'] = mapped['inquiry_question'];
        mapped['inquiryConclusion'] = mapped['inquiry_conclusion'];
        mapped['exploreTasks'] = mapped['explore_tasks'];
        mapped['scaffoldSessions'] = mapped['scaffold_sessions'];
        mapped['subtasks'] = mapped['subtasks'];
        mapped['contentFormat'] = mapped['content_format'];
        return _cleanNoteMap(mapped);
      }).toList();
      if (includeDeleted) return allNotes;
      return allNotes.where((n) => n['status'] != 'deleted').toList();
    }
  }

  Map<String, dynamic> _cleanNoteMap(Map<String, dynamic> map) {
    final cleaned = Map<String, dynamic>.from(map);
    final tagsRaw = cleaned['tags'];
    if (tagsRaw is String) {
      cleaned['tags'] = tagsRaw.isEmpty ? [] : tagsRaw.split(',').where((t) => t.trim().isNotEmpty).map((t) => t.trim()).toList();
    } else if (tagsRaw is List) {
      cleaned['tags'] = tagsRaw.whereType<String>().toList();
    } else {
      cleaned['tags'] = [];
    }
    final tasksRaw = cleaned['exploreTasks'];
    if (tasksRaw is String && tasksRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(tasksRaw);
        cleaned['exploreTasks'] = (decoded as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        cleaned['exploreTasks'] = [];
      }
    } else if (tasksRaw is List) {
      cleaned['exploreTasks'] = (tasksRaw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      cleaned['exploreTasks'] = [];
    }
    cleaned['inquiryQuestion'] = cleaned['inquiryQuestion'] as String?;
    cleaned['inquiryConclusion'] = cleaned['inquiryConclusion'] as String?;
    final cfRaw = cleaned['contentFormat'];
    cleaned['contentFormat'] = (cfRaw is String && cfRaw.isNotEmpty)
        ? cfRaw
        : 'markdown';
    return cleaned;
  }

  Map<String, dynamic> _prepareNoteForDb(Map<String, dynamic> map) {
    final tags = map['tags'];
    final tagsStr = tags is List ? (tags as List).whereType<String>().join(',') : (tags?.toString() ?? '');
    final tasks = map['exploreTasks'];
    final tasksStr = tasks is List && tasks.isNotEmpty
        ? jsonEncode(tasks.map((e) {
            if (e is ExploreTask) return e.toJson();
            if (e is Map) return e;
            return e;
          }).toList())
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
      'inquiry_conclusion': map['inquiryConclusion'] as String?,
      'explore_tasks': tasksStr,
      'content_format': map['contentFormat'] ?? 'markdown',
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
        'title': note.title, 'parentId': folderId, 'isFolder': 0,
        'nodeType': 'note', 'targetId': noteId, 'sortOrder': 0,
        'tags': note.tags,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await _saveNotes(notes);
    await _saveNodes(nodes);
  }

  Future<void> archiveNote(String id) async => _moveNoteToArchived(id);

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

    await _clearSearchIndexForNote(id);
  }

  Future<void> hardDeleteNote(String id) async {
    final notes = await _getAllNotesInternal(includeDeleted: true);
    notes.removeWhere((n) => n['id'] == id);
    await _saveNotes(notes);

    await _clearSearchIndexForNote(id);
  }

  Future<void> updateNote(Map<String, dynamic> noteMap) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final index = notes.indexWhere((n) => n['id'] == noteMap['id']);
    if (index != -1) {
      notes[index] = noteMap;
      await _saveNotes(notes);
    }

    await _syncSearchIndexForNote(noteMap);
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

  // ═══════════════════════════════════════════════════════
  // 搜索索引编排
  // ═══════════════════════════════════════════════════════

  /// 笔记保存后同步搜索索引。
  ///
  /// 第四轮批 1 变更：调用方法改名（_deleteTagIndexByNoteId → _deleteTagIndexBySourceId 等）。
  Future<void> _syncSearchIndexForNote(Map<String, dynamic> noteMap) async {
    final noteId = noteMap['id'] as String?;
    if (noteId == null || noteId.isEmpty) return;

    try {
      // 步骤 1 + 2：note_text
      await _deleteSearchRowBySourceAndKind('note', noteId, 'note_text');
      final noteTextRow = SearchIndexService.computeNoteTextRow(noteMap);
      if (noteTextRow != null) {
        await _insertSearchRow(noteTextRow);
      }

      // 步骤 3 + 4：tag_index
      await _deleteTagIndexBySourceId(noteId);
      final format = (noteMap['contentFormat'] as String?) ?? 'markdown';
      final tagRows = SearchIndexService.computeTagRows(noteMap, format);
      for (final row in tagRows) {
        await _insertTagIndexRow(row);
      }

      // 步骤 5 + 6：note_tag（从 tag_index 派生）
      await _deleteSearchRowBySourceAndKind('note', noteId, 'note_tag');
      final readTagRows = await _queryTagIndexBySourceId(noteId);
      final searchRows = SearchIndexService.computeSearchRowsFromTagRows(
        noteId,
        readTagRows,
      );
      for (final row in searchRows) {
        await _insertSearchRow(row);
      }
    } catch (e, st) {
      debugPrint('_syncSearchIndexForNote 失败: $e\n$st');
    }
  }

  /// 书来源（高亮 / 批注）的索引同步。第四轮批 1 新增。
  ///
  /// 步骤（先删后写）：
  ///   1. 删该 bookId 的全部 book 来源 tag_index 行
  ///   2. 算 + 写 tag_index 行
  ///   3. 删该 bookId 的 book_highlight / book_annotation 行
  ///   4. 读 tag_index → 算 → 写 search_index 行
  Future<void> syncBookNotesIndex(
    String bookId,
    List<Map<String, dynamic>> bookNoteMaps,
  ) async {
    if (bookId.isEmpty) return;

    try {
      await _deleteTagIndexBySourceId(bookId);

      final tagRows = SearchIndexService.computeBookTagRows(bookNoteMaps, bookId);
      for (final row in tagRows) {
        await _insertTagIndexRow(row);
      }

      await _deleteSearchRowBySourceAndKind('book', bookId, 'book_highlight');
      await _deleteSearchRowBySourceAndKind('book', bookId, 'book_annotation');

      final readTagRows = await _queryTagIndexBySourceId(bookId);
      final searchRows = SearchIndexService.computeSearchRowsFromTagRows(
        bookId,
        readTagRows,
      );
      for (final row in searchRows) {
        await _insertSearchRow(row);
      }
    } catch (e, st) {
      debugPrint('syncBookNotesIndex 失败: $e\n$st');
    }
  }

  /// 笔记删除后清搜索索引。
  Future<void> _clearSearchIndexForNote(String noteId) async {
    if (noteId.isEmpty) return;

    try {
      await _deleteTagIndexBySourceId(noteId);
      for (final scope in SearchIndexService.computeDeleteScopes()) {
        await _deleteSearchRowBySourceAndKind(
          scope.sourceType,
          noteId,
          scope.kind,
        );
      }
    } catch (e, st) {
      debugPrint('_clearSearchIndexForNote 失败: $e\n$st');
    }
  }

  // ═══════════════════════════════════════════════════════
  // 统一搜索（第四轮批 1 新增）
  // ═══════════════════════════════════════════════════════

  /// 统一搜索：查 search_index 表。
  Future<List<Map<String, dynamic>>> searchIndex(
    String keyword, {
    int limit = 50,
  }) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return [];

    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_searchIndexDataKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      final lower = kw.toLowerCase();
      final results = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final st = (e['searchText'] as String?)?.toLowerCase() ?? '';
            final rt = (e['rawText'] as String?)?.toLowerCase() ?? '';
            return st.contains(lower) || rt.contains(lower);
          })
          .toList();
      results.sort((a, b) {
        final ca = a['createdAt'] as String? ?? '';
        final cb = b['createdAt'] as String? ?? '';
        return cb.compareTo(ca);
      });
      return results.take(limit).toList();
    } else {
      final db = await _getDatabase();
      final rows = await db.query(
        'search_index',
        where: 'searchText LIKE ? OR rawText LIKE ?',
        whereArgs: ['%$kw%', '%$kw%'],
        orderBy: 'createdAt DESC',
        limit: limit,
      );
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
  }

  // ═══════════════════════════════════════════════════════
  // 读全量 tag_index（第四轮批 2a 新增）
  // ═══════════════════════════════════════════════════════

  /// 读全量 tag_index，按 createdAt DESC 排序。
  ///
  /// 供摘要面板用——面板需要跨书 / 跨笔记的所有标记。
  /// 现有 _queryTagIndexBySourceId 只按 sourceId 查，不够用。
  ///
  /// 第四轮批 2a 新增。方案 v3 §2.1。
  Future<List<Map<String, dynamic>>> getAllTagRows() async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tagIndexDataKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      final rows = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      rows.sort((a, b) {
        final ca = a['createdAt'] as String? ?? '';
        final cb = b['createdAt'] as String? ?? '';
        return cb.compareTo(ca);
      });
      return rows;
    } else {
      final db = await _getDatabase();
      final rows = await db.query('tag_index', orderBy: 'createdAt DESC');
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
  }

  // ═══════════════════════════════════════════════════════
  // tag_index / search_index 读写辅助
  // ═══════════════════════════════════════════════════════

  static const String _tagIndexDataKey = 'tag_index_data';
  static const String _searchIndexDataKey = 'search_index_data';

  Future<void> _insertTagIndexRow(Map<String, dynamic> row) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tagIndexDataKey);
      final List<dynamic> list =
          raw == null || raw.isEmpty ? [] : jsonDecode(raw) as List;
      list.add(row);
      await prefs.setString(_tagIndexDataKey, jsonEncode(list));
    } else {
      final db = await _getDatabase();
      await db.insert('tag_index', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// 第四轮批 1 改名：_queryTagIndexByNoteId → _queryTagIndexBySourceId
  Future<List<Map<String, dynamic>>> _queryTagIndexBySourceId(
      String sourceId) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tagIndexDataKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .where((e) => e['sourceId'] == sourceId)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      final db = await _getDatabase();
      final rows =
          await db.query('tag_index', where: 'sourceId = ?', whereArgs: [sourceId]);
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
  }

  /// 第四轮批 1 改名：_deleteTagIndexByNoteId → _deleteTagIndexBySourceId
  Future<void> _deleteTagIndexBySourceId(String sourceId) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tagIndexDataKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List;
      final filtered = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['sourceId'] != sourceId)
          .toList();
      await prefs.setString(_tagIndexDataKey, jsonEncode(filtered));
    } else {
      final db = await _getDatabase();
      await db.delete('tag_index', where: 'sourceId = ?', whereArgs: [sourceId]);
    }
  }

  Future<void> _insertSearchRow(Map<String, dynamic> row) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_searchIndexDataKey);
      final List<dynamic> list =
          raw == null || raw.isEmpty ? [] : jsonDecode(raw) as List;
      list.add(row);
      await prefs.setString(_searchIndexDataKey, jsonEncode(list));
    } else {
      final db = await _getDatabase();
      await db.insert('search_index', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _deleteSearchRowBySourceAndKind(
    String sourceType,
    String sourceId,
    String kind,
  ) async {
    if (_isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_searchIndexDataKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List;
      final filtered = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) =>
              !(e['sourceType'] == sourceType &&
                  e['sourceId'] == sourceId &&
                  e['kind'] == kind))
          .toList();
      await prefs.setString(_searchIndexDataKey, jsonEncode(filtered));
    } else {
      final db = await _getDatabase();
      await db.delete(
        'search_index',
        where: 'sourceType = ? AND sourceId = ? AND kind = ?',
        whereArgs: [sourceType, sourceId, kind],
      );
    }
  }  // ─── 图书 CRUD ──────────────────────────────────────────
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
      try { return books.firstWhere((b) => b['id'] == id); } catch (_) { return null; }
    } else {
      final db = await _getDatabase();
      final result = await db.query('books', where: 'id = ?', whereArgs: [id]);
      if (result.isNotEmpty) return _cleanBookMap(_mapBookDbRowToCamel(result.first));
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

  Map<String, dynamic> _mapBookDbRowToCamel(Map<String, dynamic> row) => {
    'id': row['id'], 'title': row['title'], 'author': row['author'], 'isbn': row['isbn'],
    'coverUrl': row['cover_url'], 'filePath': row['file_path'], 'fileType': row['file_type'],
    'fileName': row['file_name'], 'fileSize': row['file_size'], 'status': row['status'],
    'readingProgress': row['reading_progress'], 'totalPages': row['total_pages'],
    'createdAt': row['created_at'], 'lastReadAt': row['last_read_at'],
    'source': row['source'] ?? '',
  };

  Map<String, dynamic> _cleanBookMap(Map<String, dynamic> map) => Map<String, dynamic>.from(map);

  Map<String, dynamic> _prepareBookForDb(Map<String, dynamic> map) => {
    'id': map['id'], 'title': map['title'], 'author': map['author'], 'isbn': map['isbn'],
    'cover_url': map['coverUrl'], 'file_path': map['filePath'], 'file_type': map['fileType'],
    'file_name': map['fileName'], 'file_size': map['fileSize'], 'status': map['status'],
    'reading_progress': map['readingProgress'], 'total_pages': map['totalPages'],
    'created_at': map['createdAt'], 'last_read_at': map['lastReadAt'],
    'source': map['source'] ?? '',
  };

  // ─── 占位 ──────────────────────────────────────────────
  Future<void> insertAnnotation(Map<String, dynamic> annotationMap) async {}
  Future<List<Map<String, dynamic>>> getAllAnnotationsForBook(String bookId) async => [];

  // ─── 系统文件夹 ────────────────────────────────────────
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
        for (var child in children) await moveNode(child.id, keep.id);
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

  Future<NotebookEntry> createReviewNote({required String title, required String content, List<String> extraTags = const []}) async {
    final folderId = await ensureReviewFolder();
    final noteId = DateTime.now().millisecondsSinceEpoch.toString();
    final allTags = <String>['复盘', ...extraTags];
    final noteMap = {
      'id': noteId, 'title': title, 'content': content, 'status': 'active',
      'editorMode': 'plain', 'updatedAt': DateTime.now().toIso8601String(),
      'isLocked': 0, 'exploreTasks': [],
    };
    await insertNote(noteMap);
    await attachNoteToNode(noteId: noteId, title: title, parentId: folderId, tags: allTags);
    return NotebookEntry.fromMap(noteMap);
  }

  Future<void> migrateExpiredToArchived() async {
    final nodes = await _getAllNodesInternal();
    final expiredFolders = nodes.where((n) => n['title'] == '灵感过期' && n['isFolder'] == 1 && n['parentId'] == null).toList();
    if (expiredFolders.isEmpty) { print('没有需要迁移的旧文件夹'); return; }
    final archivedId = await ensureArchivedFolder();
    for (var folder in expiredFolders) {
      final children = nodes.where((n) => n['parentId'] == folder['id']).toList();
      for (var child in children) child['parentId'] = archivedId;
      nodes.remove(folder);
    }
    await _saveNodes(nodes);
  }

  // ─── 解析 Markdown ────────────────────────────────────
  List<Map<String, dynamic>> parseSubtasksFromMarkdown(String content) {
    final results = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    int index = 0;
    for (var line in lines) {
      final uncheckedMatch = RegExp(r'^-\s*\[\s*\]\s*(.+)$').firstMatch(line);
      final checkedMatch = RegExp(r'^-\s*\[x\]\s*(.+)$').firstMatch(line);
      if (uncheckedMatch != null) {
        results.add({'id': '${DateTime.now().millisecondsSinceEpoch}_${index++}', 'title': uncheckedMatch.group(1)?.trim() ?? '未命名子任务', 'isDone': false});
      } else if (checkedMatch != null) {
        results.add({'id': '${DateTime.now().millisecondsSinceEpoch}_${index++}', 'title': checkedMatch.group(1)?.trim() ?? '未命名子任务', 'isDone': true});
      }
    }
    return results;
  }

  // ─── 导出/导入 ────────────────────────────────────────
  Future<String> exportAllData() async => jsonEncode({
    'version': '1.0', 'exportDate': DateTime.now().toIso8601String(),
    'notes': await getAllNotes(includeDeleted: true),
    'nodes': await _getAllNodesInternal(),
    'books': await getAllBooks(),
  });

  Future<void> importAllData(String jsonString) async {
    final data = jsonDecode(jsonString);
    await _clearAllData();
    if (data['notes'] != null) for (var note in data['notes']) await insertNote(note);
    if (data['nodes'] != null) for (var node in data['nodes']) await insertNode(node);
    if (data['books'] != null) for (var book in data['books']) await insertBook(book);
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

  // ─── 灵感自动归档 ────────────────────────────────────
  Future<int> archiveExpiredRawNotes(int retentionDays) async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: retentionDays));
    final expiredNoteIds = <String>[];
    for (var note in notes) {
      final updatedAt = DateTime.parse(note['updatedAt']);
      if (note['status'] == 'raw' && note['isLocked'] != 1 && updatedAt.isBefore(cutoff)) expiredNoteIds.add(note['id']);
    }
    if (expiredNoteIds.isEmpty) return 0;
    for (var id in expiredNoteIds) await _moveNoteToArchived(id);
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
      if (daysAgo >= retentionDays - 7 && daysAgo < retentionDays) result.add(NotebookEntry.fromMap(map));
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
    final archivedFolder = nodes.firstWhere((n) => n.title == '已归档' && n.isFolder && n.parentId == null, orElse: () => Node.empty);
    if (archivedFolder.id.isEmpty) return 0;
    final children = await getChildren(archivedFolder.id);
    return children.where((n) => !n.isFolder).length;
  }

  Future<List<NotebookEntry>> getArchivedFolderNotes() async {
    final nodes = await getAllNodes();
    final archivedFolder = nodes.firstWhere((n) => n.title == '已归档' && n.isFolder && n.parentId == null, orElse: () => Node.empty);
    if (archivedFolder.id.isEmpty) return [];
    final children = await getChildren(archivedFolder.id);
    final noteIds = children.where((n) => n.nodeType == 'note' && n.targetId != null).map((n) => n.targetId!).toList();
    if (noteIds.isEmpty) return [];
    final allNotes = await _getAllNotesInternal(includeDeleted: false);
    final result = <NotebookEntry>[];
    for (var map in allNotes) {
      if (noteIds.contains(map['id'])) result.add(NotebookEntry.fromMap(map));
    }
    return result;
  }

  // ─── SQLite 核心 ──────────────────────────────────────
  static Database? _database;

  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;
    String path = join(await getDatabasesPath(), 'notebook.db');
    // ✅ 第四轮批 1：版本 16 → 17
    _database = await openDatabase(path, version: 17, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async => _createTables(db);

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { try { await db.execute('ALTER TABLE notes ADD COLUMN status TEXT DEFAULT "raw"'); } catch (_) {} }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE books ADD COLUMN cover_image TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN pdf_path TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_type TEXT DEFAULT "none"'); } catch (_) {}
    }
    if (oldVersion < 4) { try { await db.execute('ALTER TABLE notes ADD COLUMN editorMode TEXT DEFAULT "plain"'); } catch (_) {} }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT DEFAULT ""'); } catch (_) {}
      try { await db.execute('ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS nodes(
            id TEXT PRIMARY KEY, title TEXT, parent_id TEXT,
            is_folder INTEGER DEFAULT 0, node_type TEXT DEFAULT 'folder',
            target_id TEXT, sort_order INTEGER DEFAULT 0, tags TEXT DEFAULT '',
            created_at TEXT, updated_at TEXT
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
            id TEXT PRIMARY KEY, book_id TEXT, page_number INTEGER,
            quote TEXT, note TEXT, color TEXT, created_at TEXT,
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN inquiry_question TEXT');
        await db.execute('ALTER TABLE notes ADD COLUMN scaffold_sessions TEXT DEFAULT "[]"');
        await db.execute('ALTER TABLE notes ADD COLUMN subtasks TEXT DEFAULT "[]"');
      } catch (_) {}
    }
    if (oldVersion < 10) { try { await db.execute('ALTER TABLE notes ADD COLUMN new_understanding TEXT'); } catch (_) {} }
    if (oldVersion < 11) { try { await db.execute('ALTER TABLE notes ADD COLUMN explore_tasks TEXT DEFAULT "[]"'); } catch (_) {} }
    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS isbn_cache(
            isbn TEXT PRIMARY KEY, title TEXT, author TEXT,
            cover_url TEXT, source TEXT, updated_at TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      try { await db.execute("ALTER TABLE books ADD COLUMN source TEXT DEFAULT ''"); } catch (_) {}
      try { await db.execute("UPDATE books SET source = 'import' WHERE file_path IS NOT NULL AND file_path != ''"); } catch (_) {}
      try { await db.execute("UPDATE books SET source = 'scan' WHERE file_path IS NULL OR file_path = ''"); } catch (_) {}
    }
    if (oldVersion < 14) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pdf_drawings(
            id TEXT PRIMARY KEY, book_id TEXT, page INTEGER,
            points TEXT, color TEXT, created_at TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_views(
            id TEXT PRIMARY KEY, name TEXT, type TEXT,
            owner_id TEXT, created_at TEXT, updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_nodes(
            id TEXT PRIMARY KEY, view_id TEXT, card_id TEXT,
            x REAL, y REAL, z_index INTEGER
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_nodes_view ON board_nodes(view_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_edges(
            id TEXT PRIMARY KEY, view_id TEXT,
            source_node_id TEXT, target_node_id TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_edges_view ON board_edges(view_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_groups(
            id TEXT PRIMARY KEY, view_id TEXT, node_ids TEXT, color TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_groups_view ON board_groups(view_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_texts(
            id TEXT PRIMARY KEY, view_id TEXT, x REAL, y REAL, content TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_texts_view ON board_texts(view_id)');
      } catch (_) {}
    }
    if (oldVersion < 16) {
      for (final sql in SearchIndexService.getCreateTableSql()) {
        await db.execute(sql);
      }

      final cols = await db.rawQuery('PRAGMA table_info(notes)');
      final hasContentFormat =
          cols.any((c) => c['name'] == 'content_format');
      if (!hasContentFormat) {
        await db.execute(
          "ALTER TABLE notes ADD COLUMN content_format TEXT DEFAULT 'markdown'",
        );
      }
    }
    // ✅ 第四轮批 1：版本 16 → 17：tag_index 加 sourceType 列，noteId 改名 sourceId
    if (oldVersion < 17) {
      try {
        final cols = await db.rawQuery('PRAGMA table_info(tag_index)');
        final hasTable = cols.isNotEmpty;
        final hasNoteId = cols.any((c) => c['name'] == 'noteId');
        final hasSourceId = cols.any((c) => c['name'] == 'sourceId');

        if (!hasTable) {
          for (final sql in SearchIndexService.getCreateTableSql()) {
            await db.execute(sql);
          }
        } else if (hasSourceId) {
          // 已是新 schema：跳过
        } else if (hasNoteId) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tag_index_new(
              id TEXT PRIMARY KEY,
              sourceType TEXT NOT NULL DEFAULT 'note',
              sourceId TEXT NOT NULL,
              type TEXT NOT NULL,
              tag TEXT NOT NULL,
              blockId TEXT,
              text TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO tag_index_new (id, sourceType, sourceId, type, tag, blockId, text, createdAt)
            SELECT id, 'note', noteId, type, tag, blockId, text, createdAt FROM tag_index
          ''');
          await db.execute('DROP TABLE tag_index');
          await db.execute('ALTER TABLE tag_index_new RENAME TO tag_index');
          await db.execute('DROP INDEX IF EXISTS idx_tag_index_note');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_index_tag ON tag_index(tag)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_index_source ON tag_index(sourceId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_index_type ON tag_index(type)');
        }
      } catch (e) {
        debugPrint('tag_index 16→17 迁移失败: $e');
      }
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY, title TEXT, content TEXT, updatedAt TEXT,
        status TEXT DEFAULT 'raw', editorMode TEXT DEFAULT 'plain',
        isLocked INTEGER DEFAULT 0, tags TEXT DEFAULT '',
        inquiry_question TEXT, inquiry_conclusion TEXT,
        explore_tasks TEXT DEFAULT '[]',
        content_format TEXT DEFAULT 'markdown'
      )
    ''');
    await db.execute('''
      CREATE TABLE books(
        id TEXT PRIMARY KEY, title TEXT, author TEXT, isbn TEXT,
        cover_url TEXT, file_path TEXT, file_type TEXT DEFAULT 'none',
        file_name TEXT, file_size INTEGER DEFAULT 0, status TEXT DEFAULT 'want',
        reading_progress INTEGER DEFAULT 0, total_pages INTEGER DEFAULT 0,
        created_at TEXT, last_read_at TEXT, source TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE book_annotations(
        id TEXT PRIMARY KEY, book_id TEXT, page_number INTEGER,
        quote TEXT, note TEXT, color TEXT, created_at TEXT,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE nodes(
        id TEXT PRIMARY KEY, title TEXT, parent_id TEXT,
        is_folder INTEGER DEFAULT 0, node_type TEXT DEFAULT 'folder',
        target_id TEXT, sort_order INTEGER DEFAULT 0, tags TEXT DEFAULT '',
        created_at TEXT, updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS isbn_cache(
        isbn TEXT PRIMARY KEY, title TEXT, author TEXT,
        cover_url TEXT, source TEXT, updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pdf_drawings(
        id TEXT PRIMARY KEY, book_id TEXT, page INTEGER,
        points TEXT, color TEXT, created_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS board_views(
        id TEXT PRIMARY KEY, name TEXT, type TEXT,
        owner_id TEXT, created_at TEXT, updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS board_nodes(
        id TEXT PRIMARY KEY, view_id TEXT, card_id TEXT,
        x REAL, y REAL, z_index INTEGER
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_board_nodes_view ON board_nodes(view_id)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS board_edges(
        id TEXT PRIMARY KEY, view_id TEXT,
        source_node_id TEXT, target_node_id TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_board_edges_view ON board_edges(view_id)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS board_groups(
        id TEXT PRIMARY KEY, view_id TEXT, node_ids TEXT, color TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_board_groups_view ON board_groups(view_id)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS board_texts(
        id TEXT PRIMARY KEY, view_id TEXT, x REAL, y REAL, content TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_board_texts_view ON board_texts(view_id)');

    for (final sql in SearchIndexService.getCreateTableSql()) {
      await db.execute(sql);
    }
  }

  Future<Map<String, dynamic>?> getIsbnCache(String isbn) async {
    if (_isWeb) return null;
    final db = await _getDatabase();
    final rows = await db.query('isbn_cache', where: 'isbn = ?', whereArgs: [isbn]);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> saveIsbnCache({required String isbn, required String title, required String author, required String coverUrl, required String source}) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    await db.insert('isbn_cache', {
      'isbn': isbn, 'title': title, 'author': author, 'cover_url': coverUrl,
      'source': source, 'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── PDF 划痕 ────────────────────────────────────────
  Future<void> savePdfDrawing(PdfDrawing drawing) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    final map = drawing.toMap();
    await db.insert('pdf_drawings', {
      'id': map['id'], 'book_id': map['bookId'], 'page': map['page'],
      'points': map['points'], 'color': map['color'], 'created_at': map['createdAt'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PdfDrawing>> getPdfDrawingsByBook(String bookId) async {
    if (_isWeb) return [];
    final db = await _getDatabase();
    final rows = await db.query('pdf_drawings', where: 'book_id = ?', whereArgs: [bookId], orderBy: 'page ASC, created_at ASC');
    return rows.map((row) => PdfDrawing.fromMap({
      'id': row['id'], 'bookId': row['book_id'], 'page': row['page'],
      'points': row['points'], 'color': row['color'], 'createdAt': row['created_at'],
    })).toList();
  }

  Future<void> deletePdfDrawingsByBook(String bookId) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    await db.delete('pdf_drawings', where: 'book_id = ?', whereArgs: [bookId]);
  }

  // ═══════════════════════════════════════════════════════
  // 线索墙 CRUD
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getBoardView(String id) async {
    if (_isWeb) return null;
    final db = await _getDatabase();
    final rows = await db.query('board_views', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'id': row['id'], 'name': row['name'], 'type': row['type'],
      'ownerId': row['owner_id'], 'createdAt': row['created_at'], 'updatedAt': row['updated_at'],
    };
  }

  Future<void> upsertBoardView(Map<String, dynamic> view) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    await db.insert('board_views', {
      'id': view['id'], 'name': view['name'], 'type': view['type'],
      'owner_id': view['ownerId'], 'created_at': view['createdAt'], 'updated_at': view['updatedAt'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBoardNodes(String viewId) async {
    if (_isWeb) return [];
    final db = await _getDatabase();
    final rows = await db.query('board_nodes', where: 'view_id = ?', whereArgs: [viewId], orderBy: 'z_index ASC');
    return rows.map((row) => {
      'id': row['id'], 'viewId': row['view_id'], 'cardId': row['card_id'],
      'x': row['x'], 'y': row['y'], 'zIndex': row['z_index'],
    }).toList();
  }

  Future<void> replaceBoardNodes(String viewId, List<Map<String, dynamic>> nodes) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete('board_nodes', where: 'view_id = ?', whereArgs: [viewId]);
      for (final node in nodes) {
        await txn.insert('board_nodes', {
          'id': node['id'], 'view_id': node['viewId'], 'card_id': node['cardId'],
          'x': node['x'], 'y': node['y'], 'z_index': node['zIndex'],
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBoardEdges(String viewId) async {
    if (_isWeb) return [];
    final db = await _getDatabase();
    final rows = await db.query('board_edges', where: 'view_id = ?', whereArgs: [viewId]);
    return rows.map((row) => {
      'id': row['id'], 'viewId': row['view_id'],
      'sourceNodeId': row['source_node_id'], 'targetNodeId': row['target_node_id'],
    }).toList();
  }

  Future<void> replaceBoardEdges(String viewId, List<Map<String, dynamic>> edges) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete('board_edges', where: 'view_id = ?', whereArgs: [viewId]);
      for (final edge in edges) {
        await txn.insert('board_edges', {
          'id': edge['id'], 'view_id': edge['viewId'],
          'source_node_id': edge['sourceNodeId'], 'target_node_id': edge['targetNodeId'],
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBoardTexts(String viewId) async {
    if (_isWeb) return [];
    final db = await _getDatabase();
    final rows = await db.query('board_texts', where: 'view_id = ?', whereArgs: [viewId]);
    return rows.map((row) => {
      'id': row['id'], 'viewId': row['view_id'],
      'x': row['x'], 'y': row['y'], 'content': row['content'],
    }).toList();
  }

  Future<void> replaceBoardTexts(String viewId, List<Map<String, dynamic>> texts) async {
    if (_isWeb) return;
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.delete('board_texts', where: 'view_id = ?', whereArgs: [viewId]);
      for (final t in texts) {
        await txn.insert('board_texts', {
          'id': t['id'], 'view_id': t['viewId'],
          'x': t['x'], 'y': t['y'], 'content': t['content'],
        });
      }
    });
  }
}