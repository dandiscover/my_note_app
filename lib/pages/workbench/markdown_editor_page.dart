import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/explore_task.dart';
import 'workbench.dart';
import 'editor_kernel.dart';
import 'kernel_markdown.dart';

/// Markdown 编辑器页壳——D批块5b
///
/// 场景两个：
///  1. push（wisdom 新建笔记）：shouldPopOnSave = true，保存后关闭本页
///  2. tab（adaptive 第 5 tab）：shouldPopOnSave = false，保存后留原地
///
/// 结构 = Scaffold + Workbench + 可选 pop
class MarkdownEditorPage extends StatefulWidget {
  final NotebookEntry entry;
  final bool isFromCollection;
  final bool shouldPopOnSave;
  final Future<bool> Function(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
    String? inquiryQuestion,
    List<ExploreTask> exploreTasks,
  ) onSave;

  const MarkdownEditorPage({
    super.key,
    required this.entry,
    this.isFromCollection = false,
    this.shouldPopOnSave = true,
    required this.onSave,
  });

  @override
  State<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<MarkdownEditorPage> {
  late MarkdownKernel _kernel;

  @override
  void initState() {
    super.initState();
    _kernel = MarkdownKernel(EditorContext(
      entry: widget.entry,
      isFromCollection: widget.isFromCollection,
      onSave: _handleSave,
      onInquiryConfirmed: null,
    ));
  }

  Future<bool> _handleSave(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
    String? inquiryQuestion,
    List<ExploreTask> exploreTasks,
  ) async {
    final success = await widget.onSave(
      entry, title, content, editorMode, tags, inquiryQuestion, exploreTasks,
    );
    if (success && mounted && widget.shouldPopOnSave) {
      Navigator.pop(context, true);
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Workbench(
        kernel: _kernel,
        entry: widget.entry,
      ),
    );
  }
}