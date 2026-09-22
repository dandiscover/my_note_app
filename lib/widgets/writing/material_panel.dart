// lib/widgets/writing/material_panel.dart
// 写作素材面板 — 搜索 + 筛选 + 排序 + 插入 + 拖拽
// E批：接 MaterialItem（卡片 + 笔记两源）
// 功能批1 C：加 Draggable
// 1c-redo-甲：按 layer 分段渲染（priority / structure / library）

import 'package:flutter/material.dart';
import '../../models/card.dart';
import '../../models/note.dart';
import '../../models/material_item.dart';
import '../../services/material_service.dart';
import '../../pages/wisdom_page.dart';

class MaterialPanel extends StatefulWidget {
  final List<MaterialItem> items;
  final Function(CardModel) onInsertCard;
  final Function(NotebookEntry) onInsertNote;
  final bool enabled;   // 批 3：false = 卡片不可点（多栏无笔记栏时）

  const MaterialPanel({
    super.key,
    required this.items,
    required this.onInsertCard,
    required this.onInsertNote,
    this.enabled = true,
  });

  @override
  State<MaterialPanel> createState() => _MaterialPanelState();
}

/// 面板行（sealed——分段渲染用）
sealed class _PanelRow {
  const _PanelRow();
}

class _PanelHeader extends _PanelRow {
  final String label;
  const _PanelHeader(this.label);
}

class _PanelItem extends _PanelRow {
  final MaterialItem item;
  const _PanelItem(this.item);
}

class _PanelDivider extends _PanelRow {
  const _PanelDivider();
}

class _MaterialPanelState extends State<MaterialPanel> {
  String _keyword = '';
  MaterialItemType? _typeFilter;
  MaterialSortKey _sortKey = MaterialSortKey.timeDesc;

  List<MaterialItem> _filtered() {
    var list = List<MaterialItem>.from(widget.items);

    if (_typeFilter != null) {
      list = list.where((i) => i.type == _typeFilter).toList();
    }

    if (_keyword.isNotEmpty) {
      final kw = _keyword.toLowerCase();
      list = list.where((i) =>
        i.title.toLowerCase().contains(kw) ||
        i.summary.toLowerCase().contains(kw) ||
        i.tags.any((t) => t.toLowerCase().contains(kw))
      ).toList();
    }

    return list;
  }

  /// 按 _sortKey 段内排序
  void _sortInPlace(List<MaterialItem> list) {
    switch (_sortKey) {
      case MaterialSortKey.timeDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case MaterialSortKey.timeAsc:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case MaterialSortKey.titleAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case MaterialSortKey.tagCount:
        list.sort((a, b) => b.tags.length.compareTo(a.tags.length));
        break;
    }
  }

  /// 按 layer 分三段，段内排序，摊平成行
  ///
  /// 规则：
  ///  - 段空 → 不显示
  ///  - 只有一段非空 → 不显示段头 + 不显示分隔线
  ///  - 段序：priority → structure → library
  List<_PanelRow> _rows(List<MaterialItem> filtered) {
    final byLayer = <MaterialLayer, List<MaterialItem>>{
      MaterialLayer.priority: [],
      MaterialLayer.structure: [],
      MaterialLayer.library: [],
    };
    for (final item in filtered) {
      byLayer[item.layer]!.add(item);
    }

    final nonEmptyLayers = <MaterialLayer>[
      MaterialLayer.priority,
      MaterialLayer.structure,
      MaterialLayer.library,
    ].where((l) => byLayer[l]!.isNotEmpty).toList();

    // 每段内排序
    for (final l in nonEmptyLayers) {
      _sortInPlace(byLayer[l]!);
    }

    final showLabels = nonEmptyLayers.length > 1;

    final rows = <_PanelRow>[];
    for (var i = 0; i < nonEmptyLayers.length; i++) {
      final layer = nonEmptyLayers[i];
      if (i > 0) rows.add(const _PanelDivider());
      if (showLabels) rows.add(_PanelHeader(_labelFor(layer)));
      for (final item in byLayer[layer]!) {
        rows.add(_PanelItem(item));
      }
    }
    return rows;
  }

  String _labelFor(MaterialLayer layer) {
    switch (layer) {
      case MaterialLayer.priority:
        return '🔥 相关';
      case MaterialLayer.structure:
        return '📁 同文件夹';
      case MaterialLayer.library:
        return '📚 库';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final rows = _rows(filtered);

    return _wrapEnabled(Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text('📚 素材库',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => setState(() => _keyword = v),
              decoration: InputDecoration(
                hintText: '🔍 搜索素材...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _chip('全部', null),
                const SizedBox(width: 4),
                _chip('卡片', MaterialItemType.card),
                const SizedBox(width: 4),
                _chip('笔记', MaterialItemType.note),
                const Spacer(),
                PopupMenuButton<MaterialSortKey>(
                  icon: const Icon(Icons.sort, size: 18),
                  tooltip: '排序',
                  onSelected: (k) => setState(() => _sortKey = k),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: MaterialSortKey.timeDesc, child: Text('时间倒序')),
                    PopupMenuItem(
                        value: MaterialSortKey.timeAsc, child: Text('时间正序')),
                    PopupMenuItem(
                        value: MaterialSortKey.titleAsc, child: Text('标题')),
                    PopupMenuItem(
                        value: MaterialSortKey.tagCount, child: Text('标签数')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          widget.items.isEmpty ? '暂无素材' : '无匹配结果',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.items.isEmpty
                              ? '在智库中创建笔记或卡片后，可在此调用'
                              : '试试调整搜索或筛选条件',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final r = rows[index];
                      return switch (r) {
                        _PanelHeader(:final label) => _buildHeader(label),
                        _PanelItem(:final item) => _buildMaterialItem(item),
                        _PanelDivider() => const Divider(height: 1),
                      };
                    },
                                    ),
          ),
          _buildMoreFooter(),
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
    ));
  }
  /// 批 3：enabled=false → 卡片不可点 + 灰化
  Widget _wrapEnabled(Widget child) {
    if (widget.enabled) return child;
    return IgnorePointer(
      ignoring: true,
      child: Opacity(opacity: 0.5, child: child),
    );
  }
  /// 素材数据源扩展——library 段被截时显「还有更多」
  /// 说明：靠「library 段条数 == quotaLibrary」推断被截——不精确（15==15 会误显）
  /// 记债：改 record 返回可得精确 N——归后续轮
  Widget _buildMoreFooter() {
    final libraryCount = widget.items
        .where((i) => i.layer == MaterialLayer.library)
        .length;
    if (libraryCount < MaterialService.quotaLibrary) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WisdomPage()),
            );
          },
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('还有更多 → 去智库看全部'),
        ),
      ),
    );
  }

  Widget _buildHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, MaterialItemType? type) {
    final selected = _typeFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.teal.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.teal.shade700 : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialItem(MaterialItem item) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Draggable<MaterialItem>(
            data: item,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Text(
                  item.title,
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                padding: const EdgeInsets.all(8),
                child: Text(item.title, style: const TextStyle(fontSize: 13)),
              ),
            ),
            child: GestureDetector(
              onTap: () {
                if (item.type == MaterialItemType.card && item.card != null) {
                  widget.onInsertCard(item.card!);
                } else if (item.type == MaterialItemType.note &&
                    item.note != null) {
                  widget.onInsertNote(item.note!);
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHovered ? Colors.teal.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isHovered ? Colors.teal.shade300 : Colors.grey.shade200,
                    width: isHovered ? 1.5 : 0.5,
                  ),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                              color: Colors.teal.withValues(alpha: 0.08),
                              blurRadius: 4)
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.type == MaterialItemType.card ? '📇' : '📝',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isHovered
                                  ? Colors.teal.shade700
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.sourceType == 'book' &&
                            item.card?.sourceTitle != null)
                          Text(
                            '📖 《${item.card!.sourceTitle}》',
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                    if (item.summary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.summary,
                          style: TextStyle(
                            fontSize: 12,
                            color: isHovered
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (item.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 4,
                          children: item.tags
                              .take(2)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _getTagColor(tag)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(tag,
                                        style: TextStyle(
                                            fontSize: 7,
                                            color: _getTagColor(tag))),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
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
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.deepPurple,
      Colors.red,
    ];
    return colors[hash % colors.length];
  }
}