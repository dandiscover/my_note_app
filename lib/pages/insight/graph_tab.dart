// lib/pages/insight/graph_tab.dart
// 知识图谱 Tab（独立组件，支持刷新）

import 'dart:math';
import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import '../../models/note.dart';
import '../../widgets/insight/knowledge_graph.dart';
import '../note_detail_page.dart';
import '../book_detail_page.dart';

class GraphTab extends StatefulWidget {
  final List<Node> allNodes;
  final List<NotebookEntry> allNotes;

  const GraphTab({
    super.key,
    required this.allNodes,
    required this.allNotes,
  });

  @override
  State<GraphTab> createState() => GraphTabState();
}

class GraphTabState extends State<GraphTab> {
  // ✅ 添加 DatabaseService 实例
  final DatabaseService _db = DatabaseService();

  GraphData? _graphData;
  bool _isGraphReady = false;
  String? _focusNodeId;
  GraphLayoutMode _layoutMode = GraphLayoutMode.forceDirected;

  GraphData? _cachedGraph;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedGraph == null) {
      _prepareGraph();
    }
  }

  void refresh() {
    setState(() {
      _cachedGraph = null;
      _isGraphReady = false;
      _graphData = null;
    });
    _prepareGraph();
  }

  void _prepareGraph() {
    final validNodes = widget.allNodes.where((n) =>
      n.isFolder || n.nodeType == 'note' || n.nodeType == 'book'
    ).toList();

    if (validNodes.isEmpty) {
      setState(() {
        _isGraphReady = false;
        _graphData = null;
      });
      return;
    }

    final noteContentMap = <String, String>{};
    for (var note in widget.allNotes) {
      noteContentMap[note.id] = note.content;
    }

    final rawGraph = GraphBuilder.build(validNodes, noteContents: noteContentMap);
    _cachedGraph = rawGraph;
    _applyLayout();
  }

  void _applyLayout() {
    if (_cachedGraph == null) return;
    setState(() {
      _isGraphReady = true;
    });
  }

  GraphData _getLayoutedGraph(Size size) {
    if (_cachedGraph == null) return GraphData(nodes: [], edges: []);

    GraphData result;

    if (_layoutMode == GraphLayoutMode.groupByType) {
      result = ForceDirectedLayout.layout(
        _cachedGraph!,
        size,
        mode: GraphLayoutMode.groupByType,
      );
    } else if (_layoutMode == GraphLayoutMode.localFocus && _focusNodeId != null) {
      result = ForceDirectedLayout.layout(
        _cachedGraph!,
        size,
        mode: GraphLayoutMode.localFocus,
        focusNodeId: _focusNodeId,
        localHopCount: 2,
      );
    } else {
      result = ForceDirectedLayout.layout(
        _cachedGraph!,
        size,
        mode: GraphLayoutMode.forceDirected,
      );
    }

    return result;
  }

  void _onNodeTap(String nodeId) {
    if (_layoutMode == GraphLayoutMode.localFocus) {
      setState(() {
        _focusNodeId = nodeId;
      });
      _applyLayout();
      return;
    }
    final node = widget.allNodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => widget.allNodes.first,
    );
    _openNode(node);
  }

  void _openNode(Node node) {
    if (node.nodeType == 'note' && node.targetId != null) {
      _db.getNoteByNodeId(node.id).then((note) {
        if (note != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteDetailPage(
                entry: note,
                isFromCollection: false,
                nodeId: node.id,
              ),
            ),
          );
        }
      });
    } else if (node.nodeType == 'book' && node.targetId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(
            bookId: node.targetId!,
            nodeId: node.id,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📁 ${node.title}'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _changeMode(GraphLayoutMode mode) {
    if (_layoutMode == mode) return;
    setState(() {
      _layoutMode = mode;
      if (mode != GraphLayoutMode.localFocus) {
        _focusNodeId = null;
      }
      _isGraphReady = false;
    });
    _prepareGraph();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allNodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bubble_chart, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text('还没有内容', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('去采集页创建一些笔记和图书吧', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_isGraphReady || _cachedGraph == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('正在构建知识图谱...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);
    final size = Size(graphWidth, graphHeight);

    final graph = _getLayoutedGraph(size);

    if (graph.isEmpty) {
      return const Center(
        child: Text('图谱数据不足，至少需要2个节点', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: SizedBox(
            width: graphWidth,
            height: graphHeight,
            child: InteractiveViewer(
              minScale: 0.2,
              maxScale: 3.0,
              constrained: false,
              child: Container(
                width: graphWidth,
                height: graphHeight,
                child: KnowledgeGraphWidget(
                  graph: graph,
                  onNodeTap: _onNodeTap,
                  mode: _layoutMode,
                ),
              ),
            ),
          ),
        ),
        _buildFooter(graph),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeChip('🌐 力导向', GraphLayoutMode.forceDirected),
          const SizedBox(width: 6),
          _buildModeChip('📂 分组', GraphLayoutMode.groupByType),
          const SizedBox(width: 6),
          _buildModeChip('🎯 聚焦', GraphLayoutMode.localFocus),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, GraphLayoutMode mode) {
    final isSelected = _layoutMode == mode;
    return GestureDetector(
      onTap: () => _changeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(GraphData graph) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '🖱️ 悬停查看 · 点击跳转 · 滚轮缩放',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
          Text(
            '${graph.nodes.length} 节点 · ${graph.edges.length} 边',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}