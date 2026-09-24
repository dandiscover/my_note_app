import 'package:flutter/material.dart';
import '../../models/note.dart';

/// 编辑器顶栏——工作台零件 · 丁方案第 3 步
///
/// 回调全 optional——壳自选显哪些
/// 布局切换 / 侧栏切换 / 专注——也归此零件，但由壳传回调
class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isReadMode;
  final bool isRichtext;

  // 主按钮回调（全 optional——null = 不显示）
  final VoidCallback? onInquiry;          // 深入
  final VoidCallback onToggleMode;         // 阅读/编辑切换
  final VoidCallback onCard;               // 生成卡片
  final VoidCallback? onQuickSwitch;       // 快速切换
  final VoidCallback? onOpenMultiPane;     // 并排打开（新）
  final VoidCallback? onCycleLayout;       // 布局切换
  final IconData? layoutIcon;
  final String? layoutLabel;
  final VoidCallback? onToggleSidebar;     // 侧栏切换（双栏）
  final IconData? sidebarIcon;
  final String? sidebarLabel;
  final VoidCallback? onToggleFocus;       // 专注
  final bool isFocusMode;
  final VoidCallback? onToggleMaterial;    // 素材库（单栏）
  final VoidCallback? onFileTree;          // 文件树
  final VoidCallback? onToggleOutline;     // 大纲面板
  final bool isOutlineOpen;
  // onToggleMap / isMapOpen 已撤 —— 导图切换在正文区

  const EditorAppBar({
    super.key,
    required this.title,
    required this.isReadMode,
    this.isRichtext = false,
    this.onInquiry,
    required this.onToggleMode,
    required this.onCard,
    this.onQuickSwitch,
    this.onOpenMultiPane,
    this.onCycleLayout,
    this.layoutIcon,
    this.layoutLabel,
    this.onToggleSidebar,
    this.sidebarIcon,
    this.sidebarLabel,
    this.onToggleFocus,
    this.isFocusMode = false,
    this.onToggleMaterial,
    this.onFileTree,
    this.onToggleOutline,
    this.isOutlineOpen = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      actions: [
        if (onInquiry != null)
          IconButton(
            icon: const Icon(Icons.explore, color: Colors.purple),
            tooltip: '深入',
            onPressed: onInquiry,
          ),
        IconButton(
          icon: Icon(isReadMode ? Icons.edit : Icons.remove_red_eye),
          tooltip: isRichtext
              ? '编辑'
              : (isReadMode ? '切换到修改模式' : '切换到阅读模式'),
          onPressed: onToggleMode,
        ),
        IconButton(
          icon: const Icon(Icons.credit_card),
          tooltip: '生成卡片',
          onPressed: onCard,
        ),
        if (onQuickSwitch != null)
          if (onToggleOutline != null && !isReadMode)
            IconButton(
              icon: Icon(
                isOutlineOpen ? Icons.list_alt : Icons.list_alt_outlined,
                color: isOutlineOpen ? Colors.blue : null,
              ),
              tooltip: '大纲',
              onPressed: onToggleOutline,
            ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '快速切换笔记',
            onPressed: onQuickSwitch,
          ),
                  if (onOpenMultiPane != null)
          IconButton(
            icon: const Icon(Icons.view_column_outlined),
            tooltip: '并排打开',
            onPressed: onOpenMultiPane,
          ),
        if (onCycleLayout != null && !isReadMode)
          IconButton(
            icon: Icon(layoutIcon ?? Icons.crop_square),
            tooltip: layoutLabel ?? '布局',
            onPressed: onCycleLayout,
          ),
        if (onToggleSidebar != null && !isReadMode)
          IconButton(
            icon: Icon(sidebarIcon ?? Icons.folder_open),
            tooltip: sidebarLabel ?? '切换侧栏',
            onPressed: onToggleSidebar,
          ),
        if (onToggleFocus != null)
          IconButton(
            icon: Icon(isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: isFocusMode ? '退出专注' : '专注模式',
            onPressed: onToggleFocus,
          ),        
          if (onToggleFocus != null)
        if (onToggleMaterial != null && !isReadMode)
          IconButton(
            icon: const Icon(Icons.library_books, color: Colors.purple),
            tooltip: '素材库',
            onPressed: onToggleMaterial,
          ),
        if (onFileTree != null)
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '文件树',
            onPressed: onFileTree,
          ),
      ],
    );
  }
}