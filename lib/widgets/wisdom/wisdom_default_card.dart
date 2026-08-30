// lib/widgets/wisdom/wisdom_default_card.dart
// 智库 - 默认卡片

import 'package:flutter/material.dart';
import '../../models/node.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';

class WisdomDefaultCard extends StatelessWidget {
  final Node node;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckChanged;
  final double cardWidth;
  final double cardHeight;

  const WisdomDefaultCard({
    super.key,
    required this.node,
    required this.isSelectMode,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.onCheckChanged,
    required this.cardWidth,
    required this.cardHeight,
  });

  static const List<Color> _cardColors = [
    Color(0xFFF5F0E8),
    Color(0xFFE8EDF2),
    Color(0xFFF0EDE5),
    Color(0xFFF5E8E8),
    Color(0xFFEDE8F0),
    Color(0xFFE8F0ED),
    Color(0xFFF5EBE8),
    Color(0xFFEDF0F0),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex = node.id.hashCode.abs() % _cardColors.length;
    final bgColor = _cardColors[colorIndex];

    final cardContent = GestureDetector(
      onTap: onTap,
      onLongPress: isSelectMode ? null : onLongPress,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: bgColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelectMode)
                WisdomCheckbox(
                  value: isSelected,
                  onChanged: onCheckChanged,
                ),
              Text(node.iconEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                node.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // ✅ 修复：WisdomDraggable 只传 node 和 child
    return WisdomDraggable(
      node: node,
      child: cardContent,
    );
  }
}