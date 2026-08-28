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

  @override
  void initState() {
    super.initState();
    _loadTree();
    if (widget.currentNodeId != null) {
      _db.getAncestors(widget.currentNodeId!).then((ancestors) {
        setState(() {
          for (var node in ancestors) {
            if (node.isFolder) {
              _expandedIds.add(node.id);
            }
          }
        });
      });
    }
  }

  Future<void> _loadTree() async {
    setState(() => _isLoading = true);
    try {
      final roots = await _db.getRootNodes();
      setState(() {
        _tree = roots;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载文件树失败: $e');
      setState(() => _isLoading = false);
    }
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
                          return _buildTreeNode(node);
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

  Widget _buildTreeNode(Node node) {
    final isExpanded = _expandedIds.contains(node.id);
    final isSelected = node.id == widget.currentNodeId;
    final isFolder = node.isFolder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          child: ListTile(
            dense: true,
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
            trailing: isFolder
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
                setState(() {
                  if (isExpanded) {
                    _expandedIds.remove(node.id);
                  } else {
                    _expandedIds.add(node.id);
                  }
                });
              } else {
                widget.onNodeTap(node.id, node.nodeType);
              }
            },
          ),
        ),
        if (isFolder && isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: FutureBuilder<List<Node>>(
              future: _db.getChildren(node.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Text(
                      '空文件夹',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.data!.map((child) {
                    return _buildTreeNode(child);
                  }).toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}