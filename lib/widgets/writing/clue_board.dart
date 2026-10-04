// lib/widgets/writing/clue_board.dart
// 线索墙 — 交互式画板（卡片 + 文字 + 连线）
// 本轮：接数据库、viewId 参数、砍 shape、删 notes/onNoteTap

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../database_service.dart';
import '../../models/card.dart';
import '../../models/clue_stroke.dart';
import '../../services/board_revision.dart';
import '../../models/material_item.dart';
import '../../models/note.dart';
import '../../utils/app_string_utils.dart';
import 'material_panel.dart';

// ─── 节点模型 ──────────────────────────────────────────────
class ClueNode {
  final String id;
  String label;
  final String type; // 'card', 'text', 'note'
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
enum DrawMode { select, line, text, pen, eraser }
enum _ClueToolbarAction {
  select, line, text, pen, eraser, delete, reset, saveAlbum, undo
}
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

  // B8：笔画数据
  List<ClueStroke> _strokes = [];
  Color _penColor = Colors.black;
  double _penWidth = 4.0;
  bool _rulerOn = false;
  Offset? _rulerStart;
  List<Offset>? _currentStrokePoints;
  bool _eraseChanged = false;
  final List<_ClueBoardSnapshot> _undoStack = [];
  static const int _undoMaxDepth = 30;
  bool _hasPendingChanges = false;
  OverlayEntry? _penPanelEntry;
  Timer? _saveDebounce;
  bool _showMaterialPanel = true;

  Set<String> get _validCardIds => widget.items
      .where((i) => i.type == MaterialItemType.card)
      .map((i) => i.id)
      .toSet();

  Set<String> get _validNoteIds => widget.items
      .where((i) => i.type == MaterialItemType.note)
      .map((i) => i.id)
      .toSet();

  @override
  void initState() {
    super.initState();
    BoardRevision.revision.addListener(_onRevision);
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
    final strokeMaps = await _db.getBoardStrokes(widget.viewId);

          final validCardIds = _validCardIds;
      final loadedNodes = <ClueNode>[];

      for (final m in nodeMaps) {
        if ((m['type'] as String? ?? 'card') != 'card') continue;
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

    final validNoteIds = _validNoteIds;
    for (final m in nodeMaps) {
      if ((m['type'] as String? ?? 'card') != 'note') continue;
      final noteId = m['noteId'] as String?;
      if (noteId == null) continue;
      if (!validNoteIds.contains(noteId)) continue;
      final item = widget.items.firstWhere(
        (i) => i.id == noteId && i.type == MaterialItemType.note,
      );
      final note = item.note!;
      loadedNodes.add(ClueNode(
        id: m['id'] as String,
        label: AppStringUtils.displayNoteTitle(note.title, note.content),
        type: 'note',
        position: Offset((m['x'] as num).toDouble(), (m['y'] as num).toDouble()),
        color: Colors.indigo,
        data: note,
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

    final loadedStrokes = <ClueStroke>[];
    for (final m in strokeMaps) {
      try {
        loadedStrokes.add(ClueStroke.fromMap(m));
      } catch (e) {
        debugPrint('[clue_board] stroke 反序列化失败: $e');
      }
    }

    final loadedBoardCount = loadedNodes
        .where((n) => n.type == 'card' || n.type == 'note')
        .length;
    final hasOrphan = nodeMaps.length != loadedBoardCount;

    if (hasOrphan) {
      final validNodeIds = loadedNodes.map((n) => n.id).toSet();
      final filteredEdges = loadedEdges
          .where((e) => validNodeIds.contains(e.sourceId) && validNodeIds.contains(e.targetId))
          .toList();
      await _db.replaceBoardNodes(
        widget.viewId,
        loadedNodes
            .where((n) => n.type == 'card' || n.type == 'note')
            .map((n) => _nodeToMap(n, widget.viewId))
            .toList(),
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
      _strokes = loadedStrokes;
    });
  }

  void _onRevision() {
    if (_hasPendingChanges) {
      debugPrint('[clue_board] revision 跳过 —— 有未落库操作');
      return;
    }
    if (!mounted) return;
    _loadFromDb();
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
      if (n.type == 'note' && n.data is NotebookEntry) {
        if (!_validNoteIds.contains((n.data as NotebookEntry).id)) {
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
    _hasPendingChanges = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      _flushToDbWith(widget.viewId, _validCardIds);
    });
  }
    // ─── B8：画笔 / 橡皮 ───
  void _selectPen() {
    setState(() => _drawMode = DrawMode.pen);
    _showPenPanel();
  }

  void _selectEraser() {
    setState(() => _drawMode = DrawMode.eraser);
    _showPenPanel();
  }

  void _showPenPanel() {
    if (_penPanelEntry != null) {
      _penPanelEntry!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    _penPanelEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 16,
          top: MediaQuery.of(ctx).padding.top + 100,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('颜色', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    ..._penColors.map((c) => GestureDetector(
                          onTap: () {
                            setState(() => _penColor = c);
                            _penPanelEntry?.markNeedsBuild();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _penColor == c
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: _penColor == c ? 2 : 1,
                              ),
                            ),
                          ),
                        )),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Text('粗细', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    ..._penWidths.map((w) => GestureDetector(
                          onTap: () {
                            setState(() => _penWidth = w);
                            _penPanelEntry?.markNeedsBuild();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _penWidth == w
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Container(
                              width: 18,
                              height: w.clamp(2, 8),
                              color: Colors.black87,
                            ),
                          ),
                        )),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Text('尺子', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _rulerOn,
                      onChanged: (v) {
                        setState(() => _rulerOn = v);
                        _penPanelEntry?.markNeedsBuild();
                      },
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _hidePenPanel,
                      child: const Text('收起'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_penPanelEntry!);
  }

  void _hidePenPanel() {
    _penPanelEntry?.remove();
    _penPanelEntry = null;
  }

  static const List<Color> _penColors = [
    Colors.black, Colors.red, Colors.orange,
    Colors.green, Colors.blue, Colors.grey,
  ];
  static const List<double> _penWidths = [2.0, 4.0, 8.0];

  // ─── B8：撤销栈 ───
  void _pushSnapshot() {
    _undoStack.add(_ClueBoardSnapshot.from(
      nodes: _nodes,
      edges: _edges,
      strokes: _strokes,
    ));
    if (_undoStack.length > _undoMaxDepth) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    setState(() {
      _nodes = snap.nodes;
      _edges.clear();
      _edges.addAll(snap.edges);
      _strokes = snap.strokes;
      _currentStrokePoints = null;
      _rulerStart = null;
    });
    _scheduleSave();
  }

  // ─── B8：画布手势 ───
  void _onCanvasPanStart(DragStartDetails d) {
    if (_drawMode != DrawMode.pen && _drawMode != DrawMode.eraser) return;
    _eraseChanged = false;
    if (_drawMode == DrawMode.eraser) {
      return;
    }
    final local = _globalToLocal(d.globalPosition);
    _currentStrokePoints = [local];
    if (_rulerOn) _rulerStart = local;
    setState(() {});
  }

  void _onCanvasPanUpdate(DragUpdateDetails d) {
    if (_drawMode != DrawMode.pen && _drawMode != DrawMode.eraser) return;
    final local = _globalToLocal(d.globalPosition);
    if (_drawMode == DrawMode.eraser) {
      _eraseAt(local);
      return;
    }
    if (_rulerOn && _rulerStart != null) {
      setState(() => _currentStrokePoints = [_rulerStart!, local]);
    } else {
      final cur = _currentStrokePoints;
      if (cur == null) {
        debugPrint('[clue_board] panUpdate: currentStrokePoints null');
        return;
      }
      setState(() => _currentStrokePoints = [...cur, local]);
    }
  }

  void _onCanvasPanEnd(DragEndDetails d) {
    _eraseChanged = false;
    if (_drawMode != DrawMode.pen) {
      _currentStrokePoints = null;
      _rulerStart = null;
      setState(() {});
      return;
    }
    final pts = _currentStrokePoints;
    if (pts == null || pts.length < 2) {
      _currentStrokePoints = null;
      _rulerStart = null;
      setState(() {});
      return;
    }
    _pushSnapshot();
    final stroke = ClueStroke(
      id: 'stroke_${DateTime.now().microsecondsSinceEpoch}',
      viewId: widget.viewId,
      groupId: null,
      zIndex: 0,
      points: List<Offset>.from(pts),
      color: _penColor,
      width: _penWidth,
      createdAt: DateTime.now(),
    );
    setState(() {
      _strokes = List.from(_strokes)..add(stroke);
      _currentStrokePoints = null;
      _rulerStart = null;
    });
    _scheduleSave();
  }

  Offset _globalToLocal(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  void _eraseAt(Offset p) {
    if (_strokes.isEmpty) return;
    final threshold = 8.0;
    int? removeIdx;
    for (int i = _strokes.length - 1; i >= 0; i--) {
      final s = _strokes[i];
      final r = s.width / 2 + threshold;
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (final q in s.points) {
        if (q.dx < minX) minX = q.dx;
        if (q.dy < minY) minY = q.dy;
        if (q.dx > maxX) maxX = q.dx;
        if (q.dy > maxY) maxY = q.dy;
      }
      if (p.dx < minX - r || p.dx > maxX + r) continue;
      if (p.dy < minY - r || p.dy > maxY + r) continue;
      for (final q in s.points) {
        if ((q - p).distance < r) {
          removeIdx = i;
          break;
        }
      }
      if (removeIdx != null) break;
    }
    if (removeIdx != null) {
      if (!_eraseChanged) {
        _pushSnapshot();
        _eraseChanged = true;
      }
      setState(() => _strokes = List.from(_strokes)..removeAt(removeIdx!));
      _scheduleSave();
    }
  }

  // ─── B8：存画册 ───
  Future<void> _saveToAlbum() async {
    if (_strokes.isEmpty) return;
    final imageBytes = await _renderThumbnail();
    if (imageBytes == null) return;
    final b64 = base64Encode(imageBytes);
    final albumId = 'album_${DateTime.now().millisecondsSinceEpoch}';
    final strokesJson = jsonEncode(
      _strokes.map((s) => s.toAlbumJson()).toList(),
    );
    await _db.insertBoardAlbum({
      'id': albumId,
      'title': '画册 ${DateTime.now().toString().substring(0, 16)}',
      'source_view_id': widget.viewId,
      'strokes_json': strokesJson,
      'thumbnail_base64': b64,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': null,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已存到画册'), duration: Duration(seconds: 1)),
    );
  }

  Future<Uint8List?> _renderThumbnail() async {
    if (_strokes.isEmpty) return null;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final s in _strokes) {
      for (final q in s.points) {
        if (q.dx < minX) minX = q.dx;
        if (q.dy < minY) minY = q.dy;
        if (q.dx > maxX) maxX = q.dx;
        if (q.dy > maxY) maxY = q.dy;
      }
    }
    final w = maxX - minX;
    final h = maxY - minY;
    if (w <= 0 || h <= 0) return null;
    const target = 312.0;
    final scale = target / (w > h ? w : h);
    final canvasW = (w * scale) + 8;
    final canvasH = (h * scale) + 8;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasW, canvasH),
      Paint()..color = Colors.white,
    );
    canvas.save();
    canvas.translate(4, 4);
    canvas.scale(scale);
    canvas.translate(-minX, -minY);
    for (final s in _strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width / scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasW.toInt(), canvasH.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
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

      // ⚠️ 必补：原为 (n) => n.type == 'card' —— note 节点会被丢，不写库 —— 已改
      final boardNodes = validNodes
          .where((n) => n.type == 'card' || n.type == 'note')
          .toList();
      final textNodes = validNodes.where((n) => n.type == 'text').toList();
      final validNodeIds = validNodes.map((n) => n.id).toSet();
      final validEdges = _edges
          .where((e) => validNodeIds.contains(e.sourceId) && validNodeIds.contains(e.targetId))
          .toList();

      await _db.replaceBoardNodes(viewId, boardNodes.map((n) => _nodeToMap(n, viewId)).toList());
      await _db.replaceBoardEdges(viewId, validEdges.map((e) => _edgeToMap(e, viewId)).toList());
      await _db.replaceBoardTexts(viewId, textNodes.map((n) => _nodeToMap(n, viewId)).toList());
      await _db.replaceBoardStrokes(
          viewId, _strokes.map((s) => s.toMap(viewId)).toList());
      _hasPendingChanges = false;
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
    if (n.type == 'note') {
      return {
        'id': n.id,
        'viewId': viewId,
        'cardId': null,
        'type': 'note',
        'noteId': n.data is NotebookEntry ? (n.data as NotebookEntry).id : null,
        'x': n.position.dx,
        'y': n.position.dy,
        'zIndex': 0,
      };
    }
    return {
      'id': n.id,
      'viewId': viewId,
      'cardId': n.data is CardModel ? (n.data as CardModel).id : null,
      'type': 'card',
      'noteId': null,
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
    BoardRevision.revision.removeListener(_onRevision);
    _penPanelEntry?.remove();
    _penPanelEntry = null;
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

  void addNoteToBoard(NotebookEntry note) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _nodes.add(ClueNode(
        id: newId,
        label: AppStringUtils.displayNoteTitle(note.title, note.content),
        type: 'note',
        position: Offset(
          100 + Random().nextDouble() * 300,
          100 + Random().nextDouble() * 200,
        ),
        color: Colors.indigo,
        data: note,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final paneWidth = constraints.maxWidth;
              // 老白裁：多栏 pane < 64 —— 工具栏 + Divider 全不渲染
              if (widget.embedded && paneWidth < 64) {
                return const SizedBox.shrink();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolbar(paneWidth),
                  const Divider(height: 1),
                ],
              );
            },
          ),
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
                        onInsertNote: addNoteToBoard,
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

   Widget _buildToolbar(double paneWidth) {
    if (!widget.embedded) return _buildToolbarWide();
    if (paneWidth >= 480) return _buildToolbarWide();
    if (paneWidth >= 380) return _buildToolbarMid();
    return _buildToolbarNarrow();
  }

  Widget _buildToolbarMid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          _toolbarIcon(DrawMode.select, Icons.select_all, '选择',
              () => setState(() {
                    _drawMode = DrawMode.select;
                    _lineStartId = null;
                  })),
          _toolbarIcon(DrawMode.line, Icons.timeline, '连线模式',
              () => setState(() {
                    _drawMode = DrawMode.line;
                    _lineStartId = null;
                  })),
          _toolbarIcon(DrawMode.text, Icons.title, '添加文字',
              () => setState(() {
                    _drawMode = DrawMode.text;
                    _addTextNode();
                  })),
          _toolbarIcon(DrawMode.pen, Icons.edit, '画笔', _selectPen),
          _toolbarIcon(DrawMode.eraser, Icons.cleaning_services_outlined, '橡皮',
              _selectEraser),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '撤销',
          ),
          const Spacer(),
          PopupMenuButton<_ClueToolbarAction>(
            icon: const Icon(Icons.more_horiz),
            tooltip: '更多',
            onSelected: _handleToolbarAction,
            itemBuilder: (_) => [
              _toolbarMenuItem(_ClueToolbarAction.delete, Icons.delete_outline,
                  '删除选中', isDelete: true),
              _toolbarMenuItem(
                  _ClueToolbarAction.reset, Icons.clear_all, '重置'),
              _toolbarMenuItem(_ClueToolbarAction.saveAlbum,
                  Icons.collections_bookmark, '存画册'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolbarIcon(
      DrawMode m, IconData icon, String tip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: _drawMode == m ? Colors.blue : null),
      onPressed: onTap,
      tooltip: tip,
    );
  }

  /// 宽态 —— 与 v0.3 前原文逐字一致
  Widget _buildToolbarWide() {
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
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(Icons.edit,
                color: _drawMode == DrawMode.pen ? Colors.blue : null),
            onPressed: _selectPen,
            tooltip: '画笔',
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(Icons.cleaning_services_outlined,
                color: _drawMode == DrawMode.eraser ? Colors.blue : null),
            onPressed: _selectEraser,
            tooltip: '橡皮',
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSelected,
            tooltip: '删除选中',
          ),
          IconButton(
            icon: const Icon(Icons.collections_bookmark),
            onPressed: _saveToAlbum,
            tooltip: '存画册',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _handleToolbarAction(_ClueToolbarAction.reset),
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

  /// 窄态 —— 单个 ⋯，菜单含全部动作


  Widget _buildToolbarNarrow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          const Spacer(),
          PopupMenuButton<_ClueToolbarAction>(
            icon: const Icon(Icons.more_horiz),
            tooltip: '更多',
            onSelected: _handleToolbarAction,
            itemBuilder: (_) => [
              _toolbarMenuItem(_ClueToolbarAction.select, Icons.select_all, '选择'),
              _toolbarMenuItem(_ClueToolbarAction.line, Icons.timeline, '连线模式'),
              _toolbarMenuItem(_ClueToolbarAction.text, Icons.title, '添加文字'),
              _toolbarMenuItem(_ClueToolbarAction.delete, Icons.delete_outline, '删除选中', isDelete: true),
              _toolbarMenuItem(_ClueToolbarAction.reset, Icons.clear_all, '重置'),
            ],
          ),
        ],
      ),
    );
  }
  PopupMenuItem<_ClueToolbarAction> _toolbarMenuItem(
    _ClueToolbarAction action,
    IconData icon,
    String label, {
    bool isDelete = false,
  }) {
    final isActive = switch (action) {
      _ClueToolbarAction.select => _drawMode == DrawMode.select,
      _ClueToolbarAction.line => _drawMode == DrawMode.line,
      _ClueToolbarAction.text => _drawMode == DrawMode.text,
      _ClueToolbarAction.pen => _drawMode == DrawMode.pen,
      _ClueToolbarAction.eraser => _drawMode == DrawMode.eraser,
      _ => false,
    };
    return PopupMenuItem<_ClueToolbarAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDelete ? Colors.red : null),
          const SizedBox(width: 12),
          Text(label),
          if (isActive) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: Colors.blue),
          ],
        ],
      ),
    );
  }

  void _handleToolbarAction(_ClueToolbarAction action) {
    switch (action) {
      case _ClueToolbarAction.select:
        setState(() {
          _drawMode = DrawMode.select;
          _lineStartId = null;
        });
      case _ClueToolbarAction.line:
        setState(() {
          _drawMode = DrawMode.line;
          _lineStartId = null;
        });
      case _ClueToolbarAction.text:
        setState(() {
          _drawMode = DrawMode.text;
          _addTextNode();
        });
      case _ClueToolbarAction.pen:
        _selectPen();
      case _ClueToolbarAction.eraser:
        _selectEraser();
      case _ClueToolbarAction.delete:
        _deleteSelected();
      case _ClueToolbarAction.reset:
        _pushSnapshot();
        setState(() {
          _nodes.clear();
          _edges.clear();
          _strokes.clear();
          _lineStartId = null;
          _selectedNodeId = null;
        });
        _scheduleSave();
      case _ClueToolbarAction.saveAlbum:
        _saveToAlbum();
      case _ClueToolbarAction.undo:
        _undo();
    }
  }

  Widget _buildBoard() {
    final drawing = _drawMode == DrawMode.pen || _drawMode == DrawMode.eraser;
    return GestureDetector(
      onTap: () {
        if (drawing) return;
        setState(() {
          _selectedNodeId = null;
          if (_drawMode == DrawMode.line) _lineStartId = null;
        });
      },
      onPanStart: drawing ? _onCanvasPanStart : null,
      onPanUpdate: drawing ? _onCanvasPanUpdate : null,
      onPanEnd: drawing ? _onCanvasPanEnd : null,
      child: Container(
        key: _boardKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ClueBoardPainter(
                  nodes: _nodes,
                  edges: _edges,
                  selectedId: _selectedNodeId,
                  lineStartId: _lineStartId,
                  mode: _drawMode,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _StrokePainter(
                  strokes: _strokes,
                  current: _currentStrokePoints,
                  currentColor: _penColor,
                  currentWidth: _penWidth,
                ),
              ),
            ),
            IgnorePointer(
              ignoring: drawing,
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
          ],
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

    if (node.type == 'note') {
      final color = Colors.indigo;
      final note = node.data is NotebookEntry ? node.data as NotebookEntry : null;
      final title = note != null
          ? AppStringUtils.displayNoteTitle(note.title, note.content)
          : node.label;
      final summary = note?.content ?? '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: node.width - 24,
              child: Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  summary,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
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
    if (oldDelegate.mode != mode) return true;
    return false;
  }
}
class _StrokePainter extends CustomPainter {
  final List<ClueStroke> strokes;
  final List<Offset>? current;
  final Color currentColor;
  final double currentWidth;

  _StrokePainter({
    required this.strokes,
    this.current,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length < 2) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    final cur = current;
    if (cur != null && cur.length >= 2) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(cur.first.dx, cur.first.dy);
      for (int i = 1; i < cur.length; i++) {
        path.lineTo(cur[i].dx, cur[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) {
    if (old.strokes != strokes) return true;
    if (old.current != current) return true;
    if (old.currentColor != currentColor) return true;
    if (old.currentWidth != currentWidth) return true;
    return false;
  }
}

class _ClueBoardSnapshot {
  final List<ClueNode> nodes;
  final List<ClueEdge> edges;
  final List<ClueStroke> strokes;

  _ClueBoardSnapshot({
    required this.nodes,
    required this.edges,
    required this.strokes,
  });

  factory _ClueBoardSnapshot.from({
    required List<ClueNode> nodes,
    required List<ClueEdge> edges,
    required List<ClueStroke> strokes,
  }) {
    return _ClueBoardSnapshot(
      nodes: nodes.map((n) => n.copyWith()).toList(),
      edges: edges
          .map((e) => ClueEdge(
                id: e.id,
                sourceId: e.sourceId,
                targetId: e.targetId,
              ))
          .toList(),
      strokes: strokes
          .map((s) => s.copyWith(
                points: List<Offset>.from(s.points),
              ))
          .toList(),
    );
  }
}