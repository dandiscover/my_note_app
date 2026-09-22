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
///      （原 MaterialPanel 在 note_detail_page 出现两处——本次合一）
class EditorMaterialSlot extends StatelessWidget {
  final List<MaterialItem> items;
  final double width;
  final bool enabled;   // 批 3：透传

  const EditorMaterialSlot({
    super.key,
    required this.items,
    this.width = 280,
    this.enabled = true,
  });

  void _handleInsertCard(CardModel card) {
    final quote = card.highlight ?? card.indexTitle ?? card.displayFront;
    final citation =
        '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}';
    EditorKernel.insertTextGlobal(citation);
  }

  void _handleInsertNote(NotebookEntry note) {
    // 暂 no-op——与原调用点一致；「笔记插入」格式归债
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MaterialPanel(
        items: items,
        enabled: enabled,
        onInsertCard: _handleInsertCard,
        onInsertNote: _handleInsertNote,
      ),
    );
  }
}