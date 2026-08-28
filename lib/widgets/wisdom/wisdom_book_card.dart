// lib/widgets/wisdom/wisdom_book_card.dart
// 智库 - 图书卡片（只接收 node，内部查询数据）

import 'package:flutter/material.dart';
import '../../models/node.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';

class WisdomBookCard extends StatelessWidget {
  final Node node;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onCheckChanged;
  final double cardWidth;
  final double cardHeight;

  const WisdomBookCard({
    super.key,
    required this.node,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onCheckChanged,
    required this.cardWidth,
    required this.cardHeight,
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book, size: 28, color: Colors.green),
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