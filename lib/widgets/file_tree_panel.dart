// lib/widgets/file_tree_panel.dart
// ✅ 子笔记嵌套：全量加载 + 同步校验 + 拖拽（LongPressDraggable + DragTarget）
//    - 一次性加载全量节点，构建 _childrenMap / _parentMap（替代原 FutureBuilder）
//    - 任何节点只要有子节点即可展开（不再用 isFolder 判断）
//    - 拖拽悬停时同步校验：防环 + 三层限制；非法目标不高亮不接收
//    - 释放后 moveNode 并刷新
// ✅ v2：tile 从局部变量改为 _buildTile 方法（每次调用生成新实例，避免同 widget 复用）

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';

class FileTreePanel extends StatefulWidget {
  final String? currentNodeId;
  final String? currentNodeName;
  final String? currentFolderId;
  final Function(String nodeId, String nodeType) onNodeTap;

  const FileTreePanel({
    super.key,
    this.currentNodeId,
    this.currentNodeName,
    this.currentFolderId,
    required this.onNodeTap,
  });

  @override
  State<FileTreePanel> createState() => _FileTreePanelState();
}

class _FileTreePanelState extends State<FileTreePanel> {
  final DatabaseService _db = DatabaseService();
  List<Node> _tree = [];
  bool _isLoading = true;
  final Set<String> _expandedIds = {};

  // ✅ 子笔记嵌套：全量加载后本地维护
  Map<String, List<Node>> _childrenMap = {};
  Map<String, String?> _parentMap = {};

  @override
  void initState() {
    super.initState();
    _loadTree();
    if (widget.currentNodeId != null) {
      _db.getAncestors(widget.currentNodeId!).then((ancestors) {
        if (!mounted) return;
        setState(() {
          // ✅ 展开所有祖先（跳过自身）
          for (var node in ancestors) {
            if (node.id != widget.currentNodeId) {
              _expandedIds.add(node.id);
            }
          }
        });
      });
    }
  }

  // ✅ 子笔记嵌套：一次性加载全部节点，本地构建父子映射
  Future<void> _loadTree() async {
    setState(() => _isLoading = true);
    try {
      final all = await _db.getAllNodes();
      final map = <String, List<Node>>{};
      final parentMap = <String, String?>{};
      final roots = <Node>[];
      for (var n in all) {
        parentMap[n.id] = n.parentId;
        if (n.parentId == null) {
          roots.add(n);
        } else {
          map.putIfAbsent(n.parentId!, () => []).add(n);
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

  // ✅ 同步校验工具：possibleAncestor 是否是 nodeId 的祖先（含自身）
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

  // ✅ 同步校验工具：节点自身深度（含自身，根为 1）
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

  // ✅ 同步校验工具：节点子树最大深度（含自身）
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
    return Container(
      width: MediaQuery.of(context).size.width / 3,
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18),
                const SizedBox(width: 8),
                const Text(
                  '文件树',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (widget.currentNodeName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📍 ${widget.currentNodeName}',
                      style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tree.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无内容',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: _tree.map((node) {
                          return _buildTreeNode(node, 0);
                        }).toList(),
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _loadTree,
                  tooltip: '刷新',
                ),
                const SizedBox(width: 4),
                Text(
                  '共 ${_tree.length} 个根目录',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ v2：tile 从局部变量改为方法，每次调用生成新实例
  //    Flutter Element 树不允许同一 widget 实例出现在两处
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
            : Text(
                node.iconEmoji,
                style: const TextStyle(fontSize: 16),
              ),
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
            // 文件夹：切换展开（保持原行为）
            if (hasChildren) {
              setState(() {
                if (isExpanded) {
                  _expandedIds.remove(node.id);
                } else {
                  _expandedIds.add(node.id);
                }
              });
            }
          } else {
            // 笔记 / 图书：打开
            widget.onNodeTap(node.id, node.nodeType);
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

    // ─── 拖拽包装：DragTarget（接收）+ LongPressDraggable（拖出） ───
    final draggableTile = DragTarget<String>(
      // ✅ 悬停时同步校验：防环 + 三层限制
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
                child: Text(
                  node.title,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          // ✅ v2：每次调用 _buildTile 生成新实例
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildTile(
              node,
              depth,
              isSelected: isSelected,
              isFolder: isFolder,
              isExpanded: isExpanded,
              hasChildren: hasChildren,
            ),
          ),
          child: Container(
            color: isHovering ? Colors.green.shade100 : null,
            child: _buildTile(
              node,
              depth,
              isSelected: isSelected,
              isFolder: isFolder,
              isExpanded: isExpanded,
              hasChildren: hasChildren,
            ),
          ),
        );
      },
      onAcceptWithDetails: (details) async {
        // 校验已在 onWillAcceptWithDetails 完成，此处直接改
        await _db.moveNode(details.data, node.id);
        await _loadTree();
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        draggableTile,
        // ✅ 有子节点且展开时，显示递归内容
        if (hasChildren && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((child) {
                return _buildTreeNode(child, depth + 1);
              }).toList(),
            ),
          ),
      ],
    );
  }
}