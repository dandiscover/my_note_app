import 'package:flutter/material.dart';
import '../../models/note.dart';
import 'editor_kernel.dart';

/// 工作台外壳——D 批块 3（块 5a 扩 entry 更新链路）
///
/// 职责：
/// 1. 吃一个 EditorKernel 实例 + 当前 entry
/// 2. 生命周期内接管焦点（initState → focus / dispose → blur）
/// 3. entry 变化时通知 kernel.updateEntry
/// 4. build 转发给 kernel
///
/// 设计约束：内核必须 `extends EditorKernel`（静态字段不被 implements 继承）
class Workbench extends StatefulWidget {
  final EditorKernel kernel;
  final NotebookEntry entry;

  const Workbench({
    super.key,
    required this.kernel,
    required this.entry,
  });

  @override
  State<Workbench> createState() => _WorkbenchState();
}

class _WorkbenchState extends State<Workbench> {
  @override
  void initState() {
    super.initState();
    // 批：焦点归属——Workbench 不介入焦点（由页面 owner set/clear）
  }

  @override
  void didUpdateWidget(Workbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 批：焦点归属——Workbench 不介入焦点
    if (oldWidget.entry != widget.entry) {
      widget.kernel.updateEntry(widget.entry);
    }
  }

  @override
  void dispose() {
    // 批：焦点归属——条件清移交页面 owner
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.kernel.build(context);
  }
}