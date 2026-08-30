// lib/pages/wisdom_page.dart
// 📚 智库页面 — 含“灵感过期”文件夹 + “图书馆”系统文件夹

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';  // ✅ 添加

import '../database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/node.dart';
import '../models/card.dart';
import '../models/task.dart';
import '../services/card_service.dart';
import '../services/task_service.dart';
import '../services/cache_manager.dart';
import '../mixins/state_mixin.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/wisdom/wisdom_folder_card.dart';
import '../widgets/wisdom/wisdom_note_card.dart';
import '../widgets/wisdom/wisdom_book_card.dart';
import '../widgets/wisdom/wisdom_card_box.dart';
import '../widgets/wisdom/wisdom_toolbar.dart';
import '../widgets/wisdom/wisdom_draggable.dart';
import '../widgets/wisdom/wisdom_search_bar.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';
import 'writing_page.dart';

enum WisdomViewMode { list, grid, large, split }

class WisdomPage extends StatefulWidget {
  const WisdomPage({super.key});

  @override
  WisdomPageState createState() => WisdomPageState();
}

class WisdomPageState extends State<WisdomPage> with StateMixin {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();
  final TaskService _taskService = TaskService();
  final CacheManager _cache = CacheManager();

  List<Node> _nodes = [];
  List<NotebookEntry> _notes = [];
  List<Book> _books = [];
  List<CardModel> _cards = [];
  String? _currentFolderId;
  String _searchKeyword = '';
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};
  bool _showSearchBar = false;

  WisdomViewMode _viewMode = WisdomViewMode.grid;
  bool _fabExpanded = false;

  List<Node>? _cachedFilteredNodes;
  static const String _cacheKeyNodes = 'wisdom_nodes';
  static const String _cacheKeyNotes = 'wisdom_notes';
  static const String _cacheKeyBooks = 'wisdom_books';
  static const String _cacheKeyCards = 'wisdom_cards';
  Map<String, Map<String, int>>? _folderStatsCache;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refreshData() {
    _cache.invalidate(_cacheKeyNodes);
    _cache.invalidate(_cacheKeyNotes);
    _cache.invalidate(_cacheKeyBooks);
    _cache.invalidate(_cacheKeyCards);
    _folderStatsCache = null;
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading = true;
    try {
      await _db.ensureLibraryFolder();

      final nodes = await _cache.get<List<Node>>(
        _cacheKeyNodes,
        () => _db.getAllNodes(),
        ttl: const Duration(seconds: 30),
      );
      final notes = await _cache.get<List<NotebookEntry>>(
        _cacheKeyNotes,
        () async {
          final maps = await _db.getAllNotes(includeDeleted: false);
          return maps.map((m) => NotebookEntry.fromMap(m)).toList();
        },
        ttl: const Duration(seconds: 30),
      );
      final books = await _cache.get<List<Book>>(
        _cacheKeyBooks,
        () async {
          final maps = await _db.getAllBooks();
          return maps.map((m) => Book.fromMap(m)).toList();
        },
        ttl: const Duration(seconds: 30),
      );
      final cards = await _cache.get<List<CardModel>>(
        _cacheKeyCards,
        () => _cardService.getAllCards(),
        ttl: const Duration(seconds: 30),
      );

      setState(() {
        _nodes = nodes;
        _notes = notes;
        _books = books;
        _cards = cards;
        _cachedFilteredNodes = null;
        _folderStatsCache = null;
      });

      await _ensureCardBoxFolder();
    } catch (e) {
      print('加载数据失败: $e');
    }
    isLoading = false;
  }

  Map<String, Map<String, int>> _getFolderStats() {
    if (_folderStatsCache != null) return _folderStatsCache!;
    
    final stats = <String, Map<String, int>>{};
    if (_nodes.isEmpty) return stats;

    final folderIds = _nodes.where((n) => n.isFolder).map((n) => n.id).toList();
    final cardSourceIds = _cards.map((c) => c.sourceId).toList();

    for (var folderId in folderIds) {
      final children = _nodes.where((n) => n.parentId == folderId).toList();
      int subFolderCount = 0, noteCount = 0, bookCount = 0, cardCount = 0;
      for (var child in children) {
        if (child.isFolder) {
          subFolderCount++;
        } else if (child.nodeType == 'note') { noteCount++; if (cardSourceIds.contains(child.targetId)) cardCount++; }
        else if (child.nodeType == 'book') { bookCount++; if (cardSourceIds.contains(child.targetId)) cardCount++; }
      }
      stats[folderId] = {
        'subFolders': subFolderCount,
        'notes': noteCount,
        'books': bookCount,
        'cards': cardCount,
        'total': children.length,
      };
    }
    _folderStatsCache = stats;
    return stats;
  }

  Future<void> _ensureCardBoxFolder() async {
    final existing = _nodes.where((n) => n.title == '卡片盒' && n.isFolder && n.parentId == null).toList();
    if (existing.length > 1) {
      for (var i = 1; i < existing.length; i++) { await _db.deleteNode(existing[i].id); }
      _cache.invalidate(_cacheKeyNodes); await _loadData(); return;
    }
    if (existing.isEmpty && _cards.isNotEmpty) {
      await _db.createFolder(title: '卡片盒', parentId: null, tags: ['卡片盒', '系统']);
      _cache.invalidate(_cacheKeyNodes); await _loadData();
    }
  }

  bool get _isCardBoxView {
    if (_currentFolderId == null) return false;
    final node = _nodes.firstWhere((n) => n.id == _currentFolderId, orElse: () => _nodes.first);
    return node.title == '卡片盒' && node.isFolder && node.parentId == null && _cards.isNotEmpty;
  }

  List<Node> get _children => _nodes.where((n) => n.parentId == _currentFolderId).toList();

  List<Node> get _filteredNodes {
    if (_cachedFilteredNodes != null) return _cachedFilteredNodes!;
    final children = _children;
    if (_searchKeyword.isEmpty) { _cachedFilteredNodes = children; return children; }
    final result = children.where((n) =>
      n.title.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
      n.tags.any((t) => t.toLowerCase().contains(_searchKeyword.toLowerCase()))
    ).toList();
    _cachedFilteredNodes = result;
    return result;
  }

  List<Node> get _breadcrumbPath {
    if (_currentFolderId == null) return [];
    final result = <Node>[];
    String? currentId = _currentFolderId;
    final folderMap = {for (var n in _nodes.where((n) => n.isFolder)) n.id: n};
    while (currentId != null && folderMap.containsKey(currentId)) {
      final node = folderMap[currentId]!;
      result.insert(0, node);
      currentId = node.parentId;
    }
    return result;
  }

  List<Node> get _rootFolders => _nodes.where((n) => n.isFolder && n.parentId == null).toList();

  List<Node> get _userFolders {
    return _nodes.where((n) => 
      n.isFolder && 
      n.parentId == null && 
      n.title != '灵感过期' &&
      n.title != '图书馆'
    ).toList();
  }

  // ✅ 修复：使用 firstWhereOrNull
  Node? get _libraryFolder {
    final folder = _nodes.firstWhereOrNull(
      (n) => n.title == '图书馆' && n.isFolder && n.parentId == null,
    );
    if (folder == null) return null;
    final children = _nodes.where((n) => n.parentId == folder.id && !n.isFolder).toList();
    if (children.isEmpty) return null;
    return folder;
  }

  int get _libraryBookCount {
    if (_libraryFolder == null) return 0;
    return _nodes.where((n) => n.parentId == _libraryFolder!.id && n.nodeType == 'book').length;
  }

  // ✅ 修复：使用 firstWhereOrNull
  Node? get _expiredFolder {
    final folder = _nodes.firstWhereOrNull(
      (n) => n.title == '灵感过期' && n.isFolder && n.parentId == null,
    );
    if (folder == null) return null;
    final children = _nodes.where((n) => n.parentId == folder.id && !n.isFolder).toList();
    if (children.isEmpty) return null;
    return folder;
  }

  int get _expiredNoteCount {
    if (_expiredFolder == null) return 0;
    return _nodes.where((n) => n.parentId == _expiredFolder!.id && !n.isFolder).length;
  }

  void _navigateToFolder(String? folderId) {
    setState(() { _currentFolderId = folderId; _cachedFilteredNodes = null; _searchKeyword = ''; _showSearchBar = false; });
  }

  void _openClueBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritingPage(
          initialViewMode: WritingViewMode.clueBoard,
        ),
      ),
    );
  }

  Future<void> _createNote() async {
    _closeFab();
    final tempNote = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '无标题笔记', content: '', tags: [], updatedAt: DateTime.now(), editorMode: 'plain',
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: tempNote,
          isFromCollection: true,
          onSave: (entry, title, content, mode, tags) async {
            final noteMap = { 'id': entry.id, 'title': title, 'content': content, 'status': 'active', 'editorMode': mode, 'updatedAt': DateTime.now().toIso8601String(), 'isLocked': 0 };
            await _db.insertNote(noteMap);
            await _db.attachNoteToNode(noteId: entry.id, title: title, parentId: _currentFolderId, tags: tags);
            _cache.invalidate(_cacheKeyNodes); _cache.invalidate(_cacheKeyNotes); _folderStatsCache = null;
            await _loadData(); return true;
          },
        ),
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📝 笔记已创建'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _createExploreTask() async {
    _closeFab();
    final tempNote = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '探究任务',
      content: '# 探究任务\n\n## 🎯 目标\n\n## 📋 步骤\n\n## 📎 参考资料\n\n',
      tags: ['探究'], updatedAt: DateTime.now(), editorMode: 'markdown',
    );
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: tempNote,
          isFromCollection: true,
          onSave: (entry, title, content, mode, tags) async {
            final noteMap = { 'id': entry.id, 'title': title, 'content': content, 'status': 'active', 'editorMode': mode, 'updatedAt': DateTime.now().toIso8601String(), 'isLocked': 0 };
            await _db.insertNote(noteMap);
            final task = Task(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, type: TaskType.explore, description: content, difficulty: Difficulty.medium, urgency: Urgency.medium, necessity: Necessity.important, noteId: entry.id);
            await _saveTask(task);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 探究任务已创建，可在「创作 → 任务」中查看'), duration: Duration(seconds: 2)));
            return true;
          },
        ),
      ),
    );
    if (result == true) { _cache.invalidate(_cacheKeyNodes); _cache.invalidate(_cacheKeyNotes); _folderStatsCache = null; await _loadData(); }
  }

  Future<void> _saveTask(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('tasks') ?? [];
    jsonList.add(jsonEncode(task.toJson()));
    await prefs.setStringList('tasks', jsonList);
  }

  Future<void> _createFolder() async {
    _closeFab();
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '请输入文件夹名称'), onSubmitted: (value) => Navigator.pop(context, value)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('创建')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _db.createFolder(title: result, parentId: _currentFolderId);
      _cache.invalidate(_cacheKeyNodes); _folderStatsCache = null; await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📁 文件夹已创建'), duration: Duration(seconds: 1)));
    }
  }

  void _toggleSelectMode() {
    setState(() { _isSelectMode = !_isSelectMode; if (!_isSelectMode) _selectedIds.clear(); });
  }

  void _closeFab() => setState(() => _fabExpanded = false);
  void _toggleSearch() => setState(() => _showSearchBar = !_showSearchBar);

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除 ${_selectedIds.length} 个项目吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      for (var id in _selectedIds) { await _db.deleteNode(id); }
      _selectedIds.clear(); setState(() => _isSelectMode = false);
      _cache.invalidate(_cacheKeyNodes); _folderStatsCache = null; await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已批量删除'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _batchMove() async {
    if (_selectedIds.isEmpty) return;
    final folders = _nodes.where((n) => n.isFolder).toList();
    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有可移动的目标文件夹'), duration: Duration(seconds: 1)));
      return;
    }
    String? selectedId;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到...'),
        content: SizedBox(
          width: 300, height: 300,
          child: ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final f = folders[index];
              return ListTile(
                title: Text(f.title), leading: const Icon(Icons.folder),
                selected: selectedId == f.id,
                onTap: () { selectedId = f.id; Navigator.pop(context, f.id); },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消'))],
      ),
    );
    if (selectedId != null) {
      for (var id in _selectedIds) { await _db.moveNode(id, selectedId); }
      _selectedIds.clear(); setState(() => _isSelectMode = false);
      _cache.invalidate(_cacheKeyNodes); _folderStatsCache = null; await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已批量移动'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _openNode(Node node) async {
    if (node.isFolder) { _navigateToFolder(node.id); return; }
    if (node.nodeType == 'note') {
      final note = await _db.getNoteByNodeId(node.id);
      if (note != null) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailPage(entry: note, nodeId: node.id)));
        _cache.invalidate(_cacheKeyNotes); await _loadData();
      }
    } else if (node.nodeType == 'book') {
      final book = await _db.getBookByNodeId(node.id);
      if (book != null) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(bookId: book.id, nodeId: node.id)));
        _cache.invalidate(_cacheKeyBooks); await _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(title: const Text('📚 智库'), centerTitle: true, elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black87),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isCardBoxView ? _buildCardBoxView() : _buildFolderView(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isCardBoxView ? '📇 卡片盒' : '📚 智库'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leading: _isCardBoxView
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _navigateToFolder(null), tooltip: '返回智库')
          : null,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearch, tooltip: '搜索'),
        IconButton(icon: const Icon(Icons.explore, color: Colors.purple), onPressed: _createExploreTask, tooltip: '探究任务'),
        IconButton(
          icon: const Icon(Icons.bubble_chart, color: Colors.teal),
          onPressed: _openClueBoard,
          tooltip: '🧩 线索墙',
        ),
      ],
    );
  }

  Widget _buildFolderView() {
    final children = _filteredNodes;
    final folderStats = _getFolderStats();
    final expiredFolder = _expiredFolder;
    final expiredCount = _expiredNoteCount;
    final libraryFolder = _libraryFolder;
    final libraryCount = _libraryBookCount;

    return Column(
      children: [
        _buildBreadcrumb(),
        const Divider(height: 1),
        if (_showSearchBar) _buildSearchBar(),
        WisdomToolbar(
          currentMode: _viewMode,
          onModeChanged: (mode) { setState(() => _viewMode = mode); },
          isSelectMode: _isSelectMode,
          onToggleSelectMode: _toggleSelectMode,
          selectedCount: _selectedIds.length,
          onBatchDelete: _batchDelete,
          onBatchMove: _batchMove,
        ),
        Expanded(
          child: children.isEmpty && expiredFolder == null && libraryFolder == null
              ? _buildEmptyState()
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: _viewMode == WisdomViewMode.split
                      ? _buildSplitView(children, folderStats, expiredFolder, expiredCount, libraryFolder, libraryCount)
                      : _buildGrid(children, folderStats, expiredFolder, expiredCount, libraryFolder, libraryCount),
                ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    final path = _breadcrumbPath;
    if (path.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(onTap: () => _navigateToFolder(null), child: const Text('📚 根目录', style: TextStyle(fontSize: 12, color: Colors.blue))),
            ...path.map((node) => Row(
              children: [
                const Text(' / ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                GestureDetector(
                  onTap: () => _navigateToFolder(node.id),
                  child: Text(node.title, style: TextStyle(fontSize: 12, color: node.id == _currentFolderId ? Colors.black87 : Colors.blue, fontWeight: node.id == _currentFolderId ? FontWeight.w600 : FontWeight.normal)),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: WisdomSearchBar(
        initialQuery: _searchKeyword,
        onChanged: (query) { setState(() { _searchKeyword = query; _cachedFilteredNodes = null; }); },
        onClear: () { setState(() { _searchKeyword = ''; _cachedFilteredNodes = null; _showSearchBar = false; }); },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shelves, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('这里空空如也', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('点击右下角 + 创建内容', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSplitView(
    List<Node> children,
    Map<String, Map<String, int>> folderStats,
    Node? expiredFolder,
    int expiredCount,
    Node? libraryFolder,
    int libraryCount,
  ) {
    final userFolders = _userFolders;

    return Row(
      children: [
        Container(
          width: 220,
          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
          child: ListView.builder(
            itemCount: userFolders.length + (expiredFolder != null ? 1 : 0) + (libraryFolder != null ? 1 : 0),
            itemBuilder: (context, index) {
              int offset = 0;
              if (libraryFolder != null) {
                if (index == 0) {
                  return _buildLibraryFolderTile(libraryFolder, libraryCount);
                }
                offset = 1;
              }
              final adjustedIndex = index - offset;
              if (expiredFolder != null && adjustedIndex == userFolders.length) {
                return _buildExpiredFolderTile(expiredFolder, expiredCount);
              }
              if (adjustedIndex >= userFolders.length) return const SizedBox.shrink();
              final folder = userFolders[adjustedIndex];
              final stats = folderStats[folder.id] ?? {};
              final total = stats['total'] ?? 0;
              return ListTile(
                title: Text(folder.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text('$total 个项目', style: TextStyle(fontSize: 10, color: Colors.grey)),
                selected: _currentFolderId == folder.id,
                onTap: () => _navigateToFolder(folder.id),
                leading: const Icon(Icons.folder, size: 18, color: Colors.orange),
                dense: true,
              );
            },
          ),
        ),
        Expanded(
          child: children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('选择左侧文件夹查看内容', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.8,
                  ),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final node = children[index];
                    return RepaintBoundary(child: _buildCard(node, folderStats));
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLibraryFolderTile(Node folder, int count) {
    return ListTile(
      title: Text(
        '📚 图书馆 ($count)',
        style: TextStyle(
          fontSize: 13,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '所有导入的图书',
        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
      ),
      selected: _currentFolderId == folder.id,
      onTap: () => _navigateToFolder(folder.id),
      leading: const Icon(Icons.library_books, size: 18, color: Colors.blue),
      dense: true,
    );
  }

  Widget _buildExpiredFolderTile(Node folder, int count) {
    return ListTile(
      title: Text(
        '🗂️ 灵感过期 ($count)',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: Text(
        '过期笔记自动归档于此',
        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
      ),
      selected: _currentFolderId == folder.id,
      onTap: () => _navigateToFolder(folder.id),
      leading: Icon(Icons.archive_outlined, size: 18, color: Colors.grey.shade500),
      dense: true,
    );
  }

  Widget _buildGrid(
    List<Node> children,
    Map<String, Map<String, int>> folderStats,
    Node? expiredFolder,
    int expiredCount,
    Node? libraryFolder,
    int libraryCount,
  ) {
    final crossAxisCount = _getCrossAxisCount();
    final aspectRatio = _getAspectRatio();

    List<Node> gridChildren = List.from(children);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: aspectRatio,
      ),
      itemCount: gridChildren.length,
      itemBuilder: (context, index) {
        final node = gridChildren[index];
        return RepaintBoundary(child: _buildCard(node, folderStats));
      },
    );
  }

  int _getCrossAxisCount() {
    switch (_viewMode) {
      case WisdomViewMode.list: return 1;
      case WisdomViewMode.grid: return 6;
      case WisdomViewMode.large: return 3;
      case WisdomViewMode.split: return 4;
    }
  }

  double _getAspectRatio() {
    switch (_viewMode) {
      case WisdomViewMode.list: return 4.0;
      case WisdomViewMode.grid: return 0.7;
      case WisdomViewMode.large: return 0.8;
      case WisdomViewMode.split: return 0.8;
    }
  }

  Widget _buildCard(Node node, Map<String, Map<String, int>> folderStats) {
    final cardWidth = 120.0;
    final cardHeight = 120.0;
    Widget cardContent;

    final isSystemFolder = node.isFolder && node.parentId == null &&
        (node.title == '图书馆' || node.title == '灵感过期' || node.title == '卡片盒' || node.title == '复盘');

    if (node.isFolder) {
      final stats = folderStats[node.id] ?? {};
      
      if (node.title == '图书馆') {
        final count = _libraryBookCount;
        cardContent = GestureDetector(
          onTap: () => _navigateToFolder(node.id),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books, size: 28, color: Colors.blue.shade700),
                  const SizedBox(height: 4),
                  Text(
                    '📚 图书馆',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '$count 本',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (node.title == '灵感过期') {
        final count = _expiredNoteCount;
        cardContent = GestureDetector(
          onTap: () => _navigateToFolder(node.id),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 28, color: Colors.grey.shade500),
                  const SizedBox(height: 4),
                  Text(
                    '🗂️ 灵感过期',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '$count 条',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        cardContent = WisdomFolderCard(
          node: node,
          isSelectMode: _isSelectMode,
          isSelected: _selectedIds.contains(node.id),
          onEnterFolder: () => _navigateToFolder(node.id),
          onCheckChanged: (checked) {
            setState(() { if (checked == true) {
              _selectedIds.add(node.id);
            } else {
              _selectedIds.remove(node.id);
            } });
          },
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          isDescendantOf: (a, b) => false,
          subFolderCount: stats['subFolders'] ?? 0,
          noteCount: stats['notes'] ?? 0,
          cardCount: stats['cards'] ?? 0,
          onDataChanged: () {
            _cache.invalidate(_cacheKeyNodes);
            _cache.invalidate(_cacheKeyNotes);
            _cache.invalidate(_cacheKeyBooks);
            _cache.invalidate(_cacheKeyCards);
            _folderStatsCache = null;
            _loadData();
          },
        );
      }
    } else if (node.nodeType == 'note') {
      cardContent = WisdomNoteCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onTap: () => _openNode(node),
        onCheckChanged: (checked) {
          setState(() { if (checked == true) {
            _selectedIds.add(node.id);
          } else {
            _selectedIds.remove(node.id);
          } });
        },
        cardWidth: cardWidth,
        cardHeight: cardHeight,
      );
    } else if (node.nodeType == 'book') {
      cardContent = WisdomBookCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onTap: () => _openNode(node),
        onCheckChanged: (checked) {
          setState(() { if (checked == true) {
            _selectedIds.add(node.id);
          } else {
            _selectedIds.remove(node.id);
          } });
        },
        cardWidth: cardWidth,
        cardHeight: cardHeight,
      );
    } else {
      cardContent = Container(
        width: cardWidth, height: cardHeight,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(node.iconEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(node.title, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (!_isSelectMode && !isSystemFolder) {
      return WisdomDraggable(
        node: node,
        child: cardContent,
        onDragEnd: () {
          _cache.invalidate(_cacheKeyNodes);
          _folderStatsCache = null;
          _loadData();
        },
      );
    }
    return cardContent;
  }

  Widget _buildCardBoxView() {
    return WisdomCardBox(
      cards: _cards,
      onSearch: (query) {},
      onCardTap: (card) => _showCardDetailDialog(card),
    );
  }

  void _showCardDetailDialog(CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(card.typeIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(card.typeLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            if (card.mastered) const Text('✅ 已掌握', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📖 正面', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(card.displayFront, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 背面', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(card.displayBack, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              if (card.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 4, children: card.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)).toList()),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('重要性：${card.importanceLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                  if (card.stage > 0) Text('阶段：${card.stageLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          if (!card.mastered)
            ElevatedButton(
              onPressed: () { Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              child: const Text('开始复习'),
            ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    if (_isCardBoxView) return const SizedBox.shrink();
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (_fabExpanded)
          Positioned.fill(
            child: GestureDetector(onTap: _closeFab, behavior: HitTestBehavior.translucent, child: Container(color: Colors.black.withValues(alpha: 0.3)))),
        AnimatedOpacity(
          opacity: _fabExpanded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Visibility(
            visible: _fabExpanded,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFabOption(icon: Icons.edit_note, label: '新建笔记', color: Colors.blue, onTap: _createNote),
                const SizedBox(height: 8),
                _buildFabOption(icon: Icons.create_new_folder, label: '新建文件夹', color: Colors.orange, onTap: _createFolder),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
          mini: true,
          backgroundColor: _fabExpanded ? Colors.grey.shade700 : Theme.of(context).primaryColor,
          tooltip: '创建',
          child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _fabExpanded ? const AlwaysStoppedAnimation(1) : const AlwaysStoppedAnimation(0), color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFabOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, color: color))],
        ),
      ),
    );
  }
}