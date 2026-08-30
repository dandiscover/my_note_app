// lib/core/navigation_config.dart
// 导航方式配置（修复版）

import 'package:flutter/material.dart';
import 'platform_config.dart';
import 'page_registry.dart';

enum NavigationType {
  bottomNavigation,  // 底部导航（手机/平板）
  sidebar,           // 侧边栏（桌面/Web）
}

class NavigationConfig {
  static NavigationType getNavigationType(BuildContext context) {
    final deviceType = PlatformConfig.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.tablet:
        return NavigationType.bottomNavigation;
      case DeviceType.desktop:
      case DeviceType.web:
        return NavigationType.sidebar;
    }
  }

  static int getTabCount(BuildContext context) {
    return PageRegistry.getPages(context).length;
  }
}