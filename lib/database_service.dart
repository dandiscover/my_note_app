// lib/database_service.dart
// 数据层 — 统一字段标准：代码层驼峰，数据库层下划线
// ✅ 第四轮批 1：数据库版本 16 → 17（tag_index 加 sourceType，noteId 改名 sourceId）；
//    _syncSearchIndexForNote 适配；新增 syncBookNotesIndex / searchIndex

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'database/database.dart';
import 'models/note.dart';
import 'models/book.dart';
import 'models/node.dart';
import 'models/explore_task.dart';
import 'models/note_subtask.dart';
import 'models/pdf_drawing.dart';
import 'services/search_index_service.dart';
import 'services/weread_key_store.dart';
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// 测试专用：注入 AppDatabase 实例。
  /// 业务层禁止使用；仅 test/ 下调用。
  AppDatabase? _injectedDb;
  DatabaseService.forTesting(AppDatabase db) : _injectedDb = db;

  bool get _isWeb => kIsWeb;

  /// Phase 2 换库：Drift 实例
  AppDatabase get _drift => _injectedDb ?? AppDatabaseProvider().db;

  /// NodeRow → camelCase Map
  Map<String, dynamic> _nodeRowToMap(NodeRow r) => {
        'id': r.id,
        'title': r.title,
        'parentId': r.parentId,
        'isFolder': r.isFolder ? 1 : 0,
        'nodeType': r.nodeType,
        'targetId': r.targetId,
        'sortOrder': r.sortOrder,
        'tags': r.tags.isEmpty
            ? <String>[]
            : r.tags
                .split(',')
                .where((t) => t.trim().isNotEmpty)
                .map((t) => t.trim())
                .toList(),
        'systemTag': r.systemTag,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
      };

  /// camelCase Map → NodesCompanion
  NodesCompanion _nodeMapToCompanion(Map<String, dynamic> map) {
    final tags = map['tags'];
    final tagsStr = tags is List
        ? (tags).whereType<String>().join(',')
        : (tags?.toString() ?? '');
    final parentId = map['parentId'];
    final cleanedParentId =
        (parentId == '' || parentId == 'null') ? null : parentId as String?;
    final targetId = map['targetId'];
    final cleanedTargetId =
        (targetId == '' || targetId == 'null') ? null : targetId as String?;
    final now = DateTime.now().toIso8601String();
    return NodesCompanion(
      id: Value(map['id'] as String),
      title: Value((map['title'] as String?) ?? ''),
      parentId: Value(cleanedParentId),
      isFolder: Value((map['isFolder'] ?? 0) == 1 || map['isFolder'] == true),
      nodeType: Value((map['nodeType'] as String?) ?? 'folder'),
      targetId: Value(cleanedTargetId),
      sortOrder: Value((map['sortOrder'] as int?) ?? 0),
      tags: Value(tagsStr),
      systemTag: Value(map['systemTag'] as String?),
      createdAt: Value((map['createdAt'] is String &&
              (map['createdAt'] as String).isNotEmpty)
          ? map['createdAt'] as String
          : now),
      updatedAt: Value((map['updatedAt'] is String &&
              (map['updatedAt'] as String).isNotEmpty)
          ? map['updatedAt'] as String
          : now),
    );
  }

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
    final companion = _nodeMapToCompanion(nodeMap);
    await _drift
        .into(_drift.nodes)
        .insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<List<Node>> getAllNodes() async {
    final maps = await _getAllNodesInternal();
    return maps.map((map) => Node.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> _getAllNodesInternal() async {
    final rows = await (_drift.select(_drift.nodes)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_nodeRowToMap).toList();
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
    final companion = _nodeMapToCompanion(node.toMap());
    await (_drift.update(_drift.nodes)..where((t) => t.id.equals(node.id)))
        .write(companion);
  }

  Future<void> deleteNode(String id) async {
    final allNodes = await getAllNodes();
    final node =
        allNodes.firstWhere((n) => n.id == id, orElse: () => Node.empty);
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
      await (_drift.delete(_drift.nodes)
            ..where((t) => t.id.isIn(idsToDelete.toList())))
          .go();
    } else {
      final grandParentId = node.parentId;
      final now = DateTime.now().toIso8601String();
      await (_drift.update(_drift.nodes)..where((t) => t.parentId.equals(id)))
          .write(NodesCompanion(
        parentId: Value(grandParentId),
        updatedAt: Value(now),
      ));
      await (_drift.delete(_drift.nodes)..where((t) => t.id.equals(id))).go();
    }
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
    await _drift.transaction(() async {
      for (int i = 0; i < nodeIds.length; i++) {
        await (_drift.update(_drift.nodes)
              ..where((t) => t.id.equals(nodeIds[i])))
            .write(NodesCompanion(sortOrder: Value(i)));
      }
    });
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

  Future<Node> createFolder({
    required String title,
    String? parentId,
    List<String> tags = const [],
    String? systemTag,                          // 批 BUG-003
  }) async {
    final node = Node(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, parentId: parentId, isFolder: true, nodeType: 'folder',
      tags: tags, systemTag: systemTag,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
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
  /// 债-3：笔记 + 节点同事务写（Drift）
  Future<void> insertNoteAndNodeTx({
    required Map<String, dynamic> noteMap,
    required Map<String, dynamic> nodeMap,
  }) async {
    final noteCompanion = _noteMapToCompanion(noteMap);
    final nodeCompanion = _nodeMapToCompanion(nodeMap);

    // 统一走 Drift 事务（桌面 / 移动 / Web 三端行为一致）
    await _drift.transaction(() async {
      await _drift.into(_drift.notes).insert(noteCompanion,
          mode: InsertMode.insertOrReplace);
      await _drift.into(_drift.nodes).insert(nodeCompanion,
          mode: InsertMode.insertOrReplace);
    });

    // 事务成功后，触发搜索索引更新（与旧版 Web 分支对齐）
    await _syncSearchIndexForNote(noteMap);
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

  /// 由 note id 反查 node（L5 素材栏用）
  ///
  /// note 与 node 分离存储——node.targetId 指向 note.id
  /// 全表扫描——nodes 表小——可接受
  Future<Node?> getNodeByNoteId(String noteId) async {
    final row = await (_drift.select(_drift.nodes)
          ..where(
              (t) => t.nodeType.equals('note') & t.targetId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return Node.fromMap(_nodeRowToMap(row));
  }

  Future<List<Node>> getContentNodesInFolder(String folderId) async {
    final children = await getChildren(folderId);
    return children.where((n) => !n.isFolder).toList();
  }

  Future<void> _saveNodes(List<Map<String, dynamic>> nodes) async {
    await _drift.transaction(() async {
      await _drift.delete(_drift.nodes).go();
      for (var node in nodes) {
        await _drift.into(_drift.nodes).insert(_nodeMapToCompanion(node));
      }
    });
  }

  // ─── 笔记 CRUD（Phase 2 · Drift）──────────────────────────

  /// Note → camelCase Map
  Map<String, dynamic> _noteRowToMap(Note r) {
    final tags = r.tags.isEmpty
        ? <String>[]
        : r.tags
            .split(',')
            .where((t) => t.trim().isNotEmpty)
            .map((t) => t.trim())
            .toList();
    List<Map<String, dynamic>> exploreTasks = [];
    if (r.exploreTasks.isNotEmpty) {
      try {
        final decoded = jsonDecode(r.exploreTasks);
        exploreTasks = (decoded as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {}
    }
    return {
      'id': r.id,
      'title': r.title,
      'content': r.content,
      'updatedAt': r.updatedAt,
      'status': r.status,
      'editorMode': r.editorMode,
      'isLocked': r.isLocked,
      'tags': tags,
      'inquiryQuestion': r.inquiryQuestion,
      'inquiryConclusion': r.inquiryConclusion,
      'exploreTasks': exploreTasks,
      'contentFormat': r.contentFormat,
      'createdAt': r.createdAt,
    };
  }

  /// camelCase Map → NotesCompanion
  NotesCompanion _noteMapToCompanion(Map<String, dynamic> map) {
    final tags = map['tags'];
    final tagsStr = tags is List
        ? (tags).whereType<String>().join(',')
        : (tags?.toString() ?? '');
    final tasks = map['exploreTasks'];
    final tasksStr = tasks is List && tasks.isNotEmpty
        ? jsonEncode(tasks.map((e) {
            if (e is ExploreTask) return e.toJson();
            if (e is Map) return e;
            return e;
          }).toList())
        : '[]';
    final isLockedRaw = map['isLocked'];
    final isLocked = isLockedRaw is bool
        ? (isLockedRaw ? 1 : 0)
        : (isLockedRaw as int? ?? 0);
    return NotesCompanion(
      id: Value(map['id'] as String),
      title: Value((map['title'] as String?) ?? ''),
      content: Value((map['content'] as String?) ?? ''),
      updatedAt: Value((map['updatedAt'] as String?) ??
          DateTime.now().toIso8601String()),
      status: Value((map['status'] as String?) ?? 'raw'),
      editorMode: Value((map['editorMode'] as String?) ?? 'plain'),
      isLocked: Value(isLocked),
      tags: Value(tagsStr),
      inquiryQuestion: Value(map['inquiryQuestion'] as String?),
      inquiryConclusion: Value(map['inquiryConclusion'] as String?),
      exploreTasks: Value(tasksStr),
      contentFormat: Value((map['contentFormat'] as String?) ?? 'markdown'),
      createdAt: Value((map['createdAt'] is String &&
              (map['createdAt'] as String).isNotEmpty)
          ? map['createdAt'] as String
          : DateTime.now().toIso8601String()),
    );
  }

  Future<void> insertNote(Map<String, dynamic> noteMap) async {
    if (!noteMap.containsKey('status')) noteMap['status'] = 'raw';
    if (!noteMap.containsKey('editorMode')) noteMap['editorMode'] = 'plain';
    if (!noteMap.containsKey('isLocked')) noteMap['isLocked'] = 0;
    final companion = _noteMapToCompanion(noteMap);
    await _drift
        .into(_drift.notes)
        .insert(companion, mode: InsertMode.insertOrReplace);

    await _syncSearchIndexForNote(noteMap);
  }

  Future<List<Map<String, dynamic>>> getAllNotes({bool includeDeleted = false}) async => _getAllNotesInternal(includeDeleted: includeDeleted);

  Future<List<Map<String, dynamic>>> _getAllNotesInternal({bool includeDeleted = false}) async {
    final query = _drift.select(_drift.notes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    if (!includeDeleted) {
      query.where((t) => t.status.equals('deleted').not());
    }
    final rows = await query.get();
    return rows.map(_noteRowToMap).toList();
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
    await (_drift.update(_drift.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        status: Value('active'),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> _moveNoteToArchived(String noteId) async {
    final folderId = await ensureArchivedFolder();
    final now = DateTime.now().toIso8601String();
    await _drift.transaction(() async {
      await (_drift.update(_drift.notes)..where((t) => t.id.equals(noteId)))
          .write(NotesCompanion(
        status: Value('archived'),
        updatedAt: Value(now),
      ));
      final existing = await (_drift.select(_drift.nodes)
            ..where((t) => t.targetId.equals(noteId))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) {
        await (_drift.update(_drift.nodes)
              ..where((t) => t.id.equals(existing.id)))
            .write(NodesCompanion(parentId: Value(folderId)));
      } else {
        final noteRow = await (_drift.select(_drift.notes)
              ..where((t) => t.id.equals(noteId))
              ..limit(1))
            .getSingleOrNull();
        if (noteRow == null) return;
        await _drift.into(_drift.nodes).insert(NodesCompanion.insert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: Value(noteRow.title),
          parentId: Value(folderId),
          isFolder: const Value(false),
          nodeType: const Value('note'),
          targetId: Value(noteId),
          tags: Value(noteRow.tags),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
      }
    });
  }

  Future<void> archiveNote(String id) async => _moveNoteToArchived(id);

  Future<void> unarchiveNote(String id) async {
    await (_drift.update(_drift.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        status: Value('active'),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> deleteNote(String id) async {
    await (_drift.update(_drift.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(status: Value('deleted')),
    );

    await _clearSearchIndexForNote(id);
  }

  Future<void> hardDeleteNote(String id) async {
    await (_drift.delete(_drift.notes)..where((t) => t.id.equals(id))).go();

    await _clearSearchIndexForNote(id);
  }

  Future<void> updateNote(Map<String, dynamic> noteMap) async {
    final companion = _noteMapToCompanion(noteMap);
    await (_drift.update(_drift.notes)
          ..where((t) => t.id.equals(noteMap['id'] as String)))
        .write(companion);

    await _syncSearchIndexForNote(noteMap);
  }

  Future<void> _saveNotes(List<Map<String, dynamic>> notes) async {
    await _drift.transaction(() async {
      for (var note in notes) {
        final companion = _noteMapToCompanion(note);
        await (_drift.update(_drift.notes)
              ..where((t) => t.id.equals(note['id'] as String)))
            .write(companion);
      }
    });
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

    final rows = await (_drift.select(_drift.searchIndex)
          ..where((t) =>
              t.searchText.like('%$kw%') | t.rawText.like('%$kw%'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
    return rows.map(_searchIndexRowToMap).toList();
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
    final rows = await (_drift.select(_drift.tagIndex)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_tagIndexRowToMap).toList();
  }

  // ═══════════════════════════════════════════════════════
  // tag_index / search_index 读写辅助
  // ═══════════════════════════════════════════════════════

  // ─── 批 3：Row → camelCase Map helpers ─────────────────

  Map<String, dynamic> _tagIndexRowToMap(TagIndexData r) => {
        'id': r.id,
        'sourceType': r.sourceType,
        'sourceId': r.sourceId,
        'type': r.type,
        'tag': r.tag,
        'blockId': r.blockId,
        'text': r.textContent,
        'createdAt': r.createdAt,
      };

  Map<String, dynamic> _searchIndexRowToMap(SearchIndexData r) => {
        'id': r.id,
        'sourceType': r.sourceType,
        'sourceId': r.sourceId,
        'subId': r.subId,
        'location': r.location,
        'kind': r.kind,
        'searchText': r.searchText,
        'rawText': r.rawText,
        'createdAt': r.createdAt,
      };

  Future<void> _insertTagIndexRow(Map<String, dynamic> row) async {
    await _drift.into(_drift.tagIndex).insert(
          TagIndexCompanion(
            id: Value(row['id'] as String),
            sourceType: Value((row['sourceType'] as String?) ?? 'note'),
            sourceId: Value(row['sourceId'] as String),
            type: Value(row['type'] as String),
            tag: Value(row['tag'] as String),
            blockId: Value(row['blockId'] as String?),
            textContent: Value(row['text'] as String?),
            createdAt: Value(row['createdAt'] as String),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// 第四轮批 1 改名：_queryTagIndexByNoteId → _queryTagIndexBySourceId
  Future<List<Map<String, dynamic>>> _queryTagIndexBySourceId(
      String sourceId) async {
    final rows = await (_drift.select(_drift.tagIndex)
          ..where((t) => t.sourceId.equals(sourceId)))
        .get();
    return rows.map(_tagIndexRowToMap).toList();
  }

  /// 第四轮批 1 改名：_deleteTagIndexByNoteId → _deleteTagIndexBySourceId
  Future<void> _deleteTagIndexBySourceId(String sourceId) async {
    await (_drift.delete(_drift.tagIndex)
          ..where((t) => t.sourceId.equals(sourceId)))
        .go();
  }

  Future<void> _insertSearchRow(Map<String, dynamic> row) async {
    await _drift.into(_drift.searchIndex).insert(
          SearchIndexCompanion(
            id: Value(row['id'] as String),
            sourceType: Value(row['sourceType'] as String),
            sourceId: Value(row['sourceId'] as String),
            subId: Value(row['subId'] as String?),
            location: Value(row['location'] as String?),
            kind: Value(row['kind'] as String),
            searchText: Value(row['searchText'] as String),
            rawText: Value(row['rawText'] as String?),
            createdAt: Value(row['createdAt'] as String),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> _deleteSearchRowBySourceAndKind(
    String sourceType,
    String sourceId,
    String kind,
  ) async {
    await (_drift.delete(_drift.searchIndex)
          ..where((t) =>
              t.sourceType.equals(sourceType) &
              t.sourceId.equals(sourceId) &
              t.kind.equals(kind)))
        .go();
  }  // ─── 图书 CRUD（Phase 2 · Drift）──────────────────────────

  /// BookRow → camelCase Map
  Map<String, dynamic> _bookRowToMap(BookRow r) => {
        'id': r.id,
        'title': r.title,
        'author': r.author,
        'isbn': r.isbn,
        'coverUrl': r.coverUrl,
        'filePath': r.filePath,
        'fileType': r.fileType,
        'fileName': r.fileName,
        'fileSize': r.fileSize,
        'status': r.status,
        'readingProgress': r.readingProgress,
        'totalPages': r.totalPages,
        'createdAt': r.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
        'lastReadAt': r.lastReadAt,
        'source': r.source,
      };

  /// camelCase Map → BooksCompanion
  BooksCompanion _bookMapToCompanion(Map<String, dynamic> map) {
    return BooksCompanion(
      id: Value(map['id'] as String),
      title: Value((map['title'] as String?) ?? ''),
      author: Value((map['author'] as String?) ?? ''),
      isbn: Value((map['isbn'] as String?) ?? ''),
      coverUrl: Value(map['coverUrl'] as String?),
      filePath: Value(map['filePath'] as String?),
      fileType: Value((map['fileType'] as String?) ?? 'none'),
      fileName: Value(map['fileName'] as String?),
      fileSize: Value((map['fileSize'] as int?) ?? 0),
      status: Value((map['status'] as String?) ?? 'want'),
      readingProgress: Value((map['readingProgress'] as int?) ?? 0),
      totalPages: Value((map['totalPages'] as int?) ?? 0),
      createdAt: Value((map['createdAt'] as String?) ??
          DateTime.now().toIso8601String()),
      lastReadAt: Value(map['lastReadAt'] as String?),
      source: Value((map['source'] as String?) ?? ''),
    );
  }

  Future<void> insertBook(Map<String, dynamic> bookMap) async {
    final companion = _bookMapToCompanion(bookMap);
    await _drift
        .into(_drift.books)
        .insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final rows = await (_drift.select(_drift.books)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_bookRowToMap).toList();
  }

  Future<Map<String, dynamic>?> getBook(String id) async {
    final row = await (_drift.select(_drift.books)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _bookRowToMap(row);
  }

  Future<void> updateBook(Map<String, dynamic> bookMap) async {
    final companion = _bookMapToCompanion(bookMap);
    await (_drift.update(_drift.books)
          ..where((t) => t.id.equals(bookMap['id'] as String)))
        .write(companion);
  }

  Future<void> deleteBook(String id) async {
    await (_drift.delete(_drift.books)..where((t) => t.id.equals(id))).go();
  }




  // ═══════════════════════════════════════════════════════════════
  // 批 2 步 2：三 service 迁入方法（入参 / 出参全 snake_case）
  // ═══════════════════════════════════════════════════════════════

  // ─── Row → snake_case Map helpers ──────────────────────

  Map<String, dynamic> _bookHighlightRowToMap(BookHighlightRow r) => {
        'id': r.id,
        'book_id': r.bookId,
        'chapter': r.chapter,
        'location': r.location,
        'text': r.textContent,
        'color': r.color,
        'note': r.note,
        'created_at': r.createdAt,
        'source': r.source,
      };

  Map<String, dynamic> _noteBookLinkRowToMap(NoteBookLink r) => {
        'id': r.id,
        'note_id': r.noteId,
        'book_id': r.bookId,
        'link_type': r.linkType,
        'link_text': r.linkText,
        'context': r.context,
        'created_at': r.createdAt,
      };

  Map<String, dynamic> _noteNoteLinkRowToMap(NoteNoteLink r) => {
        'id': r.id,
        'source_note_id': r.sourceNoteId,
        'target_note_id': r.targetNoteId,
        'link_type': r.linkType,
        'link_text': r.linkText,
        'created_at': r.createdAt,
      };

  Map<String, dynamic> _sparkRowToMap(SparkRow r) => {
        'id': r.id,
        'content': r.content,
        'anchor_note_id': r.anchorNoteId,
        'anchor_location': r.anchorLocation,
        'status': r.status,
        'created_at': r.createdAt,
        'updated_at': r.updatedAt,
      };

  // ─── book_highlight_service 迁入（5）───────────────────

  Future<void> insertBookHighlights(
      List<Map<String, dynamic>> highlights) async {
    if (highlights.isEmpty) return;
    await _drift.transaction(() async {
      for (final h in highlights) {
        await _drift.into(_drift.bookHighlights).insert(
              BookHighlightsCompanion(
                id: Value(h['id'] as String),
                bookId: Value(h['book_id'] as String?),
                chapter: Value(h['chapter'] as String?),
                location: Value(h['location'] as String?),
                textContent: Value(h['text'] as String?),
                color: Value(h['color'] as String?),
                note: Value(h['note'] as String?),
                createdAt: Value(h['created_at'] as String?),
                source: Value(h['source'] as String?),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBookHighlightsByBook(
      String bookId) async {
    final rows = await (_drift.select(_drift.bookHighlights)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_bookHighlightRowToMap).toList();
  }

  Future<int> countBookHighlightsByBook(String bookId) async {
    final c = _drift.bookHighlights.id.count();
    final q = _drift.selectOnly(_drift.bookHighlights)
      ..addColumns([c])
      ..where(_drift.bookHighlights.bookId.equals(bookId));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<int> countAllBookHighlights() async {
    final c = _drift.bookHighlights.id.count();
    final q = _drift.selectOnly(_drift.bookHighlights)..addColumns([c]);
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<void> deleteBookHighlightsByBook(String bookId) async {
    await (_drift.delete(_drift.bookHighlights)
          ..where((t) => t.bookId.equals(bookId)))
        .go();
  }

  // ─── note_book_link_service 迁入（10 + 1）──────────────

  Future<void> insertNoteBookLink(Map<String, dynamic> map) async {
    await _drift.into(_drift.noteBookLinks).insert(
          NoteBookLinksCompanion(
            id: Value(map['id'] as String),
            noteId: Value(map['note_id'] as String),
            bookId: Value(map['book_id'] as String),
            linkType: Value(map['link_type'] as String),
            linkText: Value(map['link_text'] as String?),
            context: Value(map['context'] as String?),
            createdAt: Value(map['created_at'] as String),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> deleteNoteBookLink({
    required String noteId,
    required String bookId,
    required String linkType,
  }) async {
    await (_drift.delete(_drift.noteBookLinks)
          ..where((t) =>
              t.noteId.equals(noteId) &
              t.bookId.equals(bookId) &
              t.linkType.equals(linkType)))
        .go();
  }

  Future<List<Map<String, dynamic>>> getNoteBookLinksByBook(
      String bookId) async {
    final rows = await (_drift.select(_drift.noteBookLinks)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_noteBookLinkRowToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getNoteBookLinksByNote(
      String noteId) async {
    final rows = await (_drift.select(_drift.noteBookLinks)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_noteBookLinkRowToMap).toList();
  }

  /// rebuildWikiLinks —— [[书名]] 正则扫 + 索引 + 循环 insert
  Future<void> rebuildWikiLinks({
    required String noteId,
    required String content,
  }) async {
    await (_drift.delete(_drift.noteBookLinks)
          ..where((t) =>
              t.noteId.equals(noteId) & t.linkType.equals('wikilink')))
        .go();

    final regex = RegExp(r'\[\[([^\]\n]+)\]\]');
    final matches = regex.allMatches(content).toList();
    if (matches.isEmpty) return;

    final allBooks = await _drift.select(_drift.books).get();
    final byTitle = <String, List<String>>{};
    for (final row in allBooks) {
      final t = row.title.trim();
      if (t.isEmpty) continue;
      byTitle.putIfAbsent(t, () => []).add(row.id);
    }

    final now = DateTime.now().toIso8601String();
    await _drift.transaction(() async {
      int counter = 0;
      for (final m in matches) {
        final title = m.group(1)?.trim() ?? '';
        if (title.isEmpty) continue;
        final ids = byTitle[title];
        if (ids == null || ids.length != 1) continue;
        final context = _extractContextInternal(content, m.start, m.end);
        await _drift.into(_drift.noteBookLinks).insert(
              NoteBookLinksCompanion(
                id: Value(
                    '${DateTime.now().microsecondsSinceEpoch}_${counter++}'),
                noteId: Value(noteId),
                bookId: Value(ids.first),
                linkType: const Value('wikilink'),
                linkText: Value(title),
                context: Value(context),
                createdAt: Value(now),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  /// rebuildNoteNoteLinks —— [[笔记标题]] 扫 + 索引
  Future<void> rebuildNoteNoteLinks({
    required String noteId,
    required String content,
  }) async {
    await (_drift.delete(_drift.noteNoteLinks)
          ..where((t) =>
              t.sourceNoteId.equals(noteId) & t.linkType.equals('wikilink')))
        .go();

    final regex = RegExp(r'\[\[([^\]\n]+)\]\]');
    final matches = regex.allMatches(content).toList();
    if (matches.isEmpty) return;

    final allNotes = await (_drift.select(_drift.notes)
          ..where((t) => t.status.equals('deleted').not()))
        .get();

    final byTitle = <String, List<String>>{};
    for (final row in allNotes) {
      if (row.id == noteId) continue;
      final rawTitle = row.title.trim();
      final displayTitle = rawTitle.isNotEmpty
          ? rawTitle
          : _virtualTitleInternal(row.content);
      byTitle.putIfAbsent(displayTitle, () => []).add(row.id);
    }

    final now = DateTime.now().toIso8601String();
    await _drift.transaction(() async {
      int counter = 0;
      for (final m in matches) {
        final title = m.group(1)?.trim() ?? '';
        if (title.isEmpty) continue;
        final targets = byTitle[title];
        if (targets == null || targets.isEmpty) continue;
        for (final targetId in targets) {
          await _drift.into(_drift.noteNoteLinks).insert(
                NoteNoteLinksCompanion(
                  id: Value(
                      '${DateTime.now().microsecondsSinceEpoch}_${counter++}'),
                  sourceNoteId: Value(noteId),
                  targetNoteId: Value(targetId),
                  linkType: const Value('wikilink'),
                  linkText: Value(title),
                  createdAt: Value(now),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBacklinks(String noteId) async {
    final rows = await (_drift.select(_drift.noteNoteLinks)
          ..where((t) => t.targetNoteId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_noteNoteLinkRowToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getOutboundNoteLinks(
      String noteId) async {
    final rows = await (_drift.select(_drift.noteNoteLinks)
          ..where((t) => t.sourceNoteId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_noteNoteLinkRowToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getOutboundNoteLinksByText(
    String sourceNoteId,
    String linkText,
  ) async {
    final rows = await (_drift.select(_drift.noteNoteLinks)
          ..where((t) =>
              t.sourceNoteId.equals(sourceNoteId) &
              t.linkText.equals(linkText)))
        .get();
    return rows.map(_noteNoteLinkRowToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getOutboundBookLinksByText(
    String sourceNoteId,
    String linkText,
  ) async {
    final rows = await (_drift.select(_drift.noteBookLinks)
          ..where((t) =>
              t.noteId.equals(sourceNoteId) &
              t.linkType.equals('wikilink') &
              t.linkText.equals(linkText)))
        .get();
    return rows.map(_noteBookLinkRowToMap).toList();
  }

  /// 全表拉 note_note_links（graph_tab / insight_page 用）
  Future<List<Map<String, dynamic>>> getAllNoteNoteLinks() async {
    final rows = await _drift.select(_drift.noteNoteLinks).get();
    return rows.map(_noteNoteLinkRowToMap).toList();
  }

  // ─── spark_service 迁入（7）────────────────────────────

  Future<void> insertSpark(Map<String, dynamic> map) async {
    await _drift.into(_drift.sparks).insert(
          SparksCompanion(
            id: Value(map['id'] as String),
            content: Value(map['content'] as String),
            anchorNoteId: Value(map['anchor_note_id'] as String?),
            anchorLocation: Value(map['anchor_location'] as String?),
            status: Value((map['status'] as String?) ?? 'pending'),
            createdAt: Value(map['created_at'] as String),
            updatedAt: Value(map['updated_at'] as String?),
          ),
        );
  }

  Future<void> updateSpark(Map<String, dynamic> map) async {
    await (_drift.update(_drift.sparks)
          ..where((t) => t.id.equals(map['id'] as String)))
        .write(SparksCompanion(
      content: Value(map['content'] as String),
      anchorNoteId: Value(map['anchor_note_id'] as String?),
      anchorLocation: Value(map['anchor_location'] as String?),
      status: Value((map['status'] as String?) ?? 'pending'),
      updatedAt: Value(map['updated_at'] as String?),
    ));
  }

  Future<void> deleteSpark(String id) async {
    await (_drift.delete(_drift.sparks)..where((t) => t.id.equals(id))).go();
  }

  Future<Map<String, dynamic>?> getSpark(String id) async {
    final row = await (_drift.select(_drift.sparks)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _sparkRowToMap(row);
  }

  Future<List<Map<String, dynamic>>> getSparksByNote(String noteId) async {
    final rows = await (_drift.select(_drift.sparks)
          ..where((t) => t.anchorNoteId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_sparkRowToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingSparksByNote(
      String noteId) async {
    final rows = await (_drift.select(_drift.sparks)
          ..where((t) =>
              t.anchorNoteId.equals(noteId) & t.status.equals('pending'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_sparkRowToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getAllPendingSparks() async {
    final rows = await (_drift.select(_drift.sparks)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_sparkRowToMap).toList();
  }

  // ─── 内部工具（迁自 note_book_link_service）────────────

  static String _extractContextInternal(String content, int start, int end) {
    const contextRadius = 30;
    final s = (start - contextRadius).clamp(0, content.length);
    final e = (end + contextRadius).clamp(0, content.length);
    return content.substring(s, e);
  }

  static String _virtualTitleInternal(String content) {
    final c = content.trim().replaceAll('\n', ' ');
    if (c.isEmpty) return '无标题';
    return c.length > 20 ? '${c.substring(0, 20)}…' : c;
  }

  // ─── 占位 ──────────────────────────────────────────────
  Future<void> insertAnnotation(Map<String, dynamic> annotationMap) async {}
  Future<List<Map<String, dynamic>>> getAllAnnotationsForBook(String bookId) async => [];

  // ─── 系统文件夹 ────────────────────────────────────────
  // 批 BUG-003：系统文件夹改按 systemTag 找——不靠 title
  Future<String> _ensureSystemFolderByTag(
    String systemTag,
    String defaultTitle, {
    List<String>? tags,
  }) async {
    final allNodes = await getAllNodes();
    final matches = allNodes
        .where((n) => n.systemTag == systemTag && n.isFolder && n.parentId == null)
        .toList();
    if (matches.isEmpty) {
      final folder = await createFolder(
        title: defaultTitle,
        parentId: null,
        tags: tags ?? [],
        systemTag: systemTag,
      );
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

  Future<String> ensureArchivedFolder() => _ensureSystemFolderByTag('archived', '已归档', tags: ['系统', '归档']);
  Future<String> ensureLibraryFolder() => _ensureSystemFolderByTag('library', '图书馆', tags: ['系统', '图书']);
  Future<String> ensureReviewFolder() => _ensureSystemFolderByTag('review', '复盘库', tags: ['系统', '复盘']);
  Future<String> ensureCardBoxFolder() => _ensureSystemFolderByTag('cardbox', '卡片盒', tags: ['系统', '卡片盒']);
  Future<String> ensureExpandFolder() => _ensureSystemFolderByTag('expand', '拓展笔记', tags: ['系统', '拓展笔记']);
  /// Markdown 导入目标文件夹
  Future<String> ensureImportedFolder([String name = '导入的 Markdown']) =>
      _ensureSystemFolderByTag('imported', name, tags: ['系统', '导入']);
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
    await _drift.transaction(() async {
      await _drift.delete(_drift.notes).go();
      await _drift.delete(_drift.nodes).go();
      await _drift.delete(_drift.books).go();
    });
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
    await (_drift.update(_drift.notes)
          ..where((t) => t.id.equals(noteId)))
        .write(NotesCompanion(isLocked: Value(locked ? 1 : 0)));
  }

  Future<int> getLockedNotesCount() async {
    final notes = await _getAllNotesInternal(includeDeleted: false);
    return notes.where((n) => n['isLocked'] == 1).length;
  }

  Future<int> getArchivedFolderNoteCount() async {
    final nodes = await getAllNodes();
    final archivedFolder = nodes.firstWhere((n) => n.systemTag == 'archived' && n.isFolder && n.parentId == null, orElse: () => Node.empty);
    if (archivedFolder.id.isEmpty) return 0;
    final children = await getChildren(archivedFolder.id);
    return children.where((n) => !n.isFolder).length;
  }

  Future<List<NotebookEntry>> getArchivedFolderNotes() async {
    final nodes = await getAllNodes();
    final archivedFolder = nodes.firstWhere((n) => n.systemTag == 'archived' && n.isFolder && n.parentId == null, orElse: () => Node.empty);
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

  /// 批 1a：暴露 db 连接给服务层（NoteBookLinkService 用）




    /// 批 1a：L2 → L3 迁移
  /// 读 SharedPreferences book_reading_note_id_$bookId → 写 note_book_links
  /// 幂等：ConflictAlgorithm.ignore + UNIQUE 约束
  /// 旧 key 保留只读（防回滚）

  /// 批 BUG-003：开发调试用——清空所有本地数据
  /// 正式版不加调用入口
  /// 用法：main() 里临时加 `await DatabaseService().dropAllForDebug();` 跑一次 —— 删那行
  Future<void> dropAllForDebug() async {
    // 统一先清 SharedPreferences（两端都要）
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 清微信读书 API Key
    try { await WereadKeyStore().clear(); } catch (_) {}

    if (!_isWeb) {
      await _drift.delete(_drift.nodes).go();
      await _drift.delete(_drift.notes).go();
      await _drift.delete(_drift.books).go();
      await _drift.delete(_drift.bookAnnotations).go();
      await _drift.delete(_drift.pdfDrawings).go();
      await _drift.delete(_drift.isbnCache).go();
      await _drift.delete(_drift.boardViews).go();
      await _drift.delete(_drift.boardNodes).go();
      await _drift.delete(_drift.boardEdges).go();
      await _drift.delete(_drift.boardGroups).go();
      await _drift.delete(_drift.boardTexts).go();
      await _drift.delete(_drift.tagIndex).go();
      try { await _drift.delete(_drift.searchIndex).go(); } catch (_) {}
      try { await _drift.delete(_drift.noteBookLinks).go(); } catch (_) {}
      try { await _drift.delete(_drift.bookHighlights).go(); } catch (_) {}
    }
  }


  Future<Map<String, dynamic>?> getIsbnCache(String isbn) async {
    if (_isWeb) return null;
    final row = await (_drift.select(_drift.isbnCache)
          ..where((t) => t.isbn.equals(isbn))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'isbn': row.isbn,
      'title': row.title,
      'author': row.author,
      'cover_url': row.coverUrl,
      'source': row.source,
      'updated_at': row.updatedAt,
    };
  }

  Future<void> saveIsbnCache({required String isbn, required String title, required String author, required String coverUrl, required String source}) async {
    if (_isWeb) return;
    await _drift.into(_drift.isbnCache).insert(
          IsbnCacheCompanion(
            isbn: Value(isbn),
            title: Value(title),
            author: Value(author),
            coverUrl: Value(coverUrl),
            source: Value(source),
            updatedAt: Value(DateTime.now().toIso8601String()),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  // ─── PDF 划痕 ────────────────────────────────────────
  Future<void> savePdfDrawing(PdfDrawing drawing) async {
    if (_isWeb) return;
    final map = drawing.toMap();
    await _drift.into(_drift.pdfDrawings).insert(
          PdfDrawingsCompanion(
            id: Value(map['id'] as String),
            bookId: Value(map['bookId'] as String?),
            page: Value(map['page'] as int?),
            points: Value(map['points'] as String?),
            color: Value(map['color'] as String?),
            createdAt: Value(map['createdAt'] as String?),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<PdfDrawing>> getPdfDrawingsByBook(String bookId) async {
    if (_isWeb) return [];
    final rows = await (_drift.select(_drift.pdfDrawings)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.page, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows
        .map((row) => PdfDrawing.fromMap({
              'id': row.id,
              'bookId': row.bookId,
              'page': row.page,
              'points': row.points,
              'color': row.color,
              'createdAt': row.createdAt,
            }))
        .toList();
  }

  Future<void> deletePdfDrawingsByBook(String bookId) async {
    if (_isWeb) return;
    await (_drift.delete(_drift.pdfDrawings)
          ..where((t) => t.bookId.equals(bookId)))
        .go();
  }

  // ═══════════════════════════════════════════════════════
  // 线索墙 CRUD
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getBoardView(String id) async {
    final row = await (_drift.select(_drift.boardViews)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _boardViewRowToMap(row);
  }

  Future<void> upsertBoardView(Map<String, dynamic> view) async {
    await _drift.into(_drift.boardViews).insert(
          BoardViewsCompanion(
            id: Value(view['id'] as String),
            name: Value(view['name'] as String?),
            type: Value(view['type'] as String?),
            ownerId: Value(view['ownerId'] as String?),
            createdAt: Value(view['createdAt'] as String?),
            updatedAt: Value(view['updatedAt'] as String?),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<Map<String, dynamic>>> getBoardNodes(String viewId) async {
    final rows = await (_drift.select(_drift.boardNodes)
          ..where((t) => t.viewId.equals(viewId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.zIndex, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_boardNodeRowToMap).toList();
  }

  Future<void> replaceBoardNodes(String viewId, List<Map<String, dynamic>> nodes) async {
    await _drift.transaction(() async {
      await (_drift.delete(_drift.boardNodes)
            ..where((t) => t.viewId.equals(viewId)))
          .go();
      for (final node in nodes) {
        await _drift.into(_drift.boardNodes).insert(
              BoardNodesCompanion(
                id: Value(node['id'] as String),
                viewId: Value(node['viewId'] as String?),
                cardId: Value(node['cardId'] as String?),
                type: Value((node['type'] as String?) ?? 'card'),
                noteId: Value(node['noteId'] as String?),
                x: Value(node['x'] as double?),
                y: Value(node['y'] as double?),
                zIndex: Value(node['zIndex'] as int?),
              ),
            );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBoardEdges(String viewId) async {
    final rows = await (_drift.select(_drift.boardEdges)
          ..where((t) => t.viewId.equals(viewId)))
        .get();
    return rows.map(_boardEdgeRowToMap).toList();
  }

  Future<void> replaceBoardEdges(String viewId, List<Map<String, dynamic>> edges) async {
    await _drift.transaction(() async {
      await (_drift.delete(_drift.boardEdges)
            ..where((t) => t.viewId.equals(viewId)))
          .go();
      for (final edge in edges) {
        await _drift.into(_drift.boardEdges).insert(
              BoardEdgesCompanion(
                id: Value(edge['id'] as String),
                viewId: Value(edge['viewId'] as String?),
                sourceNodeId: Value(edge['sourceNodeId'] as String?),
                targetNodeId: Value(edge['targetNodeId'] as String?),
              ),
            );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBoardTexts(String viewId) async {
    final rows = await (_drift.select(_drift.boardTexts)
          ..where((t) => t.viewId.equals(viewId)))
        .get();
    return rows.map(_boardTextRowToMap).toList();
  }

  Future<void> replaceBoardTexts(String viewId, List<Map<String, dynamic>> texts) async {
    await _drift.transaction(() async {
      await (_drift.delete(_drift.boardTexts)
            ..where((t) => t.viewId.equals(viewId)))
          .go();
      for (final t in texts) {
        await _drift.into(_drift.boardTexts).insert(
              BoardTextsCompanion(
                id: Value(t['id'] as String),
                viewId: Value(t['viewId'] as String?),
                x: Value(t['x'] as double?),
                y: Value(t['y'] as double?),
                content: Value(t['content'] as String?),
              ),
            );
      }
    });
  }
  Future<void> replaceBoardStrokes(String viewId, List<Map<String, dynamic>> strokes) async {
    await _drift.transaction(() async {
      await (_drift.delete(_drift.boardStrokes)
            ..where((t) => t.viewId.equals(viewId)))
          .go();
      for (final s in strokes) {
        await _drift.into(_drift.boardStrokes).insert(
              BoardStrokesCompanion(
                id: Value(s['id'] as String),
                viewId: Value(s['viewId'] as String),
                groupId: Value(s['groupId'] as String?),
                zIndex: Value((s['zIndex'] as int?) ?? 0),
                points: Value(s['points'] as String),
                color: Value(s['color'] as String),
                width: Value(s['width'] as double),
                createdAt: Value(s['createdAt'] as String),
              ),
            );
      }
    });
  }

  Future<void> insertBoardStroke(Map<String, dynamic> s) async {
    await _drift.into(_drift.boardStrokes).insert(
          BoardStrokesCompanion(
            id: Value(s['id'] as String),
            viewId: Value(s['viewId'] as String),
            groupId: Value(s['groupId'] as String?),
            zIndex: Value((s['zIndex'] as int?) ?? 0),
            points: Value(s['points'] as String),
            color: Value(s['color'] as String),
            width: Value(s['width'] as double),
            createdAt: Value(s['createdAt'] as String),
          ),
        );
  }

  Future<List<Map<String, dynamic>>> getBoardStrokes(String viewId) async {
    final rows = await (_drift.select(_drift.boardStrokes)
          ..where((t) => t.viewId.equals(viewId)))
        .get();
    return rows.map(_boardStrokeRowToMap).toList();
  }
  // ─── 批 5：Row → camelCase Map helpers ────────────────

  Map<String, dynamic> _boardViewRowToMap(BoardView r) => {
        'id': r.id,
        'name': r.name,
        'type': r.type,
        'ownerId': r.ownerId,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
      };

  Map<String, dynamic> _boardNodeRowToMap(BoardNode r) => {
        'id': r.id,
        'viewId': r.viewId,
        'cardId': r.cardId,
        'type': r.type,
        'noteId': r.noteId,
        'x': r.x,
        'y': r.y,
        'zIndex': r.zIndex,
      };

  Map<String, dynamic> _boardEdgeRowToMap(BoardEdge r) => {
        'id': r.id,
        'viewId': r.viewId,
        'sourceNodeId': r.sourceNodeId,
        'targetNodeId': r.targetNodeId,
      };

  Map<String, dynamic> _boardTextRowToMap(BoardText r) => {
        'id': r.id,
        'viewId': r.viewId,
        'x': r.x,
        'y': r.y,
        'content': r.content,
      };

  Map<String, dynamic> _boardStrokeRowToMap(BoardStroke r) => {
        'id': r.id,
        'viewId': r.viewId,
        'groupId': r.groupId,
        'zIndex': r.zIndex,
        'points': r.points,
        'color': r.color,
        'width': r.width,
        'createdAt': r.createdAt,
      };

  Map<String, dynamic> _boardAlbumRowToMap(BoardAlbum r) => {
        'id': r.id,
        'title': r.title,
        'sourceViewId': r.sourceViewId,
        'strokesJson': r.strokesJson,
        'thumbnailBase64': r.thumbnailBase64,
        'createdAt': r.createdAt,
        'updatedAt': r.updatedAt,
      };

  // ─── R-12a：节点批注 DAO ──────────────────────

  Future<void> saveNodeAnnotation(
      String nodeId, List<Map<String, dynamic>> strokesJson) async {
    final now = DateTime.now().toIso8601String();
    await _drift.transaction(() async {
      await (_drift.delete(_drift.nodeAnnotations)
            ..where((t) => t.nodeId.equals(nodeId)))
          .go();
      await _drift.into(_drift.nodeAnnotations).insert(
            NodeAnnotationsCompanion(
              id: Value('na_$nodeId'),
              nodeId: Value(nodeId),
              strokesJson: Value(jsonEncode(strokesJson)),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  Future<List<Map<String, dynamic>>> loadNodeAnnotation(String nodeId) async {
    final row = await (_drift.select(_drift.nodeAnnotations)
          ..where((t) => t.nodeId.equals(nodeId))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return [];
    try {
      return (jsonDecode(row.strokesJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteNodeAnnotation(String nodeId) async {
    await (_drift.delete(_drift.nodeAnnotations)
          ..where((t) => t.nodeId.equals(nodeId)))
        .go();
  }

  // ─── 批 5：NodeAnnotation Row → camelCase Map helper ───


  // ─── R-7-3a 单A：writing_sessions / focus_sessions DAO ───

  // ─── 批 4：Row → snake_case Map helpers ────────────────

  Map<String, dynamic> _writingSessionRowToMap(WritingSessionRow r) => {
        'id': r.id,
        'note_id': r.noteId,
        'start_at': r.startAt,
        'end_at': r.endAt,
        'word_count': r.wordCount,
        'paused_seconds': r.pausedSeconds,
      };

  Map<String, dynamic> _focusSessionRowToMap(FocusSessionRow r) => {
        'id': r.id,
        'start_at': r.startAt,
        'minutes': r.minutes,
      };

  Future<void> insertWritingSession(Map<String, dynamic> session) async {
    await _drift.into(_drift.writingSessions).insert(
          WritingSessionsCompanion(
            id: Value(session['id'] as String),
            noteId: Value(session['note_id'] as String),
            startAt: Value(session['start_at'] as String),
            endAt: Value(session['end_at'] as String),
            wordCount: Value((session['word_count'] as int?) ?? 0),
            pausedSeconds: Value((session['paused_seconds'] as int?) ?? 0),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<Map<String, dynamic>>> getAllWritingSessions() async {
    final rows = await (_drift.select(_drift.writingSessions)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_writingSessionRowToMap).toList();
  }

  Future<void> deleteWritingSessionsBefore(DateTime cutoff) async {
    await (_drift.delete(_drift.writingSessions)
          ..where((t) =>
              t.startAt.isSmallerThanValue(cutoff.toIso8601String())))
        .go();
  }

  Future<void> clearWritingSessions() async {
    await _drift.delete(_drift.writingSessions).go();
  }

  Future<void> insertFocusSession(Map<String, dynamic> session) async {
    await _drift.into(_drift.focusSessions).insert(
          FocusSessionsCompanion(
            id: Value(session['id'] as String),
            startAt: Value(session['start_at'] as String),
            minutes: Value((session['minutes'] as int?) ?? 0),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<List<Map<String, dynamic>>> getAllFocusSessions() async {
    final rows = await (_drift.select(_drift.focusSessions)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startAt, mode: OrderingMode.asc),
          ]))
        .get();
    return rows.map(_focusSessionRowToMap).toList();
  }




  Future<void> deleteFocusSessionsBefore(DateTime cutoff) async {
    await (_drift.delete(_drift.focusSessions)
          ..where((t) =>
              t.startAt.isSmallerThanValue(cutoff.toIso8601String())))
        .go();
  }
  Future<List<Map<String, dynamic>>> getAllBoardAlbums() async {
    final rows = await (_drift.select(_drift.boardAlbums)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
    return rows.map(_boardAlbumRowToMap).toList();
  }

  Future<Map<String, dynamic>?> getBoardAlbum(String id) async {
    final row = await (_drift.select(_drift.boardAlbums)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _boardAlbumRowToMap(row);
  }

  Future<void> insertBoardAlbum(Map<String, dynamic> m) async {
    await _drift.into(_drift.boardAlbums).insert(
          BoardAlbumsCompanion(
            id: Value(m['id'] as String),
            title: Value(m['title'] as String?),
            sourceViewId: Value(m['sourceViewId'] as String?),
            strokesJson: Value(m['strokesJson'] as String),
            thumbnailBase64: Value(m['thumbnailBase64'] as String?),
            createdAt: Value(m['createdAt'] as String),
            updatedAt: Value(m['updatedAt'] as String?),
          ),
        );
  }

  Future<void> deleteBoardAlbum(String id) async {
    await (_drift.delete(_drift.boardAlbums)..where((t) => t.id.equals(id)))
        .go();
  }

  Future<String> ensureAlbumFolder() =>
      _ensureSystemFolderByTag('album', '画册', tags: ['系统', '画册']);

  // ═══════════════════════════════════════════════════════════════
  // 批 6：宠物 / 设置（入参 / 出参全 camelCase）
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> _petRowToMap(PetRow r) => {
        'name': r.name,
        'level': r.level,
        'exp': r.exp,
        'stage': r.stage,
        'happiness': r.happiness,
        'lastFed': r.lastFed,
      };

  PetsCompanion _petMapToCompanion(Map<String, dynamic> map) {
    final now = DateTime.now().toIso8601String();
    return PetsCompanion(
      id: const Value(1),
      name: Value((map['name'] as String?) ?? '小云'),
      level: Value((map['level'] as int?) ?? 1),
      exp: Value((map['exp'] as int?) ?? 0),
      stage: Value((map['stage'] as String?) ?? 'droplet'),
      happiness: Value((map['happiness'] as int?) ?? 80),
      lastFed: Value((map['lastFed'] as int?) ?? 0),
      updatedAt: Value(now),
    );
  }

  Future<Map<String, dynamic>?> loadPet() async {
    final row = await (_drift.select(_drift.pets)
          ..where((t) => t.id.equals(1))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _petRowToMap(row);
  }

  Future<void> savePet(Map<String, dynamic> petMap) async {
    await _drift.into(_drift.pets).insert(
          _petMapToCompanion(petMap),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> clearPet() async {
    await _drift.delete(_drift.pets).go();
  }

  Map<String, dynamic> _userSettingsRowToMap(UserSettingsTableData r) => {
        'nickname': r.nickname,
        'bio': r.bio,
        'avatarUrl': r.avatarUrl,
        'themeMode': r.themeMode,
        'defaultMarkdown': r.defaultMarkdown,
        'reviewReminderHour': r.reviewReminderHour,
        'reviewReminderMinute': r.reviewReminderMinute,
        'dailyReviewLimit': r.dailyReviewLimit,
        'reviewFactor': r.reviewFactor,
        'heatmapStatMode': r.heatmapStatMode,
        'heatmapHighThreshold': r.heatmapHighThreshold,
        'heatmapBurstThreshold': r.heatmapBurstThreshold,
        'heatmapWordHighThreshold': r.heatmapWordHighThreshold,
        'heatmapWordBurstThreshold': r.heatmapWordBurstThreshold,
        'heatmapColorScheme': r.heatmapColorScheme,
        'heatmapColorLow': r.heatmapColorLow,
        'heatmapColorMid': r.heatmapColorMid,
        'heatmapColorHigh': r.heatmapColorHigh,
        'heatmapColorBurst': r.heatmapColorBurst,
        'showPet': r.showPet,
        'petSkin': r.petSkin,
        'petName': r.petName,
        'petInFocusMode': r.petInFocusMode,
        'rawNoteRetentionDays': r.rawNoteRetentionDays,
        'dailyWordTarget': r.dailyWordTarget,
        'typewriterSound': r.typewriterSound,
        'whiteNoiseVolume': r.whiteNoiseVolume,
        'restReminderOn': r.restReminderOn,
        'restReminderMinutes': r.restReminderMinutes,
        'customNoiseSources': r.customNoiseSources,
      };

  UserSettingsTableCompanion _userSettingsMapToCompanion(
      Map<String, dynamic> map) {
    return UserSettingsTableCompanion(
      nickname: Value((map['nickname'] as String?) ?? '小云同学'),
      bio: Value((map['bio'] as String?) ?? '📚 知识探索者'),
      avatarUrl: Value((map['avatarUrl'] as String?) ?? ''),
      themeMode: Value((map['themeMode'] as String?) ?? 'light'),
      defaultMarkdown: Value((map['defaultMarkdown'] as bool?) ?? false),
      reviewReminderHour: Value((map['reviewReminderHour'] as int?) ?? 20),
      reviewReminderMinute:
          Value((map['reviewReminderMinute'] as int?) ?? 0),
      dailyReviewLimit: Value((map['dailyReviewLimit'] as int?) ?? 20),
      reviewFactor: Value((map['reviewFactor'] as num?)?.toDouble() ?? 2.5),
      heatmapStatMode:
          Value((map['heatmapStatMode'] as String?) ?? 'count'),
      heatmapHighThreshold:
          Value((map['heatmapHighThreshold'] as int?) ?? 3),
      heatmapBurstThreshold:
          Value((map['heatmapBurstThreshold'] as int?) ?? 8),
      heatmapWordHighThreshold:
          Value((map['heatmapWordHighThreshold'] as int?) ?? 300),
      heatmapWordBurstThreshold:
          Value((map['heatmapWordBurstThreshold'] as int?) ?? 800),
      heatmapColorScheme:
          Value((map['heatmapColorScheme'] as String?) ?? 'emerald'),
      heatmapColorLow:
          Value((map['heatmapColorLow'] as String?) ?? '#E8F5E9'),
      heatmapColorMid:
          Value((map['heatmapColorMid'] as String?) ?? '#81C784'),
      heatmapColorHigh:
          Value((map['heatmapColorHigh'] as String?) ?? '#FFD93D'),
      heatmapColorBurst:
          Value((map['heatmapColorBurst'] as String?) ?? '#FF6B6B'),
      showPet: Value((map['showPet'] as bool?) ?? true),
      petSkin: Value((map['petSkin'] as String?) ?? 'default'),
      petName: Value((map['petName'] as String?) ?? '小云'),
      petInFocusMode: Value((map['petInFocusMode'] as bool?) ?? true),
      rawNoteRetentionDays:
          Value((map['rawNoteRetentionDays'] as int?) ?? 15),
      dailyWordTarget: Value((map['dailyWordTarget'] as int?) ?? 0),
      typewriterSound: Value((map['typewriterSound'] as bool?) ?? false),
      whiteNoiseVolume:
          Value((map['whiteNoiseVolume'] as num?)?.toDouble() ?? 0.5),
      restReminderOn: Value((map['restReminderOn'] as bool?) ?? false),
      restReminderMinutes:
          Value((map['restReminderMinutes'] as int?) ?? 45),
      customNoiseSources: Value(map['customNoiseSources'] != null
          ? jsonEncode(map['customNoiseSources'])
          : '[]'),
      // 其余 focusMinutes / reader* 7 列不传（Value.absent），不读不写。
    );
  }

  Future<Map<String, dynamic>?> loadSettings() async {
    final row = await (_drift.select(_drift.userSettingsTable)..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final map = _userSettingsRowToMap(row);
    // customNoiseSources 在表里是 TEXT (JSON)，转回 List
    try {
      final raw = map['customNoiseSources'] as String?;
      map['customNoiseSources'] =
          raw != null ? jsonDecode(raw) : <Map<String, dynamic>>[];
    } catch (_) {
      map['customNoiseSources'] = <Map<String, dynamic>>[];
    }
    return map;
  }

  Future<void> saveSettings(Map<String, dynamic> settingsMap) async {
    final companion = _userSettingsMapToCompanion(settingsMap);
    final existing = await (_drift.select(_drift.userSettingsTable)..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (_drift.update(_drift.userSettingsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
    } else {
      await _drift.into(_drift.userSettingsTable).insert(companion);
    }
  }
}
