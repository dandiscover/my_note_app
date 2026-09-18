import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../utils/app_string_utils.dart';

/// 标题栏——工作台零件 · 丁方案
class EditorTitleBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const EditorTitleBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        labelText: '标题',
        border: InputBorder.none,
      ),
      onChanged: (_) {
        onChanged?.call();
      },
    );
  }
}