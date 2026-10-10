// lib/widgets/tree/tree_drag_mode.dart
// 智库 - 树节点拖拽模式（触屏）
// 本批飞回改直接消失——后批补动画

import 'package:flutter/material.dart';
import 'tree_drag_registry.dart';

class TreeDragModeController {
  final BuildContext context;
  final TreeDragRegistryController registry;
  final bool Function(String draggedId, String targetId) canDrop;
  final void Function(String draggedId, String targetId) onDrop;
  final TickerProvider? vsync;               // 预留——本批 null

  OverlayEntry? _entry;
  final ValueNotifier<Offset> _position = ValueNotifier(Offset.zero);
  late String _pendingId;

  TreeDragModeController({
    required this.context,
    required this.registry,
    required this.canDrop,
    required this.onDrop,
    this.vsync,
  });

  void start({
    required String pendingId,
    required Offset originGlobalPosition,
    required Widget feedback,
    required Size feedbackSize,
  }) {
    _pendingId = pendingId;
    _position.value = originGlobalPosition;

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerMove: (e) {
            _position.value = e.position;
            final hit = registry.hitTest(e.position);
            if (hit != null && hit != _pendingId && canDrop(_pendingId, hit)) {
              registry.hoverTarget.value = hit;
            } else {
              registry.hoverTarget.value = null;
            }
          },
          onPointerUp: (e) {
            final target = registry.hoverTarget.value;
            if (target != null && canDrop(_pendingId, target)) {
              onDrop(_pendingId, target);
            }
            _cleanup();
          },
          child: Stack(children: [
            const Positioned.fill(
              child: ColoredBox(color: Colors.transparent),
            ),
            ValueListenableBuilder<Offset>(
              valueListenable: _position,
              builder: (_, pos, __) => Positioned(
                left: pos.dx - feedbackSize.width / 2,
                top: pos.dy - feedbackSize.height / 2,
                child: Material(
                  color: Colors.transparent,
                  child: feedback,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  void abort() {
    _cleanup();
  }

  void _cleanup() {
    registry.hoverTarget.value = null;
    _entry?.remove();
    _entry = null;
    _position.dispose();
  }
}