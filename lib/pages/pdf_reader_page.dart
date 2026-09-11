// lib/pages/pdf_reader_page.dart
// PDF 阅读器 — 打开、翻页、缩放、返回、手绘划痕
// 存储：SQLite（通过 PdfDrawingService）
// 坐标：全部转成 PDF 页面坐标存储，渲染时转回屏幕坐标
// 不做：文字选择、高亮、笔记、卡片、批注、书签、搜索、导出
// ✅ 首次打开加载提示：_isViewerReady 控制遮罩，onViewerReady 置位后消失

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_drawing.dart';
import '../services/pdf_drawing_service.dart';

class PdfReaderPage extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String bookId;

  const PdfReaderPage({
    super.key,
    required this.filePath,
    this.fileName = 'PDF',
    required this.bookId,
  });

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  final PdfViewerController _controller = PdfViewerController();
  final PdfDrawingService _service = PdfDrawingService();

  bool _drawMode = false;
  List<Offset> _currentPoints = [];
  List<PdfDrawing> _drawings = [];

  // ✅ 首次打开加载提示：PdfViewer ready 前置 false，遮罩显示；ready 后置 true，遮罩消失
  bool _isViewerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDrawings();
    });
  }

  // ---------- 加载划痕 ----------
  Future<void> _loadDrawings() async {
    final loaded = await _service.getByBook(widget.bookId);
    if (mounted) {
      setState(() => _drawings = loaded);
    }
    debugPrint('📂 恢复 ${loaded.length} 条划痕');
  }

  // ---------- 坐标转换 ----------
  Offset? _screenToPdf(Offset screen, int pageIndex) {
    if (!_controller.isReady) return null;
    final layout = _controller.layout;
    if (layout == null) return null;
    if (pageIndex < 0 || pageIndex >= _controller.pages.length) return null;
    final page = _controller.pages[pageIndex];
    final pageRect = layout.pageLayouts[pageIndex];
    final doc = _controller.localToDocument(screen);
    return Offset(
      doc.dx - pageRect.left,
      page.height - (doc.dy - pageRect.top),
    );
  }

  Offset? _pdfToScreen(Offset pdf, int pageIndex) {
    if (!_controller.isReady) return null;
    final layout = _controller.layout;
    if (layout == null) return null;
    if (pageIndex < 0 || pageIndex >= _controller.pages.length) return null;
    final page = _controller.pages[pageIndex];
    final pageRect = layout.pageLayouts[pageIndex];
    final doc = Offset(
      pageRect.left + pdf.dx,
      pageRect.top + (page.height - pdf.dy),
    );
    return _controller.documentToLocal(doc);
  }

  List<List<Offset>> _savedScreenLines() {
    if (!_controller.isReady) return [];
    final currentPage = _controller.pageNumber ?? 1;
    final result = <List<Offset>>[];
    for (final d in _drawings) {
      if (d.page != currentPage) continue;
      final points = <Offset>[];
      for (final pdf in d.pdfPoints) {
        final sp = _pdfToScreen(pdf, d.page - 1);
        if (sp != null) points.add(sp);
      }
      if (points.length >= 2) result.add(points);
    }
    return result;
  }

  // ---------- 手势回调 ----------
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints.add(details.localPosition);
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_currentPoints.length < 2 || !_controller.isReady) {
      setState(() => _currentPoints = []);
      return;
    }

    final currentPage = _controller.pageNumber ?? 1;
    final pageIndex = currentPage - 1;

    final pdfPoints = <Offset>[];
    for (final sp in _currentPoints) {
      final pdf = _screenToPdf(sp, pageIndex);
      if (pdf != null) pdfPoints.add(pdf);
    }

    if (pdfPoints.length < 2) {
      setState(() => _currentPoints = []);
      return;
    }

    final drawing = PdfDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.bookId,
      page: currentPage,
      pdfPoints: pdfPoints,
      createdAt: DateTime.now(),
    );

    await _service.save(drawing);

    setState(() {
      _drawings.add(drawing);
      _currentPoints = [];
    });

    debugPrint('✏️ 新增划痕: 第 $currentPage 页, ${pdfPoints.length} 个点');
  }

  void _toggleDrawMode() {
    setState(() {
      _drawMode = !_drawMode;
      if (_drawMode) {
        _currentPoints = [];
      }
    });
  }

  Future<void> _clearCanvas() async {
    await _service.deleteByBook(widget.bookId);
    setState(() {
      _currentPoints = [];
      _drawings = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(_drawMode ? Icons.edit : Icons.edit_off),
            tooltip: _drawMode ? '退出划线模式' : '进入划线模式',
            onPressed: _toggleDrawMode,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: '清除全部划痕',
            onPressed: _clearCanvas,
          ),
        ],
      ),
      body: Stack(
        children: [
          PdfViewer.file(
            widget.filePath,
            controller: _controller,
            params: PdfViewerParams(
              textSelectionParams: PdfTextSelectionParams(enabled: false),
              buildContextMenu: (context, params) => null,
              onViewerReady: (doc, controller) {
                debugPrint('✅ PdfViewer 已就绪');
                // ✅ 加载提示：ready 后置位，遮罩消失。必须替换原 setState(() {})，
                // 否则 _isViewerReady 永远为 false，遮罩不会消失。
                if (mounted) setState(() => _isViewerReady = true);
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  List<List<Offset>> lines;
                  try {
                    lines = _savedScreenLines();
                  } catch (e, st) {
                    debugPrint('❌ _savedScreenLines 异常: $e\n$st');
                    lines = [];
                  }
                  return CustomPaint(
                    painter: _DrawPainter(
                      currentPoints: _currentPoints,
                      savedLines: lines,
                    ),
                  );
                },
              ),
            ),
          ),
          if (_drawMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
              ),
            ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _drawMode
                    ? Colors.orange.withOpacity(0.85)
                    : Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _drawMode ? '✏️ 划线模式' : '👀 阅读模式',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          // ✅ 首次打开加载提示：放 Stack 最后一位（最上层），盖住 PDF + 绘制层 + 手势层 + 状态标签。
          // ready 后条件为 false，自动移除。
          if (!_isViewerReady)
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade50,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        '正在加载 PDF...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- 划线绘制器 ----------
class _DrawPainter extends CustomPainter {
  final List<Offset> currentPoints;
  final List<List<Offset>> savedLines;

  _DrawPainter({required this.currentPoints, required this.savedLines});

  @override
  void paint(Canvas canvas, Size size) {
    // 已保存的线（橙色，跟随 PDF）
    final savedPaint = Paint()
      ..color = Colors.orange.withOpacity(0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in savedLines) {
      if (line.length < 2) continue;
      final path = Path()..moveTo(line.first.dx, line.first.dy);
      for (int i = 1; i < line.length; i++) {
        path.lineTo(line[i].dx, line[i].dy);
      }
      canvas.drawPath(path, savedPaint);
    }

    // 正在划的线（黄色，屏幕坐标）
    if (currentPoints.length >= 2) {
      final currentPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.6)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(currentPoints.first.dx, currentPoints.first.dy);
      for (int i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
      canvas.drawPath(path, currentPaint);
    }
  }

  @override
  bool shouldRepaint(_DrawPainter oldDelegate) => true;
}