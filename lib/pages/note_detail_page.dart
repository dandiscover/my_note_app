// lib/pages/note_detail_page.dart
// 笔记详情页 — 阅读模式 + 修改模式 + 生成卡片
// ✅ 采集页笔记保存时触发条件②
// ✅ 采集页进入时初始为编辑模式
// ✅ 深入入口按钮（始终显示，不限于非采集笔记）
// ✅ 用 _entry 可变状态替代 widget.entry
// ✅ _saveNote 增加 inquiryQuestion 参数
// ✅ 保存时使用 newUnderstanding 和 exploreTasks
// ✅ _openInquiry 改为弹窗模式
// ✅ _handleInquiryConfirmed 先弹窗后保存，避免新建笔记未保存导致弹窗不出现
// ✅ _openInquiryDialog 增加 question 参数，弹窗关闭后统一保存
// ✅ 阅读模式增加探究缩略图区块，点击弹出只读概览弹窗
// ✅ 编辑模式也增加探究缩略图区块
// ✅ _saveNote 增加 exploreTasks 参数，保存时使用传入参数而非 _entry.exploreTasks
// ✅ 笔记加工台最小版：阅读模式加加工区 + 卡片区
// ✅ 独立 _saveCraftingFields（构造函数传 11 字段，支持清空）
// ✅ 加工台修复：弹窗溢出、输入不生效、保存按钮随 dirty 变
// ✅ 字段映射定稿：右键菜单改名"生成卡片"，_generateCard 加 selectedText 参数
// ✅ 各类型目标字段按选中文字预填：索引卡高光句 / 复习卡背面 / 问答卡答案 /
//    填空卡答案 / 判断题陈述句 / 选择题第一个选项
// ✅ 修索引卡分支 author/highlight 共用 backText 的 bug
// ✅ 修选择题分支 4 选项共用 backText + 硬编码选项的 bug

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/card.dart';
import '../models/explore_task.dart';
import '../services/card_service.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/file_tree_panel.dart';
import '../widgets/floating_pet.dart';
import '../widgets/explore_task_summary_dialog.dart';
import 'book_detail_page.dart';
import 'inquiry_page.dart';

class NoteDetailPage extends StatefulWidget {
  final NotebookEntry entry;
  final bool isFromCollection;
  final String? nodeId;
  final String? currentNodeId;

  const NoteDetailPage({
    super.key,
    required this.entry,
    this.isFromCollection = false,
    this.nodeId,
    this.currentNodeId,
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

  // ✅ 笔记加工台最小版：状态字段
  final TextEditingController _newUnderstandingCtrl = TextEditingController();
  List<CardModel> _noteCards = [];
  bool _isSavingCrafting = false;
  bool _craftingDirty = false;

  @override
  void initState() {
    super.initState();
    _isReadMode = !widget.isFromCollection;
    _entry = widget.entry;
    _newUnderstandingCtrl.text = _entry.newUnderstanding ?? '';
    _newUnderstandingCtrl.addListener(_onNewUnderstandingChanged);
    _loadNoteCards();
  }

  @override
  void dispose() {
    _newUnderstandingCtrl.removeListener(_onNewUnderstandingChanged);
    _newUnderstandingCtrl.dispose();
    super.dispose();
  }

  void _onNewUnderstandingChanged() {
    final current = _newUnderstandingCtrl.text.trim();
    final saved = _entry.newUnderstanding ?? '';
    final isDirty = current != saved;
    if (_craftingDirty != isDirty) {
      setState(() => _craftingDirty = isDirty);
    }
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

  // ─── 加工台：保存加工区字段（独立方法，不复用 _saveNote） ─────
  // 用 NotebookEntry 构造函数直接构造，传全 11 字段。
  // 理由：copyWith 对 null 的处理是 `x ?? this.x`，传 null 不会清空。
  Future<void> _saveCraftingFields() async {
    if (_isSavingCrafting) return;
    setState(() => _isSavingCrafting = true);
    try {
      final newUnder = _newUnderstandingCtrl.text.trim();
      final updated = NotebookEntry(
        id: _entry.id,
        title: _entry.title,
        content: _entry.content,
        updatedAt: DateTime.now(),
        status: _entry.status,
        editorMode: _entry.editorMode,
        tags: _entry.tags,
        isLocked: _entry.isLocked,
        inquiryQuestion: _entry.inquiryQuestion,
        newUnderstanding: newUnder.isEmpty ? null : newUnder,
        exploreTasks: _entry.exploreTasks,
      );
      await _db.updateNote(updated.toMap());
      if (mounted) {
        setState(() {
          _entry = updated;
          _isSavingCrafting = false;
          final current = _newUnderstandingCtrl.text.trim();
          final saved = updated.newUnderstanding ?? '';
          _craftingDirty = current != saved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 已保存'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingCrafting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
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
        inquiryQuestion: inquiryQuestion ?? _entry.inquiryQuestion,
        newUnderstanding: _entry.newUnderstanding,
        exploreTasks: exploreTasks,
      );

      await _db.updateNote(updated.toMap());

      if (!widget.isFromCollection && widget.nodeId != null) {
        final node = await _db.getNode(widget.nodeId!);
        if (node != null) {
          final updatedNode = node.copyWith(tags: tags);
          await _db.updateNode(updatedNode);
        }
      }

      if (widget.isFromCollection && newStatus == 'active') {
        final existingNodes = await _db.getAllNodes();
        final alreadyHasNode = existingNodes.any(
          (n) => n.targetId == _entry.id && n.nodeType == 'note',
        );
        if (!alreadyHasNode) {
          await _db.attachNoteToNode(
            noteId: _entry.id,
            title: updated.title,
            parentId: null,
            tags: tags,
          );
        }
      }

      if (widget.isFromCollection) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_organized_at', DateTime.now().toIso8601String());
        floatingPetKey.currentState?.showMessage('水开始蒸发了。');
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

  // ─── 生成卡片（统一入口） ─────────────────────────────
  // ✅ 字段映射定稿：
  //   - selectedText 非空（右键进来）→ 默认索引卡，各类型目标字段预填选中文字
  //   - selectedText 为空（AppBar 进来）→ 默认复习卡，各字段用原默认值
  //   - 索引卡三字段（标题/作者/高光句）拆独立变量
  //   - 选择题五字段（题目/A/B/C/D）拆独立变量
  Future<void> _generateCard({String? selectedText}) async {
    final hasSelection = selectedText != null && selectedText.isNotEmpty;

    // ─── 各类型字段独立变量（避免互相污染） ───

    // 复习卡
    String reviewFront = _entry.title;
    String reviewBack = hasSelection
        ? selectedText
        : (_entry.content.length > 200
            ? '${_entry.content.substring(0, 200)}...'
            : _entry.content);

    // 索引卡
    String indexTitle = _entry.title;
    String indexAuthor = '';
    String indexHighlight = hasSelection ? selectedText : '';

    // 问答卡
    String qaQuestion = _entry.title;
    String qaAnswer = hasSelection
        ? selectedText
        : (_entry.content.length > 200
            ? '${_entry.content.substring(0, 200)}...'
            : _entry.content);

    // 填空卡
    String fillQuestion = '';
    String fillAnswer = hasSelection ? selectedText : '';

    // 选择题
    String choiceQuestion = '';
    String choiceA = hasSelection ? selectedText : '';
    String choiceB = '';
    String choiceC = '';
    String choiceD = '';

    // 判断题
    String tfStatement = hasSelection ? selectedText : _entry.title;
    bool tfIsTrue = true;

    // 默认类型：有选中 → 索引卡；无选中 → 复习卡
    CardType selectedType = hasSelection ? CardType.indexCard : CardType.review;
    Importance selectedImportance = Importance.medium;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('生成卡片'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('卡片类型', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: CardType.values.map((type) {
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(type.icon, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 2),
                              Text(type.label, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          selected: selectedType == type,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedType = type;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // ─── 复习卡 ───
                    if (selectedType == CardType.review) ...[
                      TextField(
                        controller: TextEditingController(text: reviewFront),
                        decoration: const InputDecoration(labelText: '正面', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => reviewFront = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: reviewBack),
                        decoration: const InputDecoration(labelText: '背面', border: OutlineInputBorder()),
                        maxLines: 4,
                        onChanged: (v) => reviewBack = v,
                      ),
                    ],

                    // ─── 索引卡（三字段独立） ───
                    if (selectedType == CardType.indexCard) ...[
                      TextField(
                        controller: TextEditingController(text: indexTitle),
                        decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()),
                        onChanged: (v) => indexTitle = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: indexAuthor),
                        decoration: const InputDecoration(labelText: '作者（可选）', border: OutlineInputBorder()),
                        onChanged: (v) => indexAuthor = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: indexHighlight),
                        decoration: const InputDecoration(
                          labelText: '高光句',
                          hintText: '请输入高光句',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (v) => indexHighlight = v,
                      ),
                    ],

                    // ─── 问答卡 ───
                    if (selectedType == CardType.qa) ...[
                      TextField(
                        controller: TextEditingController(text: qaQuestion),
                        decoration: const InputDecoration(labelText: '问题', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => qaQuestion = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: qaAnswer),
                        decoration: const InputDecoration(labelText: '答案', border: OutlineInputBorder()),
                        maxLines: 3,
                        onChanged: (v) => qaAnswer = v,
                      ),
                    ],

                    // ─── 填空卡 ───
                    if (selectedType == CardType.fill) ...[
                      TextField(
                        controller: TextEditingController(text: fillQuestion),
                        decoration: const InputDecoration(labelText: '题目', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => fillQuestion = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: fillAnswer),
                        decoration: const InputDecoration(
                          labelText: '答案（用 {{答案}} 标记填空位置）',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (v) => fillAnswer = v,
                      ),
                    ],

                    // ─── 选择题（五字段独立） ───
                    if (selectedType == CardType.choice) ...[
                      TextField(
                        controller: TextEditingController(text: choiceQuestion),
                        decoration: const InputDecoration(labelText: '题目', border: OutlineInputBorder()),
                        onChanged: (v) => choiceQuestion = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: choiceA),
                        decoration: const InputDecoration(labelText: '选项A', border: OutlineInputBorder()),
                        onChanged: (v) => choiceA = v,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: TextEditingController(text: choiceB),
                        decoration: const InputDecoration(labelText: '选项B', border: OutlineInputBorder()),
                        onChanged: (v) => choiceB = v,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: TextEditingController(text: choiceC),
                        decoration: const InputDecoration(labelText: '选项C（可选）', border: OutlineInputBorder()),
                        onChanged: (v) => choiceC = v,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: TextEditingController(text: choiceD),
                        decoration: const InputDecoration(labelText: '选项D（可选）', border: OutlineInputBorder()),
                        onChanged: (v) => choiceD = v,
                      ),
                      const SizedBox(height: 8),
                      const Text('正确答案'),
                      Row(
                        children: [
                          _buildOptionChip('A', 0),
                          _buildOptionChip('B', 1),
                          _buildOptionChip('C', 2),
                          _buildOptionChip('D', 3),
                        ],
                      ),
                    ],

                    // ─── 判断题 ───
                    if (selectedType == CardType.truefalse) ...[
                      TextField(
                        controller: TextEditingController(text: tfStatement),
                        decoration: const InputDecoration(labelText: '陈述句', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => tfStatement = v,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('正确答案：'),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('正确'),
                            selected: tfIsTrue,
                            onSelected: (_) => setDialogState(() { tfIsTrue = true; }),
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('错误'),
                            selected: !tfIsTrue,
                            onSelected: (_) => setDialogState(() { tfIsTrue = false; }),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    const Text('重要性', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: Importance.values.map((imp) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text(imp.toString().split('.').last),
                            selected: selectedImportance == imp,
                            onSelected: (selected) {
                              setDialogState(() {
                                selectedImportance = imp;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('生成卡片'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final card = CardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardType: selectedType,
        sourceType: 'note',
        sourceId: _entry.id,
        sourceTitle: _entry.title,
        tags: _entry.tags,
        importance: selectedImportance,
        stage: 0,
        nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
        front: selectedType == CardType.review ? reviewFront : null,
        back: selectedType == CardType.review ? reviewBack : null,
        indexTitle: selectedType == CardType.indexCard ? indexTitle : null,
        author: selectedType == CardType.indexCard ? indexAuthor : null,
        highlight: selectedType == CardType.indexCard ? indexHighlight : null,
        question: selectedType == CardType.qa ? qaQuestion : null,
        answer: selectedType == CardType.qa ? qaAnswer : null,
        fillQuestion: selectedType == CardType.fill ? fillQuestion : null,
        fillAnswer: selectedType == CardType.fill ? fillAnswer : null,
        choiceQuestion: selectedType == CardType.choice ? choiceQuestion : null,
        choiceOptions: selectedType == CardType.choice
            ? [choiceA, choiceB, choiceC, choiceD]
            : null,
        choiceCorrectIndex: selectedType == CardType.choice ? 0 : null,
        tfStatement: selectedType == CardType.truefalse ? tfStatement : null,
        tfIsTrue: selectedType == CardType.truefalse ? tfIsTrue : null,
      );

      await _cardService.addCard(card);
      await _loadNoteCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 卡片已生成，可以去复习了')),
        );
      }
    }
  }

  Widget _buildOptionChip(String label, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label),
        selected: false,
        onSelected: (_) {},
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ─── 切换模式 ─────────────────────────────
  void _toggleMode() {
    setState(() {
      _isReadMode = !_isReadMode;
    });
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

  // ─── 云朵回调：先打开探究弹窗，弹窗关闭后保存 ──────────
  Future<void> _handleInquiryConfirmed(String question) async {
    await _openInquiryDialog(question: question);
  }

  // ─── 右上角深入按钮（始终显示） ─────────────────────────────
  Future<void> _openInquiry() async {
    await _openInquiryDialog();
  }

  // ─── 弹出探究概览弹窗 ─────────────────────────────
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
      appBar: AppBar(
        title: Text(
          _isReadMode ? '📖 ${_entry.title}' : '✏️ ${_entry.title}',
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
            tooltip: _isReadMode ? '切换到修改模式' : '切换到阅读模式',
            onPressed: _toggleMode,
          ),
          // ✅ 字段映射定稿：AppBar 调用点改为闭包，因为 _generateCard 已加参数
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: '生成卡片',
            onPressed: () => _generateCard(),
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
    );
  }

  Widget _buildReadMode() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    // ✅ 字段映射定稿：右键菜单改名"生成卡片"，调 _generateCard
                    ContextMenuButtonItem(
                      label: '📇 生成卡片',
                      onPressed: () {
                        _generateCard(selectedText: selectedText);
                      },
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

  // ✅ 加工台：加工区（只读主问题 + 编辑入口 + 可编辑新理解 + 底部保存按钮）
  Widget _buildCraftingSection() {
    final hasQuestion = _entry.inquiryQuestion != null && _entry.inquiryQuestion!.isNotEmpty;

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
            TextField(
              controller: _newUnderstandingCtrl,
              maxLines: null,
              style: const TextStyle(fontSize: 14, height: 1.4),
              decoration: InputDecoration(
                hintText: '写下你的联想、类比、触动',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isSavingCrafting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _craftingDirty ? _saveCraftingFields : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _craftingDirty ? '保存' : '已保存',
                      style: TextStyle(
                        fontSize: 13,
                        color: _craftingDirty ? Colors.purple : Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 加工台：卡片区（本笔记所有卡片）
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
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
            child: FullscreenEditor(
              entry: _entry,
              isFromCollection: widget.isFromCollection,
              onSave: _saveNote,
              isSaving: _isSaving,
              onInquiryConfirmed: _handleInquiryConfirmed,
            ),
          ),
        ],
      ),
    );
  }
}