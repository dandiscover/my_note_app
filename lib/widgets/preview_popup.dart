// lib/widgets/preview_popup.dart
// B5 · 悬浮参考窗
// 老白裁：撤悬停、点弹窗、跟点击点、280px 宽 / 上限 200px、点外关
// 硬伤 1 修：撤 Esc 关闭 —— 避免 Focus autofocus 抢焦点

import 'package:flutter/material.dart';

/// B5 预览数据类
class PreviewData {
  final String title;
  final String summary;
  final String? meta;
  final VoidCallback? onOpen;

  const PreviewData({
    required this.title,
    required this.summary,
    this.meta,
    this.onOpen,
  });
}

/// B5 悬浮参考窗
class PreviewPopup {
  static OverlayEntry? _entry;

  static void show(BuildContext context, Offset anchor, PreviewData data) {
    hide();

    final overlay = Overlay.of(context, rootOverlay: true);
    final screen = MediaQuery.of(context).size;

    const popupWidth = 280.0;
    const maxHeight = 200.0;
    const gap = 8.0;
    const edge = 8.0;

    final isUpperHalf = anchor.dy < screen.height / 2;
    final left = (anchor.dx - popupWidth / 2)
        .clamp(edge, screen.width - popupWidth - edge);

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          // 点外关闭
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hide,
            ),
          ),
          // 浮窗
          Positioned(
            left: left,
            top: isUpperHalf ? anchor.dy + gap : null,
            bottom:
                isUpperHalf ? null : (screen.height - anchor.dy) + gap,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: popupWidth,
                constraints: const BoxConstraints(maxHeight: maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Text(
                        data.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          data.summary,
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ),
                    ),
                    if (data.meta != null) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(
                          data.meta!,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                    if (data.onOpen != null) ...[
                      const Divider(height: 1),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            final cb = data.onOpen;
                            hide();
                            cb?.call();
                          },
                          child: const Text('打开 →'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}