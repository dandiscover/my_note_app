// lib/widgets/reader/card_box_peek.dart
// 阅读器卡片盒停靠面板（"来张卡"）
// 划线后从右侧滑出一角，露出卡片类型列表
// ✅ 滑出动画：AnimatedSlide + Curves.easeOut，250ms，露出 140px
// ✅ 父级集成：放在 Stack 里，父级控制 visible
// ✅ 第四轮 BUG-002：面板 = 标题「来张卡」+ 类型列表
//    读透（读书卡）/ 索引卡 / 更多
//    「更多」= 原「来张卡」弹窗，走原筛选逻辑（拐杖卡，排除指导卡）
//    筛选逻辑未改，一行未动

import 'package:flutter/material.dart';
import '../../models/card.dart';
import '../../services/card_service.dart';

class CardBoxPeek extends StatefulWidget {
  /// 是否滑出。父级控制。
  final bool visible;

  /// 点「📖 读透」：用选中文字创建读书卡，进三层提问。
  final VoidCallback onReadThrough;

  /// 点「📇 索引卡」：用选中文字创建索引卡。
  final VoidCallback onCreateIndexCard;

  const CardBoxPeek({
    super.key,
    required this.visible,
    required this.onReadThrough,
    required this.onCreateIndexCard,
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
    // ✅ 筛选逻辑：原样保留，一行未动。
    //   拐杖卡，排除指导卡。
    final scaffoldCards = all
        .where((c) =>
            c.kind == CardKind.scaffold && c.cardType != CardType.guide)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    setState(() => _scaffoldCards = scaffoldCards);
  }

  /// 「更多」弹窗：列用户自建的拐杖卡。
  void _showMorePicker() {
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
                '更多',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            if (_scaffoldCards.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '暂无',
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
                        // 选中已有卡后的动作，走父级原逻辑（暂未接）。
                        // 本轮 BUG-002 不动卡片逻辑，仅保留弹窗。
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              '来张卡',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(height: 0.5, color: Colors.grey.shade200),

          _buildTypeButton(
            icon: '📖',
            label: '读透',
            onTap: widget.onReadThrough,
          ),
          Container(height: 0.5, color: Colors.grey.shade200),

          _buildTypeButton(
            icon: '📇',
            label: '索引卡',
            onTap: widget.onCreateIndexCard,
          ),
          Container(height: 0.5, color: Colors.grey.shade200),

          _buildTypeButton(
            icon: '➕',
            label: '更多',
            onTap: _showMorePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}