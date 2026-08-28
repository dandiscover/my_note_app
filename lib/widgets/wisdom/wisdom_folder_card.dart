// lib/widgets/wisdom/wisdom_folder_card.dart
// 智库 - 文件夹卡片（支持拖放、卡片盒特殊处理）

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
  final int subFolderCount;
  final int noteCount;
  final int cardCount;
  final VoidCallback? onDataChanged;

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
    this.subFolderCount = 0,
    this.noteCount = 0,
    this.cardCount = 0,
    this.onDataChanged,
  });

  @override
  State<WisdomFolderCard> createState() => _WisdomFolderCardState();
}

class _WisdomFolderCardState extends State<WisdomFolderCard> {
  final DatabaseService _db = DatabaseService();
  String? _dragTargetId;
  bool _isHovered = false;

  // ✅ 判断是否为卡片盒
  bool get _isCardBox => widget.node.title == '卡片盒' && widget.node.isFolder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Node>>(
      future: _db.getChildren(widget.node.id),
      builder: (context, snapshot) {
        final totalCount = snapshot.data?.length ?? 0;

        final cardContent = MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: DragTarget<Node>(
            onWillAccept: (data) {
              if (data == null) return false;
              if (data.id == widget.node.id) return false;
              if (widget.isDescendantOf(data.id, widget.node.id)) return false;

              // ✅ 卡片盒的特殊限制
              if (_isCardBox) {
                // 如果是卡片盒，只允许接受卡片（在现有数据中，卡片不是 Node，所以这里拒绝所有拖入）
                // 但为了更好的体验，我们允许文件夹拖入（方便用户整理卡片盒中的分类？不，卡片盒是一个扁平视图，不应该拖入任何 Node）
                // 根据用户需求：笔记不可以放到卡片盒内，所以我们拒绝所有 Node 拖入卡片盒
                return false;
              }

              // ✅ 如果是普通文件夹，允许所有类型的 Node（笔记、图书、子文件夹）
              return true;
            },
            onAccept: (data) async {
              // 移动节点到当前文件夹
              await _db.moveNode(data.id, widget.node.id);
              WisdomLightToast.show(context, '✅ 已移动到「${widget.node.title}」');
              widget.onDataChanged?.call();
              widget.onEnterFolder();
            },
            onLeave: (_) => setState(() => _dragTargetId = null),
            onMove: (details) => setState(() => _dragTargetId = widget.node.id),
            builder: (context, candidateData, rejectedData) {
              final isDragTarget = _dragTargetId == widget.node.id && candidateData.isNotEmpty;

              // ✅ 卡片盒样式：紫色系
              final boxColor = _isCardBox
                  ? (widget.isSelected ? Colors.purple.shade100 : Colors.purple.shade50)
                  : (widget.isSelected ? Colors.blue.shade50 : Colors.grey.shade50);

              final borderColor = widget.isSelected
                  ? (_isCardBox ? Colors.purple.shade700 : Colors.blue.shade700)
                  : (isDragTarget ? Colors.green : Colors.transparent);

              final iconColor = _isCardBox
                  ? (widget.isSelected ? Colors.purple.shade700 : Colors.purple.shade400)
                  : (widget.isSelected ? Colors.blue.shade700 : Colors.amber);

              return GestureDetector(
                onTap: () => widget.onEnterFolder(),
                onLongPress: widget.isSelectMode ? null : widget.onLongPress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: _isHovered
                      ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
                      : Matrix4.identity(),
                  child: Card(
                    elevation: isDragTarget ? 8 : (_isHovered ? 6 : 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: borderColor,
                        width: widget.isSelected ? 2 : (isDragTarget ? 2 : 0),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: boxColor,
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
                              Icon(
                                // ✅ 卡片盒使用信用卡图标，普通文件夹使用文件夹图标
                                _isCardBox ? Icons.credit_card : Icons.folder,
                                size: 20,
                                color: iconColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.node.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: widget.isSelected
                                  ? (_isCardBox ? Colors.purple.shade700 : Colors.blue.shade700)
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // ✅ 卡片盒显示特殊统计信息
                          if (_isCardBox) ...[
                            Text(
                              '📇 卡片盒',
                              style: TextStyle(
                                fontSize: 9,
                                color: widget.isSelected ? Colors.purple.shade600 : Colors.purple.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.cardCount} 张卡片',
                              style: TextStyle(
                                fontSize: 8,
                                color: widget.isSelected ? Colors.purple.shade500 : Colors.grey.shade500,
                              ),
                            ),
                          ] else ...[
                            // 普通文件夹统计
                            Row(
                              children: [
                                if (widget.subFolderCount > 0) ...[
                                  Text('📂 ${widget.subFolderCount}',
                                    style: TextStyle(fontSize: 8, color: widget.isSelected ? Colors.blue.shade500 : Colors.grey.shade600)),
                                  const SizedBox(width: 4),
                                ],
                                if (widget.noteCount > 0) ...[
                                  Text('📄 ${widget.noteCount}',
                                    style: TextStyle(fontSize: 8, color: widget.isSelected ? Colors.blue.shade500 : Colors.grey.shade600)),
                                  const SizedBox(width: 4),
                                ],
                                if (widget.cardCount > 0) ...[
                                  Text('🎴 ${widget.cardCount}',
                                    style: TextStyle(fontSize: 8, color: widget.isSelected ? Colors.blue.shade500 : Colors.grey.shade600)),
                                  const SizedBox(width: 4),
                                ],
                                if (widget.subFolderCount == 0 && widget.noteCount == 0 && widget.cardCount == 0)
                                  Text('空文件夹',
                                    style: TextStyle(fontSize: 8, color: widget.isSelected ? Colors.blue.shade400 : Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );

        // ✅ 文件夹本身也可拖动（拖到其他文件夹），但卡片盒不可拖动
        // 卡片盒作为特殊视图，我们不希望它被移动，所以不包裹 Draggable
        if (_isCardBox) {
          return cardContent;
        }

        return WisdomDraggable(
          node: widget.node,
          child: cardContent,
        );
      },
    );
  }
}