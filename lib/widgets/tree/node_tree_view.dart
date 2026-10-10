// lib/widgets/tree/node_tree_view.dart
// R-4 批A：统一树组件
// R-4 批B：右键 / 长按菜单（Listener 捕原始指针）

import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import '../../models/note.dart';
import 'dart:async';                             // unawaited
import 'package:flutter/foundation.dart';        // kIsWeb / defaultTargetPlatform
import 'tree_drag_registry.dart';                // 新
import 'tree_drag_mode.dart';                    // 新
enum SystemFolderBehavior { hidden, readOnly, writable }

class NodeTreeView extends StatefulWidget {
  final String? rootId;
  final String? currentNodeId;
  final bool showSystemFolders;
  final bool folderOnly;
  final SystemFolderBehavior systemFolderBehavior;
  final Set<String>? initiallyExpanded;
  final List<Node>? nodes;
  final int reloadTick;

  final Function(Node node)? onTap;
  final Function(Node node)? onMenu;
  final Function(String draggedId, String targetId)? onDragDrop;

  const NodeTreeView({
    super.key,
    this.rootId,
    this.currentNodeId,
    this.showSystemFolders = false,
    this.folderOnly = false,
    this.systemFolderBehavior = SystemFolderBehavior.hidden,
    this.initiallyExpanded,
    this.nodes,
    this.reloadTick = 0,
    this.onTap,
    this.onMenu,
    this.onDragDrop,
  });

  @override
  State<NodeTreeView> createState() => _NodeTreeViewState();
}

class _NodeTreeViewState extends State<NodeTreeView> {
  final DatabaseService _db = DatabaseService();
  List<Node> _tree = [];
  bool _isLoading = true;
  final Set<String> _expandedIds = {};

  Map<String, List<Node>> _childrenMap = {};
  Map<String, String?> _parentMap = {};
  Map<String, Node> _byId = {};
  late final TreeDragRegistryController _registry =
      TreeDragRegistryController();
  TreeDragModeController? _activeDrag;

  Node? _findNodeById(String nodeId) => _byId[nodeId];

  @override
  void dispose() {
    // 顺序：
    //   1. abort drag mode——清 OverlayEntry——清 hoverTarget.value
    //   2. 子 _NodeTileRegistrar 先 dispose——removeListener（no-op 安全）
    //   3. _registry.dispose()——hoverTarget.dispose() + _boxes.clear()
    //   4. super.dispose()
    _activeDrag?.abort();
    _activeDrag = null;
    _registry.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initiallyExpanded != null) {
      _expandedIds.addAll(widget.initiallyExpanded!);
    }
    _loadTree();
    if (widget.currentNodeId != null) {
      _db.getAncestors(widget.currentNodeId!).then((ancestors) {
        if (!mounted) return;
        setState(() {
          for (var node in ancestors) {
            if (node.id != widget.currentNodeId) {
              _expandedIds.add(node.id);
            }
          }
        });
      });
    }
  }

  @override
  void didUpdateWidget(NodeTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadTick != widget.reloadTick ||
        oldWidget.nodes != widget.nodes) {
      _loadTree();
    }
  }

  Future<void> _loadTree() async {
    setState(() => _isLoading = true);
    try {
      final all = widget.nodes ?? await _db.getAllNodes();
      final map = <String, List<Node>>{};
      final parentMap = <String, String?>{};
      final roots = <Node>[];

      final byId = {for (var n in all) n.id: n};

      bool underRoot(Node n) {
        if (widget.rootId == null) return true;
        String? cur = n.parentId;
        while (cur != null) {
          if (cur == widget.rootId) return true;
          cur = byId[cur]?.parentId;
        }
        return false;
      }

      for (var n in all) {
        if (widget.folderOnly && !n.isFolder) continue;
        if (!widget.showSystemFolders && n.systemTag != null) continue;
        if (widget.rootId != null && !underRoot(n)) continue;

        parentMap[n.id] = n.parentId;

        if (widget.rootId != null) {
          if (n.id == widget.rootId) {
            roots.add(n);
          } else if (n.parentId != null) {
            map.putIfAbsent(n.parentId!, () => []).add(n);
          }
        } else {
          if (n.parentId == null) {
            roots.add(n);
          } else {
            map.putIfAbsent(n.parentId!, () => []).add(n);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _tree = roots;
        _childrenMap = map;
        _parentMap = parentMap;
        _byId = byId;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载文件树失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isAncestorSync(String possibleAncestor, String nodeId) {
    final visited = <String>{nodeId};
    String? current = _parentMap[nodeId];
    while (current != null) {
      if (visited.contains(current)) return false;
      if (current == possibleAncestor) return true;
      visited.add(current);
      current = _parentMap[current];
    }
    return false;
  }

  int _depthOfSync(String nodeId) {
    int d = 1;
    final visited = <String>{nodeId};
    String? current = _parentMap[nodeId];
    while (current != null) {
      if (visited.contains(current)) break;
      d++;
      visited.add(current);
      current = _parentMap[current];
    }
    return d;
  }

  int _subtreeDepthSync(String nodeId) {
    int maxDepth = 1;
    final visited = <String>{};
    void walk(String id, int depth) {
      if (visited.contains(id)) return;
      visited.add(id);
      if (depth > maxDepth) maxDepth = depth;
      for (var child in _childrenMap[id] ?? <Node>[]) {
        walk(child.id, depth + 1);
      }
    }
    walk(nodeId, 1);
    return maxDepth;
  }

  bool _isInSystemTree(Node node) {
    if (node.isSystemFolder) return true;
    String? cur = node.parentId;
    final visited = <String>{};
    while (cur != null) {
      if (visited.contains(cur)) return false;
      visited.add(cur);
      final parent = _byId[cur];
      if (parent == null) return false;
      if (parent.isSystemFolder) return true;
      cur = parent.parentId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tree.isEmpty) {
      return const Center(
        child: Text('暂无内容', style: TextStyle(color: Colors.grey)),
      );
    }
    return TreeDragRegistry(
      controller: _registry,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: _tree.map((node) => _buildTreeNode(node, 0)).toList(),
      ),
    );
  }

  Widget _buildTile(Node node, int depth, {
    required bool isSelected,
    required bool isFolder,
    required bool isExpanded,
    required bool hasChildren,
  }) {
    // ── R-4 批B：Listener 捕原始指针 —— 避开 ListTile 吃事件 ──
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          debugPrint('🚨 右键触发: ${node.title}');
          if (widget.onMenu != null) {
            widget.onMenu!(node);
          } else {
            _showMenu(node, event.position);
          }
        }
      },
      child: GestureDetector(
        onLongPressStart: (d) {
          debugPrint('🚨 长按触发: ${node.title}');
          if (widget.onMenu != null) {
            widget.onMenu!(node);
          } else {
            _showMenu(node, d.globalPosition);
          }
        },
        child: Material(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.only(
              left: 8.0 + depth * 16,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            leading: isFolder
                ? Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    color: isSelected ? Colors.blue.shade700 : Colors.amber,
                    size: 18,
                  )
                : Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
            title: Text(
              node.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : null,
              ),
            ),
            trailing: hasChildren
                ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedIds.remove(node.id);
                        } else {
                          _expandedIds.add(node.id);
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
            onTap: () {
              if (isFolder) {
                if (widget.onTap != null) {
                  widget.onTap!(node);
                } else if (hasChildren) {
                  setState(() {
                    if (isExpanded) {
                      _expandedIds.remove(node.id);
                    } else {
                      _expandedIds.add(node.id);
                    }
                  });
                }
              } else {
                widget.onTap?.call(node);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTreeNode(Node node, int depth) {
    final isExpanded = _expandedIds.contains(node.id);
    final isSelected = node.id == widget.currentNodeId;
    final isFolder = node.isFolder;
    final children = _childrenMap[node.id] ?? <Node>[];
    final hasChildren = children.isNotEmpty;

    final tile = _buildTile(
      node, depth,
      isSelected: isSelected,
      isFolder: isFolder,
      isExpanded: isExpanded,
      hasChildren: hasChildren,
    );

    final Widget draggableTile = widget.onDragDrop != null
        ? DragTarget<String>(
            onWillAcceptWithDetails: (details) =>
                _canDropInto(details.data, node.id),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return Container(
                color: isHovering ? Colors.green.shade100 : null,
                child: tile,
              );
            },
            onAcceptWithDetails: (details) {
              widget.onDragDrop!(details.data, node.id);
            },
          )
        : tile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NodeTileRegistrar(nodeId: node.id, child: draggableTile),
        if (hasChildren && isExpanded)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((child) {
              return _buildTreeNode(child, depth + 1);
            }).toList(),
          ),
      ],
    );
  }

  // ─── R-4 批B：右键 / 长按菜单 ──────────────────────

  Future<void> _showMenu(Node node, Offset position) async {
    final isFolder = node.isFolder;
    final systemTag = node.systemTag;
    final isTopSystem = node.isSystemFolder;
    final inSystemTree = _isInSystemTree(node);
    debugPrint('🚨 _showMenu 入口: ${node.title}  isFolder=$isFolder '
        'isTopSystem=$isTopSystem inSystemTree=$inSystemTree');

    final isFullBlocked = isTopSystem &&
        (systemTag == 'cardbox' ||
            systemTag == 'album' ||
            systemTag == 'review');

    if (isFullBlocked) {
      debugPrint('🚨 isFullBlocked —— 弹提示 return');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('此项不可操作'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final allowNewFolder = isFolder &&
        (!isTopSystem || systemTag == 'library' || systemTag == 'archived');
    final allowNewNote = isFolder && !inSystemTree;
    final allowRename = !isTopSystem;
    final allowDelete = !isTopSystem && (!isFolder || !inSystemTree);
    final allowMove = !isTopSystem && (!isFolder || !inSystemTree);

    final items = <PopupMenuEntry<String>>[];

    if (allowNewFolder) {
      items.add(const PopupMenuItem(
        value: 'new_folder',
        child: Text('📁 新建子文件夹'),
      ));
    }
    if (allowNewNote) {
      items.add(const PopupMenuItem(
        value: 'new_note',
        child: Text('📝 新建笔记'),
      ));
    }
    if (allowRename) {
      items.add(const PopupMenuItem(
        value: 'rename',
        child: Text('✏️ 重命名'),
      ));
    }
    if (allowDelete) {
      items.add(const PopupMenuItem(
        value: 'delete',
        child: Text('🗑️ 删除', style: TextStyle(color: Colors.red)),
      ));
    }
    if (allowMove) {
      items.add(const PopupMenuItem(
        value: 'move',
        child: Text('📦 移动到...'),
      ));
    }

    if (items.isEmpty) {
      debugPrint('🚨 items 空 —— return');
      return;
    }

    String? action;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final overlayRO = Overlay.of(context).context.findRenderObject();
      debugPrint('🚨 overlay RO = $overlayRO');
      final Size overlaySize = overlayRO is RenderBox
          ? overlayRO.size
          : MediaQuery.of(context).size;
      action = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          Rect.fromLTWH(position.dx, position.dy, 0, 0),
          Offset.zero & overlaySize,
        ),
        items: items,
      );
    } else {
      action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  node.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...items.map((item) {
                if (item is PopupMenuItem<String>) {
                  return ListTile(
                    title: item.child,
                    onTap: () => Navigator.pop(ctx, item.value),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      );
    }

    if (action == null || !mounted) return;

    switch (action) {
      case 'new_folder':
        await _actionNewFolder(node);
        break;
      case 'new_note':
        await _actionNewNote(node);
        break;
      case 'rename':
        await _actionRename(node);
        break;
      case 'delete':
        await _actionDelete(node);
        break;
      case 'move':
        await _actionMove(node);
        break;
    }
  }

  Future<void> _actionNewFolder(Node parent) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建子文件夹'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '文件夹名称'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    final t = (name ?? '').trim();
    if (t.isEmpty || !mounted) return;

    await _db.createFolder(title: t, parentId: parent.id);
    setState(() => _expandedIds.add(parent.id));
    await _loadTree();
  }

  Future<void> _actionNewNote(Node parent) async {
    final now = DateTime.now();
    final noteId = now.millisecondsSinceEpoch.toString();
    final entry = NotebookEntry(
      id: noteId,
      title: '无标题笔记',
      content: '',
      updatedAt: now,
      status: 'raw',
      editorMode: 'plain',
    );
    await _db.insertNote(entry.toMap());
    await _db.attachNoteToNode(
      noteId: noteId,
      title: entry.title,
      parentId: parent.id,
    );
    setState(() => _expandedIds.add(parent.id));
    await _loadTree();
  }

  Future<void> _actionRename(Node node) async {
    final ctrl = TextEditingController(text: node.title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    final t = (name ?? '').trim();
    if (t.isEmpty || !mounted) return;

    await _db.updateNode(node.copyWith(title: t, updatedAt: DateTime.now()));
    await _loadTree();
  }

  Future<void> _actionDelete(Node node) async {
    int childCount = 0;
    if (node.isFolder) {
      final visited = <String>{};
      void walk(String id) {
        if (visited.contains(id)) return;
        visited.add(id);
        for (final child in _childrenMap[id] ?? <Node>[]) {
          if (child.id == node.id) continue;
          childCount++;
          if (child.isFolder) walk(child.id);
        }
      }
      walk(node.id);
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          node.isFolder && childCount > 0
              ? '删除「${node.title}」？\n此文件夹含 $childCount 个子项，全部将删除。\n此操作不可撤销。'
              : '删除「${node.title}」？此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await _db.deleteNode(node.id);
    await _loadTree();
  }

  Future<void> _actionMove(Node node) async {
    final isTouch = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);

    if (isTouch) {
      _startDragMode(node);
      return;
    }

    await _showMoveTargetPicker(node);
  }

  Future<void> _showMoveTargetPicker(Node node) async {
    final all = widget.nodes ?? await _db.getAllNodes();
    final folders = all.where((n) {
      if (!n.isFolder) return false;
      if (n.id == node.id) return false;
      if (_isAncestorSync(node.id, n.id)) return false;
      final tag = n.systemTag;
      if (tag != null && tag != 'library' && tag != 'archived') {
        return false;
      }
      return true;
    }).toList();

    if (folders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('没有可移动的目标文件夹')),
        );
      }
      return;
    }

    final targetId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移动到...'),
        content: SizedBox(
          width: 320,
          height: 320,
          child: ListView.builder(
            itemCount: folders.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.home),
                  title: const Text('根目录'),
                  onTap: () => Navigator.pop(ctx, '__root__'),
                );
              }
              final f = folders[i - 1];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.folder, color: Colors.amber),
                title: Text(f.title),
                onTap: () => Navigator.pop(ctx, f.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (targetId == null || !mounted) return;
    final newParent = targetId == '__root__' ? null : targetId;
    await _db.moveNode(node.id, newParent);
    await _loadTree();
  }

  // ─── R-4 批D-3：触屏拖拽模式 ──────────────────────

  void _startDragMode(Node node) {
    final box = _registry.rawBox(node.id);
    if (box == null || !box.attached) {
      debugPrint('🚨 _startDragMode: box 未注册 node=${node.id} title=${node.title}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('拖拽启动失败，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final originGlobal = box.localToGlobal(Offset.zero);
    final feedbackSize = box.size;

    final feedback = Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.7,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(node.title, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );

    _activeDrag = TreeDragModeController(
      context: context,
      registry: _registry,
      canDrop: _canDropInto,
      onDrop: (draggedId, targetId) {
        unawaited(_doDrop(draggedId, targetId));
      },
    );
    _activeDrag!.start(
      pendingId: node.id,
      originGlobalPosition: originGlobal,
      feedback: feedback,
      feedbackSize: feedbackSize,
    );
  }

  Future<void> _doDrop(String draggedId, String targetId) async {
    await _db.moveNode(draggedId, targetId);
    _activeDrag = null;
    if (mounted) await _loadTree();
  }

  bool _canDropInto(String draggedId, String targetId) {
    if (draggedId == targetId) return false;
    if (_isAncestorSync(draggedId, targetId)) return false;
    final targetDepth = _depthOfSync(targetId);
    final draggedDepth = _subtreeDepthSync(draggedId);
    if (targetDepth + draggedDepth > kMaxSubNoteDepth) return false;

    final target = _findNodeById(targetId);
    if (target == null) return false;

    final tIsTopSystem = target.isSystemFolder;
    final tSystemTag = target.systemTag;
    final tIsFullBlocked = tIsTopSystem &&
        (tSystemTag == 'cardbox' ||
         tSystemTag == 'album' ||
         tSystemTag == 'review');
    if (tIsFullBlocked) return false;

    return true;
  }
}

class _NodeTileRegistrar extends StatefulWidget {
  final String nodeId;
  final Widget child;
  const _NodeTileRegistrar({required this.nodeId, required this.child});

  @override
  State<_NodeTileRegistrar> createState() => _NodeTileRegistrarState();
}

class _NodeTileRegistrarState extends State<_NodeTileRegistrar> {
  TreeDragRegistryController? _registry;
  bool _registered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registered) return;
    _registered = true;
    _registry = TreeDragRegistry.of(context);
    _registry?.hoverTarget.addListener(_onHoverChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ro = context.findRenderObject();
      if (ro is RenderBox) _registry?.register(widget.nodeId, ro);
    });
  }

  void _onHoverChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _registry?.hoverTarget.removeListener(_onHoverChanged);
    _registry?.unregister(widget.nodeId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hovering = _registry?.hoverTarget.value == widget.nodeId;
    return Container(
      decoration: hovering
          ? BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              color: Colors.green.shade50,
            )
          : null,
      child: widget.child,
    );
  }
}