// lib/widgets/spark_dialog.dart
// B8 · 火花卡编辑框

import 'package:flutter/material.dart';

class SparkDialogResult {
  final String action; // 'save_card' | 'stash' | 'send'
  final String content;
  const SparkDialogResult({required this.action, required this.content});
}

class SparkDialog extends StatefulWidget {
  final String? initialContent;

  const SparkDialog({super.key, this.initialContent});

  @override
  State<SparkDialog> createState() => _SparkDialogState();
}

class _SparkDialogState extends State<SparkDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.initialContent;
    if (t != null && t.isNotEmpty) {
      _ctrl.text = t;
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _done(String action) {
    Navigator.pop(
      context,
      SparkDialogResult(action: action, content: _ctrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💫 火花卡',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '写下此刻冒出的想法...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _done('save_card'),
                  child: const Text('存卡片库'),
                ),
                TextButton(
                  onPressed: () => _done('stash'),
                  child: const Text('暂存'),
                ),
                TextButton(
                  onPressed: () => _done('send'),
                  child: const Text('发送到光标'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}