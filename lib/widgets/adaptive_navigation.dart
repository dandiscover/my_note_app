// lib/widgets/adaptive_navigation.dart
// ✅ 自适应导航 — 完整修复（不依赖 core 外部方法）

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../pages/collection_page.dart';
import '../pages/wisdom_page.dart';
import '../pages/insight_page.dart';
import '../pages/creation_page.dart' as creation;
import '../pages/profile_page.dart';
import '../pages/workbench/markdown_editor_page.dart';
import '../database_service.dart';
import '../models/note.dart';
/// 设备类型枚举
enum DeviceType { mobile, tablet, desktop, web }

class AdaptiveNavigation extends StatefulWidget {
  final void Function(int index)? onTabChange;
  final VoidCallback? onLoginSuccess;
  final GlobalKey<WisdomPageState>? wisdomKey;
  final GlobalKey<InsightPageState>? insightKey;
  final GlobalKey<creation.CreationPageState>? creationKey;
  final VoidCallback? onRefreshAll;

  const AdaptiveNavigation({
    super.key,
    this.onTabChange,
    this.onLoginSuccess,
    this.wisdomKey,
    this.insightKey,
    this.creationKey,
    this.onRefreshAll,
  });

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  int _currentIndex = 0;
  NotebookEntry? _draftNote;

  // ─── 内置平台检测 ──────────────────────────────────────────

  DeviceType _getDeviceType(BuildContext context) {
    if (kIsWeb) return DeviceType.web;
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return DeviceType.mobile;
    if (width < 900) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  List<Map<String, dynamic>> _getPages(DeviceType deviceType) {
    final allPages = [
      {'id': 'collection', 'label': '采集', 'icon': Icons.add_box_outlined},
      {'id': 'wisdom', 'label': '智库', 'icon': Icons.shelves},
      {'id': 'insight', 'label': '洞察', 'icon': Icons.insights},
      {'id': 'creation', 'label': '创作', 'icon': Icons.create},
      {'id': 'profile', 'label': '我的', 'icon': Icons.person_outline},
      {'id': 'writing', 'label': '写作', 'icon': Icons.edit_note},
    ];

    if (deviceType == DeviceType.mobile || deviceType == DeviceType.tablet) {
      return allPages.where((p) => p['id'] != 'writing').toList();
    }
    return allPages;
  }

  // ─── Tab 切换 ──────────────────────────────────────────────

  void _onTabChange(int index) {
    setState(() => _currentIndex = index);
    widget.onTabChange?.call(index);
  }
  /// 第 5 tab「写作」——无参默认 editor 模式。
  ///
  /// ⚠️ build 副作用：首次 sidebar 渲染时建草稿，缓存到 _draftNote。
  /// 跨 rebuild 保留，避免 _entry 被替换触发 kernel 重建。
  Widget _buildWritingTab() {
    _draftNote ??= NotebookEntry(
      id: 'tab_draft_${DateTime.now().millisecondsSinceEpoch}',
      title: '无标题',
      content: '',
      tags: [],
      updatedAt: DateTime.now(),
      editorMode: 'plain',
    );
    return MarkdownEditorPage(
      entry: _draftNote!,
      isFromCollection: false,
      shouldPopOnSave: false,
      onSave: (entry, title, content, editorMode, tags, inquiryQuestion, exploreTasks) async {
        final noteMap = {
          'id': entry.id,
          'title': title,
          'content': content,
          'status': 'active',
          'editorMode': editorMode,
          'updatedAt': DateTime.now().toIso8601String(),
          'isLocked': 0,
          'inquiryQuestion': inquiryQuestion,
          'exploreTasks': exploreTasks.map((e) => e.toJson()).toList(),
        };
        await DatabaseService().insertNote(noteMap);
        await DatabaseService().attachNoteToNode(
          noteId: entry.id,
          title: title,
          parentId: null,
          tags: tags,
        );
        return true;
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);
    final pages = _getPages(deviceType);

    final showBottomNav = deviceType == DeviceType.mobile ||
        deviceType == DeviceType.tablet;

    final showSidebar = deviceType == DeviceType.desktop ||
        deviceType == DeviceType.web;

    // ─── 构建页面列表 ──────────────────────────────────────

    final children = <Widget>[
        CollectionPage(
          creationKey: widget.creationKey,
          wisdomKey: widget.wisdomKey,
          insightKey: widget.insightKey,
        ),
      WisdomPage(
        key: widget.wisdomKey,
      ),
      InsightPage(
        key: widget.insightKey,
        onTabChange: (tabIndex) => _onTabChange(1),
        onRefreshWisdom: () {
          widget.wisdomKey?.currentState?.refreshData();
        },
        onSwitchToTaskTab: () {
          _onTabChange(3);
          widget.creationKey?.currentState?.switchToTaskTab();
        },
        onSwitchToFocusMode: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🐾 专注模式开发中，敬请期待')),
          );
        },
      ),
      creation.CreationPage(
        key: widget.creationKey,
      ),
      ProfilePage(
        key: const Key('profile_page'),
        onLoginSuccess: widget.onLoginSuccess,
      ),
    ];

    final pageWidgets = showSidebar
        ? [...children, _buildWritingTab()]
        : children;

    final pageContent = IndexedStack(
      index: _currentIndex,
      children: pageWidgets,
    );

    // ─── 渲染 ──────────────────────────────────────────────

    if (showBottomNav) {
      return Scaffold(
        body: pageContent,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabChange,
          type: BottomNavigationBarType.fixed,
          items: pages.map((page) {
            return BottomNavigationBarItem(
              icon: Icon(page['icon'] as IconData),
              label: page['label'] as String,
            );
          }).toList(),
        ),
      );
    } else if (showSidebar) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabChange,
            labelType: NavigationRailLabelType.all,
            destinations: pages.map((page) {
              return NavigationRailDestination(
                icon: Icon(page['icon'] as IconData),
                label: Text(page['label'] as String),
              );
            }).toList(),
          ),
          Expanded(
            child: pageContent,
          ),
        ],
      );
    }

    return pageContent;
  }
}