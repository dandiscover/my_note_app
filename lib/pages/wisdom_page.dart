import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../database_service.dart';
import '../models/node.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../widgets/folder_selector_dialog.dart';
import '../widgets/wisdom/wisdom_light_toast.dart';
import '../widgets/wisdom/wisdom_breadcrumb.dart';
import '../widgets/wisdom/wisdom_folder_card.dart';
import '../widgets/wisdom/wisdom_note_card.dart';
import '../widgets/wisdom/wisdom_book_card.dart';
import '../widgets/wisdom/wisdom_default_card.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';

class WisdomPage extends StatefulWidget {
  const WisdomPage({super.key});

  @override
  State<WisdomPage> createState() => WisdomPageState();
}

class WisdomPageState extends State<WisdomPage> {
  final DatabaseService _db = DatabaseService();

  String? _currentFolderId;
  List<Node> _children = [];
  List<Node> _breadcrumb = [];
  List<Node> _allNodesCache = [];
  bool _isLoading = true;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchingLoading = false;

  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  bool _isDragging = false;
  Offset? _dragStart;
  Offset? _dragEnd;
  final GlobalKey _gridKey = GlobalKey();

  String? _dragTargetId;
  bool _isDraggingToBack = false;

  static const double _cardAspectRatio = 0.707;
  static const double _gridSpacing = 8.0;
  static const int _crossAxisCount = 6;

  static const List<Color> _cardColors = [
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
    Color(0xFFF3E5F5),
    Color(0xFFE0F7FA),
    Color(0xFFFFEBEE),
    Color(0xFFE8EAF6),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void refreshData() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (_currentFolderId == null) {
        await _db.ensureRootNodesExist();
      }

      final children = await _db.getChildren(_currentFolderId);
      final List<Node> breadcrumb = _currentFolderId != null
          ? await _db.getAncestors(_currentFolderId!)
          : [];

      _allNodesCache = await _db.getAllNodes();

      if (!mounted) return;
      setState(() {
        _children = children;
        _breadcrumb = breadcrumb;
        _isLoading = false;
        _isDragging = false;
        _dragStart = null;
        _dragEnd = null;
      });
    } catch (e) {
      print('加载智库数据失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isDescendantOf(String nodeId, String ancestorId) {
    if (nodeId == ancestorId) return true;
    final nodeMap = {for (var n in _allNodesCache) n.id: n};
    String? currentId = nodeId;
    while (currentId != null) {
      final node = nodeMap[currentId];
      if (node == null) break;
      if (node.parentId == ancestorId) return true;
      currentId = node.parentId;
    }
    return false;
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 24.0 * 2 + 12.0 * 2;
    final totalSpacing = _gridSpacing * (_crossAxisCount - 1);
    return (screenWidth - padding - totalSpacing) / _crossAxisCount;
  }

  double _getCardHeight(BuildContext context) {
    return _getCardWidth(context) / _cardAspectRatio;
  }

  void _onSearchChanged() => _performSearch(_searchController.text);

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearchingLoading = false; });
      return;
    }
    setState(() => _isSearchingLoading = true);
    try {
      final results = await _db.searchNodes(query);
      if (!mounted) return;
      setState(() { _searchResults = results; _isSearchingLoading = false; });
    } catch (e) {
      print('搜索失败: $e');
      if (mounted) setState(() => _isSearchingLoading = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchResults = [];
        if (_isSelectMode) _exitSelectMode();
      }
    });
  }

  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _selectedIds.clear();
      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        _searchResults = [];
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
      _isDragging = false;
      _dragStart = null;
      _dragEnd = null;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _children.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_children.map((n) => n.id));
      }
    });
  }

  void _toggleSelectNode(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  void _updateSelectionFromDrag() {
    if (_dragStart == null || _dragEnd == null) return;

    final renderBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final start = _dragStart!;
    final end = _dragEnd!;
    final left = start.dx < end.dx ? start.dx : end.dx;
    final top = start.dy < end.dy ? start.dy : end.dy;
    final right = start.dx > end.dx ? start.dx : end.dx;
    final bottom = start.dy > end.dy ? start.dy : end.dy;

    final cardWidth = _getCardWidth(context);
    final cardHeight = _getCardHeight(context);
    final padding = 12.0;
    final spacing = _gridSpacing;
    final cols = _crossAxisCount;

    final selected = <String>{};
    for (int i = 0; i < _children.length; i++) {
      final row = i ~/ cols;
      final col = i % cols;
      final x = padding + col * (cardWidth + spacing);
      final y = padding + row * (cardHeight + spacing);
      final rect = Rect.fromLTWH(x, y, cardWidth, cardHeight);
      final selectionRect = Rect.fromLTWH(left, top, right - left, bottom - top);
      if (selectionRect.overlaps(rect)) {
        selected.add(_children[i].id);
      }
    }

    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(selected);
      if (_selectedIds.isNotEmpty && !_isSelectMode) {
        _isSelectMode = true;
      }
    });
  }

  Future<void> _batchMove() async {
    if (_selectedIds.isEmpty) return;
    final targetFolderId = await showDialog<String>(
      context: context,
      builder: (context) => FolderSelectorDialog(
        excludeNodeId: _selectedIds.length == 1 ? _selectedIds.first : null,
      ),
    );
    if (targetFolderId == null) return;
    setState(() => _isLoading = true);
    try {
      await _db.batchMoveNodes(_selectedIds.toList(), targetFolderId);
      _exitSelectMode();
      await _loadData();
      _showLightToast('✅ 已移动 ${_selectedIds.length} 项');
    } catch (e) {
      print('批量移动失败: $e');
      _showLightToast('❌ 移动失败');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认批量删除'),
        content: Text('确定要永久删除 ${_selectedIds.length} 项内容吗？\n此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await _db.batchDeleteNodes(_selectedIds.toList());
      _exitSelectMode();
      await _loadData();
      _showLightToast('✅ 已删除 ${_selectedIds.length} 项');
    } catch (e) {
      print('批量删除失败: $e');
      _showLightToast('❌ 删除失败');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _enterFolder(String folderId) {
    setState(() { _currentFolderId = folderId; if (_isSelectMode) _exitSelectMode(); });
    _loadData();
  }

  void _goBack() {
    if (_breadcrumb.isNotEmpty) {
      final parentId = _breadcrumb.length > 1 ? _breadcrumb[_breadcrumb.length - 2].id : null;
      setState(() { _currentFolderId = parentId; if (_isSelectMode) _exitSelectMode(); });
      _loadData();
    }
  }

  void _goToBreadcrumb(int index) {
    if (index >= _breadcrumb.length - 1) return;
    setState(() { _currentFolderId = _breadcrumb[index].id; if (_isSelectMode) _exitSelectMode(); });
    _loadData();
  }

  Future<void> _onMoveNode(String nodeId, String? newParentId) async {
    await _db.moveNode(nodeId, newParentId);
    await _loadData();
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '输入文件夹名称', border: OutlineInputBorder()), onSubmitted: (_) => Navigator.pop(context, true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('创建')),
        ],
      ),
    );
    if (result == true) {
      final title = controller.text.trim();
      if (title.isNotEmpty) {
        await _db.createFolder(title: title, parentId: _currentFolderId);
        await _loadData();
        _showLightToast('📁 已创建「$title」');
      }
    }
  }

  Future<void> _createNote() async {
    final noteId = DateTime.now().millisecondsSinceEpoch.toString();
    final note = NotebookEntry(
      id: noteId,
      title: '无标题',
      content: '',
      updatedAt: DateTime.now(),
      status: 'active',
      editorMode: 'plain',
      tags: [],
    );
    await _db.insertNote(note.toMap());
    final node = await _db.attachNoteToNode(
      noteId: noteId,
      title: '无标题',
      parentId: _currentFolderId,
      tags: [],
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(
          entry: note,
          isFromCollection: false,
          nodeId: node.id,
          currentNodeId: _currentFolderId,
        ),
      ),
    );
    await _loadData();
  }

  void _showLightToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
    );
  }

  String get _currentFolderName => _breadcrumb.isEmpty ? '📚 智库' : _breadcrumb.last.title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomSheet: _isSelectMode && _selectedIds.isNotEmpty ? _buildBottomActionBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: _toggleSearch),
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '搜索笔记、图书、文件夹...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              IconButton(icon: const Icon(Icons.clear, color: Colors.black87), onPressed: () => _searchController.clear()),
          ],
        ),
      );
    }

    return AppBar(
      title: Text(_currentFolderName),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leading: _breadcrumb.isNotEmpty
          ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: _goBack, tooltip: '返回上级')
          : null,
      actions: [
        IconButton(icon: const Icon(Icons.search, color: Colors.black87), onPressed: _toggleSearch, tooltip: '搜索'),
        _isSelectMode
            ? IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: _exitSelectMode, tooltip: '退出多选')
            : IconButton(icon: const Icon(Icons.checklist_outlined, color: Colors.black87), onPressed: _enterSelectMode, tooltip: '多选操作'),
        IconButton(icon: const Icon(Icons.note_add_outlined, color: Colors.black87), onPressed: _createNote, tooltip: '新建笔记'),
        IconButton(icon: const Icon(Icons.create_new_folder_outlined, color: Colors.black87), onPressed: _createFolder, tooltip: '新建文件夹'),
        IconButton(icon: const Icon(Icons.refresh, color: Colors.black87), onPressed: _loadData, tooltip: '刷新'),
      ],
    );
  }

  // ✅ 核心改动：GestureDetector 替代 MouseRegion，支持拖拽多选
  Widget _buildBody() {
    if (_isSearching) return _buildSearchResults();
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final isRoot = _breadcrumb.isEmpty;
    final bgColor = isRoot ? Colors.grey.shade50 : Colors.blue.shade50;

    if (_children.isEmpty) {
      return Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_breadcrumb.isEmpty ? Icons.auto_stories : Icons.folder_open, size: 56, color: Colors.grey),
              const SizedBox(height: 14),
              Text(_breadcrumb.isEmpty ? '智库还是空的' : '此文件夹为空', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(_breadcrumb.isEmpty ? '点击右上角「+」新建笔记或文件夹' : '点击右上角「+」新建内容', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              if (_breadcrumb.isEmpty)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton.icon(onPressed: _createNote, icon: const Icon(Icons.note_add, size: 18), label: const Text('新建笔记')),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(onPressed: _createFolder, icon: const Icon(Icons.create_new_folder, size: 18), label: const Text('新建文件夹')),
                ]),
            ],
          ),
        ),
      );
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_breadcrumb.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: WisdomBreadcrumb(
                breadcrumb: _breadcrumb,
                onMoveNode: _onMoveNode,
                onGoRoot: () { setState(() { _currentFolderId = null; if (_isSelectMode) _exitSelectMode(); }); _loadData(); },
                onGoToBreadcrumb: _goToBreadcrumb,
                isDescendantOf: _isDescendantOf,
              ),
            ),
          Expanded(
            // ✅ 使用 GestureDetector 支持拖拽多选
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                if (_isSelectMode) return;
                setState(() {
                  _isDragging = true;
                  _dragStart = details.localPosition;
                  _dragEnd = details.localPosition;
                  _selectedIds.clear();
                });
              },
              onPanUpdate: (details) {
                if (!_isDragging) return;
                setState(() {
                  _dragEnd = details.localPosition;
                });
                _updateSelectionFromDrag();
              },
              onPanEnd: (details) {
                if (_isDragging && _selectedIds.isNotEmpty) {
                  setState(() {
                    _isSelectMode = true;
                  });
                }
                setState(() {
                  _isDragging = false;
                  _dragStart = null;
                  _dragEnd = null;
                });
              },
              child: Stack(
                children: [
                  _buildGrid(),
                  if (_isDragging && _dragStart != null && _dragEnd != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SelectionBoxPainter(
                          start: _dragStart!,
                          end: _dragEnd!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final cardWidth = _getCardWidth(context);
    final cardHeight = _getCardHeight(context);

    return GridView.builder(
      key: _gridKey,
      padding: const EdgeInsets.symmetric(vertical: 10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: _gridSpacing,
        mainAxisSpacing: _gridSpacing,
        childAspectRatio: _cardAspectRatio,
        mainAxisExtent: cardHeight,
      ),
      itemCount: _children.length,
      itemBuilder: (context, index) => _buildNodeCard(_children[index], cardWidth, cardHeight),
    );
  }

  Widget _buildNodeCard(Node node, double cardWidth, double cardHeight) {
    final isSelected = _selectedIds.contains(node.id);
    final onLongPress = () => _showNodeOptions(node);
    final onCheckChanged = (bool? value) => _toggleSelectNode(node.id);

    Widget card;
    if (node.isFolder) {
      card = WisdomFolderCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: isSelected,
        onLongPress: onLongPress,
        onCheckChanged: onCheckChanged,
        onEnterFolder: () => _enterFolder(node.id),
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        isDescendantOf: _isDescendantOf,
      );
    } else {
      switch (node.nodeType) {
        case 'note':
          card = WisdomNoteCard(
            node: node,
            isSelectMode: _isSelectMode,
            isSelected: isSelected,
            onTap: _isSelectMode ? () => _toggleSelectNode(node.id) : () => _openNote(node),
            onLongPress: onLongPress,
            onCheckChanged: onCheckChanged,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          );
          break;
        case 'book':
          card = WisdomBookCard(
            node: node,
            isSelectMode: _isSelectMode,
            isSelected: isSelected,
            onTap: _isSelectMode ? () => _toggleSelectNode(node.id) : () => _openBook(node),
            onLongPress: onLongPress,
            onCheckChanged: onCheckChanged,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          );
          break;
        default:
          card = WisdomDefaultCard(
            node: node,
            isSelectMode: _isSelectMode,
            isSelected: isSelected,
            onTap: _isSelectMode ? () => _toggleSelectNode(node.id) : null,
            onLongPress: onLongPress,
            onCheckChanged: onCheckChanged,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          );
      }
    }

    // ✅ 右键菜单：用 GestureDetector 包裹卡片
    return GestureDetector(
      onSecondaryTap: () => _showNodeOptions(node),
      child: card,
    );
  }

  Future<void> _openNote(Node node) async {
    final note = await _db.getNoteByNodeId(node.id);
    if (note == null) { _showLightToast('笔记数据不存在'); return; }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailPage(entry: note, isFromCollection: false, nodeId: node.id, currentNodeId: _currentFolderId)));
    if (result == true) await _loadData();
  }

  Future<void> _openBook(Node node) async {
    final book = await _db.getBookByNodeId(node.id);
    if (book == null) { _showLightToast('图书数据不存在'); return; }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(bookId: book.id, nodeId: node.id, currentNodeId: _currentFolderId)));
  }

  // ✅ 搜索列表也支持右键
  Widget _buildSearchResults() {
    if (_isSearchingLoading) return const Center(child: CircularProgressIndicator());
    if (_searchController.text.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search, size: 56, color: Colors.grey), SizedBox(height: 14), Text('输入关键词搜索', style: TextStyle(color: Colors.grey))]));
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 56, color: Colors.grey), SizedBox(height: 14), Text('未找到匹配结果', style: TextStyle(color: Colors.grey))]));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          final node = result['node'] as Node;
          final path = result['path'] as String;

          // ✅ 用 GestureDetector 包裹 ListTile 支持右键
          return GestureDetector(
            onSecondaryTap: () => _showNodeOptions(node),
            child: Card(
              child: ListTile(
                leading: node.isFolder ? const Icon(Icons.folder, color: Colors.amber) : Text(node.iconEmoji, style: const TextStyle(fontSize: 20)),
                title: Text(node.title),
                subtitle: Text(path.isNotEmpty ? '📍 $path' : '📚 根目录', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                trailing: node.isFolder ? const Icon(Icons.chevron_right) : const Icon(Icons.open_in_new, size: 18),
                onTap: () async {
                  if (node.isFolder) { _currentFolderId = node.id; if (_isSearching) _toggleSearch(); await _loadData(); }
                  else { if (_isSearching) _toggleSearch(); await _openNode(node); }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNode(Node node) async {
    if (node.nodeType == 'note') await _openNote(node);
    else if (node.nodeType == 'book') await _openBook(node);
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(_selectedIds.length == _children.length ? Icons.check_box : Icons.check_box_outline_blank),
                onPressed: _toggleSelectAll,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text('已选 ${_selectedIds.length} 项', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _batchMove,
                icon: const Icon(Icons.drive_file_move, size: 16),
                label: const Text('移动'),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: _batchDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('删除'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNodeOptions(Node node) async {
    if (_isSelectMode) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.drive_file_rename_outline), title: const Text('重命名'), onTap: () => Navigator.pop(context, 'rename')),
          ListTile(leading: const Icon(Icons.drive_file_move), title: const Text('移动到...'), onTap: () => Navigator.pop(context, 'move_to')),
          if (node.isFolder) ListTile(leading: const Icon(Icons.folder_open), title: const Text('打开'), onTap: () => Navigator.pop(context, 'open')),
          ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('删除', style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(context, 'delete')),
        ]),
      ),
    );
    if (result == 'rename') await _renameNode(node);
    else if (result == 'move_to') await _moveNodeToFolder(node);
    else if (result == 'open' && node.isFolder) _enterFolder(node.id);
    else if (result == 'delete') await _deleteNode(node);
  }

  Future<void> _renameNode(Node node) async {
    final controller = TextEditingController(text: node.title);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '输入新名称', border: OutlineInputBorder()), onSubmitted: (_) => Navigator.pop(context, true)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存')),
        ],
      ),
    );
    if (result == true) {
      final title = controller.text.trim();
      if (title.isNotEmpty && title != node.title) {
        await _db.updateNode(node.copyWith(title: title, updatedAt: DateTime.now()));
        await _loadData();
        _showLightToast('✅ 已重命名');
      }
    }
  }

  Future<void> _moveNodeToFolder(Node node) async {
    final targetFolderId = await showDialog<String>(
      context: context,
      builder: (context) => FolderSelectorDialog(excludeNodeId: node.id),
    );
    if (targetFolderId == null) return;
    setState(() => _isLoading = true);
    try {
      await _db.moveNode(node.id, targetFolderId);
      await _loadData();
      _showLightToast('✅ 已移动到目标文件夹');
    } catch (e) {
      print('移动失败: $e');
      _showLightToast('❌ 移动失败');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNode(Node node) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(node.isFolder ? '确定要删除文件夹「${node.title}」及其所有子内容吗？\n此操作不可撤销。' : '确定要永久删除「${node.title}」吗？\n此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteNode(node.id);
      await _loadData();
      _showLightToast('已删除');
    }
  }
}

// ============================================================
// 拖拽选框绘制器
// ============================================================

class _SelectionBoxPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  _SelectionBoxPainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final left = start.dx < end.dx ? start.dx : end.dx;
    final top = start.dy < end.dy ? start.dy : end.dy;
    final right = start.dx > end.dx ? start.dx : end.dx;
    final bottom = start.dy > end.dy ? start.dy : end.dy;

    final rect = Rect.fromLTWH(left, top, right - left, bottom - top);

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionBoxPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}