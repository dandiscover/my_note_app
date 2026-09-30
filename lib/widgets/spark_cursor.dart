// lib/widgets/spark_cursor.dart
// B8 · 光标旁 💫（Overlay 挂）
// B8 修：光标火花 —— 白 Icon + 深底圆 + 闪烁

import 'package:flutter/material.dart';

class SparkCursor extends StatefulWidget {
  final VoidCallback onTap;

  const SparkCursor({super.key, required this.onTap});

  @override
  State<SparkCursor> createState() => _SparkCursorState();
}

class _SparkCursorState extends State<SparkCursor>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _blink.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: '点击编辑火花',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _blink,
            builder: (context, child) {
              final double op = _hovered ? 1.0 : (0.4 + 0.6 * _blink.value);
              return Opacity(opacity: op, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}