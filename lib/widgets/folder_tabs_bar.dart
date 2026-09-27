// lib/widgets/folder_tabs_bar.dart
// 文件夹标签条 —— 同级文件夹切换

import 'package:flutter/material.dart';
import '../models/node.dart';

class FolderTabsBar extends StatelessWidget {
  final List<Node> siblings;
  final String? currentFolderId;
  final void Function(String?) onFolderTap;

  const FolderTabsBar({
    super.key,
    required this.siblings,
    required this.currentFolderId,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    if (siblings.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 36,
      color: Colors.grey.shade50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: siblings.length,
        itemBuilder: (ctx, i) {
          final node = siblings[i];
          final isActive = node.id == currentFolderId;
          return GestureDetector(
            onTap: () => onFolderTap(node.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue.shade50 : null,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                node.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}