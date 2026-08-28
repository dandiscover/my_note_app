// lib/pages/insight/review_tab.dart
// 复习Tab — 艾宾浩斯复习卡片列表（优化版）

import 'package:flutter/material.dart';
import '../../models/review_card.dart';
import '../../services/review_service.dart';
import '../../mixins/state_mixin.dart';
import '../../widgets/insight/review_stats.dart';
import '../../widgets/insight/review_card_item.dart';

class ReviewTab extends StatefulWidget {
  const ReviewTab({super.key});

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> with StateMixin {
  final ReviewService _reviewService = ReviewService();

  List<ReviewCard> _allCards = [];
  List<ReviewCard> _dueCards = [];
  String? _reviewingCardId;

  // ─── 生命周期 ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  // ─── 数据加载 ──────────────────────────────────────────────

  Future<void> _loadReviewData() async {
    isLoading = true;
    try {
      _allCards = await _reviewService.loadAll();
      _dueCards = await _reviewService.getDueCards();
    } catch (e) {
      showError('加载复习数据失败: $e');
    }
    isLoading = false;
  }

  // ─── 复习操作 ──────────────────────────────────────────────

  Future<void> _handleReview(String cardId, int quality) async {
    setState(() => _reviewingCardId = cardId);
    try {
      await _reviewService.reviewCard(cardId, quality);
      await _loadReviewData();

      if (_dueCards.isEmpty) {
        showSuccess('🎉 今日复习全部完成！');
      }
    } catch (e) {
      showError('复习失败: $e');
    }
    setState(() => _reviewingCardId = null);
  }

  // ─── 统计 ──────────────────────────────────────────────────

  Map<String, dynamic> get _stats {
    final today = DateTime.now();
    final reviewedToday = _allCards.where((c) =>
      c.lastReviewedAt != null &&
      c.lastReviewedAt!.year == today.year &&
      c.lastReviewedAt!.month == today.month &&
      c.lastReviewedAt!.day == today.day
    ).toList();

    return {
      'totalCards': _allCards.length,
      'dueCards': _dueCards.length,
      'reviewedToday': reviewedToday.length,
      'remaining': _dueCards.length - reviewedToday.length,
    };
  }

  // ─── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats;

    return Column(
      children: [
        // ─── 统计栏 ──────────────────────────────────────────
        ReviewStats(
          totalCards: stats['totalCards'],
          dueCards: stats['dueCards'],
          reviewedToday: stats['reviewedToday'],
          remaining: stats['remaining'],
        ),

        const SizedBox(height: 4),

        // ─── 卡片列表 ──────────────────────────────────────
        Expanded(
          child: _dueCards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _dueCards.length,
                  itemBuilder: (context, index) {
                    final card = _dueCards[index];
                    final isReviewing = _reviewingCardId == card.id;

                    return ReviewCardItem(
                      card: card,
                      isReviewing: isReviewing,
                      onReview: (quality) => _handleReview(card.id, quality),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '🎉 没有需要复习的卡片',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共 ${_allCards.length} 张卡片，已全部完成',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          if (_allCards.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 查看所有卡片
                showSuccess('📇 所有卡片列表功能开发中');
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('查看所有卡片'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }
}