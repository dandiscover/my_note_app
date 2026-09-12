// lib/widgets/reader/card_box_peek.dart
// 阅读器卡片盒停靠面板
// 划线后从右侧滑出一角，露出"📖 读透"和"🎴 来张卡"
// ✅ 数据源：内部调 CardService.getAllCards()，每次滑出刷新
// ✅ 滑出动画：AnimatedSlide + Curves.easeOut，250ms，露出 140px
// ✅ "来张卡"：底部弹出拐杖卡选择器，按 usageCount 降序
// ✅ 父级集成：放在 Stack 里，父级控制 visible
// ✅ 4.3：onCardSelected 类型为 void Function(CardModel card)
// ✅ 职责边界：本组件只发 onCardSelected 回调，父级决定后续
//    7.1 落点：父级 epub_reader_page.dart 的 onCardSelected 回调里判断
// ✅ 修复（问题3）：来张卡选择器过滤 CardType.guide（读透已是指导卡入口，避免重复）

import 'package:flutter/material.dart';
import '../../models/card.dart';
import '../../services/card_service.dart';

class CardBoxPeek extends StatefulWidget {
  /// 是否滑出。父级控制。
  final bool visible;

  /// 点击"📖 读透"的回调
  final VoidCallback onReadThrough;

  /// "来张卡"里选中某张卡的回调。
  /// 父级收到后自行判定：
  ///   - cardType == CardType.guide → 父级直接进三层提问（老白裁定 7.1）
  ///   - 其他拐杖卡 → 走各自的追问流程
  /// 本组件不感知"阅读划线"上下文（无 selectedText 参数）。
  final void Function(CardModel card) onCardSelected;

  const CardBoxPeek({
    super.key,
    required this.visible,
    required this.onReadThrough,
    required this.onCardSelected,
  });

  @override
  State<CardBoxPeek> createState() => _CardBoxPeekState();
}

class _CardBoxPeekState extends State<CardBoxPeek> {
  final CardService _cardService = CardService();
  List<CardModel> _scaffoldCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void didUpdateWidget(covariant CardBoxPeek oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ 每次从隐藏变可见时，重新加载数据
    if (widget.visible && !oldWidget.visible) {
      _loadCards();
    }
  }

  Future<void> _loadCards() async {
    final all = await _cardService.getAllCards();
    if (!mounted) return;
    // ✅ 修复（问题3）：来张卡选择器过滤 guide
    // 理由：读透（📖）已经是指导卡入口，来张卡再列一次是重复。
    //       来张卡保留给未来的探究卡 / 结构卡。
    final scaffoldCards = all
        .where((c) =>
            c.kind == CardKind.scaffold && c.cardType != CardType.guide)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    setState(() => _scaffoldCards = scaffoldCards);
  }

  void _showCardPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '🎴 来张卡',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            if (_scaffoldCards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '还没有拐杖卡',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _scaffoldCards.length,
                  itemBuilder: (_, i) {
                    final card = _scaffoldCards[i];
                    return ListTile(
                      leading: Text(
                        card.typeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        card.typeLabel,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        card.usageCount > 0
                            ? '用过 ${card.usageCount} 次'
                            : '还没试过',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        // ✅ 统一走 onCardSelected；父级自行判定指导卡/其他卡
                        widget.onCardSelected(card);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedSlide(
          offset: widget.visible ? Offset.zero : const Offset(1, 0),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _buildPanel(),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildButton(
              icon: '📖',
              label: '读透',
              onTap: widget.onReadThrough,
            ),
          ),
          Container(width: 0.5, height: 40, color: Colors.grey.shade200),
          Expanded(
            child: _buildButton(
              icon: '🎴',
              label: '来张卡',
              onTap: _showCardPicker,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}