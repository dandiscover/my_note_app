// lib/widgets/wisdom/wisdom_card_box.dart
// 卡片盒视图 — 显示所有卡片（含索引卡）

import 'package:flutter/material.dart';
import '../../models/card.dart';

class WisdomCardBox extends StatefulWidget {
  final List<CardModel> cards;
  final Function(String) onSearch;
  final Function(CardModel) onCardTap;

  const WisdomCardBox({
    super.key,
    required this.cards,
    required this.onSearch,
    required this.onCardTap,
  });

  @override
  State<WisdomCardBox> createState() => _WisdomCardBoxState();
}

class _WisdomCardBoxState extends State<WisdomCardBox> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CardModel> get _filteredCards {
    if (_searchQuery.trim().isEmpty) return widget.cards;
    final query = _searchQuery.trim().toLowerCase();
    return widget.cards.where((card) {
      if (card.tags.any((t) => t.toLowerCase().contains(query))) return true;
      if (card.front?.toLowerCase().contains(query) == true) return true;
      if (card.back?.toLowerCase().contains(query) == true) return true;
      if (card.indexTitle?.toLowerCase().contains(query) == true) return true;
      if (card.author?.toLowerCase().contains(query) == true) return true;
      if (card.highlight?.toLowerCase().contains(query) == true) return true;
      return false;
    }).toList();
  }

  Map<String, List<CardModel>> get _groupedCards {
    final groups = <String, List<CardModel>>{};
    for (var card in _filteredCards) {
      if (card.tags.isEmpty) {
        groups.putIfAbsent('未分类', () => []).add(card);
      } else {
        for (var tag in card.tags) {
          groups.putIfAbsent(tag, () => []).add(card);
        }
      }
    }
    final sortedKeys = groups.keys.toList()..sort();
    final sortedGroups = <String, List<CardModel>>{};
    for (var key in sortedKeys) {
      sortedGroups[key] = groups[key]!;
    }
    return sortedGroups;
  }

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue, Colors.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.pink, Colors.indigo, Colors.cyan,
      Colors.deepPurple, Colors.red, Colors.amber, Colors.brown,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedCards;
    final totalCards = widget.cards.length;
    final reviewCount = widget.cards.where((c) => c.cardType == CardType.review).length;
    final indexCount = widget.cards.where((c) => c.cardType == CardType.indexCard).length;

    if (widget.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('📇 卡片盒是空的', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('在笔记详情或全屏编辑器中点击「✨生成卡片」创建复习卡', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatChip('📇 总卡片', totalCards, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatChip('📄 复习卡', reviewCount, Colors.purple),
                  const SizedBox(width: 12),
                  _buildStatChip('📚 索引卡', indexCount, Colors.teal),
                  const Spacer(),
                  Text('${grouped.keys.length} 个标签', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 搜索卡片...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { _searchController.clear(); setState(() {}); widget.onSearch(''); })
                      : null,
                ),
                onChanged: (value) { setState(() { _searchQuery = value; }); widget.onSearch(value); },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (_filteredCards.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('没有找到匹配的卡片', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: grouped.entries.map((entry) {
                  final tag = entry.key;
                  final cards = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(tag).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer, size: 14, color: _getTagColor(tag)),
                            const SizedBox(width: 4),
                            Text(tag, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _getTagColor(tag))),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: _getTagColor(tag).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text('${cards.length}', style: TextStyle(fontSize: 10, color: _getTagColor(tag))),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 2.0,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return _buildCardItem(card);
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCardItem(CardModel card) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () => widget.onCardTap(card),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: isHovered ? Matrix4.diagonal3Values(1.04, 1.04, 1.0) : Matrix4.identity(),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isHovered ? 12 : 4),
                border: Border.all(color: isHovered ? card.typeColor : Colors.grey.shade200, width: isHovered ? 2 : 0.5),
                boxShadow: isHovered ? [BoxShadow(color: card.typeColor.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))] : null,
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: card.typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(card.typeIcon, style: const TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getCardThumbnail(card),
                    style: TextStyle(fontSize: isHovered ? 10 : 7, color: isHovered ? Colors.black87 : Colors.grey.shade700),
                    maxLines: isHovered ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (card.mastered) const Text('✅', style: TextStyle(fontSize: 6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCardThumbnail(CardModel card) {
    switch (card.cardType) {
      case CardType.indexCard:
        return card.highlight ?? card.indexTitle ?? '索引卡';
      case CardType.review:
        return card.front ?? '复习卡';
      case CardType.qa:
        return card.question ?? '问答卡';
      case CardType.fill:
        return card.fillQuestion ?? '填空卡';
      case CardType.choice:
        return card.choiceQuestion ?? '选择题';
      case CardType.truefalse:
        return card.tfStatement ?? '判断题';
    }
  }
}