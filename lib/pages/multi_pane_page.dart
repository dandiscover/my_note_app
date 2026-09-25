import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/card.dart';
import '../models/explore_task.dart';
import '../models/material_item.dart';
import '../models/note.dart';
import '../services/card_service.dart';
import '../services/material_service.dart';
import 'workbench/editor_kernel.dart';
import 'workbench/editor_material_slot.dart';
import 'workbench/kernel_markdown.dart';
import 'workbench/workbench_body.dart';
import '../widgets/quick_switch_dialog.dart';
import 'epub_reader_page.dart';

sealed class _PaneState {
  const _PaneState();
}

class _EmptyPane extends _PaneState {
  const _EmptyPane();
}

class _NotePane extends _PaneState {
  final NotebookEntry note;
  final MarkdownKernel kernel;
  bool isReadMode;                 // 批：多栏每栏读/编辑态
  _NotePane({
    required this.note,
    required this.kernel,
    this.isReadMode = false,
  });
}

class _ReaderPane extends _PaneState {
  final String bookId;
  final String fileName;
  final String? filePath;
  const _ReaderPane({
    required this.bookId,
    required this.fileName,
    this.filePath,
  });
}

class MultiPanePage extends StatefulWidget {
  final List<NotebookEntry> initialEntries;
  final int initialLayout;
  final String? initialReaderBookId;      // 批 3
  final String? initialReaderBookTitle;
  final String? initialReaderBookPath;

  const MultiPanePage({
    super.key,
    this.initialEntries = const [],
    this.initialLayout = 2,
    this.initialReaderBookId,
    this.initialReaderBookTitle,
    this.initialReaderBookPath,
  });

  @override
  State<MultiPanePage> createState() => _MultiPanePageState();
}

class _MultiPanePageState extends State<MultiPanePage> {
  final CardService _cardService = CardService();   // 批 3：阅读器栏素材区取来源卡

  late List<_PaneState> _panes;
  late int _layoutMode;
  int _activePane = 0;

  // ─── 全局素材栏（1c-redo）───
  bool _showMaterialPanel = false;
  List<MaterialItem> _materialItems = [];

  // ─── 拖拽分隔线 ───
  // 三个 pane 的比例——和恒 1——只前 _layoutMode 有效
  List<double> _paneRatios = [1 / 3, 1 / 3, 1 / 3];

  // 每 pane 最低宽——(甲) 技术门槛 + (乙) 产品门槛——取 max
  // ⚠️ 待真机实测后定——现用占位 180
  static const double _minPaneW = 180.0;

  @override
  void initState() {
    super.initState();
    _layoutMode = widget.initialLayout.clamp(1, 3);
    final entryOffset = widget.initialReaderBookId != null ? 1 : 0;
    _panes = List.generate(3, (i) {
      if (i >= entryOffset && i - entryOffset < widget.initialEntries.length) {
        return _buildNotePane(widget.initialEntries[i - entryOffset]);
      }
      return const _EmptyPane();
    });
    // 批 3：笔记数超栏上限——打日志防静默丢
    final maxNoteSlots = widget.initialReaderBookId != null ? 2 : 3;
    if (widget.initialEntries.length > maxNoteSlots) {
      debugPrint('MultiPanePage: 笔记数 ${widget.initialEntries.length} 超栏上限 $maxNoteSlots，已截断');
    }
    // 批 3：书详情进——第 1 栏放阅读器
    if (widget.initialReaderBookId != null) {
      _panes[0] = _ReaderPane(
        bookId: widget.initialReaderBookId!,
        fileName: widget.initialReaderBookTitle ?? '文档',
        filePath: widget.initialReaderBookPath,
      );
    }
    // 批：焦点归属——Workbench 不抢焦——同步调成立
    _syncFocus();
    // 批 2-4：监听卡片库变化——自动刷素材区
    CardService.revision.addListener(_onCardsChanged);
  }

  void _onCardsChanged() {
    if (mounted && _showMaterialPanel) _reloadMaterialItems();
  }

  _NotePane _buildNotePane(NotebookEntry note) {
    final kernel = MarkdownKernel(EditorContext(
      entry: note,
      isFromCollection: false,
      onSave: _savePane,
    ));
    return _NotePane(note: note, kernel: kernel);
  }

  void _syncFocus() {
    final pane = _panes[_activePane];
    if (pane is _NotePane) {
      EditorKernel.focus(pane.kernel);
    } else {
      EditorKernel.blur();
    }
  }

  // ─── 全局素材栏：按焦点栏拉素材 ───
  Future<void> _reloadMaterialItems() async {
    final pane = _panes[_activePane];
    if (pane is _NotePane) {
      final items = await MaterialService.loadFor(pane.note);
      if (!mounted) return;
      setState(() => _materialItems = items);
    } else if (pane is _ReaderPane) {
      // 批 3：阅读器栏 → 显示该书来源卡
      final cards = await _cardService.getCardsBySource(
        sourceType: 'book', sourceId: pane.bookId);
      final items = cards.map((c) => MaterialItem.fromCard(c)).toList();
      if (!mounted) return;
      setState(() => _materialItems = items);
    } else {
      if (mounted) setState(() => _materialItems = []);
    }
  }

  void _toggleMaterialPanel() {
    setState(() => _showMaterialPanel = !_showMaterialPanel);
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  // ─── 拖拽分隔线 ───

  /// 拖第 [dividerIndex] 条分隔线（1..N-1）—— 改相邻两栏比例
  /// 钳制式——拖到边界贴边停——不卡
  void _onDividerDrag(int dividerIndex, double dx, double perRatio) {
    if (perRatio <= 0) return;

    final leftIdx = dividerIndex - 1;
    final rightIdx = dividerIndex;
    final sum = _paneRatios[leftIdx] + _paneRatios[rightIdx];
    final minRatio = _minPaneW / perRatio;
    if (sum < 2 * minRatio) return;   // 无空间可拖

    final delta = dx / perRatio;
    var leftNew = _paneRatios[leftIdx] + delta;
    // 钳制——不是拒绝
    leftNew = leftNew.clamp(minRatio, sum - minRatio);
    final rightNew = sum - leftNew;

    setState(() {
      _paneRatios[leftIdx] = leftNew;
      _paneRatios[rightIdx] = rightNew;
    });
  }

  void _resetPaneRatios() {
    setState(() {
      _paneRatios = [1 / 3, 1 / 3, 1 / 3];
    });
  }

  /// 按比例 + 留最小——旋转/resize 后仍保每栏 ≥ _minPaneW
  /// 空间不足 n×min —— 均分（接受拥挤——不崩）
  List<double> _computePaneWidths(
    List<double> ratios,
    double area,
  ) {
    final n = ratios.length;
    if (n == 0) return [];

    // 空间不足——均分
    if (area <= n * _minPaneW) {
      return List.filled(n, area / n);
    }

    final ratioSum = ratios.reduce((a, b) => a + b);
    if (ratioSum <= 0) return List.filled(n, area / n);

    final widths = List<double>.filled(n, 0);
    final fixed = List<bool>.filled(n, false);
    var freeArea = area;
    var freeRatioSum = ratioSum;

    // 迭代——找 < min 的固定——剩余再分
    for (var iter = 0; iter < n; iter++) {
      var changed = false;
      for (var i = 0; i < n; i++) {
        if (fixed[i]) continue;
        final w = ratios[i] * freeArea / freeRatioSum;
        if (w < _minPaneW) {
          fixed[i] = true;
          widths[i] = _minPaneW;
          freeArea -= _minPaneW;
          freeRatioSum -= ratios[i];
          changed = true;
        }
      }
      if (!changed) break;
      if (freeRatioSum <= 0) break;
    }

    // 剩下按比例
    final freeCount = n - fixed.where((f) => f).length;
    for (var i = 0; i < n; i++) {
      if (!fixed[i]) {
        widths[i] = freeRatioSum > 0
            ? ratios[i] * freeArea / freeRatioSum
            : freeArea / freeCount.clamp(1, n);
      }
    }

    return widths;
  }

  Future<void> _showAddReaderPicker() async {
    // 找空栏
    final emptyIndex = _panes.indexWhere((p) => p is _EmptyPane);
    if (emptyIndex == -1 || emptyIndex >= _layoutMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('栏已满，请先关闭一栏再加')),
      );
      return;
    }
    final books = await DatabaseService().getAllBooks();
    if (!mounted) return;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择书'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: books.isEmpty
              ? const Center(child: Text('还没有书'))
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final b = books[i];
                    return ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(b['title'] as String? ?? '未命名'),
                      subtitle: Text(b['author'] as String? ?? ''),
                      onTap: () => Navigator.pop(ctx, b),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _panes[emptyIndex] = _ReaderPane(
        bookId: selected['id'] as String,
        fileName: selected['title'] as String? ?? '文档',
        filePath: selected['filePath'] as String?,
      );
      _activePane = emptyIndex;
    });
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  Future<bool> _savePane(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
    String? inquiryQuestion,
    List<ExploreTask> exploreTasks,
  ) async {
    final updated = entry.copyWith(
      title: title,
      content: content,
      editorMode: editorMode,
      tags: tags,
      inquiryQuestion: inquiryQuestion,
      exploreTasks: exploreTasks,
      updatedAt: DateTime.now(),
    );
    await DatabaseService().insertNote(updated.toMap());
    // 批：标题同步——笔记是源，node 是显示副本（单向 note → node）
    final node = await DatabaseService().getNodeByNoteId(updated.id);
    if (node != null && node.title != updated.title) {
      await DatabaseService().updateNode(node.copyWith(title: updated.title));
    }
    // 批：保存后切阅读态——找对应 pane
    if (mounted) {
      setState(() {
        for (var i = 0; i < _panes.length; i++) {
          final p = _panes[i];
          if (p is _NotePane && p.note.id == entry.id) {
            p.kernel.updateEntry(updated);   // ← 关键：kernel entry 同步
            _panes[i] = _NotePane(
              note: updated,
              kernel: p.kernel,              // 复用 kernel——不重建
              isReadMode: true,
            );
          }
        }
      });
    }
    return true;
  }

  Future<void> _setLayout(int n) async {
    if (n == _layoutMode) return;
    if (n < _layoutMode) {
      final hasDirty = _panes
          .sublist(n, _layoutMode)
          .any((p) => p is _NotePane && p.kernel.isDirty);
      if (hasDirty) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('未保存改动'),
            content: const Text('待关闭的栏有未保存改动，确认关闭？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
    }
    if (!mounted) return;
    setState(() {
      for (var i = n; i < _layoutMode; i++) {
        final old = _panes[i];
        if (old is _NotePane) old.kernel.dispose();
        _panes[i] = const _EmptyPane();
      }
      _layoutMode = n;
      if (_activePane >= n) _activePane = n - 1;
      _paneRatios = [1 / 3, 1 / 3, 1 / 3];   // 栏数变——重置等分
    });
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  void _setActivePane(int i) {
    if (i == _activePane) return;
    setState(() => _activePane = i);
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  Future<void> _fillPaneWithNote(int i) async {
    final maps = await DatabaseService().getAllNotes(includeDeleted: false);
    final notes = maps.map((m) => NotebookEntry.fromMap(m)).toList();
    if (!mounted) return;
    final selected = await showDialog<NotebookEntry>(
      context: context,
      builder: (ctx) => QuickSwitchDialog(
        notes: notes,
        onSelect: (n) => Navigator.pop(ctx, n),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _panes[i] = _buildNotePane(selected);
      _activePane = i;
    });
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  void _handleDropOnPane(int i, MaterialItem item) {
    if (item.type != MaterialItemType.note || item.note == null) return;
    setState(() {
      _panes[i] = _buildNotePane(item.note!);
      _activePane = i;
    });
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  @override
  void dispose() {
    // 批：焦点归属——条件清（防 pushReplacement 清掉新页）
    EditorKernel? activeKernel;
    final activePane = _panes[_activePane];
    if (activePane is _NotePane) activeKernel = activePane.kernel;
    for (final pane in _panes) {
      if (pane is _NotePane) pane.kernel.dispose();
    }
    if (activeKernel != null && EditorKernel.active == activeKernel) {
      EditorKernel.blur();
    }
    // 批 2-4：移除监听
    CardService.revision.removeListener(_onCardsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeHasNote = _panes[_activePane] is _NotePane;
    final activeHasContent = _panes[_activePane] is _NotePane ||
                             _panes[_activePane] is _ReaderPane;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('多栏工作台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop_square),
            tooltip: '单栏',
            onPressed: () => _setLayout(1),
          ),
          IconButton(
            icon: const Icon(Icons.view_column),
            tooltip: '双栏',
            onPressed: () => _setLayout(2),
          ),
          IconButton(
            icon: const Icon(Icons.view_week),
            tooltip: '三栏',
            onPressed: () => _setLayout(3),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_to_queue),
            tooltip: '加阅读器栏',
            onPressed: _showAddReaderPicker,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_showMaterialPanel
                ? Icons.view_sidebar
                : Icons.view_sidebar_outlined),
            tooltip: _showMaterialPanel ? '收起素材栏' : '展开素材栏',
            isSelected: _showMaterialPanel,
            onPressed: _toggleMaterialPanel,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availW = constraints.maxWidth;
          const dividerW = 16.0;
          const materialW = 280.0;
          final showMaterial = _showMaterialPanel && activeHasContent;

          // 可用宽 = 总宽 - 分隔线占位 - (素材栏 + 其前分隔线)
          final panesArea = availW -
              (_layoutMode - 1) * dividerW -
              (showMaterial ? dividerW + materialW : 0);

          final paneRatios = _paneRatios.take(_layoutMode).toList();
          final paneWidths = _computePaneWidths(paneRatios, panesArea);
          final ratioSum = paneRatios.reduce((a, b) => a + b);
          final perRatio = ratioSum > 0 ? panesArea / ratioSum : 0.0;

          return Row(
            children: [
              for (var i = 0; i < _layoutMode; i++) ...[
                if (i > 0)
                  _DraggableDivider(
                    width: dividerW,
                    onDrag: (dx) => _onDividerDrag(i, dx, perRatio),
                    onDoubleTap: _resetPaneRatios,
                  ),
                SizedBox(
                  width: paneWidths[i],
                  child: _buildPane(i),
                ),
              ],
              if (showMaterial) ...[
                const SizedBox(width: dividerW),
                EditorMaterialSlot(
                  items: _materialItems,
                  enabled: activeHasNote,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPane(int i) {
    final pane = _panes[i];
    final isActive = i == _activePane;
    return Listener(
      // 批：多栏焦点修——Listener.onPointerDown 走 pointer 阶段
      // 不进 Gesture Arena——不被 TextField / QuillEditor 抢
      // translucent 保留——hit-test 命中层面也需（两层配合，省不得）
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setActivePane(i),
      child: Container(
        decoration: isActive
            ? BoxDecoration(border: Border.all(color: Colors.blue, width: 2))
            : null,
        child: _buildPaneContent(pane, i),
      ),
    );
  }

  Widget _buildPaneContent(_PaneState pane, int i) {
    return switch (pane) {
      _EmptyPane() => _buildEmptyPane(i),
      _NotePane(:final note, :final kernel) => WorkbenchBody(
          kernel: kernel,
          entry: note,
          showBottomBar: true,
          onCancel: null,
          saveLabel: '💾 保存',
          compact: true,
          appBarHasCardAction: false,
          // 批：读/编辑态 + 编辑按钮回调
          isReadMode: (pane as _NotePane).isReadMode,
          onEditRequest: () {
            setState(() {
              (pane as _NotePane).isReadMode = false;
            });
          },
        ),
      _ReaderPane(:final bookId, :final fileName, :final filePath) => EpubReaderPage(
          bookId: bookId,
          fileName: fileName,
          filePath: filePath,
          embedMode: true,
          onExit: () => setState(() => _panes[i] = const _EmptyPane()),
        ),
    };
  }

  Widget _buildEmptyPane(int i) {
    return DragTarget<MaterialItem>(
      onAcceptWithDetails: (details) => _handleDropOnPane(i, details.data),
      builder: (context, candidate, rejected) {
        return Container(
          color: candidate.isNotEmpty
              ? Colors.blue.shade50
              : Colors.grey.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_new, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('拖拽笔记到这里',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _fillPaneWithNote(i),
                  icon: const Icon(Icons.add),
                  label: const Text('选笔记'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 可拖拽分隔线——宽 [width]（默认 8，视觉线仅 1 宽居中）
/// 拖拽 → onDrag(dx)
/// 双击 → onDoubleTap（复位等分）
/// 可拖拽分隔线——视觉强提示 + 8px 命中区
///
/// 常态：2px 灰线 + 中间三点 grip（暗示「可拖」）
/// hover / 拖动：4px 蓝线 + grip 变色（反馈）
class _DraggableDivider extends StatefulWidget {
  final double width;
  final void Function(double dx) onDrag;
  final VoidCallback onDoubleTap;

  const _DraggableDivider({
    required this.width,
    required this.onDrag,
    required this.onDoubleTap,
  });

  @override
  State<_DraggableDivider> createState() => _DraggableDividerState();
}

class _DraggableDividerState extends State<_DraggableDivider> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _dragging;

    final lineColor = active
        ? Colors.blue.shade400
        : Colors.grey.shade400;
    final lineWidth = active ? 4.0 : 2.0;
    final gripColor = active
        ? Colors.blue.shade700
        : Colors.grey.shade600;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onDoubleTap: widget.onDoubleTap,
        child: SizedBox(
          width: widget.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 底线——常态 2px 灰 / hover 4px 蓝
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: lineWidth,
                color: lineColor,
              ),
              // grip——三个小圆点——常态暗示「可拖」
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _gripDot(gripColor),
                  const SizedBox(height: 4),
                  _gripDot(gripColor),
                  const SizedBox(height: 4),
                  _gripDot(gripColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gripDot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}