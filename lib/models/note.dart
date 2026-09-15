// lib/models/note.dart
// 笔记模型 — 标准格式（不处理脏数据）
// ✅ 新增：inquiryQuestion（探究问题）
// ✅ 新增：inquiryConclusion（探究结论）
// ✅ 新增：exploreTasks（多任务探究列表）
// ✅ 新增：contentFormat（笔记内容格式）
// ✅ 移除：scaffoldSessions（迁移到 ExploreTask）
// ✅ 移除：subtasks（迁移到 ExploreTask）
// ✅ 移除：NoteSubtask（抽离到 note_subtask.dart）
// ✅ 修复：copyWith 哨兵方案，inquiryQuestion / inquiryConclusion 支持清空（BUG-001）
// ✅ T-177：fromMap 的 contentFormat 类型防御（脏数据不崩）

import 'note_subtask.dart';
import 'explore_task.dart';

class NotebookEntry {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final String status;
  final String editorMode;
  final List<String> tags;
  final bool isLocked;
  final String? inquiryQuestion;
  final String? inquiryConclusion;
  final List<ExploreTask> exploreTasks;

  /// 笔记内容格式：'markdown' / 'richtext'
  /// 默认 'markdown'，兼容现有笔记。
  final String contentFormat;

  /// copyWith 哨兵：区分“未传参”（保留旧值）与“显式传 null”（清空）
  static const Object _unset = Object();

  const NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.status = 'raw',
    this.editorMode = 'plain',
    this.tags = const [],
    this.isLocked = false,
    this.inquiryQuestion,
    this.inquiryConclusion,
    this.exploreTasks = const [],
    this.contentFormat = 'markdown',
  });

  static final NotebookEntry empty = NotebookEntry(
    id: '',
    title: '',
    content: '',
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    status: 'deleted',
    editorMode: 'plain',
    tags: const [],
    isLocked: false,
    inquiryQuestion: null,
    inquiryConclusion: null,
    exploreTasks: const [],
    contentFormat: 'markdown',
  );

  factory NotebookEntry.fromMap(Map<String, dynamic> map) {
    // 空字符串等同于缺省，一律回退 'markdown'
    // T-177：类型防御——脏数据（非 String）也回退，不崩
    final cfRaw = map['contentFormat'];
    final cf = (cfRaw is String && cfRaw.isNotEmpty) ? cfRaw : 'markdown';

    return NotebookEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      updatedAt: DateTime.parse(map['updatedAt']),
      status: map['status'] ?? 'raw',
      editorMode: map['editorMode'] ?? 'plain',
      tags: (map['tags'] as List?)?.cast<String>() ?? [],
      isLocked: (map['isLocked'] ?? 0) == 1,
      inquiryQuestion: map['inquiryQuestion'] as String?,
      inquiryConclusion: map['inquiryConclusion'] as String?,
      exploreTasks: (map['exploreTasks'] as List?)
          ?.map((e) => ExploreTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      contentFormat: cf,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'editorMode': editorMode,
      'isLocked': isLocked ? 1 : 0,
      'tags': tags,
      'inquiryQuestion': inquiryQuestion,
      'inquiryConclusion': inquiryConclusion,
      'exploreTasks': exploreTasks.map((e) => e.toJson()).toList(),
      'contentFormat': contentFormat,
    };
  }

  NotebookEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
    String? status,
    String? editorMode,
    List<String>? tags,
    bool? isLocked,
    Object? inquiryQuestion = _unset,
    Object? inquiryConclusion = _unset,
    List<ExploreTask>? exploreTasks,
    String? contentFormat,
  }) {
    return NotebookEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      editorMode: editorMode ?? this.editorMode,
      tags: tags ?? this.tags,
      isLocked: isLocked ?? this.isLocked,
      inquiryQuestion: identical(inquiryQuestion, _unset)
          ? this.inquiryQuestion
          : inquiryQuestion as String?,
      inquiryConclusion: identical(inquiryConclusion, _unset)
          ? this.inquiryConclusion
          : inquiryConclusion as String?,
      exploreTasks: exploreTasks ?? this.exploreTasks,
      contentFormat: contentFormat ?? this.contentFormat,
    );
  }
}