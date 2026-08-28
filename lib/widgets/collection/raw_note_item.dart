// lib/widgets/collection/raw_note_item.dart
// 采集页 - 待整理列表项（含锁定按钮 + 过期指示）

import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../utils/app_string_utils.dart';

class RawNoteItem extends StatelessWidget {
  final NotebookEntry note;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onLockToggle;
  final bool isLocked;
  final bool showExpiryIndicator;
  final int expiryDays;

  const RawNoteItem({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onArchive,
    required this.onLockToggle,
    this.isLocked = false,
    this.showExpiryIndicator = false,
    this.expiryDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 锁定笔记排在最前面
    final isLockedNote = isLocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // 锁定笔记高亮边框
          border: isLockedNote
              ? Border.all(color: Colors.blue.shade300, width: 1.5)
              : null,
        ),
        child: ListTile(
          leading: Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: isLockedNote
                  ? Colors.blue.shade500
                  : (showExpiryIndicator ? Colors.amber : Colors.orange),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          title: Row(
            children: [
              if (isLockedNote)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.blue.shade500,
                  ),
                ),
              if (showExpiryIndicator)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: Colors.amber.shade700,
                  ),
                ),
              Expanded(
                child: Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: isLockedNote ? FontWeight.w600 : FontWeight.w500,
                    color: showExpiryIndicator ? Colors.amber.shade900 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showExpiryIndicator)
                Text(
                  '${expiryDays}d',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.amber.shade700,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            AppStringUtils.truncate(note.content, 50),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: showExpiryIndicator ? Colors.amber.shade800 : Colors.grey.shade600,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 锁定按钮
              Tooltip(
                message: isLockedNote ? '解锁 (已锁定)' : '锁定 (不受过期影响)',
                child: IconButton(
                  icon: Icon(
                    isLockedNote ? Icons.lock : Icons.lock_outline,
                    size: 18,
                    color: isLockedNote ? Colors.blue.shade500 : Colors.grey.shade400,
                  ),
                  onPressed: onLockToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined, size: 20, color: Colors.grey),
                onPressed: onArchive,
                tooltip: '直接归档',
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20, color: Colors.blue),
                onPressed: onEdit,
                tooltip: '整理',
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}