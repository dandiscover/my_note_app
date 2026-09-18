// lib/widgets/quick_switch_dialog.dart
// 功能批1 C：快速切换笔记——Ctrl+P / AppBar 搜索

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/app_string_utils.dart';

class QuickSwitchDialog extends StatefulWidget {
  final List<NotebookEntry> notes;
  final void Function(NotebookEntry) onSelect;

  const QuickSwitchDialog({
    super.key,
    required this.notes,
    required this.onSelect,
  });

  @override
  State<QuickSwitchDialog> createState() => _QuickSwitchDialogState();
}

class _QuickSwitchDialogState extends State<QuickSwitchDialog> {
  String _keyword = '';

  List<NotebookEntry> _filtered() {
    if (_keyword.isEmpty) return widget.notes;
    final kw = _keyword.toLowerCase();
    return widget.notes.where((n) {
      final t = AppStringUtils.displayNoteTitle(n.title, n.content);
      return t.toLowerCase().contains(kw) ||
          n.content.toLowerCase().contains(kw);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _keyword = v),
                onSubmitted: (_) {
                  if (filtered.isNotEmpty) {
                    widget.onSelect(filtered.first);
                  }
                },
                decoration: InputDecoration(
                  hintText: '🔍 搜索笔记...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  isDense: true,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('无匹配'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final note = filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            AppStringUtils.displayNoteTitle(
                                note.title, note.content),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => widget.onSelect(note),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}