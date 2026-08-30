// lib/widgets/writing/material_panel.dart
// 写作素材面板 — 支持点击插入 + 拖拽

import 'package:flutter/material.dart';
import '../../models/card.dart';

class MaterialPanel extends StatelessWidget {
  final List<CardModel> cards;
  final Function(String) onInsertText;
  final Function(CardModel) onInsertCard;

  const MaterialPanel({
    super.key,
    required this.cards,
    required this.onInsertText,
    required this.onInsertCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text('📚 素材库', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                  ),
                ),
              ],
            ),
          ),
          // 搜索
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 搜索素材...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                isDense: true,
              ),
            ),
          ),
          // 卡片列表
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('暂无索引卡', style: TextStyle(color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text('在智库中创建索引卡后，可在此调用', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _buildMaterialItem(card);
                    },
                  ),
          ),
          // 底部提示
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              '💡 点击插入引用',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(CardModel card) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              final quote = card.highlight ?? card.indexTitle ?? card.displayFront;
              final citation = '「$quote」\n—— ${card.author ?? card.sourceTitle ?? '来源未知'}';
              onInsertText(citation);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📝 已引用：${(card.indexTitle ?? '未命名').substring(0, (card.indexTitle?.length ?? 20).clamp(0, 20))}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHovered ? Colors.teal.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHovered ? Colors.teal.shade300 : Colors.grey.shade200,
                  width: isHovered ? 1.5 : 0.5,
                ),
                boxShadow: isHovered
                    ? [BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 4)]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(card.typeIcon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          card.indexTitle ?? '未命名',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isHovered ? Colors.teal.shade700 : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card.author != null && card.author!.isNotEmpty)
                        Text(
                          card.author!,
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  if (card.highlight != null && card.highlight!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        card.highlight!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isHovered ? Colors.black87 : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (card.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 4,
                        children: card.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tag, style: TextStyle(fontSize: 7, color: _getTagColor(tag))),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue, Colors.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.pink, Colors.indigo, Colors.cyan,
      Colors.deepPurple, Colors.red,
    ];
    return colors[hash % colors.length];
  }
}