// test/pdf_draw_validation.dart
// pdfrx 划线验证 — 坐标互逆 + 划线跟随
// 只做：加载、划线、坐标对照打印、屏幕绘制、滚动/缩放跟随
// 不做：存储、文字选择、卡片、笔记

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

void main() => runApp(const ValidationApp());

class ValidationApp extends StatelessWidget {
  const ValidationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF划线验证',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ValidationPage(),
    );
  }
}

class ValidationPage extends StatefulWidget {
  const ValidationPage({super.key});

  @override
  State<ValidationPage> createState() => _ValidationPageState();
}

class _ValidationPageState extends State<ValidationPage> {
  final PdfViewerController _controller = PdfViewerController();

  bool _drawMode = false;
  List<Offset> _currentPoints = [];
  List<_Drawing> _drawings = [];
  int _pointCount = 0;

  // ---------- 坐标互逆验证 ----------
  void _verifyCoordinate(Offset local) {
    // 1. 判空保护
    if (!_controller.isReady) {
      print('⚠️ 控制器未就绪，跳过坐标验证');
      return;
    }
    final layout = _controller.layout;
    if (layout == null) {
      print('⚠️ layout 为 null，跳过坐标验证');
      return;
    }

    // 2. 当前页码（1-based）
    final int currentPage = _controller.pageNumber ?? 1;
    final int pageIndex = currentPage - 1;
    if (pageIndex < 0 || pageIndex >= _controller.pages.length) {
      print('⚠️ 页码越界: $currentPage');
      return;
    }

    final page = _controller.pages[pageIndex];
    final pageRect = layout.pageLayouts[pageIndex];

    // 3. 验证 pageLayout 尺寸是否等于 PDF 页面尺寸
    final bool widthMatch = (page.width - pageRect.width).abs() < 0.01;
    final bool heightMatch = (page.height - pageRect.height).abs() < 0.01;
    print('📏 page.width=${page.width}, pageRect.width=${pageRect.width}, 相等？$widthMatch');
    print('📏 page.height=${page.height}, pageRect.height=${pageRect.height}, 相等？$heightMatch');

    // 4. 屏幕坐标 → 文档坐标
    final Offset doc = _controller.localToDocument(local);

    // 5. 文档坐标 → PDF 页面坐标（简化公式）
    final double pageX = doc.dx - pageRect.left;
    final double pageY = page.height - (doc.dy - pageRect.top);

    // 6. PDF 页面坐标 → 文档坐标（反推）
    final Offset backDoc = Offset(
      pageRect.left + pageX,
      pageRect.top + (page.height - pageY),
    );

    // 7. 文档坐标 → 屏幕坐标（反推）
    final Offset backLocal = _controller.documentToLocal(backDoc);

    // 8. 打印完整对照
    print('📍 屏幕坐标: $local');
    print('📄 文档坐标: $doc');
    print('📐 PDF页面坐标: ($pageX, $pageY)');
    print('🔄 反推文档坐标: $backDoc');
    print('🔄 反推屏幕坐标: $backLocal');

    // 9. 完整链路是否可逆
    final double diff = (backLocal - local).distance;
    print('✅ 完整链路可逆？ ${diff < 0.01} (偏差: $diff)');

    // 10. PDF 页面坐标是否在页面范围内
    final bool inRange = pageX >= 0 &&
        pageX <= page.width &&
        pageY >= 0 &&
        pageY <= page.height;
    print('📐 PDF页面坐标在范围内？ $inRange');
    print('---');
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

  // ---------- 已保存划痕转屏幕坐标 ----------
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
    _pointCount = 0;
    setState(() {
      _currentPoints = [details.localPosition];
    });
    _verifyCoordinate(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _pointCount++;
    setState(() {
      _currentPoints.add(details.localPosition);
    });
    if (_pointCount % 5 == 0) {
      _verifyCoordinate(details.localPosition);
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    print('📊 本次划线累计点数: ${_currentPoints.length}');

    if (_currentPoints.length < 2 || !_controller.isReady) {
      setState(() => _currentPoints = []);
      return;
    }

    final currentPage = _controller.pageNumber ?? 1;
    final pageIndex = currentPage - 1;

    // 逐点转为 PDF 页面坐标
    final pdfPoints = <Offset>[];
    for (final sp in _currentPoints) {
      final pdf = _screenToPdf(sp, pageIndex);
      if (pdf != null) pdfPoints.add(pdf);
    }

    if (pdfPoints.length < 2) {
      setState(() => _currentPoints = []);
      return;
    }

    final drawing = _Drawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      page: currentPage,
      pdfPoints: pdfPoints,
    );

    setState(() {
      _drawings.add(drawing);
      _currentPoints = [];  // ← 关键：清空当前屏幕坐标
    });

    print('✏️ 新增划痕: 第 $currentPage 页, ${pdfPoints.length} 个点');
  }

  void _toggleDrawMode() {
    setState(() {
      _drawMode = !_drawMode;
      if (_drawMode) {
        _currentPoints = [];
        _pointCount = 0;
      }
    });
  }

  void _clearCanvas() {
    setState(() {
      _currentPoints = [];
      _pointCount = 0;
      _drawings = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF划线验证'),
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
            tooltip: '清除画布',
            onPressed: _clearCanvas,
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF 渲染
          PdfViewer.asset(
            'assets/sample.pdf',
            controller: _controller,
            params: PdfViewerParams(
              textSelectionParams: PdfTextSelectionParams(enabled: false),
              buildContextMenu: (context, params) => null,
            ),
          ),
          // 划线层：AnimatedBuilder 监听控制器矩阵变化
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _DrawPainter(
                      currentPoints: _currentPoints,
                      savedLines: _savedScreenLines(),
                    ),
                  );
                },
              ),
            ),
          ),
          // 划线模式下叠加手势捕获
          if (_drawMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
              ),
            ),
          // 模式提示
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
        ],
      ),
    );
  }
}

// ---------- 划痕存储模型 ----------
class _Drawing {
  final String id;
  final int page;
  final List<Offset> pdfPoints;

  _Drawing({required this.id, required this.page, required this.pdfPoints});
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