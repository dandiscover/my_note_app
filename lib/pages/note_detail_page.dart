// lib/pages/note_detail_page.dart
// 笔记详情页 — 阅读模式 + 修改模式 + 生成卡片
// ✅ 采集页笔记保存时触发条件②
// ✅ 采集页进入时初始为编辑模式
// ✅ 深入入口按钮（始终显示，不限于非采集笔记）
// ✅ 用 _entry 可变状态替代 widget.entry
// ✅ _saveNote 增加 inquiryQuestion 参数
// ✅ 保存时使用 inquiryConclusion 和 exploreTasks
// ✅ _openInquiry 改为弹窗模式
// ✅ _handleInquiryConfirmed 先弹窗后保存，避免新建笔记未保存导致弹窗不出现
// ✅ _openInquiryDialog 增加 question 参数，弹窗关闭后统一保存
// ✅ 阅读模式增加探究缩略图区块，点击弹出只读概览弹窗
// ✅ 编辑模式也增加探究缩略图区块
// ✅ _saveNote 增加 exploreTasks 参数，保存时使用传入参数而非 _entry.exploreTasks
// ✅ 笔记加工台最小版：阅读模式加加工区（只读主问题 + 可编辑探究结论）+ 卡片区
// ✅ 独立 _saveCraftingFields（构造函数传 11 字段，不走 copyWith，支持清空）
// ✅ 加工台修复：弹窗溢出、输入不生效、保存按钮随 dirty 变
// ✅ 字段映射定稿：右键菜单改名"生成卡片"，_generateCard 加 selectedText 参数
// ✅ 各类型目标字段按选中文字预填
// ✅ 修索引卡分支 author/highlight 共用 backText 的 bug
// ✅ 修选择题分支 4 选项共用 backText + 硬编码选项的 bug
// ✅ 修复：_generateCard chip 列表过滤 CardType.guide（指导卡不提供手动创建入口）
// ✅ 子笔记嵌套：加工区下加"📎 子笔记（N）"入口
//    A 方案：子笔记数用 State 字段缓存，不用 FutureBuilder（避免每次 build 打库）
// ✅ v2 修复：选择题正确答案选择功能，choiceCorrectIndex 不再硬编码为 0
// ✅ 骨架：编辑模式加素材面板（默认收起，280 宽侧栏，右侧撑满）
// ✅ B 提交：AppBar 加素材库按钮（生成卡片与文件树之间，仅编辑模式显示），FullscreenEditor 撤两参数
// ✅ T-091：_saveNote 的 inquiryQuestion 去掉 ?? 兜底，传 null 就清空
// ✅ T-167：复制构造点显式带 contentFormat
// ✅ 第三轮：richtext 路由分派（_toggleMode push 到 RichtextEditorPage）
// ✅ 第三轮：读模式富文本渲染（只读 QuillEditor）
// ✅ 路一 v6：读模式自建右键菜单（云脑生成卡片 + 复制）
// ✅ C 批：卡片按钮合并 —— 右键两项（快捷索引 / 完整制卡）+ AppBar 弹 NoteCardDialog
// ✅ 功能批1 B+C：布局单/双/三栏 + 专注模式 + 拖拽 + 快速切换

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import 'workbench/workbench.dart';
import 'workbench/kernel_markdown.dart';
import 'workbench/editor_kernel.dart';
import '../models/note.dart';
import '../utils/app_string_utils.dart';
import '../models/card.dart';
import '../models/explore_task.dart';
import '../models/node.dart';
import '../services/card_service.dart';
import '../services/focus_mode_notifier.dart';
import '../services/richtext_adapter/richtext_adapter.dart';
import '../services/richtext_adapter/shared/attributes.dart';
import '../widgets/file_tree_panel.dart';
import '../widgets/floating_pet.dart';
import '../widgets/explore_task_summary_dialog.dart';
import '../widgets/writing/material_panel.dart';
import '../models/material_item.dart';
import '../widgets/quick_switch_dialog.dart';
import '../widgets/note_card_dialog.dart';
import 'book_detail_page.dart';
import 'inquiry_page.dart';
import 'richtext_editor_page.dart';

class NoteDetailPage extends StatefulWidget {
  final NotebookEntry entry;
  final bool isFromCollection;
  final String? nodeId;
  final String? currentNodeId;
  final String initialLayoutMode;

  const NoteDetailPage({
    super.key,
    required this.entry,
    this.isFromCollection = false,
    this.nodeId,
    this.currentNodeId,
    this.initialLayoutMode = 'single',
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final DatabaseService _db = DatabaseService();
  final CardService _cardService = CardService();
  bool _isSaving = false;
  String? _errorMessage;
  bool _isReadMode = true;
  late NotebookEntry _entry;
  late MarkdownKernel _kernel;

  // ✅ 笔记加工台最小版：状态字段
  List<CardModel> _noteCards = [];

  // ✅ 子笔记嵌套：子笔记数缓存（A 方案，避免每次 build 打库）
  int _subNotesCount = 0;

  // ✅ 骨架：素材面板状态
  bool _showMaterialPanel = false;
  List<CardModel> _indexCards = [];
  List<NotebookEntry> _relatedNotes = [];

  // 功能批1 B+C：布局 + 专注 + 侧栏内容
  String _layoutMode = 'single'; // single / double / triple
  bool _focusMode = false;
  String _sidebarContent = 'material'; // material / fileTree

  @override
  void initState() {
    super.initState();
    // 富文本笔记强制进读模式；编辑走 AppBar 按钮 push 到 RichtextEditorPage。
    // markdown 笔记沿用旧规则：采集页进来编辑，其他进来读。
    if (widget.entry.contentFormat == 'richtext') {
      _isReadMode = true;
    } else {
      _isReadMode = !widget.isFromCollection;
    }
    _entry = widget.entry;
    _layoutMode = widget.initialLayoutMode;
    focusModeNotifier.addListener(_onFocusModeChanged);
    _kernel = MarkdownKernel(EditorContext(
      entry: _entry,
      isFromCollection: widget.isFromCollection,
      onSave: _saveNote,
      isSaving: _isSaving,
      onInquiryConfirmed: _handleInquiryConfirmed,
    ));
    _loadNoteCards();
    _loadSubNotesCount();
    _loadIndexCards();
  }

  @override
  void dispose() {
    focusModeNotifier.removeListener(_onFocusModeChanged);
    super.dispose();
  }

  void _onFocusModeChanged() {
    if (!mounted) return;
    setState(() => _focusMode = focusModeNotifier.value);
  }

  // ─── 加工台：加载本笔记的卡片 ─────────────────────
  Future<void> _loadNoteCards() async {
    final cards = await _cardService.getCardsBySource(
      sourceType: 'note',
      sourceId: _entry.id,
    );
    if (!mounted) return;
    setState(() => _noteCards = cards);
  }

  // ✅ 子笔记嵌套：加载直接子笔记数（缓存到 _subNotesCount）
  //   A 方案：initState 调一次，不用 FutureBuilder 每次 build 打库
  Future<void> _loadSubNotesCount() async {
    if (widget.nodeId == null) return;
    final children = await _db.getChildren(widget.nodeId!);
    if (!mounted) return;
    setState(() => _subNotesCount = children.length);
  }

  // ✅ 骨架：加载索引卡（素材面板用）
  Future<void> _loadIndexCards() async {
    final allCards = await _cardService.getAllCards();
    if (!mounted) return;
    setState(() => _indexCards = allCards.where((c) => c.cardType == CardType.indexCard).toList());

    final noteMaps = await _db.getAllNotes(includeDeleted: false);
    final allNotes = noteMaps.map((m) => NotebookEntry.fromMap(m)).toList();
    if (!mounted) return;
    setState(() {
      _relatedNotes = allNotes
          .where((n) =>
              n.tags.any((t) => _entry.tags.contains(t)) && n.id != _entry.id)
          .toList();
    });
  }

  // ✅ 骨架：切换素材面板，展开时重载索引卡
  void _toggleMaterialPanel() {
    setState(() {
      _showMaterialPanel = !_showMaterialPanel;
    });
    if (_showMaterialPanel) {
      _loadIndexCards();
    }
  }

  // ─── 保存笔记 ─────────────────────────────
  Future<bool> _saveNote(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
    String? inquiryQuestion,
    List<ExploreTask> exploreTasks,
  ) async {
    if (_isSaving) return false;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final newStatus = widget.isFromCollection ? 'active' : _entry.status;

      final updated = NotebookEntry(
        id: _entry.id,
        title: title.isEmpty ? '无标题' : title,
        content: content.isEmpty ? '暂无内容' : content,
        updatedAt: DateTime.now(),
        status: newStatus,
        editorMode: editorMode,
        tags: tags,
        isLocked: _entry.isLocked,
        inquiryQuestion: inquiryQuestion,
        inquiryConclusion: _entry.inquiryConclusion,
        exploreTasks: exploreTasks,
        contentFormat: _entry.contentFormat,
      );

      await _db.updateNote(updated.toMap());

      if (!widget.isFromCollection && widget.nodeId != null) {
        final node = await _db.getNode(widget.nodeId!);
        if (node != null) {
          final updatedNode = node.copyWith(tags: tags);
          await _db.updateNode(updatedNode);
        }
      }

      setState(() {
        _entry = updated;
      });

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isFromCollection ? '✅ 已收入智库' : '✅ 已保存'),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('保存失败: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // ─── 快捷索引 —— 选中文字直接用，生成 CardType.indexCard（C 批） ────
  Future<void> _quickGenerateIndexCard(String selectedText) async {
    final text = selectedText.trim();
    if (text.isEmpty) return;
    final card = CardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardType: CardType.indexCard,
      sourceType: 'note',
      sourceId: _entry.id,
      sourceTitle: _entry.title,
      tags: List.from(_entry.tags),
      importance: Importance.medium,
      stage: 0,
      nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
      indexTitle: text.length > 50 ? '${text.substring(0, 50)}...' : text,
      highlight: text,
    );
    await _cardService.addCard(card);
    await _loadNoteCards();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📇 索引卡已生成')),
      );
    }
  }

  // ─── 完整制卡 —— 弹 NoteCardDialog，预填选区（C 批） ────
  Future<void> _showFullNoteCardDialog({String? selectedText}) async {
    final text = (selectedText != null && selectedText.trim().isNotEmpty)
        ? selectedText
        : _entry.content;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => NoteCardDialog(
        selectedText: text,
        comment: '',
        sourceId: _entry.id,
        sourceType: 'note',
      ),
    );
    if (result == null || !mounted) return;
    final card = CardModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardType: result['cardType'] as CardType,
      sourceType: 'note',
      sourceId: _entry.id,
      sourceTitle: _entry.title,
      tags: List.from((result['tags'] as List).cast<String>()),
      importance: result['importance'] as Importance,
      stage: 0,
      nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
      front: result['front'] as String?,
      back: result['back'] as String?,
      indexTitle: result['indexTitle'] as String?,
      author: result['author'] as String?,
      highlight: result['highlight'] as String?,
      question: result['question'] as String?,
      answer: result['answer'] as String?,
      fillQuestion: result['fillQuestion'] as String?,
      fillAnswer: result['fillAnswer'] as String?,
      choiceQuestion: result['choiceQuestion'] as String?,
      choiceOptions: (result['choiceOptions'] as List?)?.cast<String>(),
      choiceCorrectIndex: result['choiceCorrectIndex'] as int?,
      tfStatement: result['tfStatement'] as String?,
      tfIsTrue: result['tfIsTrue'] as bool?,
    );
    await _cardService.addCard(card);
    await _loadNoteCards();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 卡片已生成，可以去复习了')),
      );
    }
  }

  // ─── 切换模式 ─────────────────────────────
  Future<void> _toggleMode() async {
    if (_entry.contentFormat == 'richtext') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RichtextEditorPage(entry: _entry),
        ),
      );
      if (result == true && mounted) {
        await _reloadEntry();
      }
      return;
    }
    setState(() {
      _isReadMode = !_isReadMode;
    });
  }

  /// 切换「重要」标记（改造批 A）
  Future<void> _toggleTagImportant() async {
    final newTags = List<String>.from(_entry.tags);
    if (newTags.contains('重要')) {
      newTags.remove('重要');
    } else {
      newTags.add('重要');
    }
    try {
      final updated =
          _entry.copyWith(tags: newTags, updatedAt: DateTime.now());
      await _db.updateNote(updated.toMap());

      if (widget.nodeId != null) {
        final node = await _db.getNode(widget.nodeId!);
        if (node != null) {
          await _db.updateNode(node.copyWith(tags: newTags));
        }
      }

      if (mounted) setState(() => _entry = updated);
    } catch (e) {
      debugPrint('toggleTagImportant 失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 切换「待解决」标记（改造批 A）
  Future<void> _toggleTagPending() async {
    final newTags = List<String>.from(_entry.tags);
    if (newTags.contains('待解决')) {
      newTags.remove('待解决');
    } else {
      newTags.add('待解决');
    }
    try {
      final updated =
          _entry.copyWith(tags: newTags, updatedAt: DateTime.now());
      await _db.updateNote(updated.toMap());

      if (widget.nodeId != null) {
        final node = await _db.getNode(widget.nodeId!);
        if (node != null) {
          await _db.updateNode(node.copyWith(tags: newTags));
        }
      }

      if (mounted) setState(() => _entry = updated);
    } catch (e) {
      debugPrint('toggleTagPending 失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 笔记级标记行 —— ⭐ 重要 / ❓ 待解决
  Widget _buildTagToggleRow() {
    return Row(
      children: [
        ActionChip(
          avatar: Icon(
            _entry.tags.contains('重要') ? Icons.star : Icons.star_border,
            size: 16,
            color: _entry.tags.contains('重要') ? Colors.amber : null,
          ),
          label: const Text('重要'),
          onPressed: _toggleTagImportant,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 8),
        ActionChip(
          avatar: Icon(
            _entry.tags.contains('待解决')
                ? Icons.help
                : Icons.help_outline,
            size: 16,
            color: _entry.tags.contains('待解决') ? Colors.orange : null,
          ),
          label: const Text('待解决'),
          onPressed: _toggleTagPending,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  /// 富文本编辑页保存后，从库读最新 entry 并刷新本页。
  Future<void> _reloadEntry() async {
    try {
      final all = await _db.getAllNotes(includeDeleted: false);
      final map = all.firstWhere(
        (n) => n['id'] == _entry.id,
        orElse: () => <String, dynamic>{},
      );
      if (map.isEmpty) return;
      final fresh = NotebookEntry.fromMap(map);
      if (mounted) {
        setState(() {
          _entry = fresh;
        });
      }
    } catch (e) {
      debugPrint('重新加载笔记失败: $e');
    }
  }

  // ─── 文件树 ─────────────────────────────
  void _toggleFileTree() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: FileTreePanel(
                currentNodeId: widget.nodeId,
                currentNodeName: _entry.title,
                currentFolderId: widget.currentNodeId,
                onNodeTap: (targetNodeId, nodeType) {
                  Navigator.pop(context);
                  if (nodeType == 'note') {
                    _openNote(context, targetNodeId);
                  } else if (nodeType == 'book') {
                    _openBook(context, targetNodeId);
                  }
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNote(BuildContext context, String targetNodeId) async {
    final note = await _db.getNoteByNodeId(targetNodeId);
    if (note != null) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteDetailPage(
            entry: note,
            isFromCollection: false,
            nodeId: targetNodeId,
            initialLayoutMode: _layoutMode,
          ),
        ),
      );
    }
  }

  Future<void> _openBook(BuildContext context, String targetNodeId) async {
    final node = await _db.getNode(targetNodeId);
    if (node != null && node.targetId != null) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(
            bookId: node.targetId!,
            nodeId: targetNodeId,
          ),
        ),
      );
    }
  }

  // ─── 统一探究弹窗 ─────────────────────────────
  Future<void> _openInquiryDialog({String? question}) async {
    if (question != null && mounted) {
      setState(() {
        _entry = _entry.copyWith(
          inquiryQuestion: question,
          updatedAt: DateTime.now(),
        );
      });
    }

    final result = await showDialog<List<ExploreTask>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SizedBox(
          width: 600,
          child: InquiryPage(
            entry: _entry,
            isDialog: true,
          ),
        ),
      ),
    );

    if (mounted) {
      try {
        NotebookEntry updatedEntry = _entry;
        if (result != null) {
          updatedEntry = _entry.copyWith(
            exploreTasks: result,
            updatedAt: DateTime.now(),
          );
        } else if (question != null) {
          updatedEntry = _entry.copyWith(
            inquiryQuestion: question,
            updatedAt: DateTime.now(),
          );
        }
        if (updatedEntry != _entry) {
          await _db.updateNote(updatedEntry.toMap());
          setState(() {
            _entry = updatedEntry;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 探究任务已保存')),
          );
        }
      } catch (e) {
        debugPrint('保存探究数据失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleInquiryConfirmed(String question) async {
    await _openInquiryDialog(question: question);
  }

  Future<void> _openInquiry() async {
    await _openInquiryDialog();
  }

  void _showExploreSummary() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ExploreTaskSummaryDialog(
        entry: _entry,
      ),
    );
  }

  // ─── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _focusMode ? null : AppBar(
        title: Text(
          _isReadMode
              ? '📖 ${AppStringUtils.displayNoteTitle(_entry.title, _entry.content)}'
              : '✏️ ${AppStringUtils.displayNoteTitle(_entry.title, _entry.content)}',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.explore, color: Colors.purple),
            tooltip: '深入',
            onPressed: _openInquiry,
          ),
          IconButton(
            icon: Icon(_isReadMode ? Icons.edit : Icons.remove_red_eye),
            tooltip: _entry.contentFormat == 'richtext'
                ? '编辑'
                : (_isReadMode ? '切换到修改模式' : '切换到阅读模式'),
            onPressed: _toggleMode,
          ),
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: '生成卡片',
            onPressed: () => _showFullNoteCardDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '快速切换笔记',
            onPressed: _showQuickSwitch,
          ),
          if (!_isReadMode)
            IconButton(
              icon: Icon(_layoutIcon(_layoutMode)),
              tooltip: '布局：${_layoutLabel(_layoutMode)}',
              onPressed: _cycleLayout,
            ),
          if (!_isReadMode && _layoutMode == 'double')
            IconButton(
              icon: Icon(_sidebarContent == 'material'
                  ? Icons.library_books
                  : Icons.folder_open),
              tooltip: _sidebarContent == 'material' ? '切换为文件树' : '切换为素材',
              onPressed: () {
                setState(() {
                  _sidebarContent =
                      _sidebarContent == 'material' ? 'fileTree' : 'material';
                });
              },
            ),
          IconButton(
            icon: Icon(_focusMode ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: _focusMode ? '退出专注' : '专注模式',
            onPressed: _toggleFocusMode,
          ),
          if (!_isReadMode && _layoutMode != 'double')
            IconButton(
              icon: const Icon(Icons.library_books, color: Colors.purple),
              tooltip: '素材库',
              onPressed: _toggleMaterialPanel,
            ),
          if (!widget.isFromCollection)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _toggleFileTree,
              tooltip: '文件树',
            ),
        ],
      ),
      body: _isReadMode
          ? _buildReadMode()
          : _buildEditMode(),
      floatingActionButton: _focusMode
          ? FloatingActionButton(
              mini: true,
              onPressed: _toggleFocusMode,
              tooltip: '退出专注',
              child: const Icon(Icons.fullscreen_exit),
            )
          : null,
    );
  }

  Widget _buildReadMode() {
    if (_entry.contentFormat == 'richtext') {
      return _buildRichtextReadMode();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTagToggleRow(),
            const SizedBox(height: 12),
            if (_entry.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: _entry.tags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            const SizedBox(height: 12),
            SelectableText.rich(
              TextSpan(
                text: _entry.content,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
              contextMenuBuilder: (context, editableTextState) {
                final selectedText = editableTextState.textEditingValue.selection.textInside(
                  editableTextState.textEditingValue.text,
                );
                if (selectedText.isEmpty) return const SizedBox.shrink();
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: [
                    ContextMenuButtonItem(
                      label: '快捷索引',
                      onPressed: () => _quickGenerateIndexCard(selectedText),
                    ),
                    ContextMenuButtonItem(
                      label: '完整制卡',
                      onPressed: () =>
                          _showFullNoteCardDialog(selectedText: selectedText),
                    ),
                    ...editableTextState.contextMenuButtonItems,
                  ],
                );
              },
            ),
            if (_entry.exploreTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExploreSummaryTile(),
            ],
            const SizedBox(height: 12),
            _buildCraftingSection(),
            const SizedBox(height: 12),
            _buildSubNotesSection(),
            const SizedBox(height: 12),
            _buildNoteCardsSection(),
            const SizedBox(height: 12),
            Text(
              '更新于 ${_entry.updatedAt.toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichtextReadMode() {
    Map<String, dynamic> structure;
    try {
      structure = jsonDecode(_entry.content) as Map<String, dynamic>;
    } catch (_) {
      return _buildReadFallback('内容不是合法 JSON');
    }

    DeltaWithMemo result;
    try {
      result = RichtextAdapter.structureToDelta(structure);
    } catch (e) {
      return _buildReadFallback('结构转换失败：$e');
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTagToggleRow(),
            const SizedBox(height: 12),
            if (_entry.tags.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                children: _entry.tags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
              const SizedBox(height: 12),
            ],
            _RichtextReadView(
              key: ValueKey(_entry.content),
              delta: result.delta,
              onQuickIndex: _quickGenerateIndexCard,
              onFullCard: (text) =>
                  _showFullNoteCardDialog(selectedText: text),
            ),
            if (_entry.exploreTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExploreSummaryTile(),
            ],
            const SizedBox(height: 12),
            _buildCraftingSection(),
            const SizedBox(height: 12),
            _buildSubNotesSection(),
            const SizedBox(height: 12),
            _buildNoteCardsSection(),
            const SizedBox(height: 12),
            Text(
              '更新于 ${_entry.updatedAt.toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadFallback(String reason) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200, width: 0.5),
              ),
              child: Text(
                '⚠️ 富文本渲染失败，显示原始内容（$reason）',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _entry.content,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraftingSection() {
    final hasQuestion = _entry.inquiryQuestion != null && _entry.inquiryQuestion!.trim().isNotEmpty;
    final hasConclusion = _entry.inquiryConclusion != null && _entry.inquiryConclusion!.trim().isNotEmpty;

    if (!hasQuestion && !hasConclusion) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.purple.shade100, width: 0.5),
      ),
      color: Colors.purple.shade50.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯 ', style: TextStyle(fontSize: 14)),
                const Text(
                  '你想搞清楚什么？',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openInquiry,
                  child: const Icon(Icons.edit, size: 16, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (hasQuestion)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _entry.inquiryQuestion!,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '点击右上角编辑图标，写下一个你想搞清楚的问题',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                const Text('💭 ', style: TextStyle(fontSize: 14)),
                const Text(
                  '这让我想到什么？',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                (_entry.inquiryConclusion?.trim().isNotEmpty ?? false)
                    ? _entry.inquiryConclusion!
                    : '（暂无结论，点右上角编辑）',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: (_entry.inquiryConclusion?.trim().isNotEmpty ?? false)
                      ? null
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubNotesSection() {
    if (_subNotesCount == 0) return const SizedBox.shrink();

    return InkWell(
      onTap: _toggleFileTree,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            const Text('📎 ', style: TextStyle(fontSize: 14)),
            Text(
              '子笔记（$_subNotesCount）',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📇 ', style: TextStyle(fontSize: 14)),
            Text(
              '本笔记的卡片 (${_noteCards.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_noteCards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '还没有卡片',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          )
        else
          ..._noteCards.map((card) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Text(card.typeIcon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.displayFront,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildExploreSummaryTile() {
    final total = _entry.exploreTasks.length;
    final done = _entry.exploreTasks
        .where((t) => t.status == ExploreTaskStatus.completed)
        .length;
    final question = _entry.inquiryQuestion ?? '未设置主问题';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.purple.shade200, width: 0.5),
      ),
      color: Colors.purple.shade50,
      child: InkWell(
        onTap: _showExploreSummary,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.explore, color: Colors.purple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '共 $total 个行动 · 已完成 $done / $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEditMode() {
    // 防御：richtext 不该走到这里（initState 强制读模式，
    // _toggleMode 走 push）。若真到了，显示占位，不崩。
    if (_entry.contentFormat == 'richtext') {
      return const Center(
        child: Text('请通过编辑按钮打开富文本编辑器'),
      );
    }

    // ─── 专注模式：全屏编辑器 ───
    if (_focusMode) {
      return Workbench(
        kernel: _kernel,
        entry: _entry,
      );
    }

    final showTree = _layoutMode == 'triple';
    final showSidebar = _layoutMode == 'double';
    final showMaterial = _layoutMode == 'triple' ||
        (_layoutMode == 'single' && _showMaterialPanel);

    return Row(
      children: [
        // ─── 双栏：左侧侧栏（用户切素材/文件树） ───
        if (showSidebar) ...[
          SizedBox(
            width: 280,
            child: _sidebarContent == 'fileTree'
                ? FileTreePanel(
                    currentNodeId: widget.nodeId,
                    currentNodeName: _entry.title,
                    currentFolderId: widget.currentNodeId,
                    onNodeTap: (targetNodeId, nodeType) {
                      if (nodeType == 'note') {
                        _openNote(context, targetNodeId);
                      } else if (nodeType == 'book') {
                        _openBook(context, targetNodeId);
                      }
                    },
                  )
                : MaterialPanel(
                    items: [
                      ..._indexCards.map(MaterialItem.fromCard),
                      ..._relatedNotes.map(MaterialItem.fromNote),
                    ],
                    onInsertCard: (card) {
                      final quote =
                          card.highlight ?? card.indexTitle ?? card.displayFront;
                      final citation =
                          '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}';
                      EditorKernel.insertTextGlobal(citation);
                    },
                    onInsertNote: (_) {},
                  ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
        ],
        // ─── 三栏：左侧文件树 ───
        if (showTree) ...[
          SizedBox(
            width: 240,
            child: FileTreePanel(
              currentNodeId: widget.nodeId,
              currentNodeName: _entry.title,
              currentFolderId: widget.currentNodeId,
              onNodeTap: (targetNodeId, nodeType) {
                if (nodeType == 'note') {
                  _openNote(context, targetNodeId);
                } else if (nodeType == 'book') {
                  _openBook(context, targetNodeId);
                }
              },
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
        ],
        // ─── 中：编辑器 ───
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildTagToggleRow(),
                ),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⚠️ $_errorMessage',
                      style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                    ),
                  ),
                if (_entry.exploreTasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildExploreSummaryTile(),
                ],
                Expanded(
                  child: DragTarget<MaterialItem>(
                    onAcceptWithDetails: _handleDropItem,
                    builder: (context, candidate, rejected) => Workbench(
                      kernel: _kernel,
                      entry: _entry,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ─── 右侧：素材面板 ───
        if (showMaterial) ...[
          const VerticalDivider(width: 1, thickness: 1),
          SizedBox(
            width: 280,
            child: MaterialPanel(
              items: [
                ..._indexCards.map(MaterialItem.fromCard),
                ..._relatedNotes.map(MaterialItem.fromNote),
              ],
              onInsertCard: (card) {
                final quote =
                    card.highlight ?? card.indexTitle ?? card.displayFront;
                final citation =
                    '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}';
                EditorKernel.insertTextGlobal(citation);
              },
              onInsertNote: (_) {},
            ),
          ),
        ],
      ],
    );
  }

  // ─── B+C 新辅助方法 ─────────────────────────────

  void _handleDropItem(DragTargetDetails<MaterialItem> details) {
    final item = details.data;
    if (item.type == MaterialItemType.card && item.card != null) {
      final card = item.card!;
      final quote = card.highlight ?? card.indexTitle ?? card.displayFront;
      final citation =
          '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}';
      EditorKernel.insertTextGlobal(citation);
    } else if (item.type == MaterialItemType.note && item.note != null) {
      final note = item.note!;
      final text = note.content.isNotEmpty ? note.content : note.title;
      EditorKernel.insertTextGlobal(text);
    }
  }

  void _cycleLayout() {
    setState(() {
      if (_layoutMode == 'single') {
        _layoutMode = 'double';
      } else if (_layoutMode == 'double') {
        _layoutMode = 'triple';
      } else {
        _layoutMode = 'single';
      }
    });
  }

  IconData _layoutIcon(String mode) {
    switch (mode) {
      case 'double':
        return Icons.view_column_outlined;
      case 'triple':
        return Icons.view_sidebar_outlined;
      default:
        return Icons.crop_square;
    }
  }

  String _layoutLabel(String mode) {
    switch (mode) {
      case 'double':
        return '双栏';
      case 'triple':
        return '三栏';
      default:
        return '单栏';
    }
  }

  void _toggleFocusMode() {
    focusModeNotifier.value = !focusModeNotifier.value;
  }

  Future<void> _showQuickSwitch() async {
    final maps = await _db.getAllNotes(includeDeleted: false);
    final notes = maps.map((m) => NotebookEntry.fromMap(m)).toList();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => QuickSwitchDialog(
        notes: notes,
        onSelect: (note) {
          Navigator.pop(ctx);
          _jumpToNote(note);
        },
      ),
    );
  }

  Future<void> _jumpToNote(NotebookEntry note) async {
    final nodes = await _db.getAllNodes();
    final targetNode = nodes.firstWhere(
      (n) => n.nodeType == 'note' && n.targetId == note.id,
      orElse: () => Node.empty,
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(
          entry: note,
          nodeId: targetNode.id.isEmpty ? null : targetNode.id,
          initialLayoutMode: _layoutMode,
        ),
      ),
    );
  }
}

/// 富文本只读渲染 widget。
///
/// 持有 QuillController，dispose 时释放。
///
/// 为什么独立成 StatefulWidget：
///   - QuillController 有生命周期，不能在 build 里 new
///   - _buildReadMode 每次 rebuild 都调用，controller 要复用
class _RichtextReadView extends StatefulWidget {
  final List<Map<String, dynamic>> delta;
  final ValueChanged<String> onQuickIndex;
  final ValueChanged<String> onFullCard;

  const _RichtextReadView({
    super.key,
    required this.delta,
    required this.onQuickIndex,
    required this.onFullCard,
  });

  @override
  State<_RichtextReadView> createState() => _RichtextReadViewState();
}

class _RichtextReadViewState extends State<_RichtextReadView> {
  late final quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: quill.Document.fromJson(widget.delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.readOnly = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return quill.QuillEditor.basic(
      controller: _controller,
      config: quill.QuillEditorConfig(
        embedBuilders: [_DividerEmbedBuilder()],
        contextMenuBuilder: _buildContextMenu,
      ),
    );
  }

  Widget _buildContextMenu(
    BuildContext context,
    quill.QuillRawEditorState rawEditorState,
  ) {
    final controller = rawEditorState.controller;
    final selectedText = _getSelectedText(controller);

    if (selectedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: rawEditorState.contextMenuAnchors,
      buttonItems: [
        ContextMenuButtonItem(
          label: '快捷索引',
          onPressed: () {
            ContextMenuController.removeAny();
            widget.onQuickIndex(selectedText);
          },
        ),
        ContextMenuButtonItem(
          label: '完整制卡',
          onPressed: () {
            ContextMenuController.removeAny();
            widget.onFullCard(selectedText);
          },
        ),
        ContextMenuButtonItem(
          label: '复制',
          onPressed: () {
            ContextMenuController.removeAny();
            Clipboard.setData(ClipboardData(text: selectedText));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ 已复制'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getSelectedText(quill.QuillController controller) {
    final selection = controller.selection;
    if (!selection.isValid) return '';
    final text = controller.document.toPlainText();
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    if (start >= end) return '';
    return text.substring(start, end);
  }
}
/// 分割线嵌入对象的渲染器（读模式用）。
class _DividerEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => DeltaAttributes.divider;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return const Divider(thickness: 1);
  }
}