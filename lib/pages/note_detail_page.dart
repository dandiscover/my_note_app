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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../utils/app_string_utils.dart';
import '../models/card.dart';
import '../models/explore_task.dart';
import '../services/card_service.dart';
import '../services/richtext_adapter/richtext_adapter.dart';
import '../services/richtext_adapter/shared/attributes.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/file_tree_panel.dart';
import '../widgets/floating_pet.dart';
import '../widgets/explore_task_summary_dialog.dart';
import '../widgets/writing/material_panel.dart';
import 'book_detail_page.dart';
import 'inquiry_page.dart';
import 'richtext_editor_page.dart';

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
  List<CardModel> _noteCards = [];

  // ✅ 子笔记嵌套：子笔记数缓存（A 方案，避免每次 build 打库）
  int _subNotesCount = 0;

  // ✅ 骨架：素材面板状态
  bool _showMaterialPanel = false;
  List<CardModel> _indexCards = [];

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
    _loadNoteCards();
    _loadSubNotesCount();
    _loadIndexCards();
  }

  @override
  void dispose() {
    super.dispose();
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
  ) 
  async {
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
        contentFormat: _entry.contentFormat,   // ← T-167：复制点显式带字段
      );

      await _db.updateNote(updated.toMap());

      if (!widget.isFromCollection && widget.nodeId != null) {
        final node = await _db.getNode(widget.nodeId!);
        if (node != null) {
          final updatedNode = node.copyWith(tags: tags);
          await _db.updateNode(updatedNode);
        }
      }

      // 原 isFromCollection 逻辑已迁 NoteService.organizeRawNote

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
  Future<void> _generateCard({String? selectedText}) async {
    final hasSelection = selectedText != null && selectedText.isNotEmpty;

    // ─── 各类型字段独立变量（避免互相污染） ───
    String reviewFront = _entry.title;
    String reviewBack = hasSelection
        ? selectedText
        : (_entry.content.length > 200
            ? '${_entry.content.substring(0, 200)}...'
            : _entry.content);

    String indexTitle = _entry.title;
    String indexAuthor = '';
    String indexHighlight = hasSelection ? selectedText : '';

    String qaQuestion = _entry.title;
    String qaAnswer = hasSelection
        ? selectedText
        : (_entry.content.length > 200
            ? '${_entry.content.substring(0, 200)}...'
            : _entry.content);

    String fillQuestion = '';
    String fillAnswer = hasSelection ? selectedText : '';

    String choiceQuestion = '';
    String choiceA = hasSelection ? selectedText : '';
    String choiceB = '';
    String choiceC = '';
    String choiceD = '';

    // ✅ v2 修复：选择题正确答案索引
    int choiceCorrectIndex = 0;

    String tfStatement = hasSelection ? selectedText : _entry.title;
    bool tfIsTrue = true;

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
                    // ✅ 修复：chip 列表过滤 CardType.guide（指导卡不提供手动创建入口）
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: CardType.values
                          .where((type) => type != CardType.guide)
                          .map((type) {
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
                          _buildOptionChip('A', 0, choiceCorrectIndex, (v) {
                            setDialogState(() => choiceCorrectIndex = v);
                          }),
                          _buildOptionChip('B', 1, choiceCorrectIndex, (v) {
                            setDialogState(() => choiceCorrectIndex = v);
                          }),
                          _buildOptionChip('C', 2, choiceCorrectIndex, (v) {
                            setDialogState(() => choiceCorrectIndex = v);
                          }),
                          _buildOptionChip('D', 3, choiceCorrectIndex, (v) {
                            setDialogState(() => choiceCorrectIndex = v);
                          }),
                        ],
                      ),
                    ],

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
        choiceCorrectIndex: selectedType == CardType.choice ? choiceCorrectIndex : null,
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

  Widget _buildOptionChip(
    String label,
    int index,
    int selectedIndex,
    ValueChanged<int> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label),
        selected: selectedIndex == index,
        onSelected: (_) => onSelected(index),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ─── 切换模式 ─────────────────────────────
  //
  // richtext：不内嵌编辑，push 到 RichtextEditorPage。
  // markdown：现有逻辑，切换 _isReadMode。
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

      // ✅ 同步 node.tags（与 _saveNote 一致）
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

      // ✅ 同步 node.tags（与 _saveNote 一致）
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
        // 先更新 _entry（rebuild）。
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
            onPressed: () => _generateCard(),
          ),
          // ✅ B 提交：素材库按钮（仅编辑模式显示，位置：生成卡片和文件树之间）
          if (!_isReadMode)
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
    );
  }

  Widget _buildReadMode() {
    // 富文本笔记：走只读 QuillEditor 分支
    if (_entry.contentFormat == 'richtext') {
      return _buildRichtextReadMode();
    }
    // markdown：现有逻辑不动
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
            // ✅ 子笔记嵌套：子笔记入口（有子笔记时显示）
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

  /// 富文本笔记的只读渲染。
  ///
  /// 老白裁定：
  ///   - 只读，不带工具栏、不带交互
  ///   - 损坏 JSON 兜底到纯文本
  ///   - 复用 RichtextAdapter.structureToDelta
  Widget _buildRichtextReadMode() {
    // 1. 解析结构
    Map<String, dynamic> structure;
    try {
      structure = jsonDecode(_entry.content) as Map<String, dynamic>;
    } catch (_) {
      return _buildReadFallback('内容不是合法 JSON');
    }

    // 2. 结构 → Delta（复用适配层，不重写转换）
    DeltaWithMemo result;
    try {
      result = RichtextAdapter.structureToDelta(structure);
    } catch (e) {
      return _buildReadFallback('结构转换失败：$e');
    }

    // 3. 只读渲染
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
              onGenerateCard: (text) => _generateCard(selectedText: text),
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

  /// 富文本读模式兜底：显示提示 + 原始 content。
  ///
  /// 触发场景：
  ///   - content 不是合法 JSON
  ///   - structureToDelta 抛异常（版本不符 / 结构非法）
  /// 不崩。用户至少能看到原文。
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

    // ✅ B 批：无主问题 + 无结论 → 不显示
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

  // ✅ 子笔记嵌套：子笔记入口
  //   A 方案：读 _subNotesCount（State 缓存），不用 FutureBuilder
  //   无子笔记时（count == 0）不渲染
  //   点击 → 打开文件树（复用 _toggleFileTree）
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

    return Row(
      children: [
        // ─── 左列：错误提示 + 探究缩略图 + 编辑器 ───
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
          ),
        ),
        // ─── 右侧：素材面板（默认收起） ───
        if (_showMaterialPanel) ...[
          const VerticalDivider(width: 1, thickness: 1),
          SizedBox(
            width: 280,
            child: MaterialPanel(
              cards: _indexCards,
              onInsertText: (text) => FullscreenEditor.insertText(text),
              onInsertCard: (_) {},
            ),
          ),
        ],
      ],
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
  final ValueChanged<String> onGenerateCard;

  const _RichtextReadView({
    super.key,
    required this.delta,
    required this.onGenerateCard,
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
    _controller.readOnly = true; // ✅ readOnly 在 controller 上
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
        // ✅ 路一 v6：自建菜单（云脑生成卡片 + 复制）
        contextMenuBuilder: _buildContextMenu,
      ),
    );
  }

  /// 读模式自定义右键菜单。
  ///
  /// 自建菜单两项：
  ///   1. 📇 生成卡片（云脑）
  ///   2. 复制
  ///
  /// 不依赖 flutter_quill 内部默认菜单函数。
  ///
  /// 签名匹配 typedef：
  ///   Widget Function(BuildContext, QuillRawEditorState)
   /// 读模式自定义右键菜单。
  ///
  /// 用 AdaptiveTextSelectionToolbar——它自带定位，贴在选区附近。
  /// 不自己拼 Column（会被全屏撑开）。
  Widget _buildContextMenu(
    BuildContext context,
    quill.QuillRawEditorState rawEditorState,
  ) {
    final controller = rawEditorState.controller;
    final selectedText = _getSelectedText(controller);

    // 无选中 → 空菜单
    if (selectedText.isEmpty) {
      return const SizedBox.shrink();
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: rawEditorState.contextMenuAnchors,
      buttonItems: [
        ContextMenuButtonItem(
          label: '📇 生成卡片',
          onPressed: () {
            ContextMenuController.removeAny();
            widget.onGenerateCard(selectedText);
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

  /// 从 QuillController 拿当前选中文本。
  /// 空选返回空字符串。
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
///
/// 与 `RichtextEditorPage` 里的 `_DividerEmbedBuilder` 逻辑一致——
/// 但因两者都是文件私有类，无法跨文件复用。
/// 若将来出现第三处使用，应提升为公共 widget。
class _DividerEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => DeltaAttributes.divider;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return const Divider(thickness: 1);
  }
}