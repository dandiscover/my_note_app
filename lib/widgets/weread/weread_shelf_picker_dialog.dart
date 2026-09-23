// lib/widgets/weread/weread_shelf_picker_dialog.dart
// 书架选书 + 「同时生成卡片」勾选 + 「修改 Key」按钮
import 'package:flutter/material.dart';
import 'weread_key_guide_dialog.dart';

class WereadPickResult {
  final List<String> bookIds;
  final bool alsoGenerateCards;
  final bool keyChanged;   // 用户在选择页内改了 Key
  const WereadPickResult({
    required this.bookIds,
    required this.alsoGenerateCards,
    this.keyChanged = false,
  });
}

class WereadShelfPickerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> shelf;
  const WereadShelfPickerDialog({super.key, required this.shelf});

  @override
  State<WereadShelfPickerDialog> createState() =>
      _WereadShelfPickerDialogState();
}

class _WereadShelfPickerDialogState extends State<WereadShelfPickerDialog> {
  final Set<String> _selected = {};
  bool _alsoGenerateCards = false;

  void _toggleAll(bool? v) {
    setState(() {
      if (v == true) {
        _selected.addAll(
          widget.shelf
              .map((b) => (b['bookId'] as String?) ?? '')
              .where((id) => id.isNotEmpty),
        );
      } else {
        _selected.clear();
      }
    });
  }

  Future<void> _changeKey() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const WereadKeyGuideDialog(),
    );
    if (ok == true && mounted) {
      Navigator.pop(
        context,
        const WereadPickResult(
          bookIds: [],
          alsoGenerateCards: false,
          keyChanged: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        widget.shelf.isNotEmpty && _selected.length == widget.shelf.length;
    return AlertDialog(
      title: const Text('选择要导入的书'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(value: allSelected, onChanged: _toggleAll),
                const Text('全选'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _changeKey,
                  icon: const Icon(Icons.key, size: 16),
                  label: const Text('修改 Key'),
                ),
              ],
            ),
            CheckboxListTile(
              value: _alsoGenerateCards,
              onChanged: (v) =>
                  setState(() => _alsoGenerateCards = v ?? false),
              title: const Text('同时生成卡片（高亮进卡片盒）'),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.shelf.length,
                itemBuilder: (ctx, i) {
                  final b = widget.shelf[i];
                  final id = (b['bookId'] as String?) ?? '';
                  if (id.isEmpty) return const SizedBox.shrink();
                  return CheckboxListTile(
                    value: _selected.contains(id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(id);
                        } else {
                          _selected.remove(id);
                        }
                      });
                    },
                    title: Text(
                      (b['title'] as String?) ?? '(无标题)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      (b['author'] as String?) ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: (b['cover'] as String?)?.isNotEmpty == true
                        ? Image.network(
                            b['cover'] as String,
                            width: 32,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 32, height: 44),
                          )
                        : null,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    WereadPickResult(
                      bookIds: _selected.toList(),
                      alsoGenerateCards: _alsoGenerateCards,
                    ),
                  ),
          child: Text('导入 (${_selected.length})'),
        ),
      ],
    );
  }
}