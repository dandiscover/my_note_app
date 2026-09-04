// lib/models/note.dart
// 笔记模型 — 标准格式（不处理脏数据）
// ✅ 新增：inquiryQuestion（探究问题）
// ✅ 新增：newUnderstanding（新理解）
// ✅ 新增：exploreTasks（多任务探究列表）
// ✅ 移除：scaffoldSessions（迁移到 ExploreTask）
// ✅ 移除：subtasks（迁移到 ExploreTask）
// ✅ 移除：NoteSubtask（抽离到 note_subtask.dart）

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
  final String? newUnderstanding;
  final List<ExploreTask> exploreTasks;

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
    this.newUnderstanding,
    this.exploreTasks = const [],
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
    newUnderstanding: null,
    exploreTasks: const [],
  );

  factory NotebookEntry.fromMap(Map<String, dynamic> map) {
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
      newUnderstanding: map['newUnderstanding'] as String?,
      exploreTasks: (map['exploreTasks'] as List?)
          ?.map((e) => ExploreTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
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
      'newUnderstanding': newUnderstanding,
      'exploreTasks': exploreTasks.map((e) => e.toJson()).toList(),
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
    String? inquiryQuestion,
    String? newUnderstanding,
    List<ExploreTask>? exploreTasks,
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
      inquiryQuestion: inquiryQuestion ?? this.inquiryQuestion,
      newUnderstanding: newUnderstanding ?? this.newUnderstanding,
      exploreTasks: exploreTasks ?? this.exploreTasks,
    );
  }
}