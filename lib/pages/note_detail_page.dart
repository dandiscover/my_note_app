// lib/pages/note_detail_page.dart
// 笔记详情页 — 阅读模式 + 修改模式 + 生成卡片
// ✅ 新增：采集页笔记保存时触发条件②
// ✅ 修改：采集页进入时初始为编辑模式
// ✅ 新增：“🧭 探究”入口按钮
// ✅ 重构：用 _entry 可变状态替代 widget.entry
// ✅ 适配：_saveNote 增加 inquiryQuestion 参数，保存时保留全部字段

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/card.dart';
import '../services/card_service.dart';
import '../widgets/fullscreen_editor.dart';
import '../widgets/file_tree_panel.dart';
import '../widgets/floating_pet.dart';
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

  @override
  void initState() {
    super.initState();
    _isReadMode = !widget.isFromCollection;
    _entry = widget.entry;
  }

  // ─── 保存笔记 ─────────────────────────────
  Future<bool> _saveNote(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
    String? inquiryQuestion,
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
        scaffoldSessions: _entry.scaffoldSessions,
        subtasks: _entry.subtasks,
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

      // ✅ 条件②：从采集页整理笔记时触发
      if (widget.isFromCollection) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_organized_at', DateTime.now().toIso8601String());
        floatingPetKey.currentState?.showMessage('水开始蒸发了。');
      }

      // ✅ 保存成功后更新 _entry
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

  // ─── 生成索引卡（阅读模式选中文字） ─────────────────────────────
  void _generateIndexCard(String selectedText) async {
    if (selectedText.trim().isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📚 生成索引卡'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('高光句：', style: TextStyle(fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedText.length > 100
                    ? '${selectedText.substring(0, 100)}...'
                    : selectedText,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: _entry.title),
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(),
              decoration: const InputDecoration(
                labelText: '作者（可选）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('生成索引卡'),
          ),
        ],
      ),
    );

    if (result == true) {
      final card = CardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardType: CardType.indexCard,
        sourceType: 'note',
        sourceId: _entry.id,
        sourceTitle: _entry.title,
        tags: _entry.tags,
        indexTitle: _entry.title,
        highlight: selectedText,
        stage: 0,
        nextReviewDate: DateTime.now().add(const Duration(minutes: 20)),
      );

      await _cardService.addCard(card);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 索引卡已生成')),
        );
      }
    }
  }

  // ─── 生成卡片（完整类型选择） ─────────────────────────────
  Future<void> _generateCard() async {
    CardType selectedType = CardType.review;
    String frontText = _entry.title;
    String backText = _entry.content.length > 200
        ? '${_entry.content.substring(0, 200)}...'
        : _entry.content;
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
                    // ─── 卡片类型选择 ──────────────────────────
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
                              Text(
                                type.icon,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                type.label,
                                style: const TextStyle(fontSize: 11),
                              ),
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

                    // ─── 不同类型的不同字段 ──────────────────────────
                    if (selectedType == CardType.review) ...[
                      TextField(
                        controller: TextEditingController(text: frontText),
                        decoration: const InputDecoration(labelText: '正面', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => frontText = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: backText),
                        decoration: const InputDecoration(labelText: '背面', border: OutlineInputBorder()),
                        maxLines: 4,
                        onChanged: (v) => backText = v,
                      ),
                    ],

                    if (selectedType == CardType.indexCard) ...[
                      TextField(
                        controller: TextEditingController(text: _entry.title),
                        decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder()),
                        onChanged: (v) => frontText = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(),
                        decoration: const InputDecoration(labelText: '作者', border: OutlineInputBorder()),
                        onChanged: (v) => backText = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(
                          text: _entry.content.length > 100
                              ? '${_entry.content.substring(0, 100)}...'
                              : _entry.content,
                        ),
                        decoration: const InputDecoration(labelText: '高光句', border: OutlineInputBorder()),
                        maxLines: 3,
                        onChanged: (v) => backText = v,
                      ),
                    ],

                    if (selectedType == CardType.qa) ...[
                      TextField(
                        controller: TextEditingController(text: frontText),
                        decoration: const InputDecoration(labelText: '问题', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => frontText = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: backText),
                        decoration: const InputDecoration(labelText: '答案', border: OutlineInputBorder()),
                        maxLines: 3,
                        onChanged: (v) => backText = v,
                      ),
                    ],

                    if (selectedType == CardType.fill) ...[
                      TextField(
                        decoration: const InputDecoration(labelText: '题目', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => frontText = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(labelText: '答案（用 {{答案}} 标记填空位置）', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => backText = v,
                      ),
                    ],

                    if (selectedType == CardType.choice) ...[
                      TextField(
                        decoration: const InputDecoration(labelText: '题目', border: OutlineInputBorder()),
                        onChanged: (v) => frontText = v,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(labelText: '选项A', border: OutlineInputBorder()),
                        onChanged: (v) => backText = v,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        decoration: const InputDecoration(labelText: '选项B', border: OutlineInputBorder()),
                        onChanged: (v) => backText = v,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        decoration: const InputDecoration(labelText: '选项C（可选）', border: OutlineInputBorder()),
                        onChanged: (v) => backText = v,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        decoration: const InputDecoration(labelText: '选项D（可选）', border: OutlineInputBorder()),
                        onChanged: (v) => backText = v,
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

                    if (selectedType == CardType.truefalse) ...[
                      TextField(
                        decoration: const InputDecoration(labelText: '陈述句', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => frontText = v,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('正确答案：'),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('正确'),
                            selected: backText == 'true',
                            onSelected: (_) => setDialogState(() { backText = 'true'; }),
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('错误'),
                            selected: backText == 'false',
                            onSelected: (_) => setDialogState(() { backText = 'false'; }),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ─── 重要性 ──────────────────────────
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
        front: selectedType == CardType.review ? frontText : null,
        back: selectedType == CardType.review ? backText : null,
        indexTitle: selectedType == CardType.indexCard ? frontText : null,
        author: selectedType == CardType.indexCard ? backText : null,
        highlight: selectedType == CardType.indexCard ? backText : null,
        question: selectedType == CardType.qa ? frontText : null,
        answer: selectedType == CardType.qa ? backText : null,
        fillQuestion: selectedType == CardType.fill ? frontText : null,
        fillAnswer: selectedType == CardType.fill ? backText : null,
        choiceQuestion: selectedType == CardType.choice ? frontText : null,
        choiceOptions: selectedType == CardType.choice ? ['A', 'B', 'C', 'D'] : null,
        choiceCorrectIndex: selectedType == CardType.choice ? 0 : null,
        tfStatement: selectedType == CardType.truefalse ? frontText : null,
        tfIsTrue: selectedType == CardType.truefalse ? backText == 'true' : null,
      );

      await _cardService.addCard(card);

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

  // ─── 探究入口 ─────────────────────────────
  Future<void> _openInquiry() async {
    final updatedEntry = await Navigator.push<NotebookEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => InquiryPage(entry: _entry),
      ),
    );
    if (updatedEntry != null && mounted) {
      setState(() {
        _entry = updatedEntry;
      });
    }
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
          // ✅ 新增：探究入口
          if (!widget.isFromCollection)
            IconButton(
              icon: const Icon(Icons.explore, color: Colors.purple),
              tooltip: '🧭 探究',
              onPressed: _openInquiry,
            ),
          IconButton(
            icon: Icon(_isReadMode ? Icons.edit : Icons.remove_red_eye),
            tooltip: _isReadMode ? '切换到修改模式' : '切换到阅读模式',
            onPressed: _toggleMode,
          ),
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: '生成卡片',
            onPressed: _generateCard,
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
                    ContextMenuButtonItem(
                      label: '📚 生成索引卡',
                      onPressed: () {
                        _generateIndexCard(selectedText);
                      },
                    ),
                    ...editableTextState.contextMenuButtonItems,
                  ],
                );
              },
            ),
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
          Expanded(
            child: FullscreenEditor(
              entry: _entry,
              isFromCollection: widget.isFromCollection,
              onSave: _saveNote,
              isSaving: _isSaving,
            ),
          ),
        ],
      ),
    );
  }
}