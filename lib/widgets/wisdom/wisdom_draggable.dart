// lib/widgets/wisdom/wisdom_draggable.dart
// 智库 - 拖拽功能

import 'package:flutter/material.dart';
import '../../models/node.dart';

class WisdomDraggable extends StatelessWidget {
  final Node node;
  final Widget child;
  final VoidCallback? onDragEnd;

  const WisdomDraggable({
    super.key,
    required this.node,
    required this.child,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Node>(
      data: node,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 0.5,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade400, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.iconEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  node.title,
                  // ✅ 去掉 const，因为 Colors.blue.shade700 不是常量
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: child,
      ),
      onDragEnd: (details) {
        onDragEnd?.call();
      },
      child: child,
    );
  }
}