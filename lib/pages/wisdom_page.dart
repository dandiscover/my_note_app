// lib/pages/wisdom_page.dart
// 📚 智库页面 — 统一“已归档”文件夹 + 修复卡片盒 UI 更新 + 空列表安全
// ✅ 新增：创建最小一步拐杖卡（异步保存）
// ✅ 新增：卡片详情弹窗支持删除卡片
// ✅ 修复：拐杖卡详情弹窗不显示“开始复习”按钮
// ✅ 删除：_createExploreTask 方法及 AppBar 中对应的按钮
// ✅ 删除：_taskService、_saveTask、_rootFolders、_libraryBookCount、_archivedNoteCount
// ✅ 删除：未使用的 import（dart:convert, shared_preferences, task, task_service）
// ✅ 删除：未使用的 getter（_libraryFolder、_archivedFolder）
// ✅ 适配：_createNote 中 onSave 回调增加 inquiryQuestion 参数
// ✅ 新增：Split 视图左侧递归文件夹树，支持展开/折叠
// ✅ 修改：_createNote 的 onSave 增加 exploreTasks 参数，并写入本地 noteMap
// ✅ 修改：_buildCard 的 note 分支增加 hasExplore 判断，并传给 WisdomNoteCard
// ✅ 新增：图书馆书籍状态筛选（全部/想读/在读/读完）
// ✅ 修改：WisdomBookCard 传入 Book 对象以显示来源标识
// ✅ 指导卡：_showCardDetailDialog 里，系统预置卡（system_guide_card）不显示“删除”按钮
// ✅ 第四轮批 1：搜索数据源改 DatabaseService.searchIndex()，不建新页（老白裁 A）
import 'dart:convert';
import 'richtext_editor_page.dart';
import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/node.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../services/cache_manager.dart';
import '../services/sync/cloud_sync_service.dart';
import '../services/sync/sync_manager.dart';
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
  final CacheManager _cache = CacheManager();

  List<Node> _nodes = [];
  List<NotebookEntry> _notes = [];
  List<Book> _books = [];
  List<CardModel> _cards = [];
  String? _currentFolderId;
  String _searchKeyword = '';
  // ✅ 第四轮批 1 新增：统一搜索结果（searchIndex() 返回的混合列表）
  // 依据老白裁 A：改搜索数据源为 searchIndex()，不建新页。
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};
  bool _showSearchBar = false;
  final Set<String> _expandedFolderIds = <String>{};

  WisdomViewMode _viewMode = WisdomViewMode.grid;
  bool _fabExpanded = false;

  // ✅ 图书状态筛选
  String _bookStatusFilter = 'all'; // all / want / reading / read

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

  Future<String> _ensureLibraryFolder() async {
    return await _db.ensureLibraryFolder();
  }

  Future<String> _ensureArchivedFolder() async {
    return await _db.ensureArchivedFolder();
  }

  Future<void> _migrateExpiredToArchived() async {
    await _db.migrateExpiredToArchived();
  }

  Future<void> _migrateOrphanBooks() async {
    final folderId = await _ensureLibraryFolder();
    if (folderId.isEmpty) return;

    final rootNodes = await _db.getRootNodes();
    final orphanBooks = rootNodes.where((n) => n.nodeType == 'book').toList();

    if (orphanBooks.isEmpty) return;

    for (var book in orphanBooks) {
      await _db.moveNode(book.id, folderId);
    }

    print('📚 已迁移 ${orphanBooks.length} 本图书到图书馆文件夹');
  }

  Future<void> _loadData() async {
    isLoading = true;
    try {
      await _migrateExpiredToArchived();
      await _ensureArchivedFolder();
      await _ensureLibraryFolder();
      await _db.ensureCardBoxFolder();
      await _migrateOrphanBooks();

      _cache.invalidate(_cacheKeyNodes);
      _cache.invalidate(_cacheKeyNotes);
      _cache.invalidate(_cacheKeyBooks);
      _cache.invalidate(_cacheKeyCards);
      _folderStatsCache = null;

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

      print('🎯 节点总数: ${nodes.length}');
      for (var n in nodes.where((n) => n.parentId == null)) {
        print('   根节点: ${n.title} | id=${n.id} | isFolder=${n.isFolder} | isSystemFolder=${n.isSystemFolder}');
      }

      setState(() {
        _nodes = nodes;
        _notes = notes;
        _books = books;
        _cards = cards;
        _cachedFilteredNodes = null;
        _folderStatsCache = null;
      });
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
        if (child.isFolder) subFolderCount++;
        else if (child.nodeType == 'note') { noteCount++; if (cardSourceIds.contains(child.targetId)) cardCount++; }
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

  bool get _isCardBoxView {
    if (_currentFolderId == null) return false;
    final node = _nodes.firstWhere(
      (n) => n.id == _currentFolderId,
      orElse: () => Node.empty,
    );
    if (node.id.isEmpty) return false;
    return node.title == '卡片盒' && node.isFolder && node.parentId == null;
  }

  /// 判断当前文件夹是否为图书馆
  bool get _isLibraryFolder {
    if (_currentFolderId == null) return false;
    final node = _nodes.firstWhere(
      (n) => n.id == _currentFolderId,
      orElse: () => Node.empty,
    );
    if (node.id.isEmpty) return false;
    return node.title == '图书馆' && node.isFolder && node.parentId == null;
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

  List<Node> get _userFolders {
    return _nodes.where((n) =>
      n.isFolder &&
      n.parentId == null &&
      n.title != '图书馆' &&
      n.title != '已归档' &&
      n.title != '卡片盒' &&
      n.title != '复盘'
    ).toList();
  }

  List<Map<String, dynamic>> get _systemFolders {
    final result = <Map<String, dynamic>>[];
    for (var node in _nodes) {
      if (node.isFolder && node.parentId == null) {
        if (node.title == '图书馆') {
          final count = _nodes.where((n) => n.parentId == node.id && n.nodeType == 'book').length;
          result.add({
            'node': node,
            'type': 'library',
            'count': count,
          });
        } else if (node.title == '已归档') {
          final count = _nodes.where((n) => n.parentId == node.id && !n.isFolder).length;
          result.add({
            'node': node,
            'type': 'archived',
            'count': count,
          });
        } else if (node.title == '卡片盒') {
          result.add({
            'node': node,
            'type': 'cardbox',
            'count': _cards.length,
          });
        }
      }
    }
    return result;
  }

  void _navigateToFolder(String? folderId) {
    setState(() { _currentFolderId = folderId; _cachedFilteredNodes = null; _searchKeyword = ''; _showSearchBar = false; });
  }

  void _openClueBoard() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WritingPage(initialViewMode: WritingViewMode.clueBoard)));
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
      final folder = await _db.createFolder(title: result, parentId: _currentFolderId);
      _cache.invalidate(_cacheKeyNodes); _folderStatsCache = null; await _loadData();
      if (CloudSyncService().isLoggedIn) {
        try {
          await CloudSyncService().syncNode(folder);
        } catch (_) {
          SyncManager().markDirty();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📁 文件夹已创建'), duration: Duration(seconds: 1)));
    }
  }

  // ✅ 修改：_createNote 中 onSave 增加 exploreTasks 参数，并写入 noteMap
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
          onSave: (entry, title, content, mode, tags, inquiryQuestion, exploreTasks) async {
            final noteMap = {
              'id': entry.id,
              'title': title,
              'content': content,
              'status': 'active',
              'editorMode': mode,
              'updatedAt': DateTime.now().toIso8601String(),
              'isLocked': 0,
              'inquiryQuestion': inquiryQuestion,
              'exploreTasks': exploreTasks.map((e) => e.toJson()).toList(),
            };
            await _db.insertNote(noteMap);
            final node = await _db.attachNoteToNode(
              noteId: entry.id,
              title: title,
              parentId: _currentFolderId,
              tags: tags,
            );
            _cache.invalidate(_cacheKeyNodes);
            _cache.invalidate(_cacheKeyNotes);
            _folderStatsCache = null;
            await _loadData();
            if (CloudSyncService().isLoggedIn) {
              try {
                final note = NotebookEntry.fromMap(noteMap);
                await CloudSyncService().syncNote(note);
                if (node != null) await CloudSyncService().syncNode(node);
              } catch (_) {
                SyncManager().markDirty();
              }
            }
            return true;
          },
        ),
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📝 笔记已创建'), duration: Duration(seconds: 1)));
    }
  }
  // ✅ 第三轮：新建富文本笔记（进 RichtextEditorPage）
  //
  // 按老白裁 2：
  //   - 新建空 richtext 笔记（contentFormat='richtext'）
  //   - 挂到当前文件夹
  //   - 进 RichtextEditorPage
  //   - 不做 Markdown 升级；不做"切换笔记类型"
  Future<void> _createRichtextNote() async {
    _closeFab();
    final newEntry = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '无标题',
      content: jsonEncode({'version': 2, 'blocks': <dynamic>[]}),
      updatedAt: DateTime.now(),
      status: 'active',
      editorMode: 'plain',
      contentFormat: 'richtext',
    );
    await _db.insertNote(newEntry.toMap());
    await _db.attachNoteToNode(
      noteId: newEntry.id,
      title: newEntry.title,
      parentId: _currentFolderId,
      tags: const [],
    );
    _cache.invalidate(_cacheKeyNodes);
    _cache.invalidate(_cacheKeyNotes);
    _folderStatsCache = null;
    await _loadData();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RichtextEditorPage(entry: newEntry),
      ),
    );
    await _loadData();
  }
  Future<void> _createMinimalStepCard() async {
    final card = CardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardType: CardType.review,
      sourceType: 'manual',
      sourceId: 'scaffold_manual',
      sourceTitle: '最小一步卡',
      kind: CardKind.scaffold,
      tags: ['拐杖', '最小一步'],
      front: '最小一步卡',
      back: '三个问题：\n1. 现在最困扰我的是什么？\n2. 我能做的最小一步是什么？\n3. 做完这一步会怎样？',
      stage: 0,
      nextReviewDate: DateTime.now(),
    );

    await _cardService.addCard(card);
    setState(() {
      _cards = [..._cards, card];
    });
    _cache.invalidate(_cacheKeyCards);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🧩 最小一步卡已创建')),
    );
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
        content: SizedBox(width: 300, height: 300, child: ListView.builder(
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final f = folders[index];
            return ListTile(
              title: Text(f.title), leading: const Icon(Icons.folder),
              selected: selectedId == f.id,
              onTap: () { selectedId = f.id; Navigator.pop(context, f.id); },
            );
          },
        )),
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

  // ─── 图书筛选栏 ──────────────────────────────────

  Widget _buildBookFilterBar() {
    final Map<String, String> filterMap = {
      'all': '全部',
      'want': '想读',
      'reading': '在读',
      'read': '读完',
    };
    final filters = ['all', 'want', 'reading', 'read'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((key) {
            final isSelected = _bookStatusFilter == key;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(filterMap[key] ?? key),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _bookStatusFilter = key;
                  });
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.grey.shade50,
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 对 children 应用书籍状态筛选（仅当在图书馆文件夹时生效）
  List<Node> _applyBookFilter(List<Node> nodes) {
    if (!_isLibraryFolder || _bookStatusFilter == 'all') return nodes;
    return nodes.where((node) {
      // 非书籍节点保留
      if (node.nodeType != 'book') return true;
      final book = _books.firstWhere(
        (b) => b.id == node.targetId,
        orElse: () => Book.empty,
      );
      return book.status == _bookStatusFilter;
    }).toList();
  }

  // ─── UI ──────────────────────────────────

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
      leading: _isCardBoxView ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _navigateToFolder(null), tooltip: '返回智库') : null,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: _toggleSearch, tooltip: '搜索'),
        IconButton(icon: const Icon(Icons.bubble_chart, color: Colors.teal), onPressed: _openClueBoard, tooltip: '🧩 线索墙'),
      ],
    );
  }

  Widget _buildFolderView() {
    final children = _filteredNodes;
    final folderStats = _getFolderStats();
    final systemFolders = _systemFolders;

    // ✅ 第四轮批 1 新增：搜索态优先——搜索框开 + 关键词非空
    final isSearching = _showSearchBar && _searchKeyword.trim().isNotEmpty;

    return Column(
      children: [
        _buildBreadcrumb(),
        const Divider(height: 1),
        if (_showSearchBar) _buildSearchBar(),
        // 搜索态不显示工具栏 / 图书筛选栏（这些作用于节点树，与全库搜索无关）
        if (!isSearching) ...[
          WisdomToolbar(
            currentMode: _viewMode,
            onModeChanged: (mode) { setState(() => _viewMode = mode); },
            isSelectMode: _isSelectMode,
            onToggleSelectMode: _toggleSelectMode,
            selectedCount: _selectedIds.length,
            onBatchDelete: _batchDelete,
            onBatchMove: _batchMove,
          ),
          if (_isLibraryFolder) _buildBookFilterBar(),
        ],
        Expanded(
          child: isSearching
              ? _buildSearchResults()
              : (children.isEmpty && systemFolders.isEmpty
                  ? _buildEmptyState()
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: _viewMode == WisdomViewMode.split
                          ? _buildSplitView(children, folderStats, systemFolders)
                          : _buildContentView(children, folderStats, systemFolders),
                    )),
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
        onChanged: (query) {
          setState(() {
            _searchKeyword = query;
            _cachedFilteredNodes = null;
          });
          _runSearch(query);
        },
        onClear: () {
          setState(() {
            _searchKeyword = '';
            _cachedFilteredNodes = null;
            _showSearchBar = false;
            _searchResults = [];
          });
        },
      ),
    );
  }

  /// 第四轮批 1 新增：调 DatabaseService.searchIndex() 拿混合结果。
  ///
  /// 连续输入会连续调用；查询串变化时丢弃过期结果（防乱序）。
  /// 本轮不做防抖——最小实现。若真机发现抖动明显，再补 Timer debounce。
  Future<void> _runSearch(String query) async {
    final kw = query.trim();
    if (kw.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final results = await _db.searchIndex(kw);
      if (!mounted) return;
      // 查询串已变，丢弃过期结果
      if (_searchKeyword.trim() != kw) return;
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('searchIndex 失败: $e');
    }
  }

  /// 第四轮批 1 新增：渲染统一搜索结果（searchIndex() 返回的混合列表）。
  ///
  /// 每条按 kind 显示图标 / 颜色 / 类型标签。
  /// 点击 → _openSearchResult() 分流跳转。
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('无匹配结果', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final row = _searchResults[index];
        final kind = row['kind'] as String? ?? '';
        final rawText = (row['rawText'] as String?) ?? '';
        final searchText = (row['searchText'] as String?) ?? '';

        final (IconData icon, Color color, String label) = switch (kind) {
          'note_text' => (Icons.note, Colors.blue, '笔记'),
          'note_tag' => (Icons.label, Colors.purple, '标记'),
          'book_highlight' => (Icons.highlight, Colors.amber, '高亮'),
          'book_annotation' => (Icons.chat_bubble_outline, Colors.teal, '批注'),
          _ => (Icons.search, Colors.grey, '结果'),
        };

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              rawText.isEmpty ? searchText : rawText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(label,
                style: TextStyle(fontSize: 11, color: color)),
            onTap: () => _openSearchResult(row),
          ),
        );
      },
    );
  }

  /// 第四轮批 1 新增：搜索结果点击跳转。
  ///
  /// 依据老白裁 C：搜索跳转只打开书，不定位章节。
  /// 实现方式：反查 Node（_nodes 是全库的），复用现有 _openNode()。
  Future<void> _openSearchResult(Map<String, dynamic> row) async {
    final sourceType = row['sourceType'] as String? ?? '';
    final sourceId = row['sourceId'] as String? ?? '';
    if (sourceId.isEmpty) return;

    final Node node;
    if (sourceType == 'note') {
      node = _nodes.firstWhere(
        (n) => n.nodeType == 'note' && n.targetId == sourceId,
        orElse: () => Node.empty,
      );
    } else if (sourceType == 'book') {
      node = _nodes.firstWhere(
        (n) => n.nodeType == 'book' && n.targetId == sourceId,
        orElse: () => Node.empty,
      );
    } else {
      return;
    }
    if (node.id.isEmpty) return;

    await _openNode(node);
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

  // ─── Split 视图左侧递归树 ──────────────────────────────

  Widget _buildSplitView(List<Node> children, Map<String, Map<String, int>> folderStats, List<Map<String, dynamic>> systemFolders) {
    // ✅ 应用书籍状态筛选
    final filteredChildren = _applyBookFilter(children);

    return Row(
      children: [
        Container(
          width: 220,
          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
          child: ListView(
            children: [
              ..._buildUserFolderTreeItems(),
              if (_systemFolders.isNotEmpty) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('系统', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey)),
                ),
                ..._systemFolders.map((sys) {
                  final node = sys['node'] as Node;
                  final type = sys['type'] as String;
                  final count = sys['count'] as int;
                  return _buildSystemFolderTile(node, type, count);
                }).toList(),
              ],
            ],
          ),
        ),
        Expanded(
          child: filteredChildren.isEmpty
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
              : _buildContentGrid(filteredChildren, folderStats),
        ),
      ],
    );
  }

  List<Widget> _buildUserFolderTreeItems() {
    final items = <Widget>[];
    for (final folder in _userFolders) {
      items.addAll(_buildFolderTreeItems(folder, 0));
    }
    return items;
  }

  List<Widget> _buildFolderTreeItems(Node folder, int depth) {
    final items = <Widget>[];
    final subFolders = _nodes.where((n) => n.isFolder && n.parentId == folder.id).toList();
    final isExpanded = _expandedFolderIds.contains(folder.id);
    final hasChildren = subFolders.isNotEmpty;
    final isSelected = _currentFolderId == folder.id;

    items.add(
      ListTile(
        dense: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: depth * 16.0),
            if (hasChildren)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedFolderIds.remove(folder.id);
                    } else {
                      _expandedFolderIds.add(folder.id);
                    }
                  });
                },
                child: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              )
            else
              const SizedBox(width: 18),
            const SizedBox(width: 4),
            const Icon(Icons.folder, size: 18, color: Colors.orange),
          ],
        ),
        title: Text(
          folder.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.purple : Colors.black87,
          ),
        ),
        selected: isSelected,
        onTap: () => _navigateToFolder(folder.id),
      ),
    );

    if (isExpanded) {
      for (final sub in subFolders) {
        items.addAll(_buildFolderTreeItems(sub, depth + 1));
      }
    }

    return items;
  }

  Widget _buildSystemFolderTile(Node node, String type, int count) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'library':
        icon = Icons.library_books;
        color = Colors.blue;
        label = '📚 图书馆 ($count 本)';
        break;
      case 'archived':
        icon = Icons.archive_outlined;
        color = Colors.grey;
        label = '📦 已归档 ($count 条)';
        break;
      case 'cardbox':
        icon = Icons.grid_view;
        color = Colors.purple;
        label = '📇 卡片盒 ($count 张)';
        break;
      default:
        icon = Icons.folder;
        color = Colors.grey;
        label = node.title;
    }

    return ListTile(
      dense: true,
      title: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      subtitle: Text(
        type == 'library' ? '所有导入的电子书' : type == 'archived' ? '所有已归档的笔记' : '所有复习卡片',
        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
      ),
      selected: _currentFolderId == node.id,
      onTap: () => _navigateToFolder(node.id),
      leading: Icon(icon, size: 18, color: color),
    );
  }

  // ─── 内容视图 ──────────────────────────────────────────

  Widget _buildContentView(List<Node> children, Map<String, Map<String, int>> folderStats, List<Map<String, dynamic>> systemFolders) {
    final allItems = <Widget>[];

    if (_currentFolderId == null) {
      for (var sys in systemFolders) {
        final node = sys['node'] as Node;
        final type = sys['type'] as String;
        final count = sys['count'] as int;
        allItems.add(_buildSystemFolderCard(node, type, count));
      }
    }

    // ✅ 应用书籍状态筛选
    final filteredChildren = _applyBookFilter(children);
    final nonSystemChildren = filteredChildren.where((n) => !n.isSystemFolder).toList();

    if (nonSystemChildren.isNotEmpty) {
      if (_viewMode == WisdomViewMode.list) {
        for (var node in nonSystemChildren) {
          allItems.add(_buildListItem(node, folderStats));
        }
      } else {
        allItems.addAll(nonSystemChildren.map((node) => _buildCard(node, folderStats)));
      }
    }

    if (allItems.isEmpty) {
      return _buildEmptyState();
    }

    if (_viewMode == WisdomViewMode.list) {
      return ListView(
        children: allItems,
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: _getAspectRatio(),
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) => allItems[index],
    );
  }

  Widget _buildContentGrid(List<Node> children, Map<String, Map<String, int>> folderStats) {
    // ✅ 应用书籍状态筛选
    final filteredChildren = _applyBookFilter(children);
    final nonSystemChildren = filteredChildren.where((n) => !n.isSystemFolder).toList();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: _getAspectRatio(),
      ),
      itemCount: nonSystemChildren.length,
      itemBuilder: (context, index) {
        final node = nonSystemChildren[index];
        return RepaintBoundary(child: _buildCard(node, folderStats));
      },
    );
  }

  Widget _buildSystemFolderCard(Node node, String type, int count) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case 'library':
        icon = Icons.library_books;
        color = Colors.blue;
        label = '📚 图书馆 ($count 本)';
        break;
      case 'archived':
        icon = Icons.archive_outlined;
        color = Colors.grey;
        label = '📦 已归档 ($count 条)';
        break;
      case 'cardbox':
        icon = Icons.grid_view;
        color = Colors.purple;
        label = '📇 卡片盒 ($count 张)';
        break;
      default:
        icon = Icons.folder;
        color = Colors.grey;
        label = node.title;
    }

    return GestureDetector(
      onTap: () => _navigateToFolder(node.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(Node node, Map<String, Map<String, int>> folderStats) {
    final isFolder = node.isFolder;
    final stats = folderStats[node.id] ?? {};

    String subtitle = '';
    IconData leadingIcon = Icons.insert_drive_file;
    Color iconColor = Colors.grey;

    if (isFolder) {
      leadingIcon = Icons.folder;
      iconColor = Colors.orange;
      final total = stats['total'] ?? 0;
      final subFolders = stats['subFolders'] ?? 0;
      final notes = stats['notes'] ?? 0;
      final books = stats['books'] ?? 0;
      final parts = <String>[];
      if (subFolders > 0) parts.add('$subFolders 个文件夹');
      if (notes > 0) parts.add('$notes 篇笔记');
      if (books > 0) parts.add('$books 本图书');
      subtitle = parts.isNotEmpty ? parts.join(' · ') : '空文件夹';
    } else if (node.nodeType == 'note') {
      leadingIcon = Icons.note;
      iconColor = Colors.blue;
      final note = _notes.firstWhere(
        (n) => n.id == node.targetId,
        orElse: () => NotebookEntry.empty,
      );
      subtitle = note.content.length > 80 ? '${note.content.substring(0, 80)}...' : note.content;
      if (subtitle.isEmpty) subtitle = '无内容';
    } else if (node.nodeType == 'book') {
      leadingIcon = Icons.book;
      iconColor = Colors.green;
      final book = _books.firstWhere(
        (b) => b.id == node.targetId,
        orElse: () => Book.empty,
      );
      subtitle = '📄 ${book.fileType.toUpperCase()} · ${book.author.isNotEmpty ? book.author : '未知作者'}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(leadingIcon, color: iconColor, size: 32),
        title: Text(
          node.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.tags.first,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
        onTap: isFolder ? () => _navigateToFolder(node.id) : () => _openNode(node),
        onLongPress: () {
          if (!_isSelectMode) {
            setState(() {
              _isSelectMode = true;
              _selectedIds.add(node.id);
            });
          }
        },
      ),
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

    if (node.isFolder) {
      final stats = folderStats[node.id] ?? {};
      cardContent = WisdomFolderCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onEnterFolder: () => _navigateToFolder(node.id),
        onCheckChanged: (checked) { setState(() { if (checked == true) _selectedIds.add(node.id); else _selectedIds.remove(node.id); }); },
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
    } else if (node.nodeType == 'note') {
      // ✅ 修改：通过 _notes 查 note，计算 hasExplore
      final note = _notes.firstWhere(
        (n) => n.id == node.targetId,
        orElse: () => NotebookEntry.empty,
      );
      final hasExplore = note.exploreTasks.isNotEmpty && note.inquiryConclusion == null;
      cardContent = WisdomNoteCard(
        node: node,
        hasExplore: hasExplore,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onTap: () => _openNode(node),
        onCheckChanged: (checked) { setState(() { if (checked == true) _selectedIds.add(node.id); else _selectedIds.remove(node.id); }); },
        cardWidth: cardWidth,
        cardHeight: cardHeight,
      );
    } else if (node.nodeType == 'book') {
      // ✅ 修改：传入 Book 对象
      final book = _books.firstWhere(
        (b) => b.id == node.targetId,
        orElse: () => Book.empty,
      );
      cardContent = WisdomBookCard(
        node: node,
        book: book.id.isNotEmpty ? book : null,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onTap: () => _openNode(node),
        onCheckChanged: (checked) { setState(() { if (checked == true) _selectedIds.add(node.id); else _selectedIds.remove(node.id); }); },
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

    if (!_isSelectMode) {
      return WisdomDraggable(node: node, child: cardContent, onDragEnd: () { _cache.invalidate(_cacheKeyNodes); _folderStatsCache = null; _loadData(); });
    }
    return cardContent;
  }

  Widget _buildCardBoxView() {
    return WisdomCardBox(
      cards: _cards,
      onSearch: (query) {},
      onCardTap: (card) => _showCardDetailDialog(card),
      onAddScaffold: () => _createMinimalStepCard(),
    );
  }

  void _showCardDetailDialog(CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Text(card.typeIcon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Expanded(child: Text(card.typeLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))), if (card.mastered) const Text('✅ 已掌握', style: TextStyle(fontSize: 12, color: Colors.green))]),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('📖 正面', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(card.displayFront, style: const TextStyle(fontSize: 16))])),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('💡 背面', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(card.displayBack, style: const TextStyle(fontSize: 16))])),
              if (card.tags.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 4, children: card.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)).toList())],
              const SizedBox(height: 8),
              Row(children: [Text('重要性：${card.importanceLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(width: 16), if (card.stage > 0) Text('阶段：${card.stageLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]),
            ],
          ),
        ),
        actions: [
          // ✅ 指导卡：系统预置卡（system_guide_card）不显示“删除”按钮
          if (card.id != 'system_guide_card')
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除卡片'),
                    content: const Text('确定要删除这张卡片吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  Navigator.pop(context);
                  await _cardService.deleteCard(card.id);
                  _cache.invalidate(_cacheKeyCards);
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🗑️ 卡片已删除')),
                  );
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          if (card.kind == CardKind.atomic && !card.mastered)
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
            child: GestureDetector(
              onTap: _closeFab,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
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
                // ✅ 第三轮：新建富文本笔记（老白裁 2 + 图标 Icons.article_outlined）
                _buildFabOption(icon: Icons.article_outlined, label: '新建富文本笔记', color: Colors.teal, onTap: _createRichtextNote),
                const SizedBox(height: 8),
                _buildFabOption(icon: Icons.create_new_folder, label: '新建文件夹', color: Colors.orange, onTap: _createFolder),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'wisdom_fab',
          onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
          mini: true,
          backgroundColor: _fabExpanded ? Colors.grey.shade700 : Theme.of(context).primaryColor,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabExpanded ? const AlwaysStoppedAnimation(1) : const AlwaysStoppedAnimation(0),
            color: Colors.white,
          ),
          tooltip: '创建',
        ),
      ],
    );
  }

  Widget _buildFabOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, color: color))]),
      ),
    );
  }
}