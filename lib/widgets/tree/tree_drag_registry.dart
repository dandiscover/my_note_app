// lib/widgets/tree/tree_drag_registry.dart
// 智库 - 树拖拽目标注册表（常驻）

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TreeDragRegistry extends InheritedWidget {
  final TreeDragRegistryController controller;

  const TreeDragRegistry({
    super.key,
    required this.controller,
    required super.child,
  });

  static TreeDragRegistryController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TreeDragRegistry>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(TreeDragRegistry oldWidget) =>
      controller != oldWidget.controller;
}

class TreeDragRegistryController {
  final Map<String, RenderBox> _boxes = {};
  final ValueNotifier<String?> hoverTarget = ValueNotifier(null);

  void register(String nodeId, RenderBox box) {
    _boxes[nodeId] = box;
  }

  void unregister(String nodeId) {
    _boxes.remove(nodeId);
  }

  RenderBox? rawBox(String nodeId) => _boxes[nodeId];

  /// 纯查询——不写 hoverTarget
  String? hitTest(Offset globalPosition) {
    String? hit;
    double deepestTop = -double.infinity;
    for (final entry in _boxes.entries) {
      final box = entry.value;
      if (!box.attached) continue;
      final local = box.globalToLocal(globalPosition);
      if (box.size.contains(local)) {
        final top = box.localToGlobal(Offset.zero).dy;
        if (top > deepestTop) {
          deepestTop = top;
          hit = entry.key;
        }
      }
    }
    return hit;
  }

  void dispose() {
    hoverTarget.dispose();
    _boxes.clear();
  }
}
