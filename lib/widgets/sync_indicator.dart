// lib/widgets/sync_indicator.dart
// 同步状态指示器

import 'package:flutter/material.dart';
import '../services/sync_manager.dart';

class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  final SyncManager _syncManager = SyncManager();

  @override
  void initState() {
    super.initState();
    _syncManager.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    _syncManager.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_syncManager.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
            const Text(
              '同步中...',
              style: TextStyle(fontSize: 11, color: Colors.blue),
            ),
          ],
        ),
      );
    }

    if (_syncManager.lastSyncTime != null) {
      final timeAgo = _timeAgo(_syncManager.lastSyncTime!);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '☁️ $timeAgo',
          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '刚刚同步';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前同步';
    if (diff.inHours < 24) return '${diff.inHours}小时前同步';
    return '${diff.inDays}天前同步';
  }
}