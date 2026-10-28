import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../services/multi_pane_bus.dart';
import '../widgets/writing/clue_board.dart';

sealed class _PaneState {
  const _PaneState();
}

class _EmptyPane extends _PaneState {
  const _EmptyPane();
}

class _ClueBoardPane extends _PaneState {
  final String viewId;
  const _ClueBoardPane({required this.viewId});
}

class _NotePane extends _PaneState {
  final NotebookEntry note;
  final MarkdownKernel kernel;
  bool isReadMode; // 批：多栏每栏读/编辑态
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
  final String? initialReaderBookId; // 批 3
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
  final CardService _cardService = CardService(); // 批 3：阅读器栏素材区取来源卡

  late List<_PaneState> _panes;
  late int _layoutMode;
  int _activePane = 0;

  // ─── 全局素材栏（1c-redo）───
  bool _showMaterialPanel = false;
  List<MaterialItem> _materialItems = [];

  // 线索墙 pane 的 GlobalKey —— 供分派上墙调用
  final _clueBoardKey = GlobalKey<ClueBoardState>();

  // 每个阅读器 pane 独立 GlobalKey
  final Map<int, GlobalKey<EpubReaderPageState>?> _readerKeys = {};

  // ─── 拖拽分隔线 ───
  // 三个 pane 的比例——和恒 1——只前 _layoutMode 有效
  List<double> _paneRatios = [1 / 3, 1 / 3, 1 / 3];

  // 每 pane 最低宽——(甲) 技术门槛 + (乙) 产品门槛——取 max
  // ⚠️ 待真机实测后定——现用占位 180
  static const double _minPaneW = 240.0;

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
      debugPrint(
        'MultiPanePage: 笔记数 ${widget.initialEntries.length} 超栏上限 $maxNoteSlots，已截断',
      );
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
    // 补全初始化顶栏状态：无论是阅读器、笔记还是画板，一进来就立刻接管全局顶栏
    if (_panes.isNotEmpty) {
      final firstPane = _panes[0];
      if (firstPane is _ReaderPane) {
        MultiPaneBus.instance.setContext(MultiPaneContext.reader);
      } else if (firstPane is _NotePane) {
        MultiPaneBus.instance.setContext(MultiPaneContext.note);
      } else if (firstPane is _ClueBoardPane) {
        MultiPaneBus.instance.setContext(MultiPaneContext.clueBoard);
      }
    }
    // 批 2-4：监听卡片库变化——自动刷素材区
    CardService.revision.addListener(_onCardsChanged);
  }

  void _onCardsChanged() {
    if (mounted && _showMaterialPanel) _reloadMaterialItems();
  }

  _NotePane _buildNotePane(NotebookEntry note) {
    final kernel = MarkdownKernel(
      EditorContext(entry: note, isFromCollection: false, onSave: _savePane),
    );
    return _NotePane(note: note, kernel: kernel);
  }

  List<Widget> _buildTopBarActions(MultiPaneContext ctx, bool narrow) {
    final pane = _activePane < _panes.length ? _panes[_activePane] : const _EmptyPane();
    final actions = <Widget>[];

    if (ctx == MultiPaneContext.reader && pane is _ReaderPane) {
      final key = _readerKeys[_activePane];
      actions.add(IconButton(
        icon: const Icon(Icons.menu_book),
        tooltip: '目录',
        onPressed: () => key?.currentState?.showToc(),
      ));
      actions.add(IconButton(
        icon: const Icon(Icons.search),
        tooltip: '搜索',
        onPressed: () => key?.currentState?.showSearch(),
      ));
      if (narrow) {
        actions.add(PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz),
          tooltip: '更多',
          onSelected: (v) => _handleReaderMoreAction(v, key?.currentState),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'notes', child: Text('标注列表')),
            PopupMenuItem(value: 'focus', child: Text('专注模式')),
            PopupMenuItem(value: 'mindmap', child: Text('思维导图')),
            PopupMenuItem(value: 'export_mindmap', child: Text('导出思维导图')),
            PopupMenuItem(value: 'aggregate', child: Text('关联聚合')),
            PopupMenuItem(value: 'rating', child: Text('评分书评')),
            PopupMenuItem(value: 'stats', child: Text('阅读统计')),
            PopupMenuItem(value: 'batch_cards', child: Text('批量生成卡片')),
            PopupMenuItem(value: 'export_notes', child: Text('导出笔记')),
            PopupMenuItem(value: 'settings', child: Text('设置')),
            PopupMenuItem(value: 'material', child: Text('素材栏')),
          ],
        ));
      } else {
        actions.add(IconButton(
          icon: const Icon(Icons.format_list_bulleted),
          tooltip: '标注',
          onPressed: () => key?.currentState?.showNotesPanel(),
        ));
        actions.add(PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: '更多',
          onSelected: (v) => _handleReaderMoreAction(v, key?.currentState),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'focus', child: Text('专注模式')),
            PopupMenuItem(value: 'mindmap', child: Text('思维导图')),
            PopupMenuItem(value: 'export_mindmap', child: Text('导出思维导图')),
            PopupMenuItem(value: 'aggregate', child: Text('关联聚合')),
            PopupMenuItem(value: 'rating', child: Text('评分书评')),
            PopupMenuItem(value: 'stats', child: Text('阅读统计')),
            PopupMenuItem(value: 'batch_cards', child: Text('批量生成卡片')),
            PopupMenuItem(value: 'export_notes', child: Text('导出笔记')),
            PopupMenuItem(value: 'settings', child: Text('设置')),
          ],
        ));
      }
    } else if (ctx == MultiPaneContext.note && pane is _NotePane) {
      actions.add(IconButton(
        icon: const Icon(Icons.save),
        tooltip: '保存',
        onPressed: () => pane.kernel.save(),
      ));
      actions.add(IconButton(
        icon: const Icon(Icons.credit_card),
        tooltip: '制卡',
        onPressed: () => pane.kernel.createReviewCard(),
      ));
      actions.add(PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: '更多',
        onSelected: (v) {
          switch (v) {
            case 'outline':
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('大纲功能开发中')));
              break;
            case 'export':
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导出功能开发中')));
              break;
            case 'preview':
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('预览模式开发中')));
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'outline', child: Text('文档大纲')),
          PopupMenuItem(value: 'export', child: Text('导出笔记')),
          PopupMenuItem(value: 'preview', child: Text('预览模式')),
        ],
      ));
    } else if (ctx == MultiPaneContext.clueBoard) {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: '选择',
          onPressed: () => _clueBoardKey.currentState?.setSelectMode(),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '画笔',
          onPressed: () => _clueBoardKey.currentState?.setPenMode(),
        ),
        IconButton(
          icon: const Icon(Icons.cleaning_services_outlined),
          tooltip: '橡皮',
          onPressed: () => _clueBoardKey.currentState?.setEraserMode(),
        ),
        IconButton(
          icon: const Icon(Icons.title),
          tooltip: '文字',
          onPressed: () => _clueBoardKey.currentState?.setTextMode(),
        ),
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: '撤销',
          onPressed: () => _clueBoardKey.currentState?.undo(),
        ),
        IconButton(
          icon: const Icon(Icons.clear_all, color: Colors.red),
          tooltip: '重置画板',
          onPressed: () => _clueBoardKey.currentState?.resetBoard(),
        ),
      ]);
    }

    actions.add(PopupMenuButton<String>(
      icon: const Icon(Icons.view_quilt),
      tooltip: '布局',
      onSelected: (v) {
        if (v == '1') _setLayout(1);
        if (v == '2') _setLayout(2);
        if (v == '3') _setLayout(3);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: '1', child: Text('单栏')),
        PopupMenuItem(value: '2', child: Text('双栏')),
        PopupMenuItem(value: '3', child: Text('三栏')),
      ],
    ));

    if (!narrow) {
      actions.add(IconButton(
        icon: Icon(
          _showMaterialPanel ? Icons.view_sidebar : Icons.view_sidebar_outlined,
        ),
        tooltip: _showMaterialPanel ? '收起素材栏' : '展开素材栏',
        isSelected: _showMaterialPanel,
        onPressed: _toggleMaterialPanel,
      ));
    }

    return actions;
  }

  void _handleReaderMoreAction(String v, EpubReaderPageState? s) {
    if (s == null) return;
    switch (v) {
      case 'notes': s.showNotesPanel(); break;
      case 'focus': s.toggleFocusMode(); break;
      case 'mindmap': s.showMindMap(); break;
      case 'export_mindmap': s.exportMindMap(); break;
      case 'aggregate': s.showAggregatedNotes(); break;
      case 'rating': s.showRatingReviewDialog(); break;
      case 'stats': s.showReadingStats(); break;
      case 'batch_cards': s.showBatchCardDialog(); break;
      case 'export_notes': s.exportNotes(); break;
      case 'settings': s.openSettings(); break;
      case 'material': _toggleMaterialPanel(); break;
    }
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
        sourceType: 'book',
        sourceId: pane.bookId,
      );
      final items = cards.map((c) => MaterialItem.fromCard(c)).toList();
      if (!mounted) return;
      setState(() => _materialItems = items);
    } else if (pane is _ClueBoardPane) {
      final allCards = await _cardService.getAllCards();
      final cards = allCards
          .where((c) => c.cardType == CardType.indexCard)
          .toList();
      final notesRaw = await DatabaseService().getAllNotes(
        includeDeleted: false,
      );
      final notes = notesRaw.map((m) => NotebookEntry.fromMap(m)).toList();
      final items = <MaterialItem>[
        ...cards.map((c) => MaterialItem.fromCard(c)),
        ...notes.map((n) => MaterialItem.fromNote(n)),
      ];
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
    if (sum < 2 * minRatio) return; // 无空间可拖

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
  List<double> _computePaneWidths(List<double> ratios, double area) {
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

  Future<void> _showAddReaderPicker({int? targetIndex}) async {
    final emptyIndex = targetIndex ?? _panes.indexWhere((p) => p is _EmptyPane);
    if (emptyIndex == -1 || emptyIndex >= _layoutMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('栏已满，请先关闭一栏再加')));
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

  void _addClueBoardPane(int i) {
    if (_panes.any((p) => p is _ClueBoardPane)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('线索墙已存在')));
      return;
    }
    setState(() {
      _panes[i] = const _ClueBoardPane(viewId: 'global');
      _activePane = i;
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
    List<ExploreTask> exploreTasks, {
    bool? isAuto,
  }) async {
    // isAuto 收参但不用 —— multi_pane 保存后不 pop
    // 仅为满足 SaveCallback 类型签名
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
      final auto = isAuto ?? false; // C 块 7
      setState(() {
        for (var i = 0; i < _panes.length; i++) {
          final p = _panes[i];
          if (p is _NotePane && p.note.id == entry.id) {
            p.kernel.updateEntry(updated);
            _panes[i] = _NotePane(
              note: updated,
              kernel: p.kernel,
              isReadMode: auto ? p.isReadMode : true, // C 块 7：自动保留原态
            );
          }
        }
      });
    }
    return true;
  }

  Future<void> _showExitDialog() async {
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('当前有未保存的编辑内容，是否保存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      final notePanes = _panes.whereType<_NotePane>().toList();
      var allOk = true;
      for (final p in notePanes) {
        if (p.kernel.isDirty) {
          final ok = await p.kernel.save();
          if (!ok) {
            allOk = false;
            break;
          }
        }
      }
      if (!allOk && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('部分内容保存失败，请重试')));
        return;
      }
      if (allOk && mounted) Navigator.pop(context);
    } else if (choice == 'discard') {
      for (final p in _panes.whereType<_NotePane>()) {
        if (p.kernel.isDirty) p.kernel.markClean();
      }
      if (mounted) Navigator.pop(context);
    }
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
    if (_activePane >= n && _panes[_activePane] is _ClueBoardPane) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('线索墙在将关闭的栏位，不可保留')),
      );
      return;
    }
    setState(() {
      if (_activePane >= n) {
        final tmp = _panes[n - 1];
        _panes[n - 1] = _panes[_activePane];
        _panes[_activePane] = tmp;
        final tmpKey = _readerKeys[n - 1];
        _readerKeys[n - 1] = _readerKeys[_activePane];
        _readerKeys[_activePane] = tmpKey;
      }
      for (var i = n; i < _layoutMode; i++) {
        final old = _panes[i];
        if (old is _NotePane) old.kernel.dispose();
        _panes[i] = const _EmptyPane();
        _readerKeys.remove(i);
      }
      _layoutMode = n;
      _activePane = _activePane.clamp(0, n - 1);
      _paneRatios = [1 / 3, 1 / 3, 1 / 3];
    });
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
  }

  void _setActivePane(int i) {
    if (i == _activePane) return;
    final oldPane = _panes[_activePane];
    if (oldPane is _ReaderPane) {
      _readerKeys[_activePane]?.currentState?.hideCardBoxPeek();
    }
    setState(() => _activePane = i);
    _syncFocus();
    if (_showMaterialPanel) _reloadMaterialItems();
    final pane = _panes[i];
    if (pane is _ReaderPane) {
      MultiPaneBus.instance.setContext(MultiPaneContext.reader);
    } else if (pane is _NotePane) {
      MultiPaneBus.instance.setContext(MultiPaneContext.note);
    } else if (pane is _ClueBoardPane) {
      MultiPaneBus.instance.setContext(MultiPaneContext.clueBoard);
    } else {
      MultiPaneBus.instance.setContext(MultiPaneContext.empty);
    }
  }

  Future<void> _saveActivePane() async {
    final ctx = MultiPaneBus.instance.activeContext.value;
    switch (ctx) {
      case MultiPaneContext.note:
        final pane = _panes[_activePane];
        if (pane is _NotePane) {
          final ok = await pane.kernel.save();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? '💾 笔记已保存' : '⚠️ 保存失败，请重试')),
          );
        }
        break;
      case MultiPaneContext.reader:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ℹ️ 阅读进度已自动保存')),
        );
        break;
      case MultiPaneContext.clueBoard:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ℹ️ 画板状态已自动保存')),
        );
        break;
      case MultiPaneContext.empty:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ℹ️ 没有可保存的内容')),
        );
        break;
    }
  }

  Widget _wrapWithShortcuts(Widget child) {
    return Focus(
      autofocus: false,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyS, control: true):
              _SaveActivePaneIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _SaveActivePaneIntent: CallbackAction<_SaveActivePaneIntent>(
              onInvoke: (_) {
                _saveActivePane();
                return null;
              },
            ),
          },
          child: child,
        ),
      ),
    );
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
    MultiPaneBus.instance.clearReaderState();
    // 批 2-4：移除监听
    CardService.revision.removeListener(_onCardsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (outerContext, outerConstraints) {
        final activeHasNote = _panes[_activePane] is _NotePane;
        final activeHasContent =
            _panes[_activePane] is _NotePane ||
            _panes[_activePane] is _ReaderPane ||
            _panes[_activePane] is _ClueBoardPane;

        final availW = outerConstraints.maxWidth;
        const dividerW = 16.0;
        const materialW = 280.0;
        final showMaterial = _showMaterialPanel && activeHasContent;
        final panesArea = availW -
            (_layoutMode - 1) * dividerW -
            (showMaterial ? dividerW + materialW : 0);
        final paneRatios = _paneRatios.take(_layoutMode).toList();
        final paneWidths = _computePaneWidths(paneRatios, panesArea);
        final ratioSum = paneRatios.reduce((a, b) => a + b);
        final perRatio = ratioSum > 0 ? panesArea / ratioSum : 0.0;
        final activePaneWidth =
            _activePane < paneWidths.length ? paneWidths[_activePane] : availW;

        return PopScope(
          canPop: !_panes.any((p) => p is _NotePane && p.kernel.isDirty),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _showExitDialog();
          },
          child: _wrapWithShortcuts(Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: ValueListenableBuilder<MultiPaneContext>(
                valueListenable: MultiPaneBus.instance.activeContext,
                builder: (_, ctx, __) => Text(
                  ctx == MultiPaneContext.reader ? '阅读中' : '多栏工作台',
                ),
              ),
              actions: [
                ValueListenableBuilder<MultiPaneContext>(
                  valueListenable: MultiPaneBus.instance.activeContext,
                  builder: (_, ctx, __) {
                    final narrow = activePaneWidth < 500;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildTopBarActions(ctx, narrow),
                    );
                  },
                ),
              ],
            ),
            body: Row(
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
                    child: _buildPane(i, paneWidths[i]),
                  ),
                ],
                if (showMaterial) ...[
                  const SizedBox(width: dividerW),
                  EditorMaterialSlot(
                    items: _materialItems,
                    enabled:
                        activeHasNote || _panes[_activePane] is _ClueBoardPane,
                    onCustomCardTap: _panes[_activePane] is _ClueBoardPane
                        ? (card) =>
                              _clueBoardKey.currentState?.addCardToBoard(card)
                        : null,
                    onCustomNoteTap: _panes[_activePane] is _ClueBoardPane
                        ? (note) =>
                              _clueBoardKey.currentState?.addNoteToBoard(note)
                        : null,
                    currentFocusLabel: _panes[_activePane] is _ClueBoardPane
                        ? '素材将发往：线索墙'
                        : (_panes[_activePane] is _NotePane
                              ? '素材将发往：笔记'
                              : null),
                  ),
                ],
              ],
            ),
          )),
        );
      },
    );
  }

  Widget _buildPane(int i, double paneWidth) {
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
        child: _buildPaneContent(pane, i, paneWidth),
      ),
    );
  }

  Widget _buildPaneContent(_PaneState pane, int i, double paneWidth) {
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
        paneWidth: paneWidth,
        // 批：读/编辑态 + 编辑按钮回调
        isReadMode: (pane as _NotePane).isReadMode,
        onEditRequest: () {
          setState(() {
            (pane as _NotePane).isReadMode = false;
          });
        },
      ),
      _ReaderPane(:final bookId, :final fileName, :final filePath) =>
        ClipRect(
          child: EpubReaderPage(
            key: _readerKeys.putIfAbsent(i, () => GlobalKey<EpubReaderPageState>()),
            bookId: bookId,
            fileName: fileName,
            filePath: filePath,
            multiPaneBus: MultiPaneBus.instance,
            embedMode: true,
            onExit: () => setState(() => _panes[i] = const _EmptyPane()),
          ),
        ),
      _ClueBoardPane(:final viewId) => ClueBoard(
        key: _clueBoardKey,
        viewId: viewId,
        items: _materialItems,
        onCardTap: (card) {},
        embedded: true,
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
                Text(
                  '或拖入素材 / 选一个类型',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _fillPaneWithNote(i),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('笔记'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddReaderPicker(targetIndex: i),
                      icon: const Icon(Icons.menu_book),
                      label: const Text('阅读器'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addClueBoardPane(i),
                      icon: const Icon(Icons.account_tree),
                      label: const Text('线索墙'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SaveActivePaneIntent extends Intent {
  const _SaveActivePaneIntent();
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

    final lineColor = active ? Colors.blue.shade400 : Colors.grey.shade400;
    final lineWidth = active ? 4.0 : 2.0;
    final gripColor = active ? Colors.blue.shade700 : Colors.grey.shade600;

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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
