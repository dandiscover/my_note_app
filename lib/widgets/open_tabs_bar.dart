// lib/widgets/open_tabs_bar.dart
// 笔记标签条 —— 已开笔记切换

import 'package:flutter/material.dart';
import '../services/open_tabs_manager.dart';

class OpenTabsBar extends StatelessWidget {
  final VoidCallback? onTabTap;

  const OpenTabsBar({super.key, this.onTabTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OpenTab>>(
      valueListenable: OpenTabsManager.tabs,
      builder: (context, tabs, _) {
        if (tabs.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 40,
          color: Colors.grey.shade100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            itemBuilder: (ctx, i) {
              final tab = tabs[i];
              return ValueListenableBuilder<String?>(
                valueListenable: OpenTabsManager.activeTabId,
                builder: (ctx, activeId, _) {
                  final isActive = activeId == tab.noteId;
                  return GestureDetector(
                    onTap: () {
                      onTabTap?.call();
                      OpenTabsManager.instance.activate(tab.noteId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : null,
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isActive ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(tab.title,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () =>
                                OpenTabsManager.instance.close(tab.noteId),
                            child: const Icon(Icons.close, size: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}