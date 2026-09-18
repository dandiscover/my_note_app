import 'package:flutter/material.dart';
import 'editor_kernel.dart';

/// 工作台外壳——D 批块 3
///
/// 职责三条：
/// 1. 吃一个 EditorKernel 实例
/// 2. 生命周期内接管焦点（initState → focus / dispose → blur）
/// 3. build 转发给 kernel——外壳不持编辑器状态，状态在内核里
///
/// 设计约束：内核必须 `extends EditorKernel`（静态字段不被 implements 继承）
class Workbench extends StatefulWidget {
  final EditorKernel kernel;

  const Workbench({
    super.key,
    required this.kernel,
  });

  @override
  State<Workbench> createState() => _WorkbenchState();
}

class _WorkbenchState extends State<Workbench> {
  @override
  void initState() {
    super.initState();
    EditorKernel.focus(widget.kernel);
  }

  @override
  void didUpdateWidget(Workbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kernel != widget.kernel) {
      EditorKernel.focus(widget.kernel);
    }
  }

  @override
  void dispose() {
    if (EditorKernel.active == widget.kernel) {
      EditorKernel.blur();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.kernel.build(context);
  }
}