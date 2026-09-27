// lib/widgets/quick_switch_dialog.dart
// 命令面板 —— 搜笔记 + 执行命令 · 响应式

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/command_item.dart';
import '../utils/app_string_utils.dart';

class QuickSwitchDialog extends StatefulWidget {
  final List<NotebookEntry> notes;
  final List<CommandItem> commands;
  final void Function(NotebookEntry) onSelect;

  const QuickSwitchDialog({
    super.key,
    required this.notes,
    this.commands = const [],
    required this.onSelect,
  });

  @override
  State<QuickSwitchDialog> createState() => _QuickSwitchDialogState();
}

class _QuickSwitchDialogState extends State<QuickSwitchDialog> {
  String _keyword = '';

  bool get _isMac =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  List<NotebookEntry> _filteredNotes() {
    if (_keyword.isEmpty) return widget.notes;
    final kw = _keyword.toLowerCase();
    return widget.notes.where((n) {
      final t = AppStringUtils.displayNoteTitle(n.title, n.content);
      return t.toLowerCase().contains(kw) ||
          n.content.toLowerCase().contains(kw);
    }).toList();
  }

  List<CommandItem> _filteredCommands() {
    if (_keyword.isEmpty) return widget.commands;
    final kw = _keyword.toLowerCase();
    return widget.commands.where((c) =>
        c.label.toLowerCase().contains(kw) ||
        c.description.toLowerCase().contains(kw)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w < 600) return _buildMobile();
        return _buildDesktopOrPad(w);
      },
    );
  }

  Widget _buildMobile() {
    return Dialog.fullscreen(
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _buildContent(itemHeight: 52, showShortcut: false),
        ),
      ),
    );
  }

  Widget _buildDesktopOrPad(double w) {
    final isDesktop = w >= 900;
    return Dialog(
      child: SizedBox(
        width: isDesktop ? 560 : 500,
        height: 480,
        child: _buildContent(
          itemHeight: isDesktop ? 40 : 52,
          showShortcut: isDesktop,
        ),
      ),
    );
  }

  Widget _buildContent({
    required double itemHeight,
    required bool showShortcut,
  }) {
    final filteredNotes = _filteredNotes();
    final filteredCommands = _filteredCommands();
    final isEmpty = filteredNotes.isEmpty && filteredCommands.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            autofocus: !showShortcut,
            onChanged: (v) => setState(() => _keyword = v),
            onSubmitted: (_) {
              if (filteredCommands.isNotEmpty) {
                Navigator.pop(context);
                filteredCommands.first.onExecute();
              } else if (filteredNotes.isNotEmpty) {
                widget.onSelect(filteredNotes.first);
              }
            },
            decoration: InputDecoration(
              hintText: '🔍 搜索笔记或输入命令...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              isDense: true,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: isEmpty
              ? const Center(child: Text('无匹配'))
              : ListView(
                  children: [
                    if (filteredCommands.isNotEmpty) ...[
                      _sectionLabel('命令'),
                      ...filteredCommands.map((c) => _buildItem(
                            icon: c.icon,
                            title: c.label,
                            subtitle: c.description,
                            height: itemHeight,
                            shortcut: showShortcut
                                ? _shortcutLabelFor(c)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              c.onExecute();
                            },
                          )),
                      const Divider(height: 8),
                    ],
                    if (filteredNotes.isNotEmpty) ...[
                      _sectionLabel('笔记'),
                      ...filteredNotes.map((note) => _buildItem(
                            title: AppStringUtils.displayNoteTitle(
                                note.title, note.content),
                            height: itemHeight,
                            shortcut: null,
                            onTap: () => widget.onSelect(note),
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildItem({
    IconData? icon,
    required String title,
    String? subtitle,
    required double height,
    String? shortcut,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: height,
      child: ListTile(
        dense: true,
        leading: icon != null ? Icon(icon, size: 20) : null,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 11))
            : null,
        trailing: shortcut != null
            ? Text(shortcut,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
            : null,
        onTap: onTap,
      ),
    );
  }

  String? _shortcutLabelFor(CommandItem item) {
    if (item.shortcutLabel == null) return null;
    if (_isMac) return item.shortcutLabel!.replaceAll('Ctrl', '⌘');
    return item.shortcutLabel;
  }
}