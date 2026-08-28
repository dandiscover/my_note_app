import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';

class FolderSelectorDialog extends StatefulWidget {
  final String? excludeNodeId;
  final String? currentParentId;

  const FolderSelectorDialog({
    super.key,
    this.excludeNodeId,
    this.currentParentId,
  });

  @override
  State<FolderSelectorDialog> createState() => _FolderSelectorDialogState();
}

class _FolderSelectorDialogState extends State<FolderSelectorDialog> {
  final DatabaseService _db = DatabaseService();
  List<Node> _folders = [];
  bool _isLoading = true;
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final allNodes = await _db.getAllNodes();
      final folders = allNodes.where((n) {
        if (!n.isFolder) return false;
        if (n.id == widget.excludeNodeId) return false;
        return true;
      }).toList();
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载文件夹失败: $e');
      setState(() => _isLoading = false);
    }
  }

  /// ✅ 修复：返回 List<Widget>，直接展开到 ListView
  List<Widget> _buildFolderTree(List<Node> nodes, String? parentId, int depth) {
    final children = nodes.where((n) => n.parentId == parentId).toList();
    if (children.isEmpty) return [];

    final List<Widget> widgets = [];
    for (var node in children) {
      final isSelected = _selectedFolderId == node.id;
      final isCurrent = node.id == widget.currentParentId;

      widgets.add(
        ListTile(
          dense: true,
          leading: Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: const Icon(Icons.folder, size: 18, color: Colors.amber),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  node.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Colors.blue : null,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '当前位置',
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                  ),
                ),
            ],
          ),
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedFolderId = node.id;
            });
          },
        ),
      );

      // 递归添加子节点
      widgets.addAll(_buildFolderTree(nodes, node.id, depth + 1));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择目标文件夹'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : _folders.isEmpty
              ? const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      '暂无可用文件夹',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  height: 350,
                  child: ListView(
                    children: [
                      // 根目录选项
                      ListTile(
                        leading: const Icon(Icons.folder, size: 18, color: Colors.grey),
                        title: const Text('📚 根目录（智库）'),
                        selected: _selectedFolderId == null,
                        onTap: () {
                          setState(() {
                            _selectedFolderId = null;
                          });
                        },
                      ),
                      const Divider(),
                      // ✅ 修复：直接展开列表
                      ..._buildFolderTree(_folders, null, 0),
                    ],
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedFolderId == null
              ? null
              : () => Navigator.pop(context, _selectedFolderId),
          child: const Text('移动到这里'),
        ),
      ],
    );
  }
}