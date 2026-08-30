// lib/widgets/writing/clue_board.dart
// 线索墙 — 交互式画板（支持拖拽卡片、绘图、连线、文字输入）

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/card.dart';

// ─── 节点模型 ──────────────────────────────────────────────
class ClueNode {
  final String id;
  String label;
  final String type; // 'note', 'card', 'shape', 'text'
  final String? shapeType; // 'rect', 'circle', 'arrow'
  Offset position;
  final double width;
  final double height;
  final Color color;
  final dynamic data;
  String? textContent; // 文字节点的内容

  ClueNode({
    required this.id,
    required this.label,
    this.type = 'note',
    this.shapeType,
    required this.position,
    this.width = 120,
    this.height = 60,
    this.color = Colors.blue,
    this.data,
    this.textContent,
  });

  ClueNode copyWith({
    String? id,
    String? label,
    String? type,
    String? shapeType,
    Offset? position,
    double? width,
    double? height,
    Color? color,
    dynamic data,
    String? textContent,
  }) {
    return ClueNode(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      shapeType: shapeType ?? this.shapeType,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      data: data ?? this.data,
      textContent: textContent ?? this.textContent,
    );
  }
}

// ─── 连线模型 ──────────────────────────────────────────────
class ClueEdge {
  final String id;
  final String sourceId;
  final String targetId;

  ClueEdge({required this.id, required this.sourceId, required this.targetId});
}

// ─── 画板状态 ──────────────────────────────────────────────
enum DrawMode { select, arrow, circle, rect, line, text }

class ClueBoard extends StatefulWidget {
  final List<NotebookEntry> notes;
  final List<CardModel> cards;
  final Function(NotebookEntry) onNoteTap;
  final Function(CardModel) onCardTap;

  const ClueBoard({
    super.key,
    required this.notes,
    required this.cards,
    required this.onNoteTap,
    required this.onCardTap,
  });

  @override
  State<ClueBoard> createState() => _ClueBoardState();
}

class _ClueBoardState extends State<ClueBoard> {
  // ─── 状态 ──────────────────────────────────────────────────
  List<ClueNode> _nodes = [];
  final List<ClueEdge> _edges = [];
  DrawMode _drawMode = DrawMode.select;
  String? _selectedNodeId;
  bool _isDragging = false;

  // 连线模式
  String? _lineStartId;

  // 用于拖拽添加素材
  final GlobalKey _boardKey = GlobalKey();

  // ─── 初始化 ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initNodes();
  }

  void _initNodes() {
    final random = Random(42);
    final centerX = 300;
    final centerY = 300;
    final radius = 200;

    // 笔记节点
    for (var i = 0; i < widget.notes.length; i++) {
      final note = widget.notes[i];
      final angle = (i / widget.notes.length) * 2 * pi;
      final pos = Offset(
        centerX + radius * cos(angle) + (random.nextDouble() - 0.5) * 60,
        centerY + radius * sin(angle) + (random.nextDouble() - 0.5) * 60,
      );
      _nodes.add(ClueNode(
        id: note.id,
        label: note.title,
        type: 'note',
        position: pos,
        color: Colors.blue,
        data: note,
      ));
    }

    // 卡片节点
    for (var i = 0; i < widget.cards.length; i++) {
      final card = widget.cards[i];
      final angle = (i / widget.cards.length) * 2 * pi + 0.3;
      final pos = Offset(
        centerX + radius * 0.4 * cos(angle) + (random.nextDouble() - 0.5) * 40,
        centerY + radius * 0.4 * sin(angle) + (random.nextDouble() - 0.5) * 40,
      );
      _nodes.add(ClueNode(
        id: card.id,
        label: card.indexTitle ?? '未命名',
        type: 'card',
        position: pos,
        color: Colors.purple,
        data: card,
      ));
    }
  }

  // ─── 添加图形节点 ──────────────────────────────────────────

  void _addShapeNode(String shapeType) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();
    final pos = Offset(
      100 + random.nextDouble() * 400,
      100 + random.nextDouble() * 300,
    );
    setState(() {
      _nodes.add(ClueNode(
        id: id,
        label: shapeType == 'rect' ? '矩形' : (shapeType == 'circle' ? '圆形' : '箭头'),
        type: 'shape',
        shapeType: shapeType,
        position: pos,
        width: shapeType == 'arrow' ? 80 : 100,
        height: shapeType == 'arrow' ? 30 : 80,
        color: Colors.grey.shade400,
      ));
    });
  }

  // ─── ✅ 添加文字节点 ──────────────────────────────────────────

  void _addTextNode() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();
    final pos = Offset(
      100 + random.nextDouble() * 400,
      100 + random.nextDouble() * 300,
    );
    setState(() {
      _nodes.add(ClueNode(
        id: id,
        label: '📝 文字',
        type: 'text',
        position: pos,
        width: 160,
        height: 50,
        color: Colors.green.shade300,
        textContent: '双击编辑文字',
      ));
    });
    // 选中新添加的文字节点，方便编辑
    _selectedNodeId = id;
  }

  // ─── 编辑文字内容 ──────────────────────────────────────────

  void _editTextNode(String nodeId) {
    final node = _nodes.firstWhere((n) => n.id == nodeId);
    final controller = TextEditingController(text: node.textContent ?? node.label);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑文字'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '输入文字内容...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  final index = _nodes.indexWhere((n) => n.id == nodeId);
                  if (index != -1) {
                    _nodes[index] = _nodes[index].copyWith(
                      label: newText.length > 15 ? '${newText.substring(0, 15)}...' : newText,
                      textContent: newText,
                    );
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ─── 连线操作 ──────────────────────────────────────────────

  void _startLine(String nodeId) {
    setState(() {
      if (_lineStartId == null) {
        _lineStartId = nodeId;
        _selectedNodeId = nodeId;
      } else {
        // 完成连线
        final sourceId = _lineStartId!;
        final targetId = nodeId;
        if (sourceId != targetId) {
          final edge = ClueEdge(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sourceId: sourceId,
            targetId: targetId,
          );
          _edges.add(edge);
        }
        _lineStartId = null;
        _selectedNodeId = null;
      }
    });
  }

  // ─── 删除节点/连线 ──────────────────────────────────────────

  void _deleteSelected() {
    if (_selectedNodeId == null) return;
    setState(() {
      _nodes.removeWhere((n) => n.id == _selectedNodeId);
      _edges.removeWhere((e) => e.sourceId == _selectedNodeId || e.targetId == _selectedNodeId);
      _selectedNodeId = null;
      if (_lineStartId == _selectedNodeId) _lineStartId = null;
    });
  }

  // ─── 拖拽节点 ──────────────────────────────────────────────

  void _onPanStart(DragStartDetails details, String id) {
    setState(() {
      _selectedNodeId = id;
      _isDragging = true;
    });
  }

 void _onPanUpdate(DragUpdateDetails details, String id) {
  setState(() {
    final index = _nodes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final oldNode = _nodes[index];
      final newNode = oldNode.copyWith(
        position: oldNode.position + details.delta,
      );
      _nodes[index] = newNode;
      // ✅ 关键：重新赋值引用，触发重绘
      _nodes = List.from(_nodes);
    }
  });
}
  void _onPanEnd(DragEndDetails details, String id) {
    setState(() {
      _isDragging = false;
    });
  }

  // ─── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildBoard(),
                ),
                const VerticalDivider(width: 1),
                _buildMaterialPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 顶部工具栏 ─────────────────────────────────────────────

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          // 选择
          IconButton(
            icon: Icon(Icons.select_all, color: _drawMode == DrawMode.select ? Colors.blue : null),
            onPressed: () => setState(() => _drawMode = DrawMode.select),
            tooltip: '选择',
          ),
          const SizedBox(width: 2),
          // 连线
          IconButton(
            icon: Icon(Icons.timeline, color: _drawMode == DrawMode.line ? Colors.blue : null),
            onPressed: () => setState(() {
              _drawMode = DrawMode.line;
              _lineStartId = null;
            }),
            tooltip: '连线模式',
          ),
          const SizedBox(width: 2),
          // 箭头
          IconButton(
            icon: Icon(Icons.text_fields, color: _drawMode == DrawMode.arrow ? Colors.blue : null),
            onPressed: () => setState(() {
              _drawMode = DrawMode.arrow;
              _addShapeNode('arrow');
            }),
            tooltip: '箭头',
          ),
          // 矩形
          IconButton(
            icon: Icon(Icons.crop_square, color: _drawMode == DrawMode.rect ? Colors.blue : null),
            onPressed: () => setState(() {
              _drawMode = DrawMode.rect;
              _addShapeNode('rect');
            }),
            tooltip: '矩形',
          ),
          // 圆形
          IconButton(
            icon: Icon(Icons.circle_outlined, color: _drawMode == DrawMode.circle ? Colors.blue : null),
            onPressed: () => setState(() {
              _drawMode = DrawMode.circle;
              _addShapeNode('circle');
            }),
            tooltip: '圆形',
          ),
          // ✅ 文字
          IconButton(
            icon: Icon(Icons.title, color: _drawMode == DrawMode.text ? Colors.blue : null),
            onPressed: () => setState(() {
              _drawMode = DrawMode.text;
              _addTextNode();
            }),
            tooltip: '添加文字',
          ),
          const Spacer(),
          // 删除
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSelected,
            tooltip: '删除选中',
          ),
          // 重置
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() {
              _nodes.clear();
              _edges.clear();
              _lineStartId = null;
              _selectedNodeId = null;
              _initNodes();
            }),
            tooltip: '重置',
          ),
        ],
      ),
    );
  }

  // ─── 画板 ──────────────────────────────────────────────────

  Widget _buildBoard() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNodeId = null;
          if (_drawMode == DrawMode.line) _lineStartId = null;
        });
      },
      child: Container(
        key: _boardKey,
        child: CustomPaint(
          painter: _ClueBoardPainter(
            nodes: _nodes,
            edges: _edges,
            selectedId: _selectedNodeId,
            lineStartId: _lineStartId,
            mode: _drawMode,
          ),
          size: Size.infinite,
          child: Stack(
            children: _nodes.map((node) {
              return Positioned(
                left: node.position.dx - node.width / 2,
                top: node.position.dy - node.height / 2,
                child: GestureDetector(
                  onPanStart: (details) => _onPanStart(details, node.id),
                  onPanUpdate: (details) => _onPanUpdate(details, node.id),
                  onPanEnd: (details) => _onPanEnd(details, node.id),
                  onDoubleTap: () {
                    // ✅ 双击文字节点可编辑
                    if (node.type == 'text') {
                      _editTextNode(node.id);
                    }
                  },
                  onTap: () {
                    if (_drawMode == DrawMode.line) {
                      _startLine(node.id);
                    } else {
                      setState(() => _selectedNodeId = node.id);
                    }
                  },
                  child: _buildNodeWidget(node),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(ClueNode node) {
    final isSelected = _selectedNodeId == node.id;
    final isLineStart = _lineStartId == node.id;

    // ─── 文字节点 ──────────────────────────────────────────
    if (node.type == 'text') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          node.textContent ?? node.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.green.shade700 : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ─── 图形节点 ──────────────────────────────────────────
    if (node.type == 'shape') {
      return _buildShapeWidget(node, isSelected);
    }

    // ─── 笔记或卡片 ──────────────────────────────────────────
    final isNote = node.type == 'note';
    final color = isNote ? Colors.blue : Colors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : (isLineStart ? Colors.green : Colors.transparent),
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (node.type == 'card' && node.data is CardModel)
            Text(
              (node.data as CardModel).highlight ?? '',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildShapeWidget(ClueNode node, bool isSelected) {
    final color = isSelected ? Colors.blue : Colors.grey.shade400;
    final size = node.width;

    Widget child;
    if (node.shapeType == 'rect') {
      child = Container(
        width: size,
        height: size * 0.6,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        ),
      );
    } else if (node.shapeType == 'circle') {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
        ),
      );
    } else {
      // arrow
      child = CustomPaint(
        painter: _ArrowPainter(color: color),
        size: Size(size, size * 0.4),
      );
    }

    return child;
  }

  // ─── 素材面板 ──────────────────────────────────────────────

  Widget _buildMaterialPanel() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text('📚 素材库', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.cards.length,
              itemBuilder: (context, index) {
                final card = widget.cards[index];
                return ListTile(
                  leading: const Icon(Icons.credit_card, size: 18, color: Colors.purple),
                  title: Text(card.indexTitle ?? '未命名', style: const TextStyle(fontSize: 12)),
                  subtitle: Text(card.author ?? '', style: const TextStyle(fontSize: 10)),
                  onTap: () {
                    final newId = DateTime.now().millisecondsSinceEpoch.toString();
                    setState(() {
                      _nodes.add(ClueNode(
                        id: newId,
                        label: card.indexTitle ?? '卡片',
                        type: 'card',
                        position: Offset(100 + Random().nextDouble() * 300, 100 + Random().nextDouble() * 200),
                        color: Colors.purple,
                        data: card,
                      ));
                    });
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💡 点击卡片添加到画布',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  '双击编辑文字',
                  style: TextStyle(fontSize: 9, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 自定义绘制器 ──────────────────────────────────────────

class _ClueBoardPainter extends CustomPainter {
  final List<ClueNode> nodes;
  final List<ClueEdge> edges;
  final String? selectedId;
  final String? lineStartId;
  final DrawMode mode;

  _ClueBoardPainter({
    required this.nodes,
    required this.edges,
    this.selectedId,
    this.lineStartId,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制连线
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final selectedPaint = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceId, orElse: () => nodes.first);
      final target = nodes.firstWhere((n) => n.id == edge.targetId, orElse: () => nodes.first);
      final isSelected = selectedId == edge.sourceId || selectedId == edge.targetId;
      canvas.drawLine(
        source.position,
        target.position,
        isSelected ? selectedPaint : paint,
      );
    }

    // 如果处于连线模式且有起始节点，绘制临时连线
    if (mode == DrawMode.line && lineStartId != null) {
      final startNode = nodes.firstWhere((n) => n.id == lineStartId, orElse: () => nodes.first);
      final pos = startNode.position;
      final dotPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 6, dotPaint);
    }
  }

 @override
bool shouldRepaint(_ClueBoardPainter oldDelegate) {
  if (oldDelegate.nodes != nodes) return true;
  if (oldDelegate.edges != edges) return true;
  if (oldDelegate.selectedId != selectedId) return true;
  if (oldDelegate.lineStartId != lineStartId) return true;
  return false;
}
}

// ─── 箭头绘制器 ─────────────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.7, size.height / 2);
    path.lineTo(size.width * 0.5, size.height * 0.25);
    path.moveTo(size.width * 0.7, size.height / 2);
    path.lineTo(size.width * 0.5, size.height * 0.75);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}