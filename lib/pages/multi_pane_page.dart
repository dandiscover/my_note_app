import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/explore_task.dart';
import '../models/material_item.dart';
import '../models/note.dart';
import 'workbench/editor_kernel.dart';
import 'workbench/kernel_markdown.dart';
import 'workbench/workbench_body.dart';
import '../widgets/quick_switch_dialog.dart';

sealed class _PaneState {
  const _PaneState();
}

class _EmptyPane extends _PaneState {
  const _EmptyPane();
}

class _NotePane extends _PaneState {
  final NotebookEntry note;
  final MarkdownKernel kernel;
  _NotePane({required this.note, required this.kernel});
}

class MultiPanePage extends StatefulWidget {
  final List<NotebookEntry> initialEntries;
  final int initialLayout;

  const MultiPanePage({
    super.key,
    this.initialEntries = const [],
    this.initialLayout = 2,
  });

  @override
  State<MultiPanePage> createState() => _MultiPanePageState();
}

class _MultiPanePageState extends State<MultiPanePage> {
  late List<_PaneState> _panes;
  late int _layoutMode;
  int _activePane = 0;

  @override
  void initState() {
    super.initState();
    _layoutMode = widget.initialLayout.clamp(1, 3);
    _panes = List.generate(3, (i) {
      if (i < widget.initialEntries.length) {
        return _buildNotePane(widget.initialEntries[i]);
      }
      return const _EmptyPane();
    });
    _syncFocus();
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
    });
    _syncFocus();
  }

  void _setActivePane(int i) {
    if (i == _activePane) return;
    setState(() => _activePane = i);
    _syncFocus();
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
    setState(() => _panes[i] = _buildNotePane(selected));
    _activePane = i;
    _syncFocus();
  }

  void _handleDropOnPane(int i, MaterialItem item) {
    if (item.type != MaterialItemType.note || item.note == null) return;
    setState(() => _panes[i] = _buildNotePane(item.note!));
    _activePane = i;
    _syncFocus();
  }

  @override
  void dispose() {
    for (final pane in _panes) {
      if (pane is _NotePane) {
        pane.kernel.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
      body: Row(
        children: [
          for (var i = 0; i < _layoutMode; i++) ...[
            if (i > 0) const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _buildPane(i)),
          ],
        ],
      ),
    );
  }

  Widget _buildPane(int i) {
    final pane = _panes[i];
    final isActive = i == _activePane;
    return GestureDetector(
      onTap: () => _setActivePane(i),
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