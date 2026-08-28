// lib/widgets/insight/review_card_item.dart
// 复习卡片项 — 显示卡片内容 + 评分按钮

import 'package:flutter/material.dart';
import '../../models/review_card.dart';
import '../../mixins/state_mixin.dart';

class ReviewCardItem extends StatefulWidget {
  final ReviewCard card;
  final bool isReviewing;
  final Function(int quality) onReview;

  const ReviewCardItem({
    super.key,
    required this.card,
    required this.isReviewing,
    required this.onReview,
  });

  @override
  State<ReviewCardItem> createState() => _ReviewCardItemState();
}

class _ReviewCardItemState extends State<ReviewCardItem> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 头部信息 ──────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.card.isNew ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.card.isNew ? '新卡片' : '复习 #${widget.card.repetitions}',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.card.isNew ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '间隔 ${widget.card.interval}天',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── 卡片内容（可翻转） ──────────────────────
            GestureDetector(
              onTap: () {
                if (!widget.isReviewing) {
                  setState(() {
                    _isFlipped = !_isFlipped;
                  });
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _isFlipped
                    ? _buildCardBack()
                    : _buildCardFront(),
              ),
            ),

            const SizedBox(height: 12),

            // ─── 提示 ──────────────────────────────────────
            if (!widget.isReviewing && !_isFlipped)
              Center(
                child: Text(
                  '👆 点击翻转查看答案',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),

            // ─── 评分按钮 ──────────────────────────────────
            if (_isFlipped || widget.isReviewing)
              _buildReviewButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      key: const ValueKey('front'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📖 问题',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            widget.card.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 答案',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            widget.card.answer,
            style: const TextStyle(fontSize: 15),
          ),
          if (widget.card.isDue)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⏰ 需要复习',
                style: TextStyle(fontSize: 10, color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewButtons() {
    if (widget.isReviewing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          _buildRatingButton(
            label: '😞 忘记',
            color: Colors.red,
            quality: 0,
            onTap: () => widget.onReview(0),
          ),
          const SizedBox(width: 6),
          _buildRatingButton(
            label: '🤔 模糊',
            color: Colors.orange,
            quality: 1,
            onTap: () => widget.onReview(1),
          ),
          const SizedBox(width: 6),
          _buildRatingButton(
            label: '😊 记得',
            color: Colors.green,
            quality: 2,
            onTap: () => widget.onReview(2),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required Color color,
    required int quality,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}