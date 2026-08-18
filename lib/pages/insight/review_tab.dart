// lib/pages/insight/review_tab.dart
// 洞察页 → 复习Tab（艾宾浩斯调度 + 记住了/还不行）

import 'package:flutter/material.dart';
import '../../models/card.dart';
import '../../services/card_service.dart';

class ReviewTab extends StatefulWidget {
  const ReviewTab({super.key});

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  final CardService _cardService = CardService();
  List<CardModel> _cards = [];
  bool _isLoading = true;
  CardModel? _currentCard;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final due = await _cardService.getDueCards();
      print('📌 待复习卡片数: ${due.length}');
      setState(() {
        _cards = due;
        _isLoading = false;
        _currentCard = due.isNotEmpty ? due[0] : null;
        _showBack = false;
      });
    } catch (e) {
      print('❌ 加载卡片失败: $e');
      setState(() {
        _cards = [];
        _isLoading = false;
        _currentCard = null;
        _showBack = false;
      });
    }
  }

  void _nextCard() {
    if (_cards.isEmpty) return;
    final index = _cards.indexOf(_currentCard!);
    if (index < _cards.length - 1) {
      setState(() {
        _currentCard = _cards[index + 1];
        _showBack = false;
      });
    } else {
      setState(() {
        _currentCard = null;
        _showBack = false;
      });
    }
  }

  Future<void> _rateCard(bool remembered) async {
    if (_currentCard == null) return;
    final card = _currentCard!;

    if (remembered) {
      await _cardService.rateRemembered(card);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 记住了！进入下一阶段'), duration: Duration(seconds: 1)),
      );
    } else {
      await _cardService.rateForgotten(card);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 还不行，重置到第一阶段'), duration: Duration(seconds: 1)),
      );
    }

    setState(() {
      _cards.remove(_currentCard);
      _currentCard = _cards.isNotEmpty ? _cards[0] : null;
      _showBack = false;
    });

    if (_cards.isNotEmpty) {
      setState(() {
        _currentCard = _cards[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              '🎉 今日复习已完成！',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '所有卡片都复习过了，明天再来吧',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCards,
              child: const Text('刷新'),
            ),
          ],
        ),
      );
    }

    // 获取当前卡片的阶段信息
    final stageInfo = _getStageInfo(_currentCard!);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── 进度信息 ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '剩余 ${_cards.length} 张',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '阶段 ${_currentCard!.stage + 1}/7',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
              Text(
                '${_cards.indexOf(_currentCard!) + 1} / ${_cards.length}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ─── 进度条 ──────────────────────────
          LinearProgressIndicator(
            value: _cards.isNotEmpty ? (_cards.indexOf(_currentCard!) + 1) / _cards.length : 0,
            backgroundColor: Colors.grey.shade200,
            color: Colors.blue,
            minHeight: 4,
          ),
          const SizedBox(height: 12),

          // ─── 卡片 ──────────────────────────
          Expanded(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showBack = !_showBack;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ─── 标签行 ──────────────────────────
                      Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentCard!.typeIcon} ${_currentCard!.typeLabel}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getImportanceColor(_currentCard!.importance).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _currentCard!.importanceLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getImportanceColor(_currentCard!.importance),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                stageInfo,
                                style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // ─── 内容 ──────────────────────────
                      Text(
                        _showBack ? _currentCard!.displayBack : _currentCard!.displayFront,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: _showBack ? Colors.grey.shade700 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      // ─── 翻转提示 ──────────────────────────
                      Text(
                        _showBack ? '👆 点击返回正面' : '👆 点击查看背面',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── 评分按钮 ──────────────────────────
          if (_showBack) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRatingButton(
                  label: '🔄 还不行',
                  onTap: () => _rateCard(false),
                  color: Colors.red,
                ),
                _buildRatingButton(
                  label: '✅ 记住了',
                  onTap: () => _rateCard(true),
                  color: Colors.green,
                ),
              ],
            ),
          ],
          if (!_showBack)
            const Text(
              '点击卡片翻转',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.15),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: color, width: 2),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  String _getStageInfo(CardModel card) {
    if (card.mastered) return '🏆 已掌握';
    final stage = card.stage;
    final intervals = CardModel.ebbinghausIntervals;
    if (stage < intervals.length) {
      final interval = intervals[stage];
      if (interval.inDays > 0) {
        return '${interval.inDays}天后再复习';
      } else if (interval.inHours > 0) {
        return '${interval.inHours}小时后复习';
      } else {
        return '${interval.inMinutes}分钟后复习';
      }
    }
    return '已掌握';
  }

  Color _getImportanceColor(Importance importance) {
    switch (importance) {
      case Importance.low:
        return Colors.grey;
      case Importance.medium:
        return Colors.blue;
      case Importance.high:
        return Colors.orange;
      case Importance.critical:
        return Colors.red;
    }
  }
}