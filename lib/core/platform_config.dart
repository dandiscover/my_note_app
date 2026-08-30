// lib/core/platform_config.dart
// 端侧平台判定

import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum DeviceType {
  mobile,    // 手机
  tablet,    // 平板
  desktop,   // Windows / macOS / Linux
  web,       // Web 浏览器
}

class PlatformConfig {
  /// 获取当前设备类型
  static DeviceType getDeviceType(BuildContext context) {
    if (kIsWeb) {
      // Web 端按桌面布局处理
      return DeviceType.web;
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return DeviceType.desktop;
    }

    // 移动端根据屏幕宽度判断手机/平板
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide >= 600) {
      return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }

  /// 是否桌面端
  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// 是否 Web
  static bool get isWeb => kIsWeb;

  /// 是否手机
  static bool get isMobile {
    return !isDesktop && !isWeb;
  }

  /// 获取设备类型标签（调试用）
  static String getTypeLabel(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return '📱 手机';
      case DeviceType.tablet:
        return '📱 平板';
      case DeviceType.desktop:
        return '💻 桌面';
      case DeviceType.web:
        return '🌐 Web';
    }
  }
}