import 'package:flutter/material.dart';
import '../../models/card.dart';
import '../../models/material_item.dart';
import '../../models/note.dart';
import '../../widgets/writing/material_panel.dart';
import 'editor_kernel.dart';

/// 素材面板槽——工作台零件 · 丁方案第 1 步
///
/// 布局：宽 280（默认）侧栏，内含 MaterialPanel
/// 行为：点卡片 → 拼引用文本 → 插入当前焦点内核
///      （可由 onCustomCardTap 覆盖——如线索墙 pane 焦点时改为上墙）
class EditorMaterialSlot extends StatelessWidget {
  final List<MaterialItem> items;
  final double width;
  final bool enabled;

  /// 自定义卡片点击——非 null 时覆盖默认「插正文」行为
  final void Function(CardModel)? onCustomCardTap;

  /// 自定义笔记点击——非 null 时覆盖默认「插正文」行为
  final void Function(NotebookEntry)? onCustomNoteTap;

  /// 焦点提示——素材栏顶部一行小字
  /// 例：「素材将发往：笔记」/「素材将发往：线索墙」
  /// null = 不显
  final String? currentFocusLabel;

  const EditorMaterialSlot({
    super.key,
    required this.items,
    this.width = 280,
    this.enabled = true,
    this.onCustomCardTap,
    this.onCustomNoteTap,
    this.currentFocusLabel,
  });

  void _handleInsertCard(CardModel card) {
    if (onCustomCardTap != null) {
      onCustomCardTap!(card);
      return;
    }
    final quote = card.highlight ?? card.indexTitle ?? card.displayFront;
    final citation =
        '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}';
    EditorKernel.insertTextGlobal(citation);
  }

  void _handleInsertNote(NotebookEntry note) {
    if (onCustomNoteTap != null) {
      onCustomNoteTap!(note);
      return;
    }
    // 默认仍 no-op——与原调用点一致
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          if (currentFocusLabel != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.blue.shade50,
              child: Text(
                currentFocusLabel!,
                style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
              ),
            ),
          Expanded(
            child: MaterialPanel(
              items: items,
              enabled: enabled,
              onInsertCard: _handleInsertCard,
              onInsertNote: _handleInsertNote,
            ),
          ),
        ],
      ),
    );
  }
}