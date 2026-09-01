// lib/services/sync/sync_manager.dart
// 同步状态管理器

import 'package:flutter/material.dart';
import 'cloud_sync_service.dart';
import '../../models/note.dart';
import '../../models/node.dart';
import '../../models/task.dart';
import '../../models/card.dart';
import '../../models/book.dart';
import '../../models/pet.dart';
import '../../models/user_settings.dart';

class SyncManager extends ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final CloudSyncService _cloud = CloudSyncService();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _pendingChanges = 0;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  int get pendingChanges => _pendingChanges;

  /// 标记有数据需要同步
  void markDirty() {
    _pendingChanges++;
    notifyListeners();
  }

  /// 标记同步完成
  void markClean() {
    _pendingChanges = 0;
    notifyListeners();
  }

  /// 执行全量同步
  Future<bool> syncAll({
    required List<NotebookEntry> notes,
    required List<Node> nodes,
    required List<Book> books,
    required List<CardModel> cards,
    required List<Task> tasks,
    required List<Subtask> subtasks,
    required Pet pet,
    required UserSettings settings,
  }) async {
    if (_isSyncing) return false;
    if (!_cloud.isLoggedIn) {
      _lastSyncError = '请先登录';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      await _cloud.syncAll(
        notes: notes,
        nodes: nodes,
        books: books,
        cards: cards,
        tasks: tasks,
        subtasks: subtasks,
        pet: pet,
        settings: settings,
      );
      _lastSyncTime = DateTime.now();
      _pendingChanges = 0;
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastSyncError = e.toString();
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// 从云端拉取数据
  Future<SyncResult?> pullAll() async {
    if (!_cloud.isLoggedIn) {
      _lastSyncError = '请先登录';
      notifyListeners();
      return null;
    }

    try {
      return await _cloud.pullAll();
    } catch (e) {
      _lastSyncError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 重置状态
  void reset() {
    _isSyncing = false;
    _lastSyncError = null;
    _pendingChanges = 0;
    notifyListeners();
  }

  bool get isLoggedIn => _cloud.isLoggedIn;
}