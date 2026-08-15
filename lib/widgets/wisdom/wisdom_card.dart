import 'package:flutter/material.dart';
import '../../database_service.dart';
import '../../models/node.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';
import 'wisdom_light_toast.dart';

class WisdomFolderCard extends StatefulWidget {
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

  const WisdomFolderCard({
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
  State<WisdomFolderCard> createState() => _WisdomFolderCardState();
}

class _WisdomFolderCardState extends State<WisdomFolderCard> {
  final DatabaseService _db = DatabaseService();
  String? _dragTargetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Node>>(
      future: _db.getChildren(widget.node.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        final cardContent = DragTarget<String>(
          onWillAccept: (data) {
            if (data == null) return false;
            if (data == widget.node.id) return false;
            if (widget.isDescendantOf(data, widget.node.id)) return false;
            return true;
          },
          onAccept: (data) async {
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
}