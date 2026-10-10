// lib/pages/workbench/kernel_markdown.dart
// D批块2a：Markdown 内核
// 拆源：fullscreen_editor.dart（_FullscreenEditorState 全量搬）
// 静态成员不搬——由 EditorKernel（块 1）接管
// 替换清单见块 2a 方案 §三
import '../../utils/markdown_image_builder.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/note.dart';
import '../../models/card.dart';
import '../../models/explore_task.dart';
import '../../services/card_service.dart';
import '../../widgets/note_card_dialog.dart';
import '../../pages/inquiry_page.dart';
import 'editor_kernel.dart';
import '../../widgets/spark_cursor.dart';
import '../../widgets/spark_dialog.dart';
import '../../services/spark_service.dart';
import '../../utils/debouncer.dart';
import '../../utils/markdown_custom_syntax.dart';
/// Markdown 内核——D 批块 2a
///
/// 骨架（乙模式）：
/// - Kernel 不是 StatefulWidget（已 extends EditorKernel）
/// - 内嵌 _MarkdownBody 承载状态
/// - 通过 _state 回填实现 save() / insertText() 转发
class MarkdownKernel extends EditorKernel {
  final EditorContext _ctx;
  _MarkdownBodyState? _state;

  // B8：火花编辑框全局触发入口
  static VoidCallback? onSparkRequested;
  // C2：状态监听 —— WorkbenchBody 底栏读
  final ValueNotifier<bool> dirtyNotifier = ValueNotifier(false);
  final ValueNotifier<bool> savingNotifier = ValueNotifier(false);
  late final TextEditingController titleController =
      TextEditingController(text: _ctx.entry.title);
  late final TextEditingController contentController =
      TextEditingController(text: _ctx.entry.content);

  /// 大纲联动：把光标定位到指定 charOffset
  void scrollToOffset(int offset) {
    final ctrl = contentController;
    final len = ctrl.text.length;
    var o = offset;
    if (o < 0) o = 0;
    if (o > len) o = len;
    ctrl.selection = TextSelection.collapsed(offset: o);
  }
  late final TextEditingController tagController = TextEditingController();
  late final TextEditingController subtaskController = TextEditingController();

  MarkdownKernel(this._ctx);

  @override
  String get id => 'markdown';

  @override
  EditorContext get ctx => _ctx;

 @override
Widget build(BuildContext context) => _MarkdownBody(
  key: ObjectKey(this),
  kernel: this,
);
  @override
  Future<bool> save({bool isAuto = false}) async =>
      await _state?.save(isAuto: isAuto) ?? false;

  @override
  void insertText(String text) => _state?.insertText(text);

    @override
  void updateEntry(NotebookEntry entry) {
    _ctx.entry = entry;
    _state?.updateEntry(entry);
  }

  // ─── 零件化：暴露状态 ───
  bool get isMarkdown => _state?._isMarkdown ?? false;
  bool get isSaving => _state?._isSavingLocal ?? false;
  bool get isGeneratingCard => _state?._isGeneratingCard ?? false;
  List<String> get tags => _state?._tags ?? const [];
  int get wordCount => contentController.text.length;
  int get lineCount => contentController.text.split('\n').length;

  // ─── 零件化：页面调用的方法 ───
  void toggleMarkdown(bool v) => _state?.toggleMarkdown(v);
  void addTagExternal(String tag) => _state?.addTagExternal(tag);
  void removeTagExternal(String tag) => _state?.removeTagExternal(tag);
  void submitTagInput(String value) => _state?.submitTagInput(value);
  void createReviewCard() => _state?.createReviewCardExternal();
  bool get isDirty => _state?.isDirty ?? false;
  // ─── 零件化：dispose ───
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    tagController.dispose();
    subtaskController.dispose();
    dirtyNotifier.dispose();    // C2
    savingNotifier.dispose();   // C2
  }
}

class _MarkdownBody extends StatefulWidget {
  final MarkdownKernel kernel;

  const _MarkdownBody({super.key, required this.kernel});

  @override
  State<_MarkdownBody> createState() => _MarkdownBodyState();
}

class _MarkdownBodyState extends State<_MarkdownBody> {
  // 零件化：controller 归 kernel——本类 getter 转发
  TextEditingController get _titleController => widget.kernel.titleController;
  TextEditingController get _contentController =>
      widget.kernel.contentController;
  TextEditingController get _tagController => widget.kernel.tagController;
  TextEditingController get _subtaskController =>
      widget.kernel.subtaskController;
  bool _isMarkdown = false;
  List<String> _tags = [];
  final CardService _cardService = CardService();
  final FocusNode _contentFocus = FocusNode();
  // B8：火花锚点（global 坐标 —— Overlay 挂）
  Offset? _sparkAnchorOffset;
  bool _showSparkCursor = false;
  OverlayEntry? _sparkOverlayEntry;
  Timer? _sparkRecalcThrottle;
  List<Spark> _pendingSparks = [];
  final Map<String, Offset> _sparkOffsets = {};
  // B8：记录上次 selection —— TextField 无 onSelectionChanged —— 靠 listener 差分
  TextSelection? _lastSelection;
  bool _isGeneratingCard = false;
  bool _isSavingLocal = false;
  bool _isDirty = false;
  bool get isDirty => _isDirty;
  // ─── 深度笔记入口状态 ─────────────────────────────
  String? _inquiryQuestion;
  bool _showInquiryPrompt = false;
  bool _hasShownPrompt = false;
  bool _isInquiryEditing = false;
  Timer? _typingTimer;
    final Debouncer _autoSaveDebouncer = Debouncer(const Duration(seconds: 3));
  late TextEditingController _inquiryController;
  late FocusNode _inquiryFocusNode;

  // ✅ 完整笔记状态
  late NotebookEntry _entry;
@override
void initState() {
  super.initState();
  final prev = widget.kernel._state;
  if (prev != null && prev != this) {
    debugPrint('🚨 [MarkdownBody] 双 state 共存 —— '
        'kernel=${widget.kernel.hashCode} prev=${prev.hashCode} new=${hashCode}');
  }
  _entry = widget.kernel.ctx.entry;
    _isMarkdown = _entry.editorMode == 'markdown';
    _tags = List.from(_entry.tags);

    // ✅ 深度笔记入口初始化
    _inquiryController = TextEditingController();
    _inquiryFocusNode = FocusNode();
    _inquiryQuestion = _entry.inquiryQuestion;
    if (_inquiryQuestion != null) {
      _inquiryController.text = _inquiryQuestion!;
      _hasShownPrompt = true;
    }

    // ✅ 注册当前实例到 kernel
    widget.kernel._state = this;
    MarkdownKernel.onSparkRequested = _onSparkTap;
    _contentFocus.addListener(_onFocusChanged);
    // B8：监听 controller 变 —— selection 变也触发（TextField 无 onSelectionChanged）
    _contentController.addListener(_onControllerChanged);
    _lastSelection = _contentController.selection;
    _loadPendingSparks();
  }

  @override
  void dispose() {
    _autoSaveDebouncer.cancel();                     // C3
    _contentController.removeListener(_onControllerChanged);
    _contentFocus.removeListener(_onFocusChanged);
    _sparkRecalcThrottle?.cancel();
    _sparkOverlayEntry?.remove();
    _sparkOverlayEntry = null;
    _contentFocus.dispose();
    _typingTimer?.cancel();
    _inquiryController.dispose();
    _inquiryFocusNode.dispose();
    if (widget.kernel._state == this) {
      widget.kernel._state = null;
      MarkdownKernel.onSparkRequested = null;
    }
    super.dispose();
  }

  // ─── 深度笔记入口交互 ─────────────────────────────

  void _onContentChanged(String value) {
    // R-性能 3：只在「提示需消失」时 setState —— 其他不走 —— 不重建整页
    if (_showInquiryPrompt) {
      setState(() => _showInquiryPrompt = false);
    }
    _isDirty = true;
    widget.kernel.dirtyNotifier.value = true;
    _resetTypingTimer();
    _autoSaveDebouncer.run(() {
      if (mounted && _isDirty && !_isSavingLocal) {
        save(isAuto: true);
      }
    });
  }

  // B8：从 FocusNode 找 EditableTextState
  EditableTextState? _getContentEditableState() {
    final ctx = _contentFocus.context;
    if (ctx == null) {
      debugPrint('[spark] getState: focus.context null');
      return null;
    }
    final state = ctx.findAncestorStateOfType<EditableTextState>();
    debugPrint('[spark] getState: state=${state != null}');
    return state;
  }

  // B8：controller 变 —— text 或 selection —— 差分 selection —— 触发 💫 重算
  void _onControllerChanged() {
    final sel = _contentController.selection;
    if (sel == _lastSelection) return;
    _lastSelection = sel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onSelectionChanged(sel);
    });
  }

  // B8：光标 / 选区变化
  void _onSelectionChanged(TextSelection selection) {
    if (!selection.isValid || !selection.isCollapsed) {
      if (_showSparkCursor) {
        setState(() => _showSparkCursor = false);
        _sparkOverlayEntry?.markNeedsBuild();
      }
      return;
    }
    final state = _getContentEditableState();
    if (state == null) return;
    final render = state.renderEditable;
    final rect = render.getLocalRectForCaret(selection.base);
    final globalPos = render.localToGlobal(rect.topLeft);
    setState(() {
      _sparkAnchorOffset = globalPos;
      _showSparkCursor = true;
    });
    _insertSparkOverlay();
    _sparkOverlayEntry?.markNeedsBuild();
  }

  void _onFocusChanged() {
    if (!_contentFocus.hasFocus && _showSparkCursor) {
      setState(() => _showSparkCursor = false);
      _sparkOverlayEntry?.markNeedsBuild();
    }
  }

  // B8：滚动跟随 —— throttle 16ms（不 cancel —— 活跃跳过）
  void _onScrollNotification(ScrollNotification n) {
    if (n is! ScrollUpdateNotification && n is! ScrollEndNotification) return;
    if (_sparkRecalcThrottle?.isActive ?? false) return;
    _sparkRecalcThrottle = Timer(
      const Duration(milliseconds: 16),
      _recalcSparkPositions,
    );
  }

  // B8：重算所有 💫 位置（global）
  void _recalcSparkPositions() {
    if (!mounted) return;
    final state = _getContentEditableState();
    if (state == null) {
      debugPrint('[spark] recalc: state null —— abort');
      return;
    }
    final render = state.renderEditable;
    debugPrint('[spark] recalc: pending=${_pendingSparks.length}');

    Offset? newCursorOffset;
    if (_showSparkCursor) {
      final sel = state.textEditingValue.selection;
      if (sel.isValid && sel.isCollapsed) {
        final rect = render.getLocalRectForCaret(sel.base);
        newCursorOffset = render.localToGlobal(rect.topLeft);
      }
    }
    final newSparkOffsets = <String, Offset>{};
    for (final s in _pendingSparks) {
      final off = int.tryParse(s.anchorLocation ?? '') ?? 0;
      try {
        final rect = render.getLocalRectForCaret(TextPosition(offset: off));
        newSparkOffsets[s.id] = render.localToGlobal(rect.topLeft);
      } catch (e) {
        debugPrint('spark 坐标计算失败 offset=$off: $e');
      }
    }
    setState(() {
      if (newCursorOffset != null) _sparkAnchorOffset = newCursorOffset;
      _sparkOffsets
        ..clear()
        ..addAll(newSparkOffsets);
    });
    _sparkOverlayEntry?.markNeedsBuild();
  }

  Future<void> _loadPendingSparks() async {
    final sparks = await SparkService().getPendingByNote(_entry.id);
    if (!mounted) return;
    setState(() => _pendingSparks = sparks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recalcSparkPositions();
    });
  }

  // B8：Overlay 插 / 清
  void _insertSparkOverlay() {
    if (_sparkOverlayEntry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _sparkOverlayEntry = OverlayEntry(
      builder: (ctx) {
        // B8 修：拿编辑器可视矩形 —— X / Y 都对着它
        final editorBox =
            _contentFocus.context?.findRenderObject() as RenderBox?;
        final editorRect = (editorBox != null && editorBox.hasSize)
            ? (editorBox.localToGlobal(Offset.zero) & editorBox.size)
            : null;
        final rightX = editorRect?.right ?? MediaQuery.of(ctx).size.width;

        return Stack(
          children: [
            if (_showSparkCursor && _sparkAnchorOffset != null)
              Positioned(
                left: _sparkAnchorOffset!.dx + 8,
                top: _sparkAnchorOffset!.dy,
                child: SparkCursor(onTap: () { _onSparkTap(); }),
              ),
            ..._pendingSparks.map((s) {
              final sPos = _sparkOffsets[s.id];
              if (sPos == null) return const SizedBox.shrink();
              // B8 修：Y 越编辑器可视区 —— 不显
              if (editorRect != null &&
                  (sPos.dy < editorRect.top ||
                      sPos.dy > editorRect.bottom - 20)) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: rightX - 32,
                top: sPos.dy,
                child: GestureDetector(
                  onTap: () { _onSparkItemTap(s); },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text('💫', style: TextStyle(fontSize: 16)),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
    overlay.insert(_sparkOverlayEntry!);
  }

  // B8：存火花为索引卡
  /// [content] 火花正文
  /// [offset] 锚点字符位置（String 形式 —— 与 CardModel.anchor String? 一致）
  /// ⚠️ 顺序不可调换 —— 两处调用点均 (content, offset)
  Future<void> _saveSparkAsCard(String content, String offset) async {
    final noteId = _entry.id;
    final rawTitle = _entry.title.trim();
    final card = CardModel(
      id: 'spark_${DateTime.now().millisecondsSinceEpoch}',
      cardType: CardType.indexCard,
      sourceType: 'note',
      sourceId: noteId,
      sourceTitle: rawTitle.isEmpty ? '无标题笔记' : rawTitle,
      indexTitle:
          content.length > 50 ? '${content.substring(0, 50)}...' : content,
      highlight: content,
      anchor: offset,
    );
    await CardService().addCard(card);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💫 已存卡片库'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // B8：点 💫 —— 弹编辑框
 Future<void> _onSparkTap() async {
  if (!mounted) return;
  final result = await showDialog<SparkDialogResult>(
    context: context,
    builder: (_) => const SparkDialog(),
  );
  if (!mounted) return;
  if (result == null || result.content.isEmpty) return;
    
    final noteId = _entry.id;
    final offset = _contentController.selection.baseOffset.toString();
    switch (result.action) {
      case 'save_card':
        await _saveSparkAsCard(result.content, offset);
        break;
      case 'stash':
        final spark = Spark(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: result.content,
          anchorNoteId: noteId,
          anchorLocation: offset,
          status: 'pending',
          createdAt: DateTime.now(),
        );
        await SparkService().create(spark);
        await _loadPendingSparks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💫 火花已保存'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        break;
      case 'send':
        insertText('\n${result.content}\n');
        break;
    }
  }

  // B8：点右侧 💫 —— 处理已有
  Future<void> _onSparkItemTap(Spark spark) async {
    final result = await showDialog<SparkDialogResult>(
      context: context,
      builder: (_) => SparkDialog(initialContent: spark.content),
    );
    if (result == null || result.content.isEmpty) return;
    switch (result.action) {
      case 'save_card':
        await _saveSparkAsCard(result.content, spark.anchorLocation ?? '0');
        final updated = spark.copyWith(
          status: 'done',
          updatedAt: DateTime.now(),
        );
        await SparkService().update(updated);
        await _loadPendingSparks();
        break;
      case 'stash':
        final updated = spark.copyWith(
          content: result.content,
          updatedAt: DateTime.now(),
        );
        await SparkService().update(updated);
        await _loadPendingSparks();
        break;
      case 'send':
        insertText('\n${result.content}\n');
        await SparkService().delete(spark.id);
        await _loadPendingSparks();
        break;
    }
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _checkAndShowPrompt();
    });
  }

  void _checkAndShowPrompt() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    if (_inquiryQuestion != null) return;
    if (_hasShownPrompt) return;
    if (mounted) {
      setState(() {
        _showInquiryPrompt = true;
      });
    }
  }

  void _onPromptTap() {
    setState(() {
      _showInquiryPrompt = false;
      _hasShownPrompt = true;
      _isInquiryEditing = true;
      _inquiryController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_inquiryFocusNode);
    });
  }

  // ✅ 确认问题：更新状态并直接打开探究弹窗
  void _confirmInquiry() {
    final text = _inquiryController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _inquiryQuestion = text;
      _entry = _entry.copyWith(inquiryQuestion: text);
      _isInquiryEditing = false;
    });
    _openInquiryDialog();
  }

  // ✅ 在编辑器内打开探究弹窗
  Future<void> _openInquiryDialog() async {
    final result = await showDialog<List<ExploreTask>>(
      context: context,
      barrierDismissible: false,
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

    if (result != null) {
      setState(() {
        _entry = _entry.copyWith(
          exploreTasks: result,
          inquiryQuestion: _inquiryQuestion,
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  void _cancelInquiryEdit() {
    setState(() {
      _isInquiryEditing = false;
      if (_inquiryQuestion != null) {
        _inquiryController.text = _inquiryQuestion!;
      } else {
        _inquiryController.clear();
      }
    });
  }

  void _onInquiryTap() {
    setState(() {
      _isInquiryEditing = true;
      _inquiryController.text = _inquiryQuestion ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_inquiryFocusNode);
    });
  }

  // ✅ 删除探究问题：同时清除探究任务和探究结论，保证数据一致
  void _deleteInquiry() {
    setState(() {
      _inquiryQuestion = null;
      _entry = _entry.copyWith(
        inquiryQuestion: null,
        exploreTasks: [],
        inquiryConclusion: null,
      );
      _isInquiryEditing = false;
      _showInquiryPrompt = false;
    });
    _inquiryController.clear();
    _typingTimer?.cancel();
  }

  // ─── 原有方法 ─────────────────────────────

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) {
      _showLightToast('标签已存在');
      return;
    }
    setState(() {
      _tags.add(trimmed);
    });
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showLightToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
    );
  }

  Future<void> _createReviewCard() async {
    if (_isGeneratingCard) return;
    setState(() => _isGeneratingCard = true);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      _showLightToast('笔记内容为空，无法制卡');
      setState(() => _isGeneratingCard = false);
      return;
    }

    final previewContent =
        content.length > 200 ? '${content.substring(0, 200)}...' : content;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => NoteCardDialog(
        selectedText: previewContent,
        comment: title,
        sourceId: _entry.id,
        sourceType: 'note',
      ),
    );

    if (result != null) {
      final card = CardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardType: result['cardType'] as CardType,
        sourceType: 'note',
        sourceId: _entry.id,
        sourceTitle: title.isEmpty ? '无标题笔记' : title,
        tags: (result['tags'] as List<String>?) ?? [],
        front: result['front'] as String?,
        back: result['back'] as String?,
        indexTitle: result['indexTitle'] as String?,
        author: result['author'] as String?,
        highlight: result['highlight'] as String?,
        question: result['question'] as String?,
        answer: result['answer'] as String?,
        fillQuestion: result['fillQuestion'] as String?,
        fillAnswer: result['fillAnswer'] as String?,
        tfStatement: result['tfStatement'] as String?,
        tfIsTrue: result['tfIsTrue'] as bool?,
        importance: result['importance'] ?? Importance.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _cardService.addCard(card);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ 卡片已生成！可在「智库 → 卡片盒」查看'),
            duration: Duration(seconds: 2)),
      );
    }
    setState(() => _isGeneratingCard = false);
  }

  void _addSubtaskFromEditor() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) {
      _showLightToast('请输入子任务标题');
      return;
    }
    final subtaskLine = '- [ ] $title\n';
    if (widget.kernel.ctx.onAddSubtask != null) {
      widget.kernel.ctx.onAddSubtask!(title);
    }
    final currentText = _contentController.text;
    final cursorPosition = _contentController.selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > currentText.length) {
      _contentController.text = currentText + subtaskLine;
    } else {
      final newText = currentText.substring(0, cursorPosition) +
          subtaskLine +
          currentText.substring(cursorPosition);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
          offset: cursorPosition + subtaskLine.length);
    }
    _subtaskController.clear();
    _showLightToast('✅ 子任务已添加');
  }

  // ✅ 往内容光标处插入文本（供 MaterialPanel 等外部调用）
  //   逻辑对齐 EditorArea.insertText：光标处插入，光标后移
  void _insertTextIntoContent(String text) {
    final cursorPosition = _contentController.selection.baseOffset;
    final currentText = _contentController.text;
    if (cursorPosition < 0 || cursorPosition > currentText.length) {
      _contentController.text = currentText + text;
    } else {
      final newText = currentText.substring(0, cursorPosition) +
          text +
          currentText.substring(cursorPosition);
      _contentController.text = newText;
      final newCursor = cursorPosition + text.length;
      _contentController.selection =
          TextSelection.collapsed(offset: newCursor);
    }
    setState(() {});
  }

  /// 对外接口——供 MarkdownKernel.insertText 转发
  void insertText(String text) => _insertTextIntoContent(text);

  // ─── 零件化：对外方法 ───
  void toggleMarkdown(bool v) {
    setState(() {
      _isMarkdown = v;
      // B8：切模式 —— 坐标全失效 —— 清缓存
      _sparkOffsets.clear();
      _showSparkCursor = false;
      _sparkAnchorOffset = null;
    });
    _sparkOverlayEntry?.markNeedsBuild();
    // B8：切模式后 layout 未稳 —— 延迟一帧重算
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recalcSparkPositions();
    });
  }
  void addTagExternal(String tag) {
    final t = tag.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() => _tags.add(t));
  }
  void removeTagExternal(String tag) => setState(() => _tags.remove(tag));
  void submitTagInput(String value) {
    if (value.contains(',')) {
      for (var tag in value.split(',')) {
        _addTag(tag);
      }
    } else {
      _addTag(value);
    }
  }
  void createReviewCardExternal() => _createReviewCard();

  /// 外部 entry 更新——由 kernel.updateEntry 转发
void updateEntry(NotebookEntry newEntry) {
  if (!mounted) return;
  setState(() {
    _entry = newEntry;
    _contentController.text = newEntry.content;
    _titleController.text = newEntry.title;
    _sparkOffsets.clear();
    _showSparkCursor = false;
    _sparkAnchorOffset = null;
  });
  _loadPendingSparks();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final e = _sparkOverlayEntry;
    if (e == null || !e.mounted) return;
    e.markNeedsBuild();
  });
}

  @override
  Widget build(BuildContext context) {
    final wordCount = _contentController.text.length;
    final lineCount = _contentController.text.split('\n').length;
    final isExploreMode = widget.kernel.ctx.exploreTaskId != null;
    final isSaving = _isSavingLocal;
    final isFromCollection = widget.kernel.ctx.isFromCollection;

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ─── 已保存的探究问题 ────────────────────
              if (_inquiryQuestion != null && !_isInquiryEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.purple.shade200, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: GestureDetector(
                          onTap: _onInquiryTap,
                          child: Text(
                            _inquiryQuestion!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.purple),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _deleteInquiry,
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              // ─── 标签 ──────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('标签',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: '输入标签，按回车或逗号添加',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            hintStyle: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (value) {
                            if (value.contains(',')) {
                              for (var tag in value.split(',')) {
                                _addTag(tag);
                              }
                            } else {
                              _addTag(value);
                            }
                          },
                          onChanged: (value) {
                            if (value.endsWith(',')) {
                              final tag =
                                  value.substring(0, value.length - 1);
                              _addTag(tag);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final chipMaxW = constraints.maxWidth - 6;
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _tags
                              .map((tag) => Container(
                                    constraints:
                                        BoxConstraints(maxWidth: chipMaxW),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getTagColor(tag)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: _getTagColor(tag)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            tag,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: _getTagColor(tag),
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _removeTag(tag),
                                          child: Icon(Icons.close,
                                              size: 12,
                                              color: _getTagColor(tag)),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 12),

              // ─── 正文 ──────────────────────────────
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    _onScrollNotification(n);
                    return false;
                  },
                  child: _isMarkdown
                      ? _buildMarkdownEditor()
                      : _buildPlainEditor(),
                ),
              ),

              // ─── 深度笔记提示 ────────────────────────
              if (_showInquiryPrompt && !_isInquiryEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onTap: _onPromptTap,
                    child: Row(
                      children: [
                        const Text('💭 ', style: TextStyle(fontSize: 14)),
                        Text(
                          '你停下来了。有个疑问吗？',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),

              // ─── 内联输入行 ──────────────────────────
              if (_isInquiryEditing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: TextField(
                          controller: _inquiryController,
                          focusNode: _inquiryFocusNode,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '你在想什么？',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _confirmInquiry(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: _cancelInquiryEdit,
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('取消',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: _confirmInquiry,
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('确认',
                            style: TextStyle(
                                fontSize: 12, color: Colors.purple)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              if (isExploreMode) ...[
                Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right,
                        size: 18, color: Colors.purple),
                    const SizedBox(width: 6),
                    const Text('子任务',
                        style: TextStyle(fontSize: 13, color: Colors.purple)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: const InputDecoration(
                          hintText: '输入子任务，按回车添加',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(fontSize: 13),
                        onSubmitted: (_) => _addSubtaskFromEditor(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.purple),
                      onPressed: _addSubtaskFromEditor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlainEditor() {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocus,
      maxLines: null,
      expands: true,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(
          hintText: '开始写内容...', border: InputBorder.none),
      onChanged: _onContentChanged,
    );
  }

  Widget _buildMarkdownEditor() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
              onChanged: _onContentChanged,
              decoration: const InputDecoration(
                hintText: '支持 Markdown 语法...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8)),
            child: _contentController.text.isEmpty
                ? const Center(
                    child:
                        Text('预览', style: TextStyle(color: Colors.grey)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: MarkdownBody(
                      data: _contentController.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 15),
                        h1: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                        h2: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        h3: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        codeblockDecoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4)),
                        listBullet: const TextStyle(fontSize: 15),
                        listIndent: 24,
                        listBulletPadding:
                            const EdgeInsets.only(right: 8),
                      ),
                      
                      extensionSet: buildMarkdownExtensionSet(),
                      sizedImageBuilder: (config) =>
                          buildMarkdownImage(config.uri),
                       builders: buildMarkdownBuilders(),

                    ),
                  ),
          ),
          
        ),
      ],
    );
  }

  /// 保存——原 _handleSave，去 pop，返回 bool 给外壳
  Future<bool> save({bool isAuto = false}) async {
    if (_isSavingLocal) return false;
    setState(() => _isSavingLocal = true);
    widget.kernel.savingNotifier.value = true;
    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      if (title.isEmpty && content.isEmpty) {
        _showLightToast('标题和内容不能都为空');
        return false;
      }

      final updatedEntry = _entry.copyWith(
        title: title,
        content: content,
        editorMode: _isMarkdown ? 'markdown' : 'plain',
        tags: _tags,
        inquiryQuestion: _inquiryQuestion,
        exploreTasks: _entry.exploreTasks,
        updatedAt: DateTime.now(),
      );

      final success = await widget.kernel.ctx.onSave(
        updatedEntry,
        updatedEntry.title,
        updatedEntry.content,
        updatedEntry.editorMode,
        updatedEntry.tags,
        updatedEntry.inquiryQuestion,
        updatedEntry.exploreTasks,
        isAuto: isAuto,
      );
      if (success && mounted) {
        setState(() => _isDirty = false);
        widget.kernel.dirtyNotifier.value = false;
      }
      return success;
    } finally {
      if (mounted) {
        setState(() => _isSavingLocal = false);
        widget.kernel.savingNotifier.value = false;
      }
    }
  }

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.deepPurple,
      Colors.red,
    ];
    return colors[hash % colors.length];
  }
}