// lib/pages/wisdom_page.dart
// 📚 智库页面 — 分栏/图标/大图三种视图切换 + FAB菜单 + 卡片盒特殊视图

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/node.dart';
import '../models/task.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/wisdom/wisdom_breadcrumb.dart';
import '../widgets/wisdom/wisdom_folder_card.dart';
import '../widgets/wisdom/wisdom_note_card.dart';
import '../widgets/wisdom/wisdom_book_card.dart';
import '../widgets/wisdom/wisdom_default_card.dart';
import '../widgets/wisdom/wisdom_checkbox.dart';
import '../widgets/wisdom/wisdom_draggable.dart';
import '../widgets/wisdom/wisdom_light_toast.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';

// ─── 视图模式枚举 ─────────────────────────────
enum WisdomViewMode {
  list,
  grid,
  large,
}

class WisdomPage extends StatefulWidget {
  const WisdomPage({super.key});

  @override
  WisdomPageState createState() => WisdomPageState();
}

class WisdomPageState extends State<WisdomPage> {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();
  List<Node> _nodes = [];
  List<NotebookEntry> _notes = [];
  List<Book> _books = [];
  List<CardModel> _cards = [];
  String? _currentFolderId;
  bool _isLoading = true;
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};
  List<Node> _breadcrumbPath = [];
  String _searchKeyword = '';
  OverlayEntry? _contextMenuEntry;
  Node? _contextMenuNode;

  bool _fabExpanded = false;
  WisdomViewMode _viewMode = WisdomViewMode.grid;

  // ─── 是否为卡片盒视图 ─────────────────────────────
  bool get _isCardBoxView {
    if (_currentFolderId == null) return false;
    final node = _nodes.firstWhere(
      (n) => n.id == _currentFolderId,
      orElse: () => _nodes.first,
    );
    return node.title == '卡片盒' && node.isFolder && node.parentId == null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _removeContextMenu();
    super.dispose();
  }

  // ─── 加载数据 ─────────────────────────────
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final nodes = await _db.getAllNodes();
      final notes = await _db.getAllNotes(includeDeleted: false);
      final books = await _db.getAllBooks();
      final cards = await _cardService.getAllCards();

      if (!mounted) return;
      setState(() {
        _nodes = nodes;
        _notes = notes.map((map) => NotebookEntry.fromMap(map)).toList();
        _books = books.map((map) => Book.fromMap(map)).toList();
        _cards = cards;
        _isLoading = false;
        _updateBreadcrumb();
      });

      await _ensureCardBoxFolder();

    } catch (e) {
      print('加载智库数据失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  // ─── 自动创建卡片盒文件夹 ─────────────────────────────
  Future<void> _ensureCardBoxFolder() async {
    final existing = _nodes.where((n) =>
      n.title == '卡片盒' && n.isFolder && n.parentId == null
    ).toList();
    if (existing.isNotEmpty) return;

    try {
      await _db.createFolder(
        title: '卡片盒',
        parentId: null,
        tags: ['卡片盒', '系统'],
      );
      print('📁 已创建卡片盒文件夹');
      await _loadData();
    } catch (e) {
      print('⚠️ 创建卡片盒文件夹失败: $e');
    }
  }

  void _updateBreadcrumb() {
    if (_currentFolderId == null) {
      _breadcrumbPath = [];
      return;
    }
    final List<Node> result = [];
    String? currentId = _currentFolderId;
    final folderMap = {for (var n in _nodes.where((n) => n.isFolder)) n.id: n};
    while (currentId != null && folderMap.containsKey(currentId)) {
      final node = folderMap[currentId]!;
      result.insert(0, node);
      currentId = node.parentId;
    }
    setState(() {
      _breadcrumbPath = result;
    });
  }

  void _navigateToFolder(String? folderId) {
    setState(() {
      _currentFolderId = folderId;
      _updateBreadcrumb();
      if (_isCardBoxView) {
        _loadCards();
      }
    });
  }

  Future<void> _loadCards() async {
    final cards = await _cardService.getAllCards();
    setState(() {
      _cards = cards;
    });
  }

  List<Node> _getChildren(String? parentId) {
    return _nodes.where((n) => n.parentId == parentId).toList();
  }

  List<Node> _getFilteredNodes(String? parentId) {
    final children = _getChildren(parentId);
    if (_searchKeyword.isEmpty) return children;
    return children.where((n) =>
      n.title.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
      n.tags.any((t) => t.toLowerCase().contains(_searchKeyword.toLowerCase()))
    ).toList();
  }

  // ─── 新建笔记 ─────────────────────────────
  void _createNote() async {
    _closeFab();
    final tempNote = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '无标题笔记',
      content: '',
      tags: [],
      updatedAt: DateTime.now(),
      editorMode: 'plain',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: tempNote,
          isFromCollection: true,
          onSave: (entry, title, content, mode, tags) async {
            final noteMap = {
              'id': entry.id,
              'title': title,
              'content': content,
              'status': 'active',
              'editorMode': mode,
              'updatedAt': DateTime.now().toIso8601String(),
            };
            await _db.insertNote(noteMap);
            await _db.attachNoteToNode(
              noteId: entry.id,
              title: title,
              parentId: _currentFolderId,
              tags: tags,
            );
            await _loadData();
            return true;
          },
        ),
      ),
    );
    if (result == true && mounted) {
      _showToast('📝 笔记已创建');
    }
  }

  // ─── 新建探究任务 ─────────────────────────────
  void _createExploreTask() async {
    _closeFab();
    final tempNote = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '探究任务',
      content: '# 探究任务\n\n## 🎯 目标\n\n## 📋 步骤\n\n## 📎 参考资料\n\n',
      tags: ['探究'],
      updatedAt: DateTime.now(),
      editorMode: 'markdown',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: tempNote,
          isFromCollection: true,
          exploreTaskId: '',
          onAddSubtask: (subtaskTitle) {},
          onSave: (entry, title, content, mode, tags) async {
            final noteMap = {
              'id': entry.id,
              'title': title,
              'content': content,
              'status': 'active',
              'editorMode': mode,
              'updatedAt': DateTime.now().toIso8601String(),
            };
            await _db.insertNote(noteMap);
            await _db.attachNoteToNode(
              noteId: entry.id,
              title: title,
              parentId: _currentFolderId,
              tags: tags,
            );

            final subtasks = _parseSubtasksFromMarkdown(content);
            final taskId = DateTime.now().millisecondsSinceEpoch.toString();

            final task = Task(
              id: taskId,
              title: title,
              type: TaskType.explore,
              description: content,
              difficulty: Difficulty.medium,
              urgency: Urgency.medium,
              necessity: Necessity.important,
              noteId: entry.id,
              subtaskIds: subtasks.map((st) => st['id'] as String).toList(),
            );
            await _saveTask(task);

            for (var st in subtasks) {
              final subtask = Subtask(
                id: st['id'] as String,
                parentTaskId: taskId,
                title: st['title'] as String,
                isDone: st['isDone'] as bool,
              );
              await _saveSubtask(subtask);
            }

            await _loadData();
            return true;
          },
        ),
      ),
    );

    if (result == true && mounted) {
      _showToast('🔍 探究任务已创建');
    }
  }

  List<Map<String, dynamic>> _parseSubtasksFromMarkdown(String content) {
    final results = <Map<String, dynamic>>[];
    final lines = content.split('\n');
    int index = 0;
    for (var line in lines) {
      final uncheckedMatch = RegExp(r'^-\s*\[\s*\]\s*(.+)$').firstMatch(line);
      final checkedMatch = RegExp(r'^-\s*\[x\]\s*(.+)$').firstMatch(line);
      if (uncheckedMatch != null) {
        results.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString() + '_${index++}',
          'title': uncheckedMatch.group(1)?.trim() ?? '未命名步骤',
          'isDone': false,
        });
      } else if (checkedMatch != null) {
        results.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString() + '_${index++}',
          'title': checkedMatch.group(1)?.trim() ?? '未命名步骤',
          'isDone': true,
        });
      }
    }
    return results;
  }

  Future<void> _saveTask(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('tasks') ?? [];
      jsonList.add(jsonEncode(task.toJson()));
      await prefs.setStringList('tasks', jsonList);
    } catch (e) {
      print('保存任务失败: $e');
    }
  }

  Future<void> _saveSubtask(Subtask subtask) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('subtasks') ?? [];
      jsonList.add(jsonEncode(subtask.toJson()));
      await prefs.setStringList('subtasks', jsonList);
    } catch (e) {
      print('保存子任务失败: $e');
    }
  }

  // ─── 新建文件夹 ─────────────────────────────
  void _createFolder() async {
    _closeFab();
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入文件夹名称',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _db.createFolder(
        title: result,
        parentId: _currentFolderId,
      );
      await _loadData();
      _showToast('📁 文件夹已创建');
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ─── FAB 控制 ─────────────────────────────
  void _toggleFab() {
    setState(() {
      _fabExpanded = !_fabExpanded;
    });
  }

  void _closeFab() {
    setState(() {
      _fabExpanded = false;
    });
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 右键菜单 ─────────────────────────────
  void _showContextMenu(Offset position, Node node) {
    _removeContextMenu();
    _contextMenuNode = node;
    _contextMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeContextMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      icon: Icons.edit,
                      label: '重命名',
                      onTap: () {
                        _removeContextMenu();
                        _renameNode(node);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.drive_file_move_outlined,
                      label: '移动到...',
                      onTap: () {
                        _removeContextMenu();
                        _moveNode(node);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.delete_outline,
                      label: '删除',
                      color: Colors.red,
                      onTap: () {
                        _removeContextMenu();
                        _deleteNode(node);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_contextMenuEntry!);
  }

  void _removeContextMenu() {
    _contextMenuEntry?.remove();
    _contextMenuEntry = null;
    _contextMenuNode = null;
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: color ?? Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameNode(Node node) async {
    final controller = TextEditingController(text: node.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重命名${node.isFolder ? '文件夹' : ''}'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final updated = node.copyWith(
        title: result,
        updatedAt: DateTime.now(),
      );
      await _db.updateNode(updated);
      await _loadData();
      _showToast('已重命名');
    }
  }

  Future<void> _moveNode(Node node) async {
    final folders = _nodes.where((n) => n.isFolder).toList();
    if (folders.isEmpty) {
      _showToast('没有可移动的目标文件夹');
      return;
    }

    String? selectedId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到...'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final f = folders[index];
              return ListTile(
                title: Text(f.title),
                leading: const Icon(Icons.folder),
                selected: selectedId == f.id,
                onTap: () {
                  selectedId = f.id;
                  Navigator.pop(context, f.id);
                },
                trailing: f.id == node.id ? const Icon(Icons.fiber_manual_record, color: Colors.grey) : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedId != null && selectedId != node.id) {
      await _db.moveNode(node.id, selectedId);
      await _loadData();
      _showToast('已移动');
    }
  }

  Future<void> _deleteNode(Node node) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${node.title}" 吗？\n${node.isFolder ? '文件夹内的所有内容也将被删除。' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteNode(node.id);
      await _loadData();
      _showToast('已删除');
    }
  }

  // ─── 视图切换 ─────────────────────────────
  IconData _getViewModeIcon() {
    switch (_viewMode) {
      case WisdomViewMode.list:
        return Icons.list;
      case WisdomViewMode.grid:
        return Icons.grid_view;
      case WisdomViewMode.large:
        return Icons.grid_on;
    }
  }

  (int crossAxisCount, double aspectRatio) _getGridLayout(double maxWidth) {
    switch (_viewMode) {
      case WisdomViewMode.list:
        return (1, 4.0);
      case WisdomViewMode.grid:
        return (6, 0.7);
      case WisdomViewMode.large:
        return (3, 0.8);
    }
  }

  // ─── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    final children = _getFilteredNodes(_currentFolderId);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isCardBoxView ? '📇 卡片盒' : '📚 智库'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: _isCardBoxView
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _navigateToFolder(null),
                tooltip: '返回智库',
              )
            : null,
        actions: [
          PopupMenuButton<WisdomViewMode>(
            icon: Icon(_getViewModeIcon()),
            onSelected: (mode) {
              setState(() {
                _viewMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: WisdomViewMode.list,
                child: Row(
                  children: [
                    Icon(Icons.list, size: 18),
                    SizedBox(width: 8),
                    Text('分栏'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: WisdomViewMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view, size: 18),
                    SizedBox(width: 8),
                    Text('图标'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: WisdomViewMode.large,
                child: Row(
                  children: [
                    Icon(Icons.grid_on, size: 18),
                    SizedBox(width: 8),
                    Text('大图'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              setState(() {
                _isSelectMode = !_isSelectMode;
                if (!_isSelectMode) _selectedIds.clear();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isCardBoxView
              ? _buildCardBoxView()
              : Column(
                  children: [
                    WisdomBreadcrumb(
                      breadcrumb: _breadcrumbPath,
                      onGoRoot: () => _navigateToFolder(null),
                      onGoToBreadcrumb: (nodeId) => _navigateToFolder(nodeId.toString()),
                      onMoveNode: (sourceId, targetId) async {},
                      isDescendantOf: (nodeId, ancestorId) => false,
                    ),
                    const Divider(height: 1),
                    if (_searchKeyword.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '搜索: $_searchKeyword',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchKeyword = '';
                                  });
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: children.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shelves, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    '这里空空如也',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '点击右下角 + 创建内容',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(12),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxWidth = constraints.maxWidth;
                                  final layout = _getGridLayout(maxWidth);
                                  final crossAxisCount = layout.$1;
                                  final aspectRatio = layout.$2;
                                  final cardWidth = maxWidth / crossAxisCount - 8;
                                  final cardHeight = cardWidth / aspectRatio;

                                  return GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 6,
                                      childAspectRatio: aspectRatio,
                                    ),
                                    itemCount: children.length,
                                    itemBuilder: (context, index) {
                                      final node = children[index];
                                      return _buildCard(node, cardWidth, cardHeight);
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (_fabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFab,
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
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
                  _buildFabOption(
                    icon: Icons.edit_note,
                    label: '新建笔记',
                    color: Colors.blue,
                    onTap: _createNote,
                  ),
                  const SizedBox(height: 8),
                  _buildFabOption(
                    icon: Icons.explore,
                    label: '新建探究任务',
                    color: Colors.purple,
                    onTap: _createExploreTask,
                  ),
                  const SizedBox(height: 8),
                  _buildFabOption(
                    icon: Icons.create_new_folder,
                    label: '新建文件夹',
                    color: Colors.orange,
                    onTap: _createFolder,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: _toggleFab,
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ─── 卡片盒特殊视图 ─────────────────────────────
  Widget _buildCardBoxView() {
    // ─── 搜索状态 ─────────────────────────────
    String searchQuery = '';
    final TextEditingController searchController = TextEditingController();

    // ─── 筛选卡片 ─────────────────────────────
    List<CardModel> getFilteredCards() {
      if (searchQuery.trim().isEmpty) {
        return _cards;
      }
      final query = searchQuery.trim().toLowerCase();
      return _cards.where((card) {
        if (card.tags.any((t) => t.toLowerCase().contains(query))) return true;
        if (card.front?.toLowerCase().contains(query) == true) return true;
        if (card.back?.toLowerCase().contains(query) == true) return true;
        if (card.indexTitle?.toLowerCase().contains(query) == true) return true;
        if (card.author?.toLowerCase().contains(query) == true) return true;
        if (card.highlight?.toLowerCase().contains(query) == true) return true;
        return false;
      }).toList();
    }

    // ─── 按标签分组 ─────────────────────────────
    Map<String, List<CardModel>> groupCardsByTag(List<CardModel> cards) {
      final groups = <String, List<CardModel>>{};
      for (var card in cards) {
        if (card.tags.isEmpty) {
          groups.putIfAbsent('未分类', () => []).add(card);
        } else {
          for (var tag in card.tags) {
            groups.putIfAbsent(tag, () => []).add(card);
          }
        }
      }
      final sortedKeys = groups.keys.toList()..sort();
      final sortedGroups = <String, List<CardModel>>{};
      for (var key in sortedKeys) {
        sortedGroups[key] = groups[key]!;
      }
      return sortedGroups;
    }

    final filteredCards = getFilteredCards();
    final groupedCards = groupCardsByTag(filteredCards);

    // ─── 统计 ─────────────────────────────
    final totalCards = _cards.length;
    final reviewCount = _cards.where((c) => c.cardType == CardType.review).length;
    final indexCount = _cards.where((c) => c.cardType == CardType.indexCard).length;

    // ─── 空状态 ─────────────────────────────
    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              '📇 卡片盒是空的',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '在笔记详情中点击「📇 生成卡片」创建复习卡',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ─── 统计 + 搜索栏 ──────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatChip('📇 总卡片', totalCards, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatChip('📄 复习卡', reviewCount, Colors.purple),
                  const SizedBox(width: 12),
                  _buildStatChip('📚 索引卡', indexCount, Colors.teal),
                  const Spacer(),
                  Text(
                    '${groupedCards.keys.length} 个标签',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: '🔍 搜索卡片（标题/内容/标签/作者/高光句）...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ─── 卡片列表 ──────────────────────────
        if (filteredCards.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    '没有找到匹配的卡片',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedCards.entries.map((entry) {
                  final tag = entry.key;
                  final cards = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── 标签标题 ──────────────────────────
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(tag).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 14,
                              color: _getTagColor(tag),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getTagColor(tag),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getTagColor(tag).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${cards.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTagColor(tag),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ─── 该标签下的卡片网格 ──────────────────────────
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 2.0,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return _buildCardItem(card);
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // ─── 统计芯片 ─────────────────────────────
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ─── 卡片项（桌面端：悬停展开） ─────────────────────────────
  Widget _buildCardItem(CardModel card) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool _isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
           transform: _isHovered
    ? (Matrix4.identity()..translate(0, -20)..scale(1.05))
    : Matrix4.identity(),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isHovered ? 12 : 4),
              border: Border.all(
                color: _isHovered ? card.typeColor : Colors.grey.shade200,
                width: _isHovered ? 2 : 0.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: card.typeColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: card.typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.typeIcon,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getCardThumbnail(card),
                  style: TextStyle(
                    fontSize: _isHovered ? 10 : 7,
                    color: _isHovered ? Colors.black87 : Colors.grey.shade700,
                  ),
                  maxLines: _isHovered ? 6 : 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (card.mastered)
                  const Text('✅', style: TextStyle(fontSize: 6)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 卡片项（移动端：点击展开） ─────────────────────────────
  Widget _buildCardItemMobile(CardModel card) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool _isExpanded = false;
        return GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded ? 100 : 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isExpanded ? 8 : 4),
              border: Border.all(
                color: _isExpanded ? card.typeColor : Colors.grey.shade200,
                width: _isExpanded ? 2 : 0.5,
              ),
              boxShadow: _isExpanded
                  ? [
                      BoxShadow(
                        color: card.typeColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: card.typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      card.typeIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCardThumbnail(card),
                        style: TextStyle(
                          fontSize: _isExpanded ? 11 : 9,
                          color: _isExpanded ? Colors.black87 : Colors.grey.shade700,
                        ),
                        maxLines: _isExpanded ? 4 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isExpanded && card.tags.isNotEmpty)
                        Wrap(
                          spacing: 2,
                          children: card.tags.take(2).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getTagColor(tag).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 7,
                                color: _getTagColor(tag),
                              ),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
                if (card.mastered)
                  const Text(
                    '✅',
                    style: TextStyle(fontSize: 10),
                  ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 获取卡片缩略图内容 ─────────────────────────────
  String _getCardThumbnail(CardModel card) {
    switch (card.cardType) {
      case CardType.indexCard:
        return card.highlight ?? card.indexTitle ?? '索引卡';
      case CardType.review:
        return card.front ?? '复习卡';
      case CardType.qa:
        return card.question ?? '问答卡';
      case CardType.fill:
        return card.fillQuestion ?? '填空卡';
      case CardType.choice:
        return card.choiceQuestion ?? '选择题';
      case CardType.truefalse:
        return card.tfStatement ?? '判断题';
    }
  }

  // ─── 标签颜色 ─────────────────────────────
  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.deepPurple,
      Colors.red,
      Colors.amber,
      Colors.brown,
    ];
    return colors[hash % colors.length];
  }

  // ─── 构建普通卡片 ─────────────────────────────
  Widget _buildCard(Node node, double cardWidth, double cardHeight) {
    if (node.isFolder) {
      return WisdomFolderCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onEnterFolder: () => _navigateToFolder(node.id),
        onLongPress: () => _showContextMenu(Offset.zero, node),
        onCheckChanged: (checked) {
          setState(() {
            if (checked == true) _selectedIds.add(node.id);
            else _selectedIds.remove(node.id);
          });
        },
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        isDescendantOf: (nodeId, ancestorId) => false,
      );
    }

    if (node.nodeType == 'note') {
      final note = _notes.firstWhere(
        (n) => n.id == node.targetId,
        orElse: () => NotebookEntry(
          id: 'unknown',
          title: '笔记已删除',
          content: '',
          tags: [],
          updatedAt: DateTime.now(),
          status: 'deleted',
        ),
      );

      return WisdomNoteCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onTap: () async {
          if (note.status != 'deleted') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailPage(entry: note),
              ),
            );
            if (result == true) await _loadData();
          }
        },
        onLongPress: () => _showContextMenu(Offset.zero, node),
        onCheckChanged: (checked) {
          setState(() {
            if (checked == true) _selectedIds.add(node.id);
            else _selectedIds.remove(node.id);
          });
        },
        cardWidth: cardWidth,
        cardHeight: cardHeight,
      );
    }

    if (node.nodeType == 'book') {
      final book = _books.firstWhere(
        (b) => b.id == node.targetId,
        orElse: () => Book(
          id: 'unknown',
          title: '图书已删除',
          author: '',
          status: 'archived',
          readingProgress: 0,
          totalPages: 0,
          createdAt: DateTime.now(),
        ),
      );

      return WisdomBookCard(
        node: node,
        isSelectMode: _isSelectMode,
        isSelected: _selectedIds.contains(node.id),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailPage(bookId: book.id),
            ),
          );
        },
        onLongPress: () => _showContextMenu(Offset.zero, node),
        onCheckChanged: (checked) {
          setState(() {
            if (checked == true) _selectedIds.add(node.id);
            else _selectedIds.remove(node.id);
          });
        },
        cardWidth: cardWidth,
        cardHeight: cardHeight,
      );
    }

    return WisdomDefaultCard(
      node: node,
      isSelectMode: _isSelectMode,
      isSelected: _selectedIds.contains(node.id),
      onTap: () {},
      onLongPress: () => _showContextMenu(Offset.zero, node),
      onCheckChanged: (checked) {
        setState(() {
          if (checked == true) _selectedIds.add(node.id);
          else _selectedIds.remove(node.id);
        });
      },
      cardWidth: cardWidth,
      cardHeight: cardHeight,
    );
  }
}