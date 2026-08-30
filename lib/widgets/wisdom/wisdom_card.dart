// lib/widgets/wisdom/wisdom_card.dart
// 智库 - 通用卡片（根据 node 类型显示不同样式）

import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';
import 'wisdom_light_toast.dart';

class WisdomCard extends StatefulWidget {
  final Node node;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onCheckChanged;
  final VoidCallback onEnterFolder;
  final double cardWidth;
  final double cardHeight;
  final bool Function(String nodeId, String ancestorId) isDescendantOf;

  const WisdomCard({
    super.key,
    required this.node,
    required this.isSelectMode,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.onCheckChanged,
    required this.onEnterFolder,
    required this.cardWidth,
    required this.cardHeight,
    required this.isDescendantOf,
  });

  @override
  State<WisdomCard> createState() => _WisdomCardState();
}

class _WisdomCardState extends State<WisdomCard> {
  final DatabaseService _db = DatabaseService();
  String? _dragTargetId;

  @override
  Widget build(BuildContext context) {
    // 如果是文件夹，显示文件夹卡片
    if (widget.node.isFolder) {
      return _buildFolderCard();
    }

    // 否则显示普通卡片
    return _buildDefaultCard();
  }

  // ─── 文件夹卡片 ──────────────────────────────────────────────

  Widget _buildFolderCard() {
    return FutureBuilder<List<Node>>(
      future: _db.getChildren(widget.node.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        final cardContent = DragTarget<String>(
          onWillAcceptWithDetails: (data) {
            if (data == null) return false;
            if (data == widget.node.id) return false;
            if (widget.isDescendantOf(data, widget.node.id)) return false;
            return true;
          },
          onAcceptWithDetails: (data) async {
            await _db.moveNode(data, widget.node.id);
            WisdomLightToast.show(context, '✅ 已移动到「${widget.node.title}」');
            widget.onEnterFolder();
          },
          onLeave: (_) => setState(() => _dragTargetId = null),
          onMove: (details) => setState(() => _dragTargetId = widget.node.id),
          builder: (context, candidateData, rejectedData) {
            final isDragTarget = _dragTargetId == widget.node.id && candidateData.isNotEmpty;

            return GestureDetector(
              onTap: () => widget.onEnterFolder(),
              onLongPress: widget.isSelectMode ? null : widget.onLongPress,
              child: Card(
                elevation: isDragTarget ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isDragTarget ? Colors.green : Colors.transparent,
                    width: isDragTarget ? 2 : 0,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDragTarget ? Colors.green.shade50 : Colors.grey.shade50,
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
                          const Icon(Icons.folder, size: 20, color: Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.node.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '📂 $count',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        // ✅ 修复：WisdomDraggable 只传 node 和 child
        return WisdomDraggable(
          node: widget.node,
          child: cardContent,
        );
      },
    );
  }

  // ─── 普通卡片 ──────────────────────────────────────────────

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

  Widget _buildDefaultCard() {
    final colorIndex = widget.node.id.hashCode.abs() % _cardColors.length;
    final bgColor = _cardColors[colorIndex];

    final cardContent = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.isSelectMode ? null : widget.onLongPress,
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
              if (widget.isSelectMode)
                WisdomCheckbox(
                  value: widget.isSelected,
                  onChanged: widget.onCheckChanged,
                ),
              Text(widget.node.iconEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                widget.node.title,
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
      node: widget.node,
      child: cardContent,
    );
  }
}