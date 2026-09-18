import 'package:flutter/material.dart';
import '../../models/card.dart';
import '../../services/card_service.dart';
import '../../widgets/writing/clue_board.dart';

/// 线索墙独立页——D 批块 4
///
/// 数据源 / 过滤规则 / viewId / dialog 与 WritingPage 逐字同
/// （writing_page.dart:68-69,207 / wisdom_page.dart:1550-1611）
/// 差异：dialog 副作用两处替换（_cache.invalidate 删 / _loadData→_loadCards）
class ClueBoardPage extends StatefulWidget {
  const ClueBoardPage({super.key});

  @override
  State<ClueBoardPage> createState() => _ClueBoardPageState();
}

class _ClueBoardPageState extends State<ClueBoardPage> {
  final CardService _cardService = CardService();
  List<CardModel> _indexCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final all = await _cardService.getAllCards();
    if (!mounted) return;
    setState(() {
      _indexCards = all.where((c) => c.cardType == CardType.indexCard).toList();      _isLoading = false;
    });
  }

  void _showCardDetailDialog(CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Text(card.typeIcon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 8), Expanded(child: Text(card.typeLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))), if (card.mastered) const Text('✅ 已掌握', style: TextStyle(fontSize: 12, color: Colors.green))]),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('📖 正面', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(card.displayFront, style: const TextStyle(fontSize: 16))])),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('💡 背面', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(card.displayBack, style: const TextStyle(fontSize: 16))])),
              if (card.tags.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 4, children: card.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact)).toList())],
              const SizedBox(height: 8),
              Row(children: [Text('重要性：${card.importanceLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), const SizedBox(width: 16), if (card.stage > 0) Text('阶段：${card.stageLabel}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]),
            ],
          ),
        ),
        actions: [
          // ✅ 指导卡：系统预置卡（system_guide_card）不显示"删除"按钮
          if (card.id != 'system_guide_card')
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除卡片'),
                    content: const Text('确定要删除这张卡片吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  Navigator.pop(context);
                  await _cardService.deleteCard(card.id);
                  // 块 4 甲 A：删 wisdom_page:1592 的 _cache.invalidate(_cacheKeyCards);
                  await _loadCards();   // wisdom_page:1593 _loadData() → _loadCards()
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🗑️ 卡片已删除')),
                  );
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
          if (card.kind == CardKind.atomic && !card.mastered)
            ElevatedButton(
              onPressed: () { Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              child: const Text('开始复习'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('线索墙')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ClueBoard(
              viewId: 'global',
              cards: _indexCards,
              onCardTap: (card) => _showCardDetailDialog(card),
            ),
    );
  }
}