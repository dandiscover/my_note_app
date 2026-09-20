import 'package:flutter/material.dart';
import '../../models/material_item.dart';
import '../../models/note.dart';
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

    final body = Column(
      children: [
        // ── header（⭐/❓） ──
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
              await kernel.save();
              if (mounted) setState(() {});
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
}