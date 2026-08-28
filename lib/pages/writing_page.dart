// lib/pages/writing_page.dart
// 写作模式 — 全屏编辑器 + 素材面板 + 线索墙

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../widgets/writing/editor_area.dart';
import '../widgets/writing/material_panel.dart';
import '../widgets/writing/clue_board.dart';

enum WritingViewMode { editor, clueBoard }

class WritingPage extends StatefulWidget {
  final NotebookEntry? initialNote;
  final WritingViewMode initialViewMode; // ✅ 新增：初始视图模式

  const WritingPage({
    super.key,
    this.initialNote,
    this.initialViewMode = WritingViewMode.editor,
  });

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();

  NotebookEntry? _currentNote;
  List<NotebookEntry> _recentNotes = [];
  List<CardModel> _indexCards = [];
  bool _isLoading = true;
  bool _showMaterialPanel = false;
  WritingViewMode _viewMode = WritingViewMode.editor;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // ✅ 使用传入的 initialViewMode
    _viewMode = widget.initialViewMode;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final noteMaps = await _db.getAllNotes(includeDeleted: false);
      _recentNotes = noteMaps
          .map((m) => NotebookEntry.fromMap(m))
          .where((n) => n.status == 'active' || n.status == 'raw')
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final allCards = await _cardService.getAllCards();
      _indexCards = allCards.where((c) => c.cardType == CardType.indexCard).toList();

      if (widget.initialNote != null) {
        _currentNote = widget.initialNote;
      } else if (_recentNotes.isNotEmpty) {
        _currentNote = _recentNotes.first;
      } else {
        _currentNote = NotebookEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '无标题',
          content: '',
          tags: [],
          updatedAt: DateTime.now(),
          status: 'active',
          editorMode: 'plain',
        );
      }
    } catch (e) {
      print('加载写作数据失败: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveNote(String title, String content, String mode, List<String> tags) async {
    if (_currentNote == null) return;

    final updated = _currentNote!.copyWith(
      title: title,
      content: content,
      tags: tags,
      updatedAt: DateTime.now(),
      editorMode: mode,
      status: 'active',
    );

    await _db.updateNote(updated.toMap());
    setState(() {
      _currentNote = updated;
    });
    await _loadData();
  }

  void _insertText(String text) {
    _editorKey.currentState?.insertText(text);
  }

  void _insertCard(CardModel card) {
    final citation = '> 📚 **${card.indexTitle ?? '引用'}**\n'
        '> ${card.highlight ?? card.displayFront}\n'
        '> —— ${card.author ?? card.sourceTitle ?? '来源未知'}\n';
    _editorKey.currentState?.insertText(citation);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📇 已插入卡片：${card.indexTitle ?? '未命名'}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  final GlobalKey<EditorAreaState> _editorKey = GlobalKey<EditorAreaState>();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('✍️ 写作模式'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _viewMode == WritingViewMode.editor
          ? _buildEditorView()
          : _buildClueBoardView(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_currentNote?.title ?? '✍️ 写作模式'),
      centerTitle: true,
      actions: [
        // 切换视图
        IconButton(
          icon: Icon(_viewMode == WritingViewMode.editor
              ? Icons.bubble_chart
              : Icons.edit_note),
          onPressed: () {
            setState(() {
              _viewMode = _viewMode == WritingViewMode.editor
                  ? WritingViewMode.clueBoard
                  : WritingViewMode.editor;
            });
          },
          tooltip: _viewMode == WritingViewMode.editor ? '线索墙' : '编辑器',
        ),
        // 素材面板开关
        IconButton(
          icon: Badge(
            isLabelVisible: _indexCards.isNotEmpty,
            label: Text('${_indexCards.length}'),
            child: Icon(Icons.library_books),
          ),
          onPressed: () {
            setState(() {
              _showMaterialPanel = !_showMaterialPanel;
            });
          },
          tooltip: '素材库',
        ),
        // 保存
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () {
            _editorKey.currentState?.save();
          },
          tooltip: '保存 (Ctrl+S)',
        ),
      ],
    );
  }

  Widget _buildEditorView() {
    return Row(
      children: [
        Expanded(
          flex: _showMaterialPanel ? 7 : 10,
          child: EditorArea(
            key: _editorKey,
            note: _currentNote!,
            onSave: _saveNote,
            onInsertText: _insertText,
            onInsertCard: _insertCard,
          ),
        ),
        if (_showMaterialPanel) ...[
          VerticalDivider(width: 1, thickness: 1),
          SizedBox(
            width: 280,
            child: MaterialPanel(
              cards: _indexCards,
              onInsertText: (text) {
                _insertText(text);
              },
              onInsertCard: (card) {
                _insertCard(card);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClueBoardView() {
    return ClueBoard(
      notes: _recentNotes,
      cards: _indexCards,
      onNoteTap: (note) {
        setState(() {
          _currentNote = note;
          _viewMode = WritingViewMode.editor;
        });
      },
      onCardTap: (card) {
        _insertCard(card);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📇 已插入卡片：${card.indexTitle ?? '未命名'}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _createNewNote,
      mini: true,
      tooltip: '新建笔记',
      child: const Icon(Icons.add),
    );
  }

  void _createNewNote() {
    final newNote = NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '无标题 ${DateTime.now().hour}:${DateTime.now().minute}',
      content: '',
      tags: [],
      updatedAt: DateTime.now(),
      status: 'active',
      editorMode: 'plain',
    );
    setState(() {
      _currentNote = newNote;
      _recentNotes.insert(0, newNote);
    });
    _editorKey.currentState?.clear();
  }
}