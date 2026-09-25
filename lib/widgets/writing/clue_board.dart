// lib/widgets/writing/clue_board.dart
// 线索墙 — 交互式画板（卡片 + 文字 + 连线）
// 本轮：接数据库、viewId 参数、砍 shape、删 notes/onNoteTap

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;
import '../../database_service.dart';
import '../../models/card.dart';
import '../../models/material_item.dart';
import 'material_panel.dart';

// ─── 节点模型 ──────────────────────────────────────────────
class ClueNode {
  final String id;
  String label;
  final String type; // 'card', 'text'
  Offset position;
  final double width;
  final double height;
  final Color color;
  final dynamic data;
  String? textContent;

  ClueNode({
    required this.id,
    required this.label,
    this.type = 'card',
    required this.position,
    this.width = 120,
    this.height = 60,
    this.color = Colors.blue,
    this.data,
    this.textContent,
  });

  ClueNode copyWith({
    String? id, String? label, String? type, Offset? position,
    double? width, double? height, Color? color, dynamic data, String? textContent,
  }) {
    return ClueNode(
      id: id ?? this.id, label: label ?? this.label, type: type ?? this.type,
      position: position ?? this.position, width: width ?? this.width,
      height: height ?? this.height, color: color ?? this.color,
      data: data ?? this.data, textContent: textContent ?? this.textContent,
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
enum DrawMode { select, line, text }

class ClueBoard extends StatefulWidget {
  final String viewId;
  final List<MaterialItem> items;
  final Function(CardModel) onCardTap;
  /// 多栏嵌入模式——true 时隐内部素材面板 + 工具栏素材图标
  final bool embedded;

  const ClueBoard({
    super.key,
    required this.viewId,
    required this.items,
    required this.onCardTap,
    this.embedded = false,
  });

  @override
  State<ClueBoard> createState() => ClueBoardState();
}

class ClueBoardState extends State<ClueBoard> {
  final DatabaseService _db = DatabaseService();

  List<ClueNode> _nodes = [];
  final List<ClueEdge> _edges = [];
  DrawMode _drawMode = DrawMode.select;
  String? _selectedNodeId;
  bool _isDragging = false;
  String? _lineStartId;

  final GlobalKey _boardKey = GlobalKey();
  Timer? _saveDebounce;
  bool _showMaterialPanel = true;

  Set<String> get _validCardIds => widget.items
      .where((i) => i.type == MaterialItemType.card)
      .map((i) => i.id)
      .toSet();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final existing = await _db.getBoardView(widget.viewId);
    if (existing == null) {
      await _db.upsertBoardView({
        'id': widget.viewId,
        'name': '默认画板',
        'type': 'global',
        'ownerId': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final nodeMaps = await _db.getBoardNodes(widget.viewId);
    final edgeMaps = await _db.getBoardEdges(widget.viewId);
    final textMaps = await _db.getBoardTexts(widget.viewId);

          final validCardIds = _validCardIds;
      final loadedNodes = <ClueNode>[];

      for (final m in nodeMaps) {
        final cardId = m['cardId'] as String?;
        if (cardId == null) continue;
        if (!validCardIds.contains(cardId)) continue;
        final item = widget.items.firstWhere(
          (i) => i.id == cardId && i.type == MaterialItemType.card,
        );
        final card = item.card!;
        loadedNodes.add(ClueNode(
        id: m['id'] as String,
        label: card.indexTitle ?? '未命名',
        type: 'card',
        position: Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        color: Colors.purple,
        data: card,
      ));
    }

    for (final m in textMaps) {
      final content = m['content'] as String? ?? '';
      loadedNodes.add(ClueNode(
        id: m['id'] as String,
        label: content.length > 15 ? '${content.substring(0, 15)}...' : content,
        type: 'text',
        position: Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        color: Colors.green.shade300,
        textContent: content,
      ));
    }

    final loadedEdges = edgeMaps.map((m) => ClueEdge(
      id: m['id'] as String,
      sourceId: m['sourceNodeId'] as String,
      targetId: m['targetNodeId'] as String,
    )).toList();

    final loadedCardCount = loadedNodes.where((n) => n.type == 'card').length;
    final hasOrphan = nodeMaps.length != loadedCardCount;

    if (hasOrphan) {
      final validNodeIds = loadedNodes.map((n) => n.id).toSet();
      final filteredEdges = loadedEdges
          .where((e) => validNodeIds.contains(e.sourceId) && validNodeIds.contains(e.targetId))
          .toList();
      await _db.replaceBoardNodes(
        widget.viewId,
        loadedNodes.where((n) => n.type == 'card').map((n) => _nodeToMap(n, widget.viewId)).toList(),
      );
      await _db.replaceBoardEdges(
        widget.viewId,
        filteredEdges.map((e) => _edgeToMap(e, widget.viewId)).toList(),
      );
    }

    if (!mounted) return;
    setState(() {
      _nodes = loadedNodes;
      _edges.clear();
      _edges.addAll(loadedEdges);
    });
  }

  @override
  void didUpdateWidget(covariant ClueBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
      final oldIds = oldWidget.items
        .where((i) => i.type == MaterialItemType.card)
        .map((i) => i.id)
        .toSet();
    final newIds = widget.items
        .where((i) => i.type == MaterialItemType.card)
        .map((i) => i.id)
        .toSet();
    if (!setEquals(oldIds, newIds)) {
      _cleanOrphanNodes();
    }
  }

  void _cleanOrphanNodes() {
    final validCardIds = _validCardIds;
    final removed = <String>[];
    final survivors = <ClueNode>[];
    for (final n in _nodes) {
      if (n.type == 'card' && n.data is CardModel) {
        if (!validCardIds.contains((n.data as CardModel).id)) {
          removed.add(n.id);
          continue;
        }
      }
      survivors.add(n);
    }
    if (removed.isEmpty) return;
    setState(() {
      _nodes = survivors;
      _edges.removeWhere((e) => removed.contains(e.sourceId) || removed.contains(e.targetId));
    });
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      _flushToDbWith(widget.viewId, _validCardIds);
    });
  }

  Future<void> _flushToDbWith(String viewId, Set<String> validCardIds) async {
    // ✅ T-007：写库全链路 try-catch 兜底，避免 dispose 场景异常静默丢失。
    try {
      final validNodes = _nodes.where((n) {
        if (n.type == 'card' && n.data is CardModel) {
          return validCardIds.contains((n.data as CardModel).id);
        }
        return true;
      }).toList();

      final cardNodes = validNodes.where((n) => n.type == 'card').toList();
      final textNodes = validNodes.where((n) => n.type == 'text').toList();
      final validNodeIds = validNodes.map((n) => n.id).toSet();
      final validEdges = _edges
          .where((e) => validNodeIds.contains(e.sourceId) && validNodeIds.contains(e.targetId))
          .toList();

      await _db.replaceBoardNodes(viewId, cardNodes.map((n) => _nodeToMap(n, viewId)).toList());
      await _db.replaceBoardEdges(viewId, validEdges.map((e) => _edgeToMap(e, viewId)).toList());
      await _db.replaceBoardTexts(viewId, textNodes.map((n) => _nodeToMap(n, viewId)).toList());
    } catch (e, st) {
      debugPrint('ClueBoard _flushToDbWith 失败: $e\n$st');
    }
  }

  Map<String, dynamic> _nodeToMap(ClueNode n, String viewId) {
    if (n.type == 'text') {
      return {
        'id': n.id,
        'viewId': viewId,
        'x': n.position.dx,
        'y': n.position.dy,
        'content': n.textContent ?? n.label,
      };
    }
    return {
      'id': n.id,
      'viewId': viewId,
      'cardId': n.data is CardModel ? (n.data as CardModel).id : null,
      'x': n.position.dx,
      'y': n.position.dy,
      'zIndex': 0,
    };
  }

  Map<String, dynamic> _edgeToMap(ClueEdge e, String viewId) => {
    'id': e.id,
    'viewId': viewId,
    'sourceNodeId': e.sourceId,
    'targetNodeId': e.targetId,
  };

  @override
  void dispose() {
    _saveDebounce?.cancel();
    final viewId = widget.viewId;
         final validCardIds = _validCardIds;
    // ✅ T-007：dispose 无法 await 异步；触发写入并兜底异常。
    //   注：本方法内已被 try-catch 覆盖，此处再挂 catchError 是双保险
    //   （将来有人重构 _flushToDbWith 去掉 try-catch，这层能兜）。
    _flushToDbWith(viewId, validCardIds).catchError((Object e, StackTrace st) {
      debugPrint('ClueBoard dispose flush 失败: $e\n$st');
    });
    super.dispose();
  }

  void _addTextNode() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();
    final pos = Offset(100 + random.nextDouble() * 400, 100 + random.nextDouble() * 300);
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
    _selectedNodeId = id;
    _scheduleSave();
  }

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
          decoration: const InputDecoration(hintText: '输入文字内容...', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
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
                _scheduleSave();
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _startLine(String nodeId) {
    setState(() {
      if (_lineStartId == null) {
        _lineStartId = nodeId;
        _selectedNodeId = nodeId;
      } else {
        final sourceId = _lineStartId!;
        final targetId = nodeId;
        if (sourceId != targetId) {
          _edges.add(ClueEdge(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sourceId: sourceId,
            targetId: targetId,
          ));
        }
        _lineStartId = null;
        _selectedNodeId = null;
      }
    });
    _scheduleSave();
  }

  void _deleteSelected() {
    if (_selectedNodeId == null) return;
    final deleting = _selectedNodeId!;
    setState(() {
      _nodes.removeWhere((n) => n.id == deleting);
      _edges.removeWhere((e) => e.sourceId == deleting || e.targetId == deleting);
      if (_lineStartId == deleting) _lineStartId = null;
      _selectedNodeId = null;
    });
    _scheduleSave();
  }
  void addCardToBoard(CardModel card) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _nodes.add(ClueNode(
        id: newId,
        label: card.indexTitle ?? '卡片',
        type: 'card',
        position: Offset(
          100 + Random().nextDouble() * 300,
          100 + Random().nextDouble() * 200,
        ),
        color: Colors.purple,
        data: card,
      ));
    });
    _scheduleSave();
  }
  void _onPanStart(DragStartDetails details, String id) {
    setState(() { _selectedNodeId = id; _isDragging = true; });
  }

  void _onPanUpdate(DragUpdateDetails details, String id) {
    setState(() {
      final index = _nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final oldNode = _nodes[index];
        _nodes[index] = oldNode.copyWith(position: oldNode.position + details.delta);
        _nodes = List.from(_nodes);
      }
    });
  }

  void _onPanEnd(DragEndDetails details, String id) {
    setState(() => _isDragging = false);
    _scheduleSave();
  }

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
                  Expanded(child: _buildBoard()),
                  if (!widget.embedded && _showMaterialPanel) ...[
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 280,
                      child: MaterialPanel(
                        items: widget.items,
                        enabled: true,
                        onInsertCard: addCardToBoard,
                        onInsertNote: (_) {},
                      ),
                    ),
                  ],
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.select_all, color: _drawMode == DrawMode.select ? Colors.blue : null),
            onPressed: () => setState(() => _drawMode = DrawMode.select),
            tooltip: '选择',
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(Icons.timeline, color: _drawMode == DrawMode.line ? Colors.blue : null),
            onPressed: () => setState(() { _drawMode = DrawMode.line; _lineStartId = null; }),
            tooltip: '连线模式',
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(Icons.title, color: _drawMode == DrawMode.text ? Colors.blue : null),
            onPressed: () => setState(() { _drawMode = DrawMode.text; _addTextNode(); }),
            tooltip: '添加文字',
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSelected,
            tooltip: '删除选中',
          ),
                      IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _nodes.clear();
                  _edges.clear();
                  _lineStartId = null;
                  _selectedNodeId = null;
                });
                _scheduleSave();
              },
              tooltip: '重置',
            ),
            if (!widget.embedded)
              IconButton(
                icon: Icon(_showMaterialPanel
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined),
                onPressed: () =>
                    setState(() => _showMaterialPanel = !_showMaterialPanel),
                tooltip: _showMaterialPanel ? '收起素材栏' : '展开素材栏',
              ),
          ],
      ),
    );
  }

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
                    if (node.type == 'text') _editTextNode(node.id);
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
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

    final color = Colors.purple;
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            node.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.shade700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (node.data is CardModel)
            Text(
              (node.data as CardModel).highlight ?? '',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ─── 绘制器 ──────────────────────────────────────────────
class _ClueBoardPainter extends CustomPainter {
  final List<ClueNode> nodes;
  final List<ClueEdge> edges;
  final String? selectedId;
  final String? lineStartId;
  final DrawMode mode;

  _ClueBoardPainter({
    required this.nodes, required this.edges,
    this.selectedId, this.lineStartId, required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final selectedPaint = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var edge in edges) {
      if (nodes.isEmpty) break;
      final source = nodes.firstWhere((n) => n.id == edge.sourceId, orElse: () => nodes.first);
      final target = nodes.firstWhere((n) => n.id == edge.targetId, orElse: () => nodes.first);
      final isSelected = selectedId == edge.sourceId || selectedId == edge.targetId;
      canvas.drawLine(source.position, target.position, isSelected ? selectedPaint : paint);
    }

    if (mode == DrawMode.line && lineStartId != null && nodes.isNotEmpty) {
      final startNode = nodes.firstWhere((n) => n.id == lineStartId, orElse: () => nodes.first);
      canvas.drawCircle(startNode.position, 6, Paint()..color = Colors.green..style = PaintingStyle.fill);
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