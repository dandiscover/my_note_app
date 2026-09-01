// lib/pages/insight/review_tab.dart
// 复习Tab

import 'package:flutter/material.dart';
import '../../services/card_service.dart';
import '../../models/card.dart';
import '../../widgets/insight/review_card_item.dart';
import '../../widgets/insight/review_stats.dart';
import '../../mixins/state_mixin.dart';

class ReviewTab extends StatefulWidget {
  const ReviewTab({super.key});

  @override
  State<ReviewTab> createState() => ReviewTabState();
}

class ReviewTabState extends State<ReviewTab> with StateMixin {
  final CardService _cardService = CardService();
  List<CardModel> _dueCards = [];
  bool _isReviewing = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  Future<void> _loadDueCards() async {
    isLoading = true;
    try {
      final cards = await _cardService.getDueCards();
      setState(() {
        _dueCards = cards;
        _currentIndex = 0;
        _isReviewing = false;
      });
    } catch (e) {
      print('加载待复习卡片失败: $e');
    }
    isLoading = false;
  }

  void _startReview() {
    setState(() {
      _isReviewing = true;
    });
  }

  Future<void> _handleReview(CardModel card, int quality) async {
    // quality: 0=忘记, 1=模糊, 2=记得
    if (quality == 0) {
      await _cardService.rateForgotten(card);
    } else {
      await _cardService.rateRemembered(card);
    }

    setState(() {
      _dueCards.removeAt(_currentIndex);
    });

    if (_dueCards.isEmpty) {
      setState(() {
        _isReviewing = false;
      });
      _loadDueCards();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(quality > 0 ? '✅ 记得很好！' : '🔄 再复习一次'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dueCount = _dueCards.length;

    if (dueCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('🎉 所有卡片已掌握！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              '暂无待复习的卡片',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDueCards,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ReviewStats(
          totalCards: dueCount,
          dueCards: dueCount,
          reviewedToday: 0,
          remaining: dueCount,
        ),
        Expanded(
          child: _dueCards.isEmpty
              ? const Center(child: Text('没有待复习的卡片'))
              : ListView.builder(
                  itemCount: _dueCards.length,
                  itemBuilder: (context, index) {
                    final card = _dueCards[index];
                    return ReviewCardItem(
                      card: card,
                      isReviewing: _isReviewing && index == _currentIndex,
                      onReview: (quality) {
                        _handleReview(card, quality);
                      },
                    );
                  },
                ),
        ),
        if (_dueCards.isNotEmpty && !_isReviewing)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _startReview,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始复习'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
      ],
    );
  }
}