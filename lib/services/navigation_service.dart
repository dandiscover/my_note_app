
import 'package:flutter/material.dart';
import '../database_service.dart';
import '../pages/epub_reader_page.dart';
import '../pages/richtext_editor_page.dart';
import '../models/book_note.dart';
import '../models/note.dart';

class NavigationService {
  // 打开书；可传 initialJumpNote / initialLocation 定位
  static Future<void> openBook(
    BuildContext context,
    String bookId, {
    BookNote? initialJumpNote,
    String? initialLocation,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpubReaderPage(
          bookId: bookId,
          initialJumpNote: initialJumpNote,
          initialLocation: initialLocation,
        ),
      ),
    );
  }

  // 打开笔记：核不到单条查询方法，抛 UnimplementedError 占位
  static Future<void> openNote(BuildContext context, String noteId) async {
    // 未闭合：DatabaseService 无 getNoteById(noteId)；getAllNotes 全表查性能差，留后批新增。
    throw UnimplementedError('NavigationService.openNote 未闭合：等待 DatabaseService 新增 getNoteById');
  }

  // 打开卡片：无统一卡片详情页，回退弹窗；front/back 可空，必须判空
  static Future<void> openCard(
    BuildContext context,
    Map<String, dynamic> cardMap,
  ) async {
    final front = (cardMap['front'] as String?) ?? '';
    final back = (cardMap['back'] as String?) ?? '';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('卡片'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (front.isNotEmpty)
                Text(front, style: const TextStyle(fontSize: 15)),
              if (back.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('💭 我的想法：',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(back),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}