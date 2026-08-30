// lib/services/sync_manager.dart
// 同步状态管理

import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import 'cloud_data_service.dart';

class SyncManager extends ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final CloudDataService _cloud = CloudDataService();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _syncedBooks = 0;
  int _syncedNotes = 0;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  int get syncedBooks => _syncedBooks;
  int get syncedNotes => _syncedNotes;

  /// 执行完整同步
  Future<bool> syncAll({
    required List<Book> books,
    required List<BookNote> bookNotes,
  }) async {
    if (_isSyncing) return false;
    if (!_cloud.isLoggedIn) {
      _lastSyncError = '请先登录';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastSyncError = null;
    _syncedBooks = 0;
    _syncedNotes = 0;
    notifyListeners();

    try {
      await _cloud.syncAll(books: books, bookNotes: bookNotes);
      _syncedBooks = books.length;
      _syncedNotes = bookNotes.length;
      _lastSyncTime = DateTime.now();
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
  Future<CloudSyncResult?> pullAll() async {
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
    notifyListeners();
  }
}