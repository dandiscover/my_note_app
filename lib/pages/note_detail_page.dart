// lib/pages/note_detail_page.dart
// 笔记详情页 — 阅读模式 + 修改模式 + 生成卡片
// （顶部注释略 —— 原文件头部注释保留不动）

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../services/open_tabs_manager.dart';
import '../database_service.dart';
import '../services/sync/cloud_sync_service.dart';
import '../services/sync/sync_manager.dart';
import '../services/note_opener.dart';
import 'workbench/kernel_markdown.dart';
import 'workbench/editor_kernel.dart';
import 'workbench/editor_material_slot.dart';
import 'workbench/editor_explore_area.dart';
import 'workbench/editor_app_bar.dart';
import '../widgets/workbench/outline_panel.dart';
import '../widgets/workbench/note_map_view.dart';
import '../widgets/workbench/note_map_breadcrumb.dart';
import '../services/command_palette_launcher.dart';
import 'workbench/workbench_body.dart';
import 'multi_pane_page.dart';
import '../models/note.dart';
import '../utils/app_string_utils.dart';
import '../models/card.dart';
import '../models/explore_task.dart';
import '../models/node.dart';
import '../services/card_service.dart';
import '../services/material_service.dart';
import '../services/focus_mode_notifier.dart';
import '../services/richtext_adapter/richtext_adapter.dart';
import '../services/richtext_adapter/shared/attributes.dart';
import '../widgets/file_tree_panel.dart';

import '../widgets/explore_task_summary_dialog.dart';

import '../models/material_item.dart';
import '../widgets/quick_switch_dialog.dart';
import '../widgets/note_card_dialog.dart';
import '../widgets/preview_popup.dart';
import 'book_detail_page.dart';
import '../services/note_book_link_service.dart';
import 'inquiry_page.dart';
import 'richtext_editor_page.dart';
import 'package:flutter/gestures.dart';
class NoteDetailPage extends StatefulWidget {
  final NotebookEntry entry;
  final bool isFromCollection;
  final String? nodeId;
  final String? currentNodeId;
  final bool isNew;
  final bool shouldPopOnSave;
  final bool syncToCloud;
  final bool initInEditMode;   // 批 1b 修复：从图书侧新建 → 强制进编辑态
  final bool embedded;         // 嵌入模式 —— 不包 Scaffold

  const NoteDetailPage({
    super.key,
    required this.entry,
    this.isFromCollection = false,
    this.nodeId,
    this.currentNodeId,
    this.isNew = false,
    this.shouldPopOnSave = false,
    this.syncToCloud = false,
    this.initInEditMode = false,
    this.embedded = false,
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
  late bool _isNewLocal;   // 债-6：防保存后重挂 node

  // ✅ 笔记加工台最小版：状态字段
  List<CardModel> _noteCards = [];

  // ✅ 子笔记嵌套：子笔记数缓存
  int _subNotesCount = 0;

  // ✅ 骨架：素材面板状态
  bool _showMaterialPanel = false;
  bool _showOutlinePanel = false;
  bool _showFileTree = false;
  bool _showRightPanelWide = false;
  List<Node> _subNotesList = [];
  List<Map<String, dynamic>> _backlinks = [];
  final List<TapGestureRecognizer> _wikilinkRecognizers = [];
  bool _showNoteMap = false;
  List<BreadcrumbItem> _mapBreadcrumb = [];
  int _mapRefreshTick = 0;
  String? _currentNodeId;   // 当前笔记 node id（原地换根时变）
  List<MaterialItem> _materialItems = [];

  // 专注模式
  bool _focusMode = false;

  // 批 1b：关联的书
  List<Map<String, dynamic>> _linkedBooks = [];

  @override
  void initState() {
    super.initState();
    _isNewLocal = widget.isNew;
    _currentNodeId = widget.nodeId;
    _showNoteMap = false;
    if (widget.entry.contentFormat == 'richtext') {
      _isReadMode = true;
    } else if (widget.initInEditMode) {
      _isReadMode = false;
    } else {
      _isReadMode = !widget.isFromCollection;
    }
    _entry = widget.entry;
    focusModeNotifier.addListener(_onFocusModeChanged);
    _kernel = MarkdownKernel(EditorContext(
      entry: _entry,
      isFromCollection: widget.isFromCollection,
      onSave: _saveNote,
      isSaving: _isSaving,
      onInquiryConfirmed: _handleInquiryConfirmed,
    ));
    _kernel.contentController.addListener(_onContentChanged);
    EditorKernel.focus(_kernel);
    _loadNoteCards();
    _loadSubNotesCount();
    _loadMaterialItems();
    _loadLinkedBooks();
    _loadBacklinks();
    CardService.revision.addListener(_onCardsChanged);
  }

  void _onCardsChanged() {
    if (mounted && _showMaterialPanel) _loadMaterialItems();
  }

  @override
  void didUpdateWidget(covariant NoteDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.id != oldWidget.entry.id) {
      _entry = widget.entry;
      _kernel.updateEntry(widget.entry);
      _isReadMode = widget.entry.contentFormat == 'richtext'
          ? true
          : !widget.isFromCollection;
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final r in _wikilinkRecognizers) {
      r.dispose();
    }
    _wikilinkRecognizers.clear();
    focusModeNotifier.removeListener(_onFocusModeChanged);
    CardService.revision.removeListener(_onCardsChanged);
    _kernel.contentController.removeListener(_onContentChanged);
    if (EditorKernel.active == _kernel) {
      EditorKernel.blur();
    }
    _kernel.dispose();
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

  // ✅ 子笔记嵌套：加载直接子笔记数
  Future<void> _loadSubNotesCount() async {
    if (widget.nodeId == null) return;
    final children = await _db.getChildren(widget.nodeId!);
    if (!mounted) return;
    setState(() {
      _subNotesCount = children.length;
      _subNotesList = children;
    });
  }

  // ✅ 骨架：加载索引卡（素材面板用）
  Future<void> _loadMaterialItems() async {
    final items = await MaterialService.loadFor(_entry, nodeId: widget.nodeId);
    if (!mounted) return;
    setState(() => _materialItems = items);
  }

  void _toggleMaterialPanel() {
    setState(() {
      _showMaterialPanel = !_showMaterialPanel;
    });
    if (_showMaterialPanel) {
      _loadMaterialItems();
    }
  }

  void _toggleOutlinePanel() {
    setState(() => _showOutlinePanel = !_showOutlinePanel);
  }

  void _onOutlineTap(int offset) {
    _kernel.scrollToOffset(offset);
  }

  void _toggleNoteMap() {
    setState(() => _showNoteMap = !_showNoteMap);
    if (_showNoteMap) _loadMapBreadcrumb();
  }

  Future<void> _loadMapBreadcrumb() async {
    final items = <BreadcrumbItem>[];
    String? current = _currentNodeId;
    while (current != null) {
      final n = await _db.getNode(current);
      if (n == null) break;
      items.insert(0, BreadcrumbItem(nodeId: n.id, title: n.title));
      current = n.parentId;
    }
    if (mounted) setState(() => _mapBreadcrumb = items);
  }

  Future<void> _switchRoot(Node target) async {
    final note = await _db.getNoteByNodeId(target.id);
    if (note == null || !mounted) return;
    setState(() {
      _entry = note;
      _currentNodeId = target.id;
      _mapRefreshTick++;
    });
    _kernel.updateEntry(note);
    await _loadMapBreadcrumb();
  }

  Future<void> _onSubNoteTap(Node target) => _switchRoot(target);

  Future<void> _onBreadcrumbTap(String nodeId) async {
    final n = await _db.getNode(nodeId);
    if (n == null) return;
    await _switchRoot(n);
  }

  Future<void> _onNewSubNoteInLevel(Node parentNote) async {
    final ctrl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建子笔记'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '子笔记标题'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    final t = (title ?? '').trim();
    if (t.isEmpty) return;

    final now = DateTime.now();
    final noteId = 'sub_${now.microsecondsSinceEpoch}';
    final entry = NotebookEntry(
      id: noteId,
      title: t,
      content: '',
      updatedAt: now,
      status: 'raw',
      editorMode: 'plain',
    );
    await _db.insertNote(entry.toMap());
    await _db.attachNoteToNode(
      noteId: noteId,
      title: t,
      parentId: parentNote.id,
    );

    if (mounted) setState(() => _mapRefreshTick++);
  }

  void _onContentChanged() {
    if (_showOutlinePanel && mounted) setState(() {});
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
      final newStatus = _isNewLocal
          ? 'active'
          : (widget.isFromCollection ? 'active' : _entry.status);

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

      if (_isNewLocal) {
        await _db.insertNote(updated.toMap());
        final node = await _db.attachNoteToNode(
          noteId: _entry.id,
          title: title.isEmpty ? '无标题' : title,
          parentId: widget.currentNodeId,
          tags: tags,
        );
        _isNewLocal = false;   // 债-6：保存后置 false——防重挂
        if (widget.syncToCloud && CloudSyncService().isLoggedIn) {
          try {
            await CloudSyncService().syncNote(updated);
            if (node != null) await CloudSyncService().syncNode(node);
          } catch (_) {
            SyncManager().markDirty();
          }
        }
      } else {
        await _db.updateNote(updated.toMap());
      }

      final syncNode = await _db.getNodeByNoteId(updated.id);
      if (syncNode != null) {
        await _db.updateNode(syncNode.copyWith(
          title: updated.title,
          tags: tags,
        ));
      }

      setState(() {
        _entry = updated;
        _isReadMode = true;
      });

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isFromCollection ? '✅ 已收入智库' : '✅ 已保存'),
          ),
        );
      }

      if (widget.shouldPopOnSave && mounted) {
        if (widget.embedded) {
          OpenTabsManager.instance.close(_entry.id);
        } else {
          Navigator.pop(context, true);
        }
      }

      try {
        await NoteBookLinkService().rebuildWikiLinks(
          noteId: updated.id,
          content: updated.content,
        );
        await NoteBookLinkService().rebuildNoteNoteLinks(
          noteId: updated.id,
          content: updated.content,
        );
      } catch (e) {
        debugPrint('rebuildWikiLinks 失败: $e');
      }

      OpenTabsManager.instance.updateTitle(
        updated.id,
        AppStringUtils.displayNoteTitle(updated.title, updated.content),
      );

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

  // ─── 快捷索引 ────
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

  // ─── 完整制卡 ────
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
      _showNoteMap = false;
    });
  }

  /// 切换「重要」标记
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

  /// 切换「待解决」标记
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

  /// 笔记级标记行
  Widget _buildTagToggleRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _entry.tags.contains('重要') ? Icons.star : Icons.star_border,
            color: _entry.tags.contains('重要') ? Colors.amber : null,
          ),
          tooltip: '重要',
          onPressed: _toggleTagImportant,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            _entry.tags.contains('待解决')
                ? Icons.help
                : Icons.help_outline,
            color: _entry.tags.contains('待解决') ? Colors.orange : null,
          ),
          tooltip: '待解决',
          onPressed: _toggleTagPending,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  /// 富文本编辑页保存后重读
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
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    if (isWide) {
      setState(() => _showFileTree = !_showFileTree);
      return;
    }
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
              child: _buildFileTreePanel(),
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

  Widget _buildFileTreePanel() {
    return FileTreePanel(
      currentNodeId: _currentNodeId,
      currentNodeName: _entry.title,
      currentFolderId: widget.currentNodeId,
      onNodeTap: (targetNodeId, nodeType) {
        if (nodeType == 'note') {
          _openNote(context, targetNodeId);
        } else if (nodeType == 'book') {
          _openBook(context, targetNodeId);
        }
      },
    );
  }

  Future<void> _openNote(BuildContext context, String targetNodeId) async {
    final note = await _db.getNoteByNodeId(targetNodeId);
    if (note != null) {
      if (!widget.embedded) {
        Navigator.pop(context);
      }
      await NoteOpener.open(
        context: context,
        entry: note,
        isFromCollection: false,
        nodeId: targetNodeId,
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

  // ─── 批 1b：关联的书 ──────────────────────────────
  Future<void> _loadLinkedBooks() async {
    final rows = await NoteBookLinkService().getLinksByNote(_entry.id);
    final books = <Map<String, dynamic>>[];
    for (final r in rows) {
      final book = await _db.getBook(r['book_id'] as String);
      if (book != null) books.add(book);
    }
    if (!mounted) return;
    setState(() => _linkedBooks = books);
  }
    Future<void> _loadBacklinks() async {
    final svc = NoteBookLinkService();
    final backRows = await svc.getBacklinks(_entry.id);
    final outRows = await svc.getOutboundLinks(_entry.id);

    if (backRows.isEmpty && outRows.isEmpty) {
      if (mounted) setState(() => _backlinks = []);
      return;
    }

    final allNotes = await _db.getAllNotes(includeDeleted: false);
    final notesById = <String, Map<String, dynamic>>{
      for (final m in allNotes) m['id'] as String: m,
    };

    String displayOf(String id) {
      final m = notesById[id];
      if (m == null) return '未知';
      final rawTitle = (m['title'] as String? ?? '').trim();
      return rawTitle.isNotEmpty
          ? rawTitle
          : _virtualTitleOf(m['content'] as String? ?? '');
    }

    DateTime updatedAtOf(String id) {
      final m = notesById[id];
      if (m == null) return DateTime.fromMillisecondsSinceEpoch(0);
      try {
        return DateTime.parse(m['updatedAt'] as String? ?? '');
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final seen = <String>{};
    final enriched = <Map<String, dynamic>>[];

    // 反向：谁引用我
    for (final r in backRows) {
      final srcId = r['source_note_id'] as String;
      if (!seen.add(srcId)) continue;
      enriched.add({
        'note_id': srcId,
        'title': displayOf(srcId),
        'direction': 'back',
        'updated_at': updatedAtOf(srcId),
      });
    }

    // 正向：我引用谁
    for (final r in outRows) {
      final tgtId = r['target_note_id'] as String;
      if (!seen.add(tgtId)) continue;
      enriched.add({
        'note_id': tgtId,
        'title': displayOf(tgtId),
        'direction': 'out',
        'updated_at': updatedAtOf(tgtId),
      });
    }

    enriched.sort((a, b) {
      final da = a['direction'] as String;
      final db = b['direction'] as String;
      if (da != db) return da == 'back' ? -1 : 1;
      final ta = a['updated_at'] as DateTime;
      final tb = b['updated_at'] as DateTime;
      return tb.compareTo(ta);
    });

    if (!mounted) return;
    setState(() => _backlinks = enriched);
  }
  
  
  Widget _buildLinkedBooksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📚 关联的书 (${_linkedBooks.length})',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            TextButton.icon(
              onPressed: _onLinkBook,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('关联书目'),
            ),
          ],
        ),
        if (_linkedBooks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('还没有关联的书',
                style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          ..._linkedBooks.map((m) {
            return ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(m['title'] as String? ?? '未命名'),
              subtitle: Text(m['author'] as String? ?? ''),
              onTap: () => _openLinkedBook(m['id'] as String),
            );
          }),
      ],
    );
  }

  Future<void> _onLinkBook() async {
    final allMaps = await _db.getAllBooks();
    if (!mounted) return;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择书目'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: allMaps.isEmpty
              ? const Center(child: Text('还没有书'))
              : ListView.builder(
                  itemCount: allMaps.length,
                  itemBuilder: (_, i) {
                    final m = allMaps[i];
                    return ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(m['title'] as String? ?? '未命名'),
                      subtitle: Text(m['author'] as String? ?? ''),
                      onTap: () => Navigator.pop(ctx, m),
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
    try {
      await NoteBookLinkService().addLink(
        noteId: _entry.id,
        bookId: selected['id'] as String,
        linkType: NoteBookLinkService.linkTypeManual,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('关联失败，请重试')),
        );
      }
      return;
    }
    await _loadLinkedBooks();
  }

  Future<void> _openLinkedBook(String bookId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailPage(bookId: bookId),
      ),
    );
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
    final appBar = _focusMode
        ? null
        : EditorAppBar(
            title: null,
            isReadMode: _isReadMode,
            isRichtext: _entry.contentFormat == 'richtext',
            onInquiry: _openInquiry,
            onToggleMode: _toggleMode,
            onCard: () => _showFullNoteCardDialog(),
            onQuickSwitch: () => CommandPaletteLauncher.open(),
            onOpenMultiPane: _openMultiPane,
            onToggleFocus: _toggleFocusMode,
            isFocusMode: _focusMode,
            onToggleOutline:
                MediaQuery.sizeOf(context).width >= 600
                    ? _toggleOutlinePanel
                    : null,
            isOutlineOpen: _showOutlinePanel,
            onToggleMaterial: _toggleMaterialPanel,
            onFileTree: !widget.isFromCollection ? _toggleFileTree : null,
            trailingExtra: _buildTagToggleRow(),
          );

    final body = _isReadMode ? _buildReadMode() : _buildEditMode();

    final fab = _focusMode
        ? FloatingActionButton(
            mini: true,
            onPressed: _toggleFocusMode,
            tooltip: '退出专注',
            child: const Icon(Icons.fullscreen_exit),
          )
        : null;

    if (widget.embedded) {
      return Stack(
        children: [
          Column(
            children: [
              if (appBar != null) appBar,
              Expanded(child: body),
            ],
          ),
          if (fab != null)
            Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: appBar,
      body: body,
      floatingActionButton: fab,
    );
  }
  // _buildMapMode 已撤 —— 导图嵌入 _buildReadMode 的正文段


  Widget _buildReadMode() {
    if (_entry.contentFormat == 'richtext') {
      return _buildRichtextReadMode();
    }
     final isWide = MediaQuery.sizeOf(context).width >= 600;
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_buildReadBodySwitcher()],
            ),
            const SizedBox(height: 12),
            Builder(builder: (_) {
              final displayTags = _entry.tags
                  .where((t) => t != '重要' && t != '待解决')
                  .toList();
              if (displayTags.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: 4,
                children: displayTags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              );
            }),
            const SizedBox(height: 8),
            if (_showNoteMap)
              _buildMapBody()
            else
              SelectableText.rich(
                TextSpan(
                  children: _buildHighlightedSpans(
                    _entry.content,
                    const TextStyle(fontSize: 16, height: 1.6),
                  ),
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
              EditorExploreArea(entry: _entry, onTap: _showExploreSummary),
            ],
            const SizedBox(height: 12),
            _buildCraftingSection(),
            if (!isWide) ...[
              const SizedBox(height: 12),
              _buildLinkedBooksSection(),
              const SizedBox(height: 12),
              _buildSubNotesSection(),
              const SizedBox(height: 12),
              _buildNoteCardsSection(),
            ],
            const SizedBox(height: 12),
            Text(
              '更新于 ${_entry.updatedAt.toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
    if (!isWide) return body;

    final rightColumn = _buildRightColumn();
    final withRight = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: body),
        const VerticalDivider(width: 1),
        InkWell(
          onTap: () => setState(
              () => _showRightPanelWide = !_showRightPanelWide),
          child: rightColumn,
        ),
      ],
    );

    if (!_showFileTree) return withRight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 240, child: _buildFileTreePanel()),
        const VerticalDivider(width: 1),
        Expanded(child: withRight),
      ],
    );
  }

    /// 正文区切换 —— [正文] [导图]
  Widget _buildReadBodySwitcher() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('正文'),
          selected: !_showNoteMap,
          onSelected: (_) {
            if (_showNoteMap) setState(() => _showNoteMap = false);
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('导图'),
          selected: _showNoteMap,
          onSelected: (_) {
            if (!_showNoteMap) {
              setState(() => _showNoteMap = true);
              _loadMapBreadcrumb();
            }
          },
        ),
      ],
    );
  }
      List<TextSpan> _buildHighlightedSpans(String content, TextStyle base) {
      // 清旧 recognizer（防泄漏 / 防重复）
      for (final r in _wikilinkRecognizers) {
        r.dispose();
      }
      _wikilinkRecognizers.clear();

      // 匹配三类：#标签 / [[标题]] / [N](card:id) —— B5 加第三类
      final regex = RegExp(
          r'(^|\s)(#[^\s#]+)|(\[\[[^\]\n]+\]\])|(\[\d+\]\(card:[^)]+\))');
      final spans = <TextSpan>[];
      int last = 0;
      int refCounter = 0; // B5：动态编号 —— 每次渲染重算
      for (final m in regex.allMatches(content)) {
        if (m.start > last) {
          spans.add(TextSpan(text: content.substring(last, m.start), style: base));
        }
        final raw = m.group(0)!;
        if (m.group(3) != null) {
          // [[X]] —— 保持 B4 紫字（老白裁 1）
          final title = raw.substring(2, raw.length - 2).trim();
          final rec = TapGestureRecognizer()
            ..onTapUp = (details) =>
                _onWikilinkTap(title, details.globalPosition);
          _wikilinkRecognizers.add(rec);
          spans.add(TextSpan(
            text: raw,
            style: base.copyWith(
              color: Colors.purple.shade700,
            ),
            recognizer: rec,
          ));
        } else if (m.group(4) != null) {
          // B5：卡片角标 [N](card:id) —— N 按出现顺序重算
          final m2 = RegExp(r'^\[\d+\]\(card:([^)]+)\)$').firstMatch(raw);
          if (m2 == null) {
            spans.add(TextSpan(text: raw, style: base));
          } else {
            final cardId = m2.group(1)!;
            refCounter++;
            final rec = TapGestureRecognizer()
              ..onTapUp = (details) =>
                  _onCardRefTap(cardId, details.globalPosition);
            _wikilinkRecognizers.add(rec);
            spans.add(TextSpan(
              text: '[$refCounter]',
              style: base.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
              recognizer: rec,
            ));
          }
        } else {
          final prefix = m.group(1) ?? '';
          final tag = m.group(2) ?? '';
          if (prefix.isNotEmpty) {
            spans.add(TextSpan(text: prefix, style: base));
          }
          spans.add(TextSpan(
            text: '#$tag',
            style: base.copyWith(
              color: Colors.blue.shade700,
              backgroundColor: Colors.blue.shade50,
            ),
          ));
        }
        last = m.end;
      }
      if (last < content.length) {
        spans.add(TextSpan(text: content.substring(last), style: base));
      }
      return spans;
    }

  Future<void> _onWikilinkTap(String title, Offset anchor) async {
    final linkSvc = NoteBookLinkService();
    final noteLinks = await linkSvc.getOutboundLinksByText(_entry.id, title);
    final bookLinks =
        await linkSvc.getOutboundBookLinksByText(_entry.id, title);
    final cards = await _cardService.getCardsByIndexTitle(title);

    final total = noteLinks.length + bookLinks.length + cards.length;

    if (total == 0) {
      await _onWikilinkTapFallback(title, anchor);
      return;
    }

    if (total == 1) {
      if (noteLinks.isNotEmpty) {
        _showNotePreview(noteLinks.first['target_note_id'] as String, anchor);
      } else if (bookLinks.isNotEmpty) {
        _showBookPreview(bookLinks.first['book_id'] as String, anchor);
      } else {
        _showCardPreview(cards.first, anchor);
      }
      return;
    }

    final chosen = await _showWikilinkSelector(noteLinks, bookLinks, cards);
    if (chosen == null || !mounted) return;
    final type = chosen['type'] as String;
    final id = chosen['id'] as String;
    switch (type) {
      case 'note':
        _showNotePreview(id, anchor);
        break;
      case 'book':
        _showBookPreview(id, anchor);
        break;
      case 'card':
        final card = cards.firstWhere(
          (c) => c.id == id,
          orElse: () => cards.first,
        );
        _showCardPreview(card, anchor);
        break;
    }
  }



    /// B5：弹笔记预览 —— 单命中 / 多命中统一走
  Future<void> _showNotePreview(String noteId, Offset anchor) async {
      final notes = await _db.getAllNotes(includeDeleted: false);
      Map<String, dynamic>? target;
      for (final m in notes) {
        if (m['id'] == noteId) {
          target = m;
          break;
        }
      }
      if (target == null) {
        // 目标不存在 → 退回直跳（由 _jumpToNoteById 内部处理空）
        _jumpToNoteById(noteId);
        return;
      }
      final rawTitle = (target['title'] as String? ?? '').trim();
      final displayTitle = rawTitle.isNotEmpty
          ? rawTitle
          : _virtualTitleOf(target['content'] as String? ?? '');
      final content = target['content'] as String? ?? '';
      final summary =
          content.length > 100 ? content.substring(0, 100) : content;
      final updatedAt = target['updatedAt'] as String?;
      if (!mounted) return;
      PreviewPopup.show(
        context,
        anchor,
        PreviewData(
          title: displayTitle.isEmpty ? '（无标题）' : displayTitle,
          summary: summary.isEmpty ? '（空笔记）' : summary,
          meta: updatedAt != null ? '更新于 $updatedAt' : null,
          onOpen: () {
            _jumpToNoteById(noteId);
          },
        ),
      );
    }
    Future<void> _onWikilinkTapFallback(String title, Offset anchor) async {
    final allNotes = await _db.getAllNotes(includeDeleted: false);
    final matches = allNotes.where((m) {
      final rowId = m['id'] as String;
      if (rowId == _entry.id) return false;
      final rawTitle = (m['title'] as String? ?? '').trim();
      final displayTitle = rawTitle.isNotEmpty
          ? rawTitle
          : _virtualTitleOf(m['content'] as String? ?? '');
      return displayTitle == title;
    }).toList();

    if (matches.isEmpty) return;
    if (matches.length == 1) {
      _showNotePreview(matches.first['id'] as String, anchor);
      return;
    }
    if (!mounted) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择目标笔记'),
        children: matches
            .map((m) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, m['id'] as String),
                  child: Text((m['title'] as String? ?? '').trim().isEmpty
                      ? _virtualTitleOf(m['content'] as String? ?? '')
                      : (m['title'] as String).trim()),
                ))
            .toList(),
      ),
    );
    if (chosen != null && mounted) {
      _showNotePreview(chosen, anchor);
    }
  }

  Future<void> _showBookPreview(String bookId, Offset anchor) async {
    final book = await _db.getBook(bookId);
    if (book == null || !mounted) return;
    final title = (book['title'] as String? ?? '').trim();
    final author = (book['author'] as String? ?? '').trim();
    final status = (book['status'] as String? ?? '').trim();
    final metaParts = <String>[];
    if (author.isNotEmpty) metaParts.add(author);
    if (status.isNotEmpty) metaParts.add(status);
    PreviewPopup.show(
      context,
      anchor,
      PreviewData(
        title: title.isEmpty ? '（无书名）' : title,
        summary: metaParts.isEmpty ? '（无简介）' : metaParts.join(' · '),
        meta: null,
        onOpen: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailPage(bookId: bookId),
            ),
          );
        },
      ),
    );
  }

  void _showCardPreview(CardModel card, Offset anchor) {
    final title = card.indexTitle ?? card.highlight ?? card.displayFront;
    final summary = card.highlight ?? card.displayFront;
    final source = card.sourceTitle ?? '来源未知';
    PreviewPopup.show(
      context,
      anchor,
      PreviewData(
        title: title.isEmpty ? '（无标题卡）' : title,
        summary: summary.isEmpty ? '（空卡）' : summary,
        meta: '来自 $source',
        onOpen: null,
      ),
    );
  }

    Future<Map<String, dynamic>?> _showWikilinkSelector(
    List<Map<String, dynamic>> noteLinks,
    List<Map<String, dynamic>> bookLinks,
    List<CardModel> cards,
  ) async {
    final noteIds =
        noteLinks.map((l) => l['target_note_id'] as String).toSet();
    final allNotes = await _db.getAllNotes(includeDeleted: false);
    final notesById = <String, Map<String, dynamic>>{};
    for (final m in allNotes) {
      final id = m['id'] as String?;
      if (id != null && noteIds.contains(id)) notesById[id] = m;
    }

    final allBooks = await _db.getAllBooks();
    final booksById = <String, Map<String, dynamic>>{
      for (final b in allBooks) (b['id'] as String): b,
    };

    final entries = <_WikilinkSelectorEntry>[];
    for (final l in noteLinks) {
      final id = l['target_note_id'] as String;
      final m = notesById[id];
      if (m == null) continue;
      final raw = (m['title'] as String? ?? '').trim();
      final t = raw.isNotEmpty
          ? raw
          : _virtualTitleOf(m['content'] as String? ?? '');
      entries.add(_WikilinkSelectorEntry(
        type: 'note',
        id: id,
        title: t.isEmpty ? '（无标题）' : t,
        sortKey: _parseDt(m['updatedAt']),
      ));
    }
    for (final l in bookLinks) {
      final id = l['book_id'] as String;
      final b = booksById[id];
      if (b == null) continue;
      final t = (b['title'] as String? ?? '').trim();
      entries.add(_WikilinkSelectorEntry(
        type: 'book',
        id: id,
        title: t.isEmpty ? '（无书名）' : t,
        sortKey: _parseDt(b['lastReadAt']),   // ✅ 修正：camelCase
      ));
    }
    for (final c in cards) {
      final t = c.indexTitle ?? c.highlight ?? c.displayFront;
      entries.add(_WikilinkSelectorEntry(
        type: 'card',
        id: c.id,
        title: t.isEmpty ? '（无标题卡）' : t,
        sortKey: c.createdAt,
      ));
    }

    int typeOrder(String t) => t == 'note' ? 0 : (t == 'book' ? 1 : 2);
    entries.sort((a, b) {
      final c = typeOrder(a.type).compareTo(typeOrder(b.type));
      if (c != 0) return c;
      return b.sortKey.compareTo(a.sortKey);
    });

    if (!mounted) return null;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择目标'),
        children: entries.map((e) {
          final icon =
              e.type == 'note' ? '📝' : (e.type == 'book' ? '📖' : '📇');
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, {'type': e.type, 'id': e.id}),
            child: Text('$icon ${e.title}'),
          );
        }).toList(),
      ),
    );
  }

  DateTime _parseDt(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    final s = v.toString();
    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed;
    final ms = int.tryParse(s);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
      /// B5：点卡片角标 [N] —— 弹卡预览（卡详情入口待核 —— onOpen 暂 null）
        Future<void> _onCardRefTap(String cardId, Offset anchor) async {
      final card = await _cardService.getCard(cardId);
      if (card == null) return;
      if (!mounted) return;
      _showCardPreview(card, anchor);
    }
  
  Future<void> _jumpToNoteById(String noteId) async {
    final node = await _db.getNodeByNoteId(noteId);
    final notes = await _db.getAllNotes(includeDeleted: false);
    final target = notes.firstWhere(
      (m) => m['id'] == noteId,
      orElse: () => <String, dynamic>{},
    );
    if (target.isEmpty) return;
    final entry = NotebookEntry.fromMap(target);
    if (!mounted) return;
    await NoteOpener.open(
      context: context,
      entry: entry,
      isFromCollection: false,
      nodeId: node?.id,
    );
  }

  static String _virtualTitleOf(String content) {
    final c = content.trim().replaceAll('\n', ' ');
    if (c.isEmpty) return '无标题';
    return c.length > 20 ? '${c.substring(0, 20)}…' : c;
  }
  /// 导图体 —— 嵌在正文段（面包屑 + 树）
  Widget _buildMapBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mapBreadcrumb.isNotEmpty)
          NoteMapBreadcrumb(
            items: _mapBreadcrumb,
            onTap: _onBreadcrumbTap,
          ),
        const Divider(height: 1),
        NoteMapView(
          entry: _entry,
          nodeId: _currentNodeId,
          refreshTick: _mapRefreshTick,
          onSubNoteTap: _onSubNoteTap,
          onNewSubNote: _onNewSubNoteInLevel,
        ),
      ],
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
            Builder(builder: (_) {
              final displayTags = _entry.tags
                  .where((t) => t != '重要' && t != '待解决')
                  .toList();
              if (displayTags.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 4,
                  children: displayTags.map((tag) => Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              );
            }),
            _RichtextReadView(
              key: ValueKey(_entry.content),
              delta: result.delta,
              onQuickIndex: _quickGenerateIndexCard,
              onFullCard: (text) =>
                  _showFullNoteCardDialog(selectedText: text),
            ),
            if (_entry.exploreTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              EditorExploreArea(entry: _entry, onTap: _showExploreSummary),
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
  Widget _buildRightColumn() {
    return SizedBox(
      width: _showRightPanelWide ? 280 : 140,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRightSection(
              title: '📚 关联的书',
              count: _linkedBooks.length,
              onAdd: _onLinkBook,
              expanded: _showRightPanelWide,
              buildExpanded: _buildLinkedBooksSection,
            ),
            _buildRightSection(
              title: '📇 关联卡片',
              count: _noteCards.length,
              onAdd: () {},
              expanded: _showRightPanelWide,
              buildExpanded: _buildNoteCardsSection,
            ),
            _buildRightSection(
              title: '📎 子笔记',
              count: _subNotesList.length,
              onAdd: _toggleFileTree,
              expanded: _showRightPanelWide,
              buildExpanded: _buildSubNotesListExpanded,
            ),
            _buildRightSection(
              title: '📝 关联笔记',
              count: _backlinks.length,
              onAdd: () {},
              expanded: _showRightPanelWide,
              buildExpanded: _buildBacklinksListExpanded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSection({
    required String title,
    required int count,
    required VoidCallback onAdd,
    required bool expanded,
    required Widget Function() buildExpanded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              InkWell(
                onTap: onAdd,
                child: const Icon(Icons.add, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 6),
          if (expanded)
            buildExpanded()
          else if (count == 0)
            Text(
              '暂无',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            )
          else
            Text(
              '$count 项',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildSubNotesListExpanded() {
    if (_subNotesList.isEmpty) {
      return Text(
        '暂无',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _subNotesList
          .map((node) => InkWell(
                onTap: () => _openNote(context, node.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    node.title,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ))
          .toList(),
    );
  }
   
  Widget _buildBacklinksListExpanded() {
    if (_backlinks.isEmpty) {
      return Text(
        '暂无',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _backlinks.map((row) {
        final noteId = row['note_id'] as String;
        final title = row['title'] as String? ?? '未命名';
        final direction = row['direction'] as String? ?? 'out';
        final isBack = direction == 'back';
        final icon = isBack ? '↘' : '↗';
        final color = isBack ? Colors.green.shade700 : Colors.blue.shade700;
        return InkWell(
          onTap: () => _jumpToNoteById(noteId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: 11, color: color)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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

  Widget _buildEditMode() {
    if (_entry.contentFormat == 'richtext') {
      return const Center(
        child: Text('请通过编辑按钮打开富文本编辑器'),
      );
    }

    if (_focusMode) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: WorkbenchBody(
          kernel: _kernel,
          entry: _entry,
          showBottomBar: true,
          onCancel: null,
          saveLabel: widget.isFromCollection ? '📥 收入智库' : '💾 保存',
          isFromCollection: widget.isFromCollection,
          onDropItem: _handleDropItem,
          materialItems: null,
          appBarHasCardAction: false,
        ),
      );
    }

    final materialItems = _showMaterialPanel ? _materialItems : null;

    final workbench = WorkbenchBody(
      kernel: _kernel,
      entry: _entry,

      errorMessage: _errorMessage,
      onExploreTap: _showExploreSummary,
      onCancel: () => Navigator.pop(context),
      saveLabel: widget.isFromCollection ? '📥 收入智库' : '💾 保存',
      isFromCollection: widget.isFromCollection,
      onDropItem: _handleDropItem,
      materialItems: materialItems,
      appBarHasCardAction: true,
    );

    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final showOutline = _showOutlinePanel && isWide;
    final showFileTree = _showFileTree && isWide;

    if (!showOutline && !showFileTree) return workbench;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFileTree) ...[
          SizedBox(width: 240, child: _buildFileTreePanel()),
          const VerticalDivider(width: 1),
        ],
        if (showOutline) ...[
          SizedBox(
            width: 200,
            child: OutlinePanel(
              content: _kernel.contentController.text,
              contentFormat: _entry.contentFormat,
              onHeadingTap: _onOutlineTap,
            ),
          ),
          const VerticalDivider(width: 1),
        ],
        Expanded(child: workbench),
      ],
    );
  }

  // ─── B+C 新辅助方法 ─────────────────────────────

  void _handleDropItem(DragTargetDetails<MaterialItem> details) {
    final item = details.data;
    if (item.type == MaterialItemType.card && item.card != null) {
      final card = item.card!;
      final quote = card.highlight ?? card.indexTitle ?? card.displayFront;
      // B5：拖卡落「长内容 + 角标」—— 角标存 content 内嵌锚 [0](card:id)
      //       N 由渲染时按出现顺序动态算 —— 此处写 0 占位
      final citation =
          '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}[0](card:${card.id})';
      EditorKernel.insertTextGlobal(citation);
    } else if (item.type == MaterialItemType.note && item.note != null) {
      final note = item.note!;
      final text = note.content.isNotEmpty ? note.content : note.title;
      EditorKernel.insertTextGlobal(text);
    }
  }

  void _toggleFocusMode() {
    focusModeNotifier.value = !focusModeNotifier.value;
  }

  Future<void> _openMultiPane() async {
    if (_kernel.isDirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('未保存改动'),
          content: const Text('当前笔记有未保存改动。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'skip'),
              child: const Text('不保存直接跳'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('保存后跳'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'cancel') return;
      if (choice == 'save') {
        final ok = await _kernel.save();
        if (!ok) return;
      }
    }
    if (!mounted) return;
    final allEntries = await OpenTabsManager.instance.loadEntries();
    if (!mounted) return;
    // 当前笔记放主栏（左）—— 其余按 tabs 顺序
    final ordered = <NotebookEntry>[
      _entry,
      ...allEntries.where((e) => e.id != _entry.id),
    ];
    final limited = ordered.take(3).toList();
    if (ordered.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('超过三栏上限，只取前 3 篇')),
      );
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiPanePage(
          initialEntries: limited,
          initialLayout: limited.length.clamp(1, 3),
        ),
      ),
    );
    if (mounted) await _reloadEntry();
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
    NoteOpener.open(
      context: context,
      entry: note,
      nodeId: targetNode.id.isEmpty ? null : targetNode.id,
      replace: true,
    );
  }
}
class _WikilinkSelectorEntry {
  final String type;
  final String id;
  final String title;
  final DateTime sortKey;
  _WikilinkSelectorEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.sortKey,
  });
}
/// 富文本只读渲染 widget。
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