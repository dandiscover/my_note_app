import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/node.dart';

// ============================================================
// 图数据
// ============================================================

class GraphNode {
  final Node node;
  double x;
  double y;
  double vx;
  double vy;
  int degree = 0;

  GraphNode({
    required this.node,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.degree = 0,
  });
}

class GraphEdge {
  final String sourceId;
  final String targetId;
  final String type; // 'parent' | 'tag' | 'link'

  GraphEdge({
    required this.sourceId,
    required this.targetId,
    this.type = 'parent',
  });
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  GraphData({required this.nodes, required this.edges});

  bool get isEmpty => nodes.isEmpty;
  bool get isNotEmpty => nodes.isNotEmpty;

  void calculateDegrees() {
    final degreeMap = <String, int>{};
    for (var node in nodes) {
      degreeMap[node.node.id] = 0;
    }
    for (var edge in edges) {
      degreeMap[edge.sourceId] = (degreeMap[edge.sourceId] ?? 0) + 1;
      degreeMap[edge.targetId] = (degreeMap[edge.targetId] ?? 0) + 1;
    }
    for (var node in nodes) {
      node.degree = degreeMap[node.node.id] ?? 0;
    }
  }

  Map<String, GraphNode> get nodeMap {
    return {for (var n in nodes) n.node.id: n};
  }
}

// ============================================================
// 布局模式枚举
// ============================================================

enum GraphLayoutMode {
  forceDirected,
  groupByType,
  localFocus,
}

// ============================================================
// 配置参数
// ============================================================

class LayoutConfig {
  static const double repulsion = 1200.0;
  static const double springStrength = 0.03;
  static const double springDistance = 140.0;
  static const double centerForce = 0.006;
  static const double damping = 0.82;
  static const int iterations = 300;
  static const double maxSpeed = 30.0;
  static const double maxForce = 120.0;

  static const double groupRepulsion = 800.0;
  static const double groupSpringStrength = 0.025;
  static const double groupSpringDistance = 120.0;
  static const double groupCenterForce = 0.004;

  static const double localRepulsion = 600.0;
  static const double localSpringStrength = 0.04;
  static const double localSpringDistance = 100.0;
}

// ============================================================
// 布局参数结构
// ============================================================

class LayoutParams {
  final double repulsion;
  final double springStrength;
  final double springDistance;
  final double centerForce;
  final double damping;
  final int iterations;
  final double maxSpeed;
  final double maxForce;

  const LayoutParams({
    required this.repulsion,
    required this.springStrength,
    required this.springDistance,
    required this.centerForce,
    required this.damping,
    required this.iterations,
    required this.maxSpeed,
    required this.maxForce,
  });
}

// ============================================================
// 力导向布局算法
// ============================================================

class ForceDirectedLayout {
  static GraphData layout(
    GraphData graph,
    Size size, {
    GraphLayoutMode mode = GraphLayoutMode.forceDirected,
    String? focusNodeId,
    int localHopCount = 2,
  }) {
    if (graph.nodes.isEmpty ||
        size.width.isNaN || size.height.isNaN ||
        size.width <= 0 || size.height <= 0) {
      return graph;
    }

    // 预处理：局部聚焦
    GraphData processedGraph;
    if (mode == GraphLayoutMode.localFocus && focusNodeId != null) {
      processedGraph = _filterLocalGraph(graph, focusNodeId, localHopCount);
    } else {
      processedGraph = graph;
    }

    if (processedGraph.nodes.isEmpty) return processedGraph;

    processedGraph.calculateDegrees();

    final config = _getConfigForMode(mode);
    final result = _runForceDirected(processedGraph, size, config, mode);
    return _resolveOverlaps(result, size);
  }

  static LayoutParams _getConfigForMode(GraphLayoutMode mode) {
    switch (mode) {
      case GraphLayoutMode.groupByType:
        return LayoutParams(
          repulsion: LayoutConfig.groupRepulsion,
          springStrength: LayoutConfig.groupSpringStrength,
          springDistance: LayoutConfig.groupSpringDistance,
          centerForce: LayoutConfig.groupCenterForce,
          damping: LayoutConfig.damping,
          iterations: LayoutConfig.iterations,
          maxSpeed: LayoutConfig.maxSpeed,
          maxForce: LayoutConfig.maxForce,
        );
      case GraphLayoutMode.localFocus:
        return LayoutParams(
          repulsion: LayoutConfig.localRepulsion,
          springStrength: LayoutConfig.localSpringStrength,
          springDistance: LayoutConfig.localSpringDistance,
          centerForce: LayoutConfig.centerForce * 0.5,
          damping: LayoutConfig.damping,
          iterations: 200,
          maxSpeed: LayoutConfig.maxSpeed,
          maxForce: LayoutConfig.maxForce,
        );
      default:
        return LayoutParams(
          repulsion: LayoutConfig.repulsion,
          springStrength: LayoutConfig.springStrength,
          springDistance: LayoutConfig.springDistance,
          centerForce: LayoutConfig.centerForce,
          damping: LayoutConfig.damping,
          iterations: LayoutConfig.iterations,
          maxSpeed: LayoutConfig.maxSpeed,
          maxForce: LayoutConfig.maxForce,
        );
    }
  }

  static GraphData _runForceDirected(
    GraphData graph,
    Size size,
    LayoutParams config,
    GraphLayoutMode mode,
  ) {
    final nodes = graph.nodes;
    final edges = graph.edges;
    final random = Random(42);
    final margin = 60.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final connectedIds = <String>{};
    for (var edge in edges) {
      connectedIds.add(edge.sourceId);
      connectedIds.add(edge.targetId);
    }

    // 初始化位置
    if (mode == GraphLayoutMode.groupByType) {
      _initGroupPositions(nodes, size);
    } else {
      for (var n in nodes) {
        if (connectedIds.contains(n.node.id)) {
          n.x = margin + random.nextDouble() * (size.width - 2 * margin);
          n.y = margin + random.nextDouble() * (size.height - 2 * margin);
        } else {
          final angle = random.nextDouble() * 2 * pi;
          final radius = 60 + random.nextDouble() * 60;
          n.x = centerX + cos(angle) * radius;
          n.y = centerY + sin(angle) * radius;
        }
        n.vx = 0;
        n.vy = 0;
      }
    }

    for (int iter = 0; iter < config.iterations; iter++) {
      // 排斥力
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final dx = nodes[j].x - nodes[i].x;
          final dy = nodes[j].y - nodes[i].y;
          double dist = sqrt(dx * dx + dy * dy);
          if (dist < 1.0) dist = 1.0;

          double repulsion = config.repulsion;
          if (mode == GraphLayoutMode.groupByType) {
            final typeI = _getNodeType(nodes[i].node);
            final typeJ = _getNodeType(nodes[j].node);
            if (typeI != typeJ) {
              repulsion = config.repulsion * 1.5;
            } else {
              repulsion = config.repulsion * 0.7;
            }
          }

          final force = repulsion / (dist * dist);
          final fx = force * dx / dist;
          final fy = force * dy / dist;
          nodes[i].vx -= fx.clamp(-config.maxForce, config.maxForce);
          nodes[i].vy -= fy.clamp(-config.maxForce, config.maxForce);
          nodes[j].vx += fx.clamp(-config.maxForce, config.maxForce);
          nodes[j].vy += fy.clamp(-config.maxForce, config.maxForce);
        }
      }

      // 弹簧力
      for (var edge in edges) {
        final source = nodes.firstWhere((n) => n.node.id == edge.sourceId);
        final target = nodes.firstWhere((n) => n.node.id == edge.targetId);
        final dx = target.x - source.x;
        final dy = target.y - source.y;
        double dist = sqrt(dx * dx + dy * dy);
        if (dist < 1.0) dist = 1.0;

        double strength = config.springStrength;
        double distance = config.springDistance;
        double maxSpring = 15.0;

        if (edge.type == 'link') {
          strength = config.springStrength * 1.2;
          distance = config.springDistance * 0.8;
          maxSpring = 18.0;
        } else if (edge.type == 'tag') {
          strength = config.springStrength * 0.7;
          distance = config.springDistance * 1.1;
          maxSpring = 10.0;
        }

        final force = strength * (dist - distance);
        final fx = force * dx / dist;
        final fy = force * dy / dist;
        source.vx += fx.clamp(-maxSpring, maxSpring);
        source.vy += fy.clamp(-maxSpring, maxSpring);
        target.vx -= fx.clamp(-maxSpring, maxSpring);
        target.vy -= fy.clamp(-maxSpring, maxSpring);
      }

      // 中心引力
      for (var n in nodes) {
        final isIsolated = !connectedIds.contains(n.node.id);
        final strength = isIsolated ? config.centerForce * 3 : config.centerForce;
        n.vx -= strength * (n.x - centerX);
        n.vy -= strength * (n.y - centerY);
      }

      // 更新位置
      for (var n in nodes) {
        double speed = sqrt(n.vx * n.vx + n.vy * n.vy);
        if (speed > config.maxSpeed) {
          n.vx = (n.vx / speed) * config.maxSpeed;
          n.vy = (n.vy / speed) * config.maxSpeed;
        }
        n.vx *= config.damping;
        n.vy *= config.damping;
        n.x += n.vx;
        n.y += n.vy;

        if (n.x.isNaN || n.x.isInfinite || n.y.isNaN || n.y.isInfinite) {
          n.x = centerX + (random.nextDouble() - 0.5) * 80;
          n.y = centerY + (random.nextDouble() - 0.5) * 80;
          n.vx = 0;
          n.vy = 0;
        } else {
          n.x = max(margin, min(size.width - margin, n.x));
          n.y = max(margin, min(size.height - margin, n.y));
        }
      }
    }

    // 最终安全检查
    for (var n in nodes) {
      if (n.x.isNaN || n.x.isInfinite || n.y.isNaN || n.y.isInfinite) {
        n.x = centerX + (Random().nextDouble() - 0.5) * 80;
        n.y = centerY + (Random().nextDouble() - 0.5) * 80;
        n.vx = 0;
        n.vy = 0;
      }
      n.x = max(margin, min(size.width - margin, n.x));
      n.y = max(margin, min(size.height - margin, n.y));
    }

    return graph;
  }

  static void _initGroupPositions(List<GraphNode> nodes, Size size) {
    final noteNodes = <GraphNode>[];
    final bookNodes = <GraphNode>[];
    final folderNodes = <GraphNode>[];
    final otherNodes = <GraphNode>[];

    for (var n in nodes) {
      if (n.node.isFolder) {
        folderNodes.add(n);
      } else if (n.node.nodeType == 'note') {
        noteNodes.add(n);
      } else if (n.node.nodeType == 'book') {
        bookNodes.add(n);
      } else {
        otherNodes.add(n);
      }
    }

    final random = Random(42);
    final margin = 70.0;
    final centerY = size.height / 2;

    final leftX = margin;
    final centerXCol = size.width * 0.5;
    final rightX = size.width * (1 - 0.3);

    void placeNodes(List<GraphNode> list, double baseX, double spread) {
      for (int i = 0; i < list.length; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final radius = 20 + random.nextDouble() * spread;
        list[i].x = baseX + cos(angle) * radius;
        list[i].y = centerY + sin(angle) * radius;
        list[i].vx = 0;
        list[i].vy = 0;
      }
    }

    final spread = min(size.width, size.height) * 0.15;
    placeNodes(folderNodes, leftX, spread);
    placeNodes(noteNodes, centerXCol, spread * 1.2);
    placeNodes(bookNodes, rightX, spread);
    placeNodes(otherNodes, centerXCol, spread * 0.8);
  }

  static GraphData _filterLocalGraph(GraphData graph, String focusNodeId, int hopCount) {
    final nodeMap = graph.nodeMap;
    if (!nodeMap.containsKey(focusNodeId)) return graph;

    final visited = <String>{};
    final queue = <String>[focusNodeId];
    visited.add(focusNodeId);

    for (int hop = 0; hop < hopCount; hop++) {
      final currentLevel = List<String>.from(queue);
      queue.clear();
      for (var id in currentLevel) {
        for (var edge in graph.edges) {
          if (edge.sourceId == id && !visited.contains(edge.targetId)) {
            visited.add(edge.targetId);
            queue.add(edge.targetId);
          }
          if (edge.targetId == id && !visited.contains(edge.sourceId)) {
            visited.add(edge.sourceId);
            queue.add(edge.sourceId);
          }
        }
      }
    }

    final filteredNodes = graph.nodes.where((n) => visited.contains(n.node.id)).toList();
    final filteredEdges = graph.edges.where((e) =>
      visited.contains(e.sourceId) && visited.contains(e.targetId)
    ).toList();

    return GraphData(nodes: filteredNodes, edges: filteredEdges);
  }

  static GraphData _resolveOverlaps(GraphData graph, Size size) {
    final nodes = graph.nodes;
    const minDistance = 50.0;
    const maxIterations = 50;
    final margin = 30.0;

    for (int iter = 0; iter < maxIterations; iter++) {
      bool moved = false;
      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final dx = nodes[j].x - nodes[i].x;
          final dy = nodes[j].y - nodes[i].y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < minDistance && dist > 0.1) {
            final overlap = (minDistance - dist) / 2;
            final fx = (dx / dist) * overlap;
            final fy = (dy / dist) * overlap;
            nodes[i].x -= fx;
            nodes[i].y -= fy;
            nodes[j].x += fx;
            nodes[j].y += fy;
            moved = true;
          }
        }
      }
      if (!moved) break;

      for (var n in nodes) {
        n.x = max(margin, min(size.width - margin, n.x));
        n.y = max(margin, min(size.height - margin, n.y));
      }
    }

    return graph;
  }

  static String _getNodeType(Node node) {
    if (node.isFolder) return 'folder';
    if (node.nodeType == 'note') return 'note';
    if (node.nodeType == 'book') return 'book';
    return 'other';
  }
}

// ============================================================
// 图谱构建器（含双链检测）
// ============================================================

class GraphBuilder {
  static GraphData build(
    List<Node> allNodes, {
    Map<String, String> noteContents = const {},
  }) {
    final graphNodes = <GraphNode>[];
    for (var n in allNodes) {
      graphNodes.add(GraphNode(node: n, x: 0, y: 0));
    }

    final edges = <GraphEdge>[];

    // 1. 父子边
    for (var node in allNodes) {
      if (node.parentId != null) {
        edges.add(GraphEdge(
          sourceId: node.parentId!,
          targetId: node.id,
          type: 'parent',
        ));
      }
    }

    // 2. 标签关联边
    for (int i = 0; i < allNodes.length; i++) {
      for (int j = i + 1; j < allNodes.length; j++) {
        final a = allNodes[i];
        final b = allNodes[j];
        if (a.tags.isEmpty || b.tags.isEmpty) continue;
        final shared = a.tags.where((t) => b.tags.contains(t)).toList();
        if (shared.isNotEmpty) {
          edges.add(GraphEdge(
            sourceId: a.id,
            targetId: b.id,
            type: 'tag',
          ));
        }
      }
    }

    // 3. 双链（笔记内容中的 [[标题]] 引用）
    final noteNodes = allNodes.where((n) => n.nodeType == 'note' && n.targetId != null);
    final regExp = RegExp(r'\[\[([^\]]+)\]\]');

    for (var noteNode in noteNodes) {
      final content = noteContents[noteNode.targetId];
      if (content == null || content.isEmpty) continue;

      final matches = regExp.allMatches(content);
      for (var match in matches) {
        final refTitle = match.group(1)?.trim();
        if (refTitle == null || refTitle.isEmpty) continue;

        final targetNode = allNodes.firstWhere(
          (n) => n.title.toLowerCase() == refTitle.toLowerCase(),
          orElse: () => allNodes.first,
        );
        if (targetNode.id == noteNode.id || targetNode.id == allNodes.first.id) continue;
        if (targetNode.nodeType == 'folder') continue;

        final alreadyExists = edges.any((e) =>
          (e.sourceId == noteNode.id && e.targetId == targetNode.id) ||
          (e.sourceId == targetNode.id && e.targetId == noteNode.id)
        );
        if (alreadyExists) continue;

        edges.add(GraphEdge(
          sourceId: noteNode.id,
          targetId: targetNode.id,
          type: 'link',
        ));
        edges.add(GraphEdge(
          sourceId: targetNode.id,
          targetId: noteNode.id,
          type: 'link',
        ));
      }
    }

    return GraphData(nodes: graphNodes, edges: edges);
  }
}

// ============================================================
// 图谱交互组件（终极尺寸保护）
// ============================================================

class KnowledgeGraphWidget extends StatefulWidget {
  final GraphData graph;
  final void Function(String nodeId) onNodeTap;
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
  Set<String> _hoveredNodeIds = {};
  Offset? _mousePosition;

  String? _hitTestNode(Offset position, GraphData graph) {
    for (var gn in graph.nodes) {
      if (!gn.x.isFinite || !gn.y.isFinite) continue;
      final dx = position.dx - gn.x;
      final dy = position.dy - gn.y;
      final radius = _getNodeRadius(gn);
      if (dx * dx + dy * dy < radius * radius) {
        return gn.node.id;
      }
    }
    return null;
  }

  double _getNodeRadius(GraphNode gn) {
    const baseRadius = 24.0;
    final degree = gn.degree;
    if (degree <= 1) return baseRadius;
    if (degree <= 3) return baseRadius * 1.2;
    if (degree <= 6) return baseRadius * 1.5;
    return baseRadius * 1.8;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ 如果尺寸无效，返回空组件
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0 || width.isInfinite || height.isInfinite) {
          return const SizedBox.shrink();
        }

        final size = Size(width, height);

        return MouseRegion(
          onHover: (event) {
            final hitNodeId = _hitTestNode(event.localPosition, widget.graph);
            setState(() {
              if (hitNodeId != null) {
                _hoveredNodeIds = {hitNodeId};
              } else {
                _hoveredNodeIds = {};
              }
              _mousePosition = event.localPosition;
            });
          },
          onExit: (event) {
            setState(() {
              _hoveredNodeIds = {};
              _mousePosition = null;
            });
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              final hitNodeId = _hitTestNode(details.localPosition, widget.graph);
              if (hitNodeId != null) {
                widget.onNodeTap(hitNodeId);
              }
            },
            child: CustomPaint(
              painter: KnowledgeGraphPainter(
                graph: widget.graph,
                hoveredNodeIds: _hoveredNodeIds,
                mode: widget.mode,
              ),
              size: size,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// CustomPainter（增强版：节点大小映射度数）
// ============================================================

class KnowledgeGraphPainter extends CustomPainter {
  final GraphData graph;
  final Set<String>? hoveredNodeIds;
  final GraphLayoutMode mode;

  KnowledgeGraphPainter({
    required this.graph,
    this.hoveredNodeIds,
    this.mode = GraphLayoutMode.forceDirected,
  }) : super(repaint: RepaintTrigger());

  double _getNodeRadius(GraphNode gn) {
    const baseRadius = 22.0;
    final degree = gn.degree;
    if (degree <= 1) return baseRadius;
    if (degree <= 3) return baseRadius * 1.2;
    if (degree <= 6) return baseRadius * 1.5;
    return baseRadius * 1.8;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (graph.isEmpty || size.width <= 0 || size.height <= 0 ||
        size.width.isNaN || size.height.isNaN) {
      return;
    }

    final nodeMap = graph.nodeMap;

    // ----- 画边 -----
    for (var edge in graph.edges) {
      final source = nodeMap[edge.sourceId];
      final target = nodeMap[edge.targetId];
      if (source == null || target == null) continue;
      if (!source.x.isFinite || !source.y.isFinite ||
          !target.x.isFinite || !target.y.isFinite) continue;

      Paint paint;
      if (edge.type == 'link') {
        paint = Paint()
          ..color = Colors.purple.shade400.withOpacity(0.7)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
      } else if (edge.type == 'tag') {
        paint = Paint()
          ..color = Colors.blue.shade300.withOpacity(0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
      } else {
        paint = Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
      }

      if (edge.type == 'tag' || edge.type == 'link') {
        final path = Path();
        final dx = target.x - source.x;
        final dy = target.y - source.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 1.0) continue;
        final steps = (dist / 8.0).floor();
        for (int i = 0; i < steps; i++) {
          final t1 = i / steps;
          final t2 = (i + 0.5) / steps;
          final x1 = source.x + dx * t1;
          final y1 = source.y + dy * t1;
          final x2 = source.x + dx * t2;
          final y2 = source.y + dy * t2;
          if (x1.isFinite && y1.isFinite && x2.isFinite && y2.isFinite) {
            path.moveTo(x1, y1);
            path.lineTo(x2, y2);
          }
        }
        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(
          Offset(source.x, source.y),
          Offset(target.x, target.y),
          paint,
        );
      }
    }

    // ----- 画节点（大小按度数映射）-----
    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    for (var gn in graph.nodes) {
      final node = gn.node;
      if (!gn.x.isFinite || !gn.y.isFinite) continue;

      final isHovered = hoveredNodeIds?.contains(node.id) ?? false;
      final baseRadius = _getNodeRadius(gn);
      final radius = isHovered ? baseRadius * 1.25 : baseRadius;

      final color = _getNodeColor(node);
      final center = Offset(gn.x, gn.y);

      // 阴影
      final shadowPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.drawShadow(shadowPath, Colors.black87, 4.0, false);

      // 节点主体
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);

      // 边框
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, borderPaint);

      // 图标
      final iconSize = radius > 30 ? 18 : 14;
      final iconSpan = TextSpan(
        text: node.iconEmoji,
        style: TextStyle(fontSize: iconSize.toDouble()),
      );
      final iconPainter = TextPainter(
        text: iconSpan,
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(gn.x - iconPainter.width / 2, gn.y - iconSize / 2),
      );

      // 标题
      final maxTitleLen = radius > 30 ? 8 : 5;
      final displayTitle = node.title.length <= maxTitleLen
          ? node.title
          : '${node.title.substring(0, min(maxTitleLen, node.title.length))}…';
      final textSpan = TextSpan(text: displayTitle, style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: radius * 1.8);
      tp.paint(canvas, Offset(gn.x - tp.width / 2, gn.y + radius * 0.3));

      // 悬停高亮
      if (isHovered) {
        final glowPaint = Paint()
          ..color = Colors.blue.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
        canvas.drawCircle(center, radius + 6.0, glowPaint);

        // 悬停提示
        final tooltipStyle = TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          backgroundColor: Colors.black87,
        );
        final tooltipText = '${node.title} (${gn.degree})';
        final tooltipSpan = TextSpan(text: tooltipText, style: tooltipStyle);
        final tooltipPainter = TextPainter(
          text: tooltipSpan,
          textDirection: TextDirection.ltr,
        );
        tooltipPainter.layout();
        final tooltipX = gn.x - tooltipPainter.width / 2;
        final tooltipY = gn.y - radius - 24;
        final bgPaint = Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.fill;
        final bgRect = Rect.fromLTWH(
          tooltipX - 8,
          tooltipY - 4,
          tooltipPainter.width + 16,
          tooltipPainter.height + 8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, Radius.circular(4)),
          bgPaint,
        );
        tooltipPainter.paint(canvas, Offset(tooltipX, tooltipY));
      }
    }

    _drawLegend(canvas, size);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final y = size.height - 30.0;
    final x = 16.0;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y - 18.0, 290.0, 30.0),
      Radius.circular(6.0),
    );
    canvas.drawRRect(rect, paint);

    final textStyle = TextStyle(
      fontSize: 9,
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w500,
    );

    double offsetX = x + 8.0;

    // 父子
    final linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(offsetX, y - 4.0), Offset(offsetX + 20.0, y - 4.0), linePaint);
    final t1 = TextPainter(text: TextSpan(text: ' 父子 ', style: textStyle), textDirection: TextDirection.ltr);
    t1.layout();
    t1.paint(canvas, Offset(offsetX + 22.0, y - 12.0));
    offsetX += 65.0;

    // 标签
    final dashPaint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final x1 = offsetX + i * 5.0;
      canvas.drawLine(Offset(x1, y - 4.0), Offset(x1 + 3.0, y - 4.0), dashPaint);
    }
    final t2 = TextPainter(text: TextSpan(text: ' 标签 ', style: textStyle), textDirection: TextDirection.ltr);
    t2.layout();
    t2.paint(canvas, Offset(offsetX + 16.0, y - 12.0));
    offsetX += 60.0;

    // 双链
    final linkPaint = Paint()
      ..color = Colors.purple.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final x1 = offsetX + i * 5.0;
      canvas.drawLine(Offset(x1, y - 4.0), Offset(x1 + 3.0, y - 4.0), linkPaint);
    }
    final t3 = TextPainter(text: TextSpan(text: ' 双链 ', style: textStyle), textDirection: TextDirection.ltr);
    t3.layout();
    t3.paint(canvas, Offset(offsetX + 16.0, y - 12.0));
    offsetX += 60.0;

    // 节点类型
    final colors = [
      {'label': '笔记', 'color': Colors.blue.shade500},
      {'label': '图书', 'color': Colors.green.shade500},
      {'label': '文件夹', 'color': Colors.amber.shade600},
    ];
    for (var item in colors) {
      final c = Paint()..color = item['color'] as Color;
      canvas.drawCircle(Offset(offsetX + 5.0, y - 6.0), 4.0, c);
      final t = TextPainter(text: TextSpan(text: item['label'] as String, style: textStyle), textDirection: TextDirection.ltr);
      t.layout();
      t.paint(canvas, Offset(offsetX + 12.0, y - 12.0));
      offsetX += 40.0 + (item['label'] as String).length * 8.0;
    }
  }

  Color _getNodeColor(Node node) {
    if (node.isFolder) return Colors.amber.shade600;
    if (node.nodeType == 'note') return Colors.blue.shade500;
    if (node.nodeType == 'book') return Colors.green.shade500;
    return Colors.grey.shade500;
  }

  @override
  bool shouldRepaint(covariant KnowledgeGraphPainter oldDelegate) {
    return true;
  }
}

class RepaintTrigger extends ChangeNotifier {
  RepaintTrigger();
}