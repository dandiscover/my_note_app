// lib/widgets/adaptive_navigation.dart
// 自适应导航组件（修复版）

import 'package:flutter/material.dart';
import '../core/page_registry.dart';
import '../core/navigation_config.dart';

class AdaptiveNavigation extends StatefulWidget {
  final VoidCallback? onTabChange;

  const AdaptiveNavigation({super.key, this.onTabChange});

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation> {
  int _currentIndex = 0;
  late List<PageDefinition> _pages;
  NavigationType _navType = NavigationType.bottomNavigation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = PageRegistry.getPages(context);
    _navType = NavigationConfig.getNavigationType(context);
    // 确保当前索引有效
    if (_currentIndex >= _pages.length) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('没有可用页面')),
      );
    }

    if (_navType == NavigationType.sidebar) {
      return _buildSidebarLayout();
    } else {
      return _buildBottomNavLayout();
    }
  }

  /// 底部导航（手机 / 平板）
  Widget _buildBottomNavLayout() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages.map((p) => p.page()).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          widget.onTabChange?.call();
        },
        type: BottomNavigationBarType.fixed,
        items: _pages.map((p) => BottomNavigationBarItem(
          icon: Icon(p.icon),
          activeIcon: Icon(p.activeIcon),
          label: p.title,
        )).toList(),
      ),
    );
  }

  /// 侧边栏（桌面 / Web）
  Widget _buildSidebarLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onTabChange?.call();
            },
            labelType: NavigationRailLabelType.all,
            destinations: _pages.map((p) => NavigationRailDestination(
              icon: Icon(p.icon),
              selectedIcon: Icon(p.activeIcon),
              label: Text(p.title),
            )).toList(),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages.map((p) => p.page()).toList(),
            ),
          ),
        ],
      ),
    );
  }
}