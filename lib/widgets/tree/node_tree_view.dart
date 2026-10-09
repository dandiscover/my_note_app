// lib/widgets/tree/node_tree_view.dart
// R-4 批A：统一树组件

import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';

enum SystemFolderBehavior { hidden, readOnly, writable }

class NodeTreeView extends StatefulWidget {
  final String? rootId;
  final String? currentNodeId;
  final bool showSystemFolders;
  final bool folderOnly;
  final SystemFolderBehavior systemFolderBehavior;
  final Set<String>? initiallyExpanded;

  /// R-4 A2：外部传入数据（有则用它，无则自加载）
  final List<Node>? nodes;

  /// R-4 A2：外部触发重载（变化则重新构建）
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

      // 若 rootId 非 null —— 先建 byId 索引
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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: _tree.map((node) => _buildTreeNode(node, 0)).toList(),
    );
  }

  Widget _buildTile(Node node, int depth, {
    required bool isSelected,
    required bool isFolder,
    required bool isExpanded,
    required bool hasChildren,
  }) {
    return Container(
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
            onWillAcceptWithDetails: (details) {
              final draggedId = details.data;
              if (draggedId == node.id) return false;
              if (_isAncestorSync(draggedId, node.id)) return false;
              final targetDepth = _depthOfSync(node.id);
              final draggedDepth = _subtreeDepthSync(draggedId);
              if (targetDepth + draggedDepth > kMaxSubNoteDepth) return false;
              return true;
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return LongPressDraggable<String>(
                data: node.id,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(node.title,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: tile),
                child: Container(
                  color: isHovering ? Colors.green.shade100 : null,
                  child: tile,
                ),
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
        draggableTile,
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
}