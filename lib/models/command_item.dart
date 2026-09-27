// lib/models/command_item.dart
// 命令面板项 —— 笔记之外的动作

import 'package:flutter/material.dart';

class CommandItem {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onExecute;
  final String? shortcutLabel;   // 桌面显，移动不显

  const CommandItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.onExecute,
    this.shortcutLabel,
  });
}