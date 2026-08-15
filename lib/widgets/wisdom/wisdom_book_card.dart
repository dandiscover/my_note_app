import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import '../../models/book.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';
import 'wisdom_light_toast.dart';

class WisdomBookCard extends StatelessWidget {
  final Node node;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckChanged;
  final double cardWidth;
  final double cardHeight;

  const WisdomBookCard({
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
    Color(0xFFE8EDF2),
    Color(0xFFE8F0ED),
    Color(0xFFEDF0F0),
    Color(0xFFE8ECF0),
    Color(0xFFF0EDE8),
    Color(0xFFEDE8F0),
    Color(0xFFE8F0F0),
    Color(0xFFF5F0E8),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book?>(
      future: DatabaseService().getBookByNodeId(node.id),
      builder: (context, snapshot) {
        final book = snapshot.data;
        final colorIndex = node.id.hashCode.abs() % _cardColors.length;
        final bgColor = _cardColors[colorIndex];

        final cardContent = GestureDetector(
          onTap: onTap,
          onLongPress: isSelectMode ? null : onLongPress,
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.06),
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
                  Row(
                    children: [
                      if (isSelectMode)
                        WisdomCheckbox(
                          value: isSelected,
                          onChanged: onCheckChanged,
                        ),
                      const Icon(Icons.book, size: 24, color: Color(0xFF4A90D9)),
                    ],
                  ),
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
                  if (book != null) ...[
                    Text(
                      book.author.isNotEmpty ? book.author : '未知作者',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (book.readingProgress / 100).clamp(0, 1),
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90D9)),
                            minHeight: 3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.readingProgress}%',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        return WisdomDraggable(
          node: node,
          child: cardContent,
          isSelectMode: isSelectMode,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        );
      },
    );
  }
}