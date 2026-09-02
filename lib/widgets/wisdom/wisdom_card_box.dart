// lib/widgets/wisdom/wisdom_card_box.dart
// 卡片盒视图 — 显示所有卡片（含索引卡）
// ✅ 新增：拐杖卡（kind == CardKind.scaffold）左上角显示 🧭 标记
// ✅ 新增：“＋ 拐杖卡”按钮
// ✅ 新增：空状态时也显示“＋ 拐杖卡”按钮
// ✅ 修复：统计栏 reviewCount 和 indexCount 过滤拐杖卡
// ✅ 重构：去掉标签分组，改为平铺 + 标签下拉筛选
// ✅ 新增：统计栏 Chip 可点击筛选（总卡片/复习卡/索引卡/拐杖卡）

import 'package:flutter/material.dart';
import '../../models/card.dart';

class WisdomCardBox extends StatefulWidget {
  final List<CardModel> cards;
  final Function(String) onSearch;
  final Function(CardModel) onCardTap;
  final VoidCallback? onAddScaffold;

  const WisdomCardBox({
    super.key,
    required this.cards,
    required this.onSearch,
    required this.onCardTap,
    this.onAddScaffold,
  });

  @override
  State<WisdomCardBox> createState() => _WisdomCardBoxState();
}

class _WisdomCardBoxState extends State<WisdomCardBox> {
  String _searchQuery = '';
  String _selectedTag = '全部';
  String _selectedFilter = 'all'; // 'all' | 'review' | 'index' | 'scaffold'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CardModel> get _filteredCards {
    // 1. 按标签筛选
    final tagFiltered = _selectedTag == '全部'
        ? widget.cards
        : widget.cards.where((card) => card.tags.contains(_selectedTag)).toList();

    // 2. 按类型筛选
    final typeFiltered = tagFiltered.where((card) {
      switch (_selectedFilter) {
        case 'review':
          return card.kind == CardKind.atomic && card.cardType == CardType.review;
        case 'index':
          return card.kind == CardKind.atomic && card.cardType == CardType.indexCard;
        case 'scaffold':
          return card.kind == CardKind.scaffold;
        case 'all':
        default:
          return true;
      }
    }).toList();

    // 3. 按搜索关键词筛选
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return typeFiltered;

    return typeFiltered.where((card) {
      if (card.tags.any((t) => t.toLowerCase().contains(query))) return true;
      if (card.front?.toLowerCase().contains(query) == true) return true;
      if (card.back?.toLowerCase().contains(query) == true) return true;
      if (card.indexTitle?.toLowerCase().contains(query) == true) return true;
      if (card.author?.toLowerCase().contains(query) == true) return true;
      if (card.highlight?.toLowerCase().contains(query) == true) return true;
      return false;
    }).toList();
  }

  List<String> get _uniqueTags {
    final tagSet = <String>{};
    for (var card in widget.cards) {
      tagSet.addAll(card.tags);
    }
    final sorted = tagSet.toList()..sort();
    return ['全部', ...sorted];
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
    final totalCards = widget.cards.length;
    final reviewCount = widget.cards.where((c) => c.kind == CardKind.atomic && c.cardType == CardType.review).length;
    final indexCount = widget.cards.where((c) => c.kind == CardKind.atomic && c.cardType == CardType.indexCard).length;
    final scaffoldCount = widget.cards.where((c) => c.kind == CardKind.scaffold).length;

    if (widget.cards.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.onAddScaffold != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: widget.onAddScaffold,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('拐杖卡', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  foregroundColor: Colors.purple.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          Icon(Icons.credit_card_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('📇 卡片盒是空的', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('在笔记详情或全屏编辑器中点击「✨生成卡片」创建复习卡', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
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
              // 统计栏 — 四个可点击 Chip
              Row(
                children: [
                  _buildFilterChip(
                    label: '总卡片',
                    count: totalCards,
                    icon: '📇',
                    filterValue: 'all',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: '复习卡',
                    count: reviewCount,
                    icon: '📄',
                    filterValue: 'review',
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: '索引卡',
                    count: indexCount,
                    icon: '📚',
                    filterValue: 'index',
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: '拐杖卡',
                    count: scaffoldCount,
                    icon: '🧭',
                    filterValue: 'scaffold',
                    color: Colors.orange,
                  ),
                  const Spacer(),
                  if (widget.onAddScaffold != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        onPressed: widget.onAddScaffold,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('拐杖卡', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.purple.withValues(alpha: 0.1),
                          foregroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
              // 标签下拉筛选行（独立一行）
              const SizedBox(height: 4),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedTag,
                    items: _uniqueTags.map((tag) => DropdownMenuItem(
                      value: tag,
                      child: Text(tag, style: const TextStyle(fontSize: 11)),
                    )).toList(),
                    onChanged: (newTag) {
                      setState(() {
                        _selectedTag = newTag!;
                      });
                    },
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    isDense: true,
                  ),
                  const SizedBox(width: 4),
                  Text('${_uniqueTags.length - 1} 个标签', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 8),
              // 搜索框
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
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredCards.length,
              itemBuilder: (context, index) {
                final card = _filteredCards[index];
                return _buildCardItem(card);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required String icon,
    required String filterValue,
    required Color color,
  }) {
    final isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 点击当前已选中的 Chip → 回到 'all'（取消筛选）
          // 点击其他 Chip → 切换到对应筛选
          _selectedFilter = isSelected ? 'all' : filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 3),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 1),
                height: 1.5,
                width: double.infinity,
                color: color,
              ),
          ],
        ),
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
              child: Stack(
                children: [
                  Column(
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
                  if (card.kind == CardKind.scaffold)
                    Positioned(
                      top: 2,
                      left: 4,
                      child: Text('🧭', style: const TextStyle(fontSize: 12)),
                    ),
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