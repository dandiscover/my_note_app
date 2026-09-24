// lib/widgets/workbench/outline_panel.dart
// 大纲面板 —— 解析 Markdown 标题，只读导航
import 'package:flutter/material.dart';

class OutlinePanel extends StatelessWidget {
  final String content;
  final String contentFormat;
  final void Function(int charOffset) onHeadingTap;

  const OutlinePanel({
    super.key,
    required this.content,
    required this.contentFormat,
    required this.onHeadingTap,
  });

  @override
  Widget build(BuildContext context) {
    if (contentFormat != 'markdown') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Richtext 大纲\n开发中',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final headings = _parseHeadings(content);
    if (headings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无标题',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Text(
            '📑 大纲 (${headings.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: headings.length,
            itemBuilder: (ctx, i) {
              final h = headings[i];
              return InkWell(
                onTap: () => onHeadingTap(h.offset),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 12.0 + (h.level - 1) * 12.0,
                    right: 8,
                    top: 6,
                    bottom: 6,
                  ),
                  child: Text(
                    h.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: h.level == 1 ? 14 : 13,
                      fontWeight:
                          h.level == 1 ? FontWeight.w600 : FontWeight.normal,
                      color: h.level == 1 ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<_Heading> _parseHeadings(String md) {
    final result = <_Heading>[];
    var offset = 0;
    for (final line in md.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('#')) {
        var level = 0;
        while (level < trimmed.length && trimmed[level] == '#') {
          level++;
        }
        if (level >= 1 &&
            level <= 6 &&
            level < trimmed.length &&
            trimmed[level] == ' ') {
          final text = trimmed.substring(level + 1).trim();
          if (text.isNotEmpty) {
            result.add(_Heading(level: level, text: text, offset: offset));
          }
        }
      }
      offset += line.length + 1;
    }
    return result;
  }
}

class _Heading {
  final int level;
  final String text;
  final int offset;
  const _Heading({
    required this.level,
    required this.text,
    required this.offset,
  });
}