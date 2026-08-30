import 'package:flutter/material.dart';
import '../../models/node.dart';
import 'wisdom_light_toast.dart';

class WisdomBreadcrumb extends StatelessWidget {
  final List<Node> breadcrumb;
  final Future<void> Function(String nodeId, String? newParentId) onMoveNode;
  final VoidCallback onGoRoot;
  final void Function(int index) onGoToBreadcrumb;
  final bool Function(String nodeId, String ancestorId) isDescendantOf;

  const WisdomBreadcrumb({
    super.key,
    required this.breadcrumb,
    required this.onMoveNode,
    required this.onGoRoot,
    required this.onGoToBreadcrumb,
    required this.isDescendantOf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildBreadcrumbTarget(
              context,
              label: '📚 智库',
              onTap: onGoRoot,
              onDragAccept: (data) async {
                await onMoveNode(data, null);
                WisdomLightToast.show(context, '✅ 已移动到根目录');
              },
            ),
            ...breadcrumb.asMap().entries.map((entry) {
              final index = entry.key;
              final node = entry.value;
              final isLast = index == breadcrumb.length - 1;
              return Row(
                children: [
                  Text(' / ', style: TextStyle(color: Colors.grey.shade400)),
                  _buildBreadcrumbTarget(
                    context,
                    label: node.title,
                    isLast: isLast,
                    onTap: isLast ? null : () => onGoToBreadcrumb(index),
                    onDragAccept: (data) async {
                      if (data == node.id) {
                        WisdomLightToast.show(context, '⚠️ 不能移动到自己');
                        return;
                      }
                      if (isDescendantOf(data, node.id)) {
                        WisdomLightToast.show(context, '⚠️ 不能移动到自己的子文件夹');
                        return;
                      }
                      await onMoveNode(data, node.id);
                      WisdomLightToast.show(context, '✅ 已移动到「${node.title}」');
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbTarget(
    BuildContext context, {
    required String label,
    bool isLast = false,
    VoidCallback? onTap,
    required Future<void> Function(String) onDragAccept,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) {
        if (isLast) return false;
        return true;
      },
      onAcceptWithDetails: (data) async {
        await onDragAccept(data);
      },
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty && !isLast;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isDragTarget ? Colors.green.shade100 : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isDragTarget
                  ? Border.all(color: Colors.green, width: 1.5)
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                color: isLast
                    ? Colors.black87
                    : (isDragTarget ? Colors.green.shade800 : Colors.grey.shade600),
              ),
            ),
          ),
        );
      },
    );
  }
}