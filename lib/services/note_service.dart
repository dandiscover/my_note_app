// lib/services/note_service.dart
// 笔记整理服务 — 从 note_detail_page._saveNote 抽出的公共落库逻辑
// 依据：改造批 A 方案 v7 §四
//
// 副作用（唯一入口）：
//   - updateNote(status: 'active')
//   - 若未挂节点 → attachNoteToNode(parentId: targetFolderId)
//   - 写 last_organized_at
//
// 不负责：UI 提示（floatingPetKey.showMessage）—— 归调用方

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database_service.dart';
import '../models/note.dart';
import '../utils/app_string_utils.dart';

class NoteService {
  final DatabaseService _db = DatabaseService();

  /// 整理 raw 笔记 → active
  ///
  /// 返回：成功 → updated NotebookEntry；失败 → null
  Future<NotebookEntry?> organizeRawNote({
    required NotebookEntry entry,
    required String title,
    required String content,
    required String editorMode,
    required List<String> tags,
    String? targetFolderId,
  }) async {
    try {
      final updated = NotebookEntry(
        id: entry.id,
        title: title.isEmpty ? '无标题' : title,
        content: content.isEmpty ? '暂无内容' : content,
        updatedAt: DateTime.now(),
        status: 'active',
        editorMode: editorMode,
        tags: tags,
        isLocked: entry.isLocked,
        inquiryQuestion: entry.inquiryQuestion,
        inquiryConclusion: entry.inquiryConclusion,
        exploreTasks: entry.exploreTasks,
        contentFormat: entry.contentFormat,
      );

      await _db.updateNote(updated.toMap());

      // 挂节点：先查存在性，不存在才挂（防重复）
      final existingNodes = await _db.getAllNodes();
      final alreadyHasNode = existingNodes.any(
        (n) => n.targetId == entry.id && n.nodeType == 'note',
      );
      // ✅ 改造批 A · 标题系统：node.title = 显示值
      final nodeDisplayTitle = AppStringUtils.displayNoteTitle(
        updated.title,
        updated.content,
      );
      if (!alreadyHasNode) {
        await _db.attachNoteToNode(
          noteId: entry.id,
          title: nodeDisplayTitle,
          parentId: targetFolderId,
          tags: tags,
        );
      } else {
        // ✅ 老白裁 #22：else 分支同步 title + tags
        final existingNode = existingNodes.firstWhere(
          (n) => n.targetId == entry.id && n.nodeType == 'note',
        );
        await _db.updateNode(existingNode.copyWith(
          title: nodeDisplayTitle,
          tags: tags,
        ));
      }

      // last_organized_at 无条件写
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_organized_at',
        DateTime.now().toIso8601String(),
      );

      return updated;
    } catch (e) {
      debugPrint('organizeRawNote 失败: $e');
      return null;
    }
  }
}