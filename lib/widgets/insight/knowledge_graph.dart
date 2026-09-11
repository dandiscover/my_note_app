// lib/widgets/insight/knowledge_graph.dart
// 知识图谱 — 节点/边渲染（优化版，公开 KnowledgeGraphPainter）
// ✅ 任务二：GraphEdge 加 isWeak；GraphBuilder 加同标签弱边；三处布局跳过弱边；Painter 加弱边虚线分支
// ✅ T-019：KnowledgeGraphWidget 加 GestureDetector，onTapUp 命中节点触发 onNodeTap
// ✅ T-020：笔记节点常显标签，文件夹节点保持图标
// ✅ 问题 7 修复：GestureDetector.behavior 从 opaque 改为 deferToChild，避免抢 InteractiveViewer 多指手势

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/node.dart';

// ─── 数据模型 ──────────────────────────────────────────────

class GraphNode {
  final String id;
  final String label;
  final String? type;
  double x;
  double y;
  double radius;
  final Color color;
  final bool isFolder;

  GraphNode({
    required this.id,
    required this.label,
    this.type,
    required this.x,
    required this.y,
    this.radius = 24,
    this.color = Colors.blue,
    this.isFolder = false,
  });
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final double weight;
  final bool isWeak; // ✅ 任务二新增：弱连接（同标签）

  GraphEdge({
    required this.sourceId,
    required this.targetId,
    this.weight = 1.0,
    this.isWeak = false,
  });
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const GraphData({
    required this.nodes,
    required this.edges,
  });

  bool get isEmpty => nodes.isEmpty;
  int get nodeCount => nodes.length;
  int get edgeCount => edges.length;
}

// ─── 图谱布局引擎 ──────────────────────────────────────────

enum GraphLayoutMode {
  forceDirected,
  groupByType,
  localFocus,
}

class ForceDirectedLayout {
  static const double repulsion = 200.0;
  static const double attraction = 0.05;
  static const double damping = 0.9;
  static const int iterations = 50;

  static GraphData layout(
    GraphData graph,
    Size size, {
    GraphLayoutMode mode = GraphLayoutMode.forceDirected,
    String? focusNodeId,
    int localHopCount = 2,
  }) {
    if (graph.nodes.isEmpty) return graph;

    final nodes = graph.nodes.toList();
    final edges = graph.edges.toList();

    if (mode == GraphLayoutMode.forceDirected) {
      _forceDirectedLayout(nodes, edges, size);
    } else if (mode == GraphLayoutMode.groupByType) {
      _groupByTypeLayout(nodes, size);
    } else if (mode == GraphLayoutMode.localFocus) {
      _localFocusLayout(nodes, edges, size, focusNodeId, localHopCount);
    }

    return GraphData(nodes: nodes, edges: edges);
  }

  static void _forceDirectedLayout(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    Size size,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(size.width, size.height) / 2 * 0.8;

    final random = Random(42);
    for (var node in nodes) {
      node.x = centerX + (random.nextDouble() - 0.5) * radius * 2;
      node.y = centerY + (random.nextDouble() - 0.5) * radius * 2;
    }

    for (var iter = 0; iter < iterations; iter++) {
      final forces = <String, Offset>{};
      for (var node in nodes) {
        forces[node.id] = Offset.zero;
      }

      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final a = nodes[i];
          final b = nodes[j];
          final dx = a.x - b.x;
          final dy = a.y - b.y;
          final dist = max(sqrt(dx * dx + dy * dy), 1.0);
          final force = repulsion / (dist * dist);
          final fx = dx / dist * force;
          final fy = dy / dist * force;
          forces[a.id] = forces[a.id]! + Offset(fx, fy);
          forces[b.id] = forces[b.id]! - Offset(fx, fy);
        }
      }

      for (var edge in edges) {
        if (edge.isWeak) continue; // ✅ 弱连接不参与力导向
        final source = nodes.firstWhere((n) => n.id == edge.sourceId);
        final target = nodes.firstWhere((n) => n.id == edge.targetId);
        final dx = target.x - source.x;
        final dy = target.y - source.y;
        final dist = max(sqrt(dx * dx + dy * dy), 1.0);
        final force = attraction * dist * edge.weight;
        final fx = dx / dist * force;
        final fy = dy / dist * force;
        forces[source.id] = forces[source.id]! + Offset(fx, fy);
        forces[target.id] = forces[target.id]! - Offset(fx, fy);
      }

      for (var node in nodes) {
        final dx = centerX - node.x;
        final dy = centerY - node.y;
        final dist = max(sqrt(dx * dx + dy * dy), 1.0);
        final force = 0.01 * dist;
        forces[node.id] = forces[node.id]! + Offset(dx / dist * force, dy / dist * force);
      }

      for (var node in nodes) {
        final force = forces[node.id]!;
        node.x += force.dx * damping;
        node.y += force.dy * damping;
        node.x = max(10, min(size.width - 10, node.x));
        node.y = max(10, min(size.height - 10, node.y));
      }
    }
  }

  static void _groupByTypeLayout(List<GraphNode> nodes, Size size) {
    final groups = <String, List<GraphNode>>{};
    for (var node in nodes) {
      final type = node.type ?? 'unknown';
      groups.putIfAbsent(type, () => []).add(node);
    }

    final typeKeys = groups.keys.toList();
    final groupSpacing = size.width / (typeKeys.length + 1);

    for (var i = 0; i < typeKeys.length; i++) {
      final group = groups[typeKeys[i]]!;
      final centerX = groupSpacing * (i + 1);
      final centerY = size.height / 2;
      final radius = 60.0;

      for (var j = 0; j < group.length; j++) {
        final angle = (j / group.length) * 2 * pi;
        group[j].x = centerX + radius * cos(angle);
        group[j].y = centerY + radius * sin(angle);
      }
    }
  }

  static void _localFocusLayout(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    Size size,
    String? focusNodeId,
    int hopCount,
  ) {
    if (focusNodeId == null) {
      _forceDirectedLayout(nodes, edges, size);
      return;
    }

    GraphNode? focusNode;
    final connectedIds = <String>{};
    for (var node in nodes) {
      if (node.id == focusNodeId) {
        focusNode = node;
        connectedIds.add(node.id);
      }
    }

    if (focusNode != null) {
      var currentIds = {focusNodeId};
      for (var hop = 0; hop < hopCount; hop++) {
        final nextIds = <String>{};
        for (var edge in edges) {
          if (edge.isWeak) continue; // ✅ 弱连接不参与聚焦连通性
          if (currentIds.contains(edge.sourceId)) {
            nextIds.add(edge.targetId);
          }
          if (currentIds.contains(edge.targetId)) {
            nextIds.add(edge.sourceId);
          }
        }
        currentIds = nextIds;
        connectedIds.addAll(currentIds);
      }
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(size.width, size.height) / 3;

    if (focusNode != null) {
      focusNode.x = centerX;
      focusNode.y = centerY;
    }

    int idx = 0;
    for (var node in nodes) {
      if (node.id == focusNodeId) continue;
      if (connectedIds.contains(node.id)) {
        final angle = (idx / (connectedIds.length - 1)) * 2 * pi;
        node.x = centerX + radius * 0.7 * cos(angle);
        node.y = centerY + radius * 0.7 * sin(angle);
        idx++;
      } else {
        final angle = (idx / (nodes.length - connectedIds.length + 1)) * 2 * pi;
        node.x = centerX + radius * 1.5 * cos(angle);
        node.y = centerY + radius * 1.5 * sin(angle);
        idx++;
      }
    }
  }
}

// ─── 图谱构建器 ─────────────────────────────────────────────

class GraphBuilder {
  static GraphData build(
    List<Node> nodes, {
    Map<String, String>? noteContents,
    Map<String, Set<String>>? noteTagsByNodeId, // ✅ 任务二新增
    bool includeTagEdges = false,               // ✅ 任务二新增
  }) {
    final graphNodes = <GraphNode>[];
    final graphEdges = <GraphEdge>[];
    final nodeMap = <String, Node>{};

    for (var node in nodes) {
      nodeMap[node.id] = node;
    }

    for (var node in nodes) {
      final color = _getNodeColor(node);
      graphNodes.add(
        GraphNode(
          id: node.id,
          label: node.title,
          type: node.nodeType,
          x: 0,
          y: 0,
          color: color,
          isFolder: node.isFolder,
        ),
      );
    }

    for (var node in nodes) {
      if (node.parentId != null && nodeMap.containsKey(node.parentId)) {
        final exists = graphEdges.any((e) =>
          e.sourceId == node.parentId && e.targetId == node.id
        );
        if (!exists) {
          graphEdges.add(
            GraphEdge(
              sourceId: node.parentId!,
              targetId: node.id,
              weight: node.isFolder ? 0.8 : 1.0,
            ),
          );
        }
      }
    }

    // ✅ 任务二：同标签弱边（加在 folder edge 之后）
    if (includeTagEdges && noteTagsByNodeId != null && noteTagsByNodeId.isNotEmpty) {
      final noteNodeIds = noteTagsByNodeId.keys.toList();

      // 已存在 folder edge 的对，跳过
      final existingPairs = <String>{};
      for (var e in graphEdges) {
        final a = e.sourceId;
        final b = e.targetId;
        existingPairs.add(a.compareTo(b) < 0 ? '$a|$b' : '$b|$a');
      }

      for (var i = 0; i < noteNodeIds.length; i++) {
        for (var j = i + 1; j < noteNodeIds.length; j++) {
          final a = noteNodeIds[i];
          final b = noteNodeIds[j];
          final pairKey = a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
          if (existingPairs.contains(pairKey)) continue;

          final tagsA = noteTagsByNodeId[a]!;
          final tagsB = noteTagsByNodeId[b]!;
          if (tagsA.intersection(tagsB).isEmpty) continue;

          graphEdges.add(GraphEdge(
            sourceId: a,
            targetId: b,
            weight: 1.0,
            isWeak: true,
          ));
        }
      }
    }

    for (var node in graphNodes) {
      final children = nodes.where((n) => n.parentId == node.id).toList();
      if (children.isNotEmpty) {
        node.radius = 24 + min(children.length, 10) * 1.5;
      }
    }

    return GraphData(nodes: graphNodes, edges: graphEdges);
  }

  static Color _getNodeColor(Node node) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.red,
      Colors.amber,
    ];
    final hash = node.id.hashCode.abs();
    return colors[hash % colors.length];
  }
}

// ─── 图谱渲染组件 ───────────────────────────────────────────

class KnowledgeGraphWidget extends StatefulWidget {
  final GraphData graph;
  final Function(String) onNodeTap;
  final GraphLayoutMode mode;

  const KnowledgeGraphWidget({
    super.key,
    required this.graph,
    required this.onNodeTap,
    this.mode = GraphLayoutMode.forceDirected,
  });

  @override
  State<KnowledgeGraphWidget> createState() => _KnowledgeGraphWidgetState();
}

class _KnowledgeGraphWidgetState extends State<KnowledgeGraphWidget> {
  String? _hoveredNodeId;

  @override
  Widget build(BuildContext context) {
    if (widget.graph.isEmpty) {
      return const Center(
        child: Text('图谱数据不足，至少需要2个节点', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    return GestureDetector(
      // ✅ 问题 7 修复：opaque → deferToChild
      // 理由：opaque 会在手势竞技场里提前占位，InteractiveViewer 的多指 scale
      // 识别器可能失去竞争机会。deferToChild 让事件按正常命中树传递。
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (details) {
        // ✅ T-019：命中判定
        // 说明：KnowledgeGraphWidget 在 InteractiveViewer 内，
        // Flutter 手势系统已对 details.localPosition 做逆变换，
        // 此处坐标与 node.x / node.y 处于同一坐标系，无需手动乘/除 scale。
        final localPos = details.localPosition;
        GraphNode? hit;
        // 反向遍历：后画的在上层，视觉与命中一致
        for (var node in widget.graph.nodes.reversed) {
          final dx = localPos.dx - node.x;
          final dy = localPos.dy - node.y;
          if (dx * dx + dy * dy <= node.radius * node.radius) {
            hit = node;
            break;
          }
        }
        if (hit != null) {
          widget.onNodeTap(hit.id);
        }
      },
      child: CustomPaint(
        painter: KnowledgeGraphPainter(
          graph: widget.graph,
          onNodeTap: widget.onNodeTap,
          hoveredNodeId: _hoveredNodeId,
          mode: widget.mode,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// ─── ✅ 公开的图谱绘制器 ──────────────────────────────────

class KnowledgeGraphPainter extends CustomPainter {
  final GraphData graph;
  final String? hoveredNodeId;
  final Function(String) onNodeTap;
  final GraphLayoutMode mode;

  KnowledgeGraphPainter({
    required this.graph,
    required this.onNodeTap,
    this.hoveredNodeId,
    this.mode = GraphLayoutMode.forceDirected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final hoverEdgePaint = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // ✅ 任务二：弱边画笔（比文件夹关系更弱）
    final weakEdgePaint = Paint()
      ..color = Colors.teal.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var edge in graph.edges) {
      final source = graph.nodes.firstWhere((n) => n.id == edge.sourceId);
      final target = graph.nodes.firstWhere((n) => n.id == edge.targetId);

      if (edge.isWeak) {
        // 弱连接：虚线，不参与 hover
        _drawDashedLine(
          canvas,
          Offset(source.x, source.y),
          Offset(target.x, target.y),
          weakEdgePaint,
        );
      } else {
        final isHovered = hoveredNodeId == source.id || hoveredNodeId == target.id;
        canvas.drawLine(
          Offset(source.x, source.y),
          Offset(target.x, target.y),
          isHovered ? hoverEdgePaint : edgePaint,
        );
      }
    }

    for (var node in graph.nodes) {
      final isHovered = hoveredNodeId == node.id;
      final radius = isHovered ? node.radius * 1.2 : node.radius;
      final color = isHovered ? node.color.withValues(alpha: 1.0) : node.color.withValues(alpha: 0.8);

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(node.x + 2, node.y + 2), radius, shadowPaint);

      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(node.x, node.y), radius, nodePaint);

      final borderPaint = Paint()
        ..color = isHovered ? Colors.white : Colors.transparent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(node.x, node.y), radius, borderPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: node.isFolder ? '📁' : '📄',
          style: const TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(node.x - textPainter.width / 2, node.y - textPainter.height / 2),
      );

      if (isHovered) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: node.label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        final labelX = node.x - labelPainter.width / 2;
        final labelY = node.y + radius + 6;

        final bgPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              labelX - 4,
              labelY - 2,
              labelPainter.width + 8,
              labelPainter.height + 4,
            ),
            const Radius.circular(4),
          ),
          bgPaint,
        );

        labelPainter.paint(canvas, Offset(labelX, labelY));
      } else if (!node.isFolder && node.type == 'note') {
        // ✅ T-020：笔记节点常显标签（小字灰色，与悬停互斥）
        final labelPainter = TextPainter(
          text: TextSpan(
            text: node.label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        );
        labelPainter.layout(maxWidth: 80);
        final labelX = node.x - labelPainter.width / 2;
        final labelY = node.y + radius + 4;
        labelPainter.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  // ✅ 任务二：虚线辅助方法
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(KnowledgeGraphPainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.hoveredNodeId != hoveredNodeId;
  }
}