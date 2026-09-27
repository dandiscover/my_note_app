// lib/services/note_opener.dart
// 笔记打开统一入口 —— 13 处归一
// A2 标签条落时 —— 只改本文件内部

import 'package:flutter/material.dart';
import '../models/note.dart';
import '../pages/note_detail_page.dart';

class NoteOpener {
  NoteOpener._();

  /// 打开 / 新建笔记
  ///
  /// [replace] = true 时走 pushReplacement（唯一调用点 note_detail_page:1427）
  /// 返回：路由 pop 时的值（笔记页 return true / false / null）
  static Future<bool?> open({
    required BuildContext context,
    required NotebookEntry entry,
    String? nodeId,
    String? currentNodeId,
    bool isFromCollection = false,
    bool isNew = false,
    bool shouldPopOnSave = false,
    bool syncToCloud = false,
    bool initInEditMode = false,
    bool replace = false,
  }) async {
    final route = MaterialPageRoute<bool>(
      builder: (_) => NoteDetailPage(
        entry: entry,
        nodeId: nodeId,
        currentNodeId: currentNodeId,
        isFromCollection: isFromCollection,
        isNew: isNew,
        shouldPopOnSave: shouldPopOnSave,
        syncToCloud: syncToCloud,
        initInEditMode: initInEditMode,
      ),
    );
    if (replace) {
      return Navigator.pushReplacement<bool, dynamic>(context, route);
    }
    return Navigator.push<bool>(context, route);
  }
}