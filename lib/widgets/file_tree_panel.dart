// lib/widgets/file_tree_panel.dart
// R-4 批A：改薄壳 —— 内部调 NodeTreeView

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';
import 'tree/node_tree_view.dart';

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
  int _reloadTick = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 3,
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部保留
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📍 ${widget.currentNodeName}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.blue.shade700),
                    ),
                  ),
              ],
            ),
          ),
          // 树 —— NodeTreeView
          Expanded(
            child: NodeTreeView(
              currentNodeId: widget.currentNodeId,
              reloadTick: _reloadTick,
              onTap: (node) => widget.onNodeTap(node.id, node.nodeType),
              onDragDrop: (draggedId, targetId) async {
                await DatabaseService().moveNode(draggedId, targetId);
                if (mounted) setState(() => _reloadTick++);
              },
            ),
          ),
          // 底部保留
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
                  onPressed: () => setState(() => _reloadTick++),
                  tooltip: '刷新',
                ),
                const SizedBox(width: 4),
                Text(
                  '文件树',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}