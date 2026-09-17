// lib/widgets/wisdom/epub_reorder_dialog.dart
// 多篇导出设置对话框 — 标题输入 + 拖拽排序（一步完成）
// 依据：第五轮方案 v6 §5.7（老白裁定 1：合并对话框）
// v9 修正：onReorder → onReorderItem（Flutter 3.41+）

import 'package:flutter/material.dart';

/// 排序项（与 Node 解耦，id = note.id）
class EpubReorderItem {
  /// = NotebookEntry.id（不是 node.id）
  /// 依据：EpubExporter.exportBook 入参是 List<NotebookEntry>
  final String id;
  final String title;
  const EpubReorderItem({required this.id, required this.title});
}

/// 导出设置结果（标题 + 排序后列表）
class EpubExportSettings {
  final String title;
  final List<EpubReorderItem> items;
  const EpubExportSettings({required this.title, required this.items});
}

/// 多篇导出设置对话框
class EpubReorderDialog extends StatefulWidget {
  final List<EpubReorderItem> items;
  final String defaultTitle;
  const EpubReorderDialog({
    super.key,
    required this.items,
    required this.defaultTitle,
  });

  @override
  State<EpubReorderDialog> createState() => _EpubReorderDialogState();
}

class _EpubReorderDialogState extends State<EpubReorderDialog> {
  late List<EpubReorderItem> _items;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _items = List<EpubReorderItem>.from(widget.items);
    _titleController = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出设置'),
      content: SizedBox(
        width: 400,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 标题输入（上方）
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '书名',
                hintText: '合并导出',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: false,
            ),
            const SizedBox(height: 12),
            // 2. 拖拽提示
            Text(
              '拖拽调整章节顺序（共 ${_items.length} 章）',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            // 3. 拖拽列表（下方）
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ReorderableListView.builder(
                  itemCount: _items.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      // v9: onReorderItem 已自动调整 newIndex，不再手动减 1
                      final item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final displayTitle = item.title.isEmpty
                        ? '第 ${index + 1} 章'
                        : item.title;
                    return ListTile(
                      key: ValueKey(item.id),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(displayTitle),
                      dense: true,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            Navigator.pop(
              context,
              EpubExportSettings(
                title: title.isEmpty ? widget.defaultTitle : title,
                items: _items,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}