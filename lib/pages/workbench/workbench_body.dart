import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/material_item.dart';
import '../../models/note.dart';
import '../../utils/app_string_utils.dart';
import 'editor_bottom_bar.dart';
import 'editor_explore_area.dart';
import 'editor_material_slot.dart';
import 'editor_title_bar.dart';
import 'kernel_markdown.dart';
import 'workbench.dart';

/// 拼好的工作台——工作台组合件 · 丁方案
///
/// = 标题 + 探究 + 正文 + 底栏 [+ 右侧素材槽]
///
/// 三处共用：
///  - note_detail 单页
///  - MultiPanePage 每栏
///
/// 零件仍独立——本件只做「标准拼法」
class WorkbenchBody extends StatefulWidget {
  final MarkdownKernel kernel;
  final NotebookEntry entry;

  // ── 顶部自定义区（如 ⭐/❓ 标记行）──
  final Widget? header;

  // ── 错误提示 ──
  final String? errorMessage;

  // ── 探究区 ──
  final bool showExplore;
  final VoidCallback? onExploreTap;

  // ── 底栏 ──
  final bool showBottomBar;
  final VoidCallback? onCancel;
  final String saveLabel;
  final bool isFromCollection;

  // ── 右侧素材槽（null = 不显示）──
  final List<MaterialItem>? materialItems;

  // ── 拖拽接收 ──
  final Function(DragTargetDetails<MaterialItem>)? onDropItem;

  // ── 紧凑模式（缩内边距 + 缩底栏按钮）──
  final bool compact;

  // ── 外层 AppBar 是否已有制卡入口 ──
  final bool appBarHasCardAction;

  // ── 批：阅读态（多栏保存后切）──
  final bool isReadMode;
  final double? paneWidth;

  // ── 批：阅读态顶部「编辑」按钮回调（null = 不显，单栏用）──
  final VoidCallback? onEditRequest;

  const WorkbenchBody({
    super.key,
    required this.kernel,
    required this.entry,
    this.header,
    this.errorMessage,
    this.showExplore = true,
    this.onExploreTap,
    this.showBottomBar = true,
    this.onCancel,
    this.saveLabel = '💾 保存',
    this.isFromCollection = false,
    this.materialItems,
    this.onDropItem,
    this.compact = false,
    this.appBarHasCardAction = false,
    this.isReadMode = false,
    this.paneWidth,
    this.onEditRequest,
  });

  @override
  State<WorkbenchBody> createState() => _WorkbenchBodyState();
}

class _WorkbenchBodyState extends State<WorkbenchBody> {
  @override
  Widget build(BuildContext context) {
    final kernel = widget.kernel;
    final entry = widget.entry;
    final hPad = widget.compact ? 8.0 : 24.0;

    // 批：阅读态——直接显示 entry，不渲染 kernel，也不显素材槽
    if (widget.isReadMode) {
      return _buildReadBody(context, entry);
    }

    final body = Column(
      children: [
        // ── header（⭐/❓）──
        if (widget.header != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: widget.header!,
          ),
        // ── 错误提示 ──
        if (widget.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '⚠️ ${widget.errorMessage}',
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        // ── 探究区 ──
        if (widget.showExplore && entry.exploreTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          EditorExploreArea(
            entry: entry,
            onTap: widget.onExploreTap ?? () {},
          ),
        ],
        // ── 标题 ──
        EditorTitleBar(
          controller: kernel.titleController,
          onChanged: () => setState(() {}),
        ),
        const Divider(height: 8),
        // ── 正文 ──
        Expanded(
          child: widget.onDropItem != null
              ? DragTarget<MaterialItem>(
                  onAcceptWithDetails: widget.onDropItem!,
                  builder: (context, _, __) =>
                      Workbench(kernel: kernel, entry: entry),
                )
              : Workbench(kernel: kernel, entry: entry),
        ),
        // ── 底栏 ──
        if (widget.showBottomBar) ...[
          const Divider(height: 8),
          EditorBottomBar(
            paneWidth: widget.paneWidth,
            wordCount: kernel.wordCount,
            lineCount: kernel.lineCount,
            tagCount: kernel.tags.length,
            isMarkdown: kernel.isMarkdown,
            onMarkdownChanged: (v) {
              kernel.toggleMarkdown(v);
              setState(() {});
            },
            isSaving: kernel.isSaving,
            onSave: () async {
              final ok = await kernel.save();
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '✅ 已保存' : '❌ 保存失败')),
                );
              }
            },
            onCancel: widget.onCancel,
            onGenerateCard: kernel.createReviewCard,
            isGeneratingCard: kernel.isGeneratingCard,
            saveLabel: widget.saveLabel,
            isFromCollection: widget.isFromCollection,
            compact: widget.compact,
            appBarHasCardAction: widget.appBarHasCardAction,
          ),
        ],
      ],
    );

    // 无素材槽——直接返回
    if (widget.materialItems == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: body,
      );
    }

    // 有素材槽——右侧
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: body,
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        EditorMaterialSlot(items: widget.materialItems!),
      ],
    );
  }

  /// 批：阅读态视图——多栏保存后切
  /// 简化显示（标题 / 标签 / 正文）——不引单栏全功能 read 渲染
  /// 债：单栏 / 多栏 read 态样式不统一——归后续「read 视图统一」块
  Widget _buildReadBody(BuildContext context, NotebookEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部「编辑」按钮（onEditRequest != null 时显）
        if (widget.onEditRequest != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: widget.onEditRequest,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑'),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStringUtils.displayNoteTitle(entry.title, entry.content),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: entry.tags
                        .map((t) => Chip(label: Text(t)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                entry.editorMode == 'markdown'
                    ? MarkdownBody(data: entry.content)
                    : SelectableText(entry.content,
                        style:
                            const TextStyle(fontSize: 16, height: 1.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}