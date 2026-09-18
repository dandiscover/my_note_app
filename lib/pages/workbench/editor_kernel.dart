import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/explore_task.dart';

/// 保存回调——7 参数，返回 Future<bool>
/// 对齐 FullscreenEditor.onSave 实际签名（fullscreen_editor.dart:27-35）
typedef SaveCallback = Future<bool> Function(
  NotebookEntry entry,
  String title,
  String content,
  String editorMode,
  List<String> tags,
  String? inquiryQuestion,
  List<ExploreTask> exploreTasks,
);

/// 内核上下文——字段对齐 FullscreenEditor 全部 final 字段
/// （fullscreen_editor.dart:25-40）
/// D批块5a：entry 去 final（Workbench.didUpdateWidget 可改）
class EditorContext {
  NotebookEntry entry;
  final bool isFromCollection;
  final SaveCallback onSave;
  final bool isSaving;
  final String? exploreTaskId;
  final Function(String)? onAddSubtask;
  final void Function(String question)? onInquiryConfirmed;

  // D批块5a：去 const（entry 非 final）
  EditorContext({
    required this.entry,
    this.isFromCollection = false,
    required this.onSave,
    this.isSaving = false,
    this.exploreTaskId,
    this.onAddSubtask,
    this.onInquiryConfirmed,
  });
}

/// 编辑器内核抽象——实例接口 + 静态焦点管理
///
/// ⚠️ 设计约束：内核必须 `extends EditorKernel`，不得 `implements`
///    原因：静态字段 _active 不被 implements 继承
abstract class EditorKernel {
  // ── 实例接口 ──
  String get id;
  EditorContext get ctx;
  Widget build(BuildContext context);
  Future<bool> save();
  void insertText(String text);

  /// 上下文 entry 更新通知——Workbench.didUpdateWidget 调用
  /// 空默认实现：子类可选覆盖。RichtextKernel 暂不覆盖（债，块 5b）
  void updateEntry(NotebookEntry entry) {}

  // ── 静态焦点管理（复用 FullscreenEditor 模式）──
  static EditorKernel? _active;

  static EditorKernel? get active => _active;
  static bool get isActive => _active != null;

  static void focus(EditorKernel k) => _active = k;
  static void blur() => _active = null;

  static Future<bool> triggerSave() async => await _active?.save() ?? false;
  static void insertTextGlobal(String text) => _active?.insertText(text);
}