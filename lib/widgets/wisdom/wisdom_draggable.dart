import 'package:flutter/material.dart';
import '../../models/node.dart';

class WisdomDraggable extends StatelessWidget {
  final Node node;
  final Widget child;
  final bool isSelectMode;
  final double cardWidth;
  final double cardHeight;
  final double padding;

  const WisdomDraggable({
    super.key,
    required this.node,
    required this.child,
    required this.isSelectMode,
    required this.cardWidth,
    required this.cardHeight,
    this.padding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelectMode) {
      return child;
    }

    final feedbackWidth = cardWidth * 0.667;
    final feedbackHeight = cardHeight * 0.667;

    final feedbackChild = Container(
      width: feedbackWidth,
      height: feedbackHeight,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          node.isFolder
              ? const Icon(Icons.folder, size: 26, color: Color(0xFFF5A623))
              : Text(node.iconEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          // ✅ 修复：style 改为命名参数
          Text(
            node.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3D3D3D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: node.id,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(10),
        child: feedbackChild,
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}