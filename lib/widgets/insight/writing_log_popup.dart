// lib/widgets/insight/writing_log_popup.dart

import 'package:flutter/material.dart';
import '../../services/writing_session_service.dart';

class WritingLogPopup extends StatelessWidget {
  final VoidCallback onClose;
  const WritingLogPopup({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📓 写作日志',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: WritingSessionService().getDailyLogs(7),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 60,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final logs = snap.data!;
                if (logs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('还没有写作记录',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  );
                }
                return Column(
                  children: logs.map((log) {
                    final min = (log['duration'] as int) ~/ 60;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(log['date'] as String,
                              style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          Text('$min 分钟 · ${log['words']} 字',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}