// lib/pages/insight/graph_tab.dart
// 知识图谱 Tab（独立组件）

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/node.dart';
import '../../models/note.dart';
import '../../widgets/insight/knowledge_graph.dart';

class GraphTab extends StatefulWidget {
  final List<Node> allNodes;
  final List<NotebookEntry> allNotes;

  const GraphTab({
    super.key,
    required this.allNodes,
    required this.allNotes,
  });

  @override
  State<GraphTab> createState() => _GraphTabState();
}

class _GraphTabState extends State<GraphTab> {
  GraphData? _graphData;
  bool _isGraphReady = false;
  String? _focusNodeId;
  GraphLayoutMode _layoutMode = GraphLayoutMode.forceDirected;

  // ─── 缓存 ──────────────────────────────────────────────────
  GraphData? _cachedGraph;
  GraphData? _cachedGroupGraph;
  GraphData? _cachedFocusGraph;

  @override
  void initState() {
    super.initState();
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

    // 按类型分组布局
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);
    final size = Size(graphWidth, graphHeight);

    _cachedGroupGraph = ForceDirectedLayout.layout(
      rawGraph,
      size,
      mode: GraphLayoutMode.groupByType,
    );

    _applyLayout(mode: _layoutMode);
  }

  void _applyLayout({
    GraphLayoutMode? mode,
    String? focusNodeId,
  }) {
    final finalMode = mode ?? _layoutMode;
    final finalFocus = focusNodeId ?? _focusNodeId;

    if (_cachedGraph == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);
    final size = Size(graphWidth, graphHeight);

    GraphData result;

    if (finalMode == GraphLayoutMode.groupByType && _cachedGroupGraph != null) {
      result = _cachedGroupGraph!;
    } else if (finalMode == GraphLayoutMode.localFocus && finalFocus != null) {
      result = ForceDirectedLayout.layout(
        _cachedGraph!,
        size,
        mode: GraphLayoutMode.localFocus,
        focusNodeId: finalFocus,
        localHopCount: 2,
      );
    } else {
      result = ForceDirectedLayout.layout(
        _cachedGraph!,
        size,
        mode: GraphLayoutMode.forceDirected,
      );
    }

    setState(() {
      _graphData = result;
      _isGraphReady = true;
      _layoutMode = finalMode;
      _focusNodeId = finalFocus;
    });
  }

  void _onNodeTap(String nodeId) {
    if (_layoutMode == GraphLayoutMode.localFocus) {
      _applyLayout(
        mode: GraphLayoutMode.localFocus,
        focusNodeId: nodeId,
      );
      return;
    }
    // 否则通知父组件跳转
    final node = widget.allNodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => widget.allNodes.first,
    );
    _openNode(node);
  }

  void _openNode(Node node) {
    // TODO: 跳转到节点详情
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📄 ${node.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _changeMode(GraphLayoutMode mode) {
    if (_layoutMode == mode) return;
    setState(() {
      _layoutMode = mode;
      _focusNodeId = null;
    });
    _applyLayout(mode: mode, focusNodeId: null);
  }

  // ─── UI ──────────────────────────────────────────────────────

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

    if (!_isGraphReady || _graphData == null) {
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

    final graph = _graphData!;
    if (graph.isEmpty) {
      return const Center(
        child: Text('图谱数据不足，至少需要2个节点', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);

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
              child: SizedBox(
                width: graphWidth,
                height: graphHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = max(constraints.maxWidth, graphWidth);
                    final height = max(constraints.maxHeight, graphHeight);
                    final size = Size(width, height);
                    final relayouted = ForceDirectedLayout.layout(
                      graph,
                      size,
                      mode: _layoutMode,
                      focusNodeId: _focusNodeId,
                      localHopCount: 2,
                    );
                    return KnowledgeGraphWidget(
                      graph: relayouted,
                      onNodeTap: _onNodeTap,
                      mode: _layoutMode,
                    );
                  },
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