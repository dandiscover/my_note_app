import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import '../../models/note.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';
import 'wisdom_light_toast.dart';

class WisdomNoteCard extends StatefulWidget {
  final Node node;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckChanged;
  final double cardWidth;
  final double cardHeight;

  const WisdomNoteCard({
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

  @override
  State<WisdomNoteCard> createState() => _WisdomNoteCardState();
}

class _WisdomNoteCardState extends State<WisdomNoteCard> {
  final DatabaseService _db = DatabaseService();

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
    return FutureBuilder<NotebookEntry?>(
      future: _db.getNoteByNodeId(widget.node.id),
      builder: (context, snapshot) {
        final note = snapshot.data;
        final colorIndex = widget.node.id.hashCode.abs() % _cardColors.length;
        final bgColor = _cardColors[colorIndex];

        final cardContent = GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.isSelectMode ? null : widget.onLongPress,
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
                      if (widget.isSelectMode)
                        WisdomCheckbox(
                          value: widget.isSelected,
                          onChanged: widget.onCheckChanged,
                        ),
                      const Icon(Icons.note, size: 18, color: Color(0xFF6B6B6B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.node.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note?.content ?? '无内容',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(note?.updatedAt ?? DateTime.now()),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return WisdomDraggable(
          node: widget.node,
          child: cardContent,
          isSelectMode: widget.isSelectMode,
          cardWidth: widget.cardWidth,
          cardHeight: widget.cardHeight,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}