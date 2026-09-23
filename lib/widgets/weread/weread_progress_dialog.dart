// lib/widgets/weread/weread_progress_dialog.dart
// 导入进度——两段（local / cloud）——不可取消
import 'package:flutter/material.dart';

class WereadProgress {
  final String phase;
  final int cur;
  final int total;
  final String label;
  const WereadProgress({
    required this.phase,
    required this.cur,
    required this.total,
    required this.label,
  });
}

class WereadProgressDialog extends StatelessWidget {
  final ValueNotifier<WereadProgress> notifier;
  const WereadProgressDialog({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('正在导入'),
      content: ValueListenableBuilder<WereadProgress>(
        valueListenable: notifier,
        builder: (_, p, __) {
          final denom = p.total == 0 ? 1 : p.total;
          final v = (p.cur / denom).clamp(0.0, 1.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: v),
              const SizedBox(height: 12),
              Text(p.phase == 'cloud' ? '☁ 云端同步中' : '📥 正在写入本地'),
              const SizedBox(height: 4),
              Text(
                '${p.label}（${p.cur}/${p.total}）',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          );
        },
      ),
    );
  }
}