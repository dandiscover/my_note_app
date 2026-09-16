// lib/widgets/mark_summary/mark_summary_panel.dart
// 摘要面板 — 第四轮批 2a 新增
//
// 职责：展示所有标记（高亮 / 批注 / 自定义），按 type 分三组，组内 createdAt DESC。
// 数据来源：外部传入 List<MarkSummaryItem>。面板自己分组 / 筛选，不做反查。
//
// 责任分层：
//   wisdom_page：拿数据 + 反查标题 + 构造 DTO + 跳转
//   本面板：展示 + 筛选 + 分组 + 回调

import 'package:flutter/material.dart';
import 'mark_summary_item.dart';

class MarkSummaryPanel extends StatefulWidget {
  /// 扁平 list，不过滤、不分组。面板内部处理。
  final List<MarkSummaryItem> items;

  /// 点击一条时回调。由调用方做跳转。
  final void Function(MarkSummaryItem item) onTap;

  /// DraggableScrollableSheet 传下来的控制器。
  /// 面板列表接它，才能拖拽改变高度。
  final ScrollController? scrollController;

  const MarkSummaryPanel({
    super.key,
    required this.items,
    required this.onTap,
    this.scrollController,
  });

  @override
  State<MarkSummaryPanel> createState() => _MarkSummaryPanelState();
}

class _MarkSummaryPanelState extends State<MarkSummaryPanel> {
  /// 筛选：'all' / 'custom' / 'highlight' / 'annotation'
  String _filter = 'all';

  List<MarkSummaryItem> get _filtered {
    if (_filter == 'all') return widget.items;
    return widget.items.where((i) => i.type == _filter).toList();
  }

  int _countOf(String type) =>
      widget.items.where((i) => i.type == type).length;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmpty();
    }

    final byType = <String, List<MarkSummaryItem>>{
      'custom': [],
      'highlight': [],
      'annotation': [],
    };
    for (final item in _filtered) {
      byType.putIfAbsent(item.type, () => []).add(item);
    }
    // 组内 createdAt DESC 已由 getAllTagRows 保证，这里不重排

    return Column(
      children: [
        _buildHeader(),
        _buildFilterBar(),
        const Divider(height: 1),
        Expanded(child: _buildList(byType)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🏷️ 标记汇总',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('全部', widget.items.length, 'all'),
            const SizedBox(width: 8),
            _filterChip('自定义', _countOf('custom'), 'custom'),
            const SizedBox(width: 8),
            _filterChip('高亮', _countOf('highlight'), 'highlight'),
            const SizedBox(width: 8),
            _filterChip('批注', _countOf('annotation'), 'annotation'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int count, String value) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: _filter == value,
      onSelected: (sel) {
        if (sel) setState(() => _filter = value);
      },
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildList(Map<String, List<MarkSummaryItem>> byType) {
    final children = <Widget>[];

    void addGroup(String type, String title) {
      final list = byType[type] ?? [];
      if (list.isEmpty) return;
      children.add(_buildGroupHeader(title, list.length));
      children.addAll(list.map(_buildItem));
    }

    addGroup('custom', '自定义标记');
    addGroup('highlight', '高亮');
    addGroup('annotation', '批注');

    if (children.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('无匹配结果', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        '$title ($count)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildItem(MarkSummaryItem item) {
    final (IconData icon, Color color, String label) = switch (item.type) {
      'custom' => (Icons.label, Colors.purple, item.tag),
      'highlight' => (Icons.highlight, Colors.amber, '高亮'),
      'annotation' => (Icons.chat_bubble_outline, Colors.teal, '批注'),
      _ => (Icons.label_outline, Colors.grey, '标记'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.text.isNotEmpty)
              Text(
                item.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              '来自：${item.sourceTitle}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        onTap: () => widget.onTap(item),
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('还没有任何标记', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(
                    '在阅读器中划线 / 写想法，或在笔记编辑页点 ⭐ / ❓',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}