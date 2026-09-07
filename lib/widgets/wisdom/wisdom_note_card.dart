// lib/widgets/wisdom/wisdom_note_card.dart
// 智库 - 笔记卡片（只接收 node，内部查询数据）
// ✅ 新增可选参数 hasExplore，用于轻量标记“探究中”状态
// ✅ 保持卡片主体视觉不变，仅右上角增加紫色小圆点

import 'package:flutter/material.dart';
import '../../models/node.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';

class WisdomNoteCard extends StatelessWidget {
  final Node node;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onCheckChanged;
  final double cardWidth;
  final double cardHeight;
  final bool hasExplore;

  const WisdomNoteCard({
    super.key,
    required this.node,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onCheckChanged,
    required this.cardWidth,
    required this.cardHeight,
    this.hasExplore = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.note, size: 28, color: Colors.blue),
                  const SizedBox(height: 4),
                  Text(node.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (node.tags.isNotEmpty)
                    Text(node.tags.join(', '), style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelectMode)
              Positioned(
                top: 4, right: 4,
                child: WisdomCheckbox(
                  value: isSelected,
                  onChanged: (value) => onCheckChanged(value ?? false),
                ),
              ),
            // ✅ 探究中标记：紫色小圆点
            if (hasExplore && !isSelectMode)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isSelectMode) {
      return WisdomDraggable(
        node: node,
        child: cardContent,
      );
    }
    return cardContent;
  }
}