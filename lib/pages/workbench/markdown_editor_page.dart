import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/explore_task.dart';
import 'workbench.dart';
import 'editor_kernel.dart';
import 'kernel_markdown.dart';
import 'editor_title_bar.dart';
import 'editor_bottom_bar.dart';

/// Markdown 编辑器页壳——D批块5b（丁方案零件化）
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
      entry,
      title,
      content,
      editorMode,
      tags,
      inquiryQuestion,
      exploreTasks,
    );
    if (success && mounted && widget.shouldPopOnSave) {
      Navigator.pop(context, true);
    }
    if (mounted) setState(() {});
    return success;
  }

  @override
  void dispose() {
    _kernel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            EditorTitleBar(
              controller: _kernel.titleController,
              onChanged: () => setState(() {}),
            ),
            const Divider(height: 8),
            Expanded(
              child: Workbench(
                kernel: _kernel,
                entry: widget.entry,
              ),
            ),
            const Divider(height: 8),
            EditorBottomBar(
              wordCount: _kernel.wordCount,
              lineCount: _kernel.lineCount,
              tagCount: _kernel.tags.length,
              isMarkdown: _kernel.isMarkdown,
              onMarkdownChanged: (v) {
                _kernel.toggleMarkdown(v);
                setState(() {});
              },
              isSaving: _kernel.isSaving,
              onSave: () async {
                await _kernel.save();
                if (mounted) setState(() {});
              },
              onCancel: null,
              onGenerateCard: _kernel.createReviewCard,
              isGeneratingCard: _kernel.isGeneratingCard,
              saveLabel: widget.isFromCollection ? '📥 收入智库' : '💾 保存',
              isFromCollection: widget.isFromCollection,
            ),
          ],
        ),
      ),
    );
  }
}