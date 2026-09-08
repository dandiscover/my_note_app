// lib/widgets/wisdom/wisdom_book_card.dart
// 智库 - 图书卡片（接收 node + book，显示封面 + 来源标识）

import 'package:flutter/material.dart';
import '../../models/node.dart';
import '../../models/book.dart';
import 'wisdom_draggable.dart';
import 'wisdom_checkbox.dart';

class WisdomBookCard extends StatelessWidget {
  final Node node;
  final Book? book;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onCheckChanged;
  final double cardWidth;
  final double cardHeight;

  const WisdomBookCard({
    super.key,
    required this.node,
    this.book,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onCheckChanged,
    required this.cardWidth,
    required this.cardHeight,
  });

  String get _sourceLabel {
    if (book == null || book!.source.isEmpty) return '';
    return book!.source == 'import' ? '📄 电子书' : '📚 实体书';
  }

  bool get _hasSource => _sourceLabel.isNotEmpty;
  bool get _hasCover => book != null && book!.coverUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Stack(
          children: [
            // ─── 封面图片 ──────────────────────────────
            if (_hasCover)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book!.coverUrl,
                  width: cardWidth,
                  height: cardHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackContent(),
                ),
              )
            else
              _buildFallbackContent(),
            // ─── 来源轻标识（右下角） ──────────────────
            if (_hasSource)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _sourceLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // ─── 选择模式复选框 ──────────────────────────
            if (isSelectMode)
              Positioned(
                top: 4,
                right: 4,
                child: WisdomCheckbox(
                  value: isSelected,
                  onChanged: (value) => onCheckChanged(value ?? false),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isSelectMode) {
      return WisdomDraggable(
        node: node,
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _buildFallbackContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 28, color: Colors.green),
          const SizedBox(height: 4),
          Text(
            node.title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (node.tags.isNotEmpty)
            Text(
              node.tags.join(', '),
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}