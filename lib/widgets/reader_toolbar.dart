// lib/widgets/reader_toolbar.dart
// 阅读器通用工具栏

import 'package:flutter/material.dart';

class ReaderToolbar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onSaveProgress;
  final VoidCallback onAddNote;
  final VoidCallback onBack;

  const ReaderToolbar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onSaveProgress,
    required this.onAddNote,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey.shade900,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
            tooltip: '返回',
          ),
          Expanded(
            child: Text(
              '第 $currentPage / $totalPages 页',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.note_add, color: Colors.white70),
            onPressed: onAddNote,
            tooltip: '添加笔记',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white70),
            onPressed: onSaveProgress,
            tooltip: '保存进度',
          ),
        ],
      ),
    );
  }
}