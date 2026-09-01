// lib/core/page_registry.dart
// 页面注册表 — 定义每端显示哪些页面（使用相对导入）

import 'package:flutter/material.dart';
import '../pages/collection_page.dart';
import '../pages/wisdom_page.dart';
import '../pages/insight_page.dart';
import '../pages/creation_page.dart' as creation;
import '../pages/profile_page.dart';
import '../pages/writing_page.dart';
import 'platform_config.dart';

/// 页面定义类
class PageDefinition {
  final String id;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final Widget Function() page;
  final bool mobile;
  final bool tablet;
  final bool desktop;
  final bool web;

  const PageDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.page,
    this.mobile = true,
    this.tablet = true,
    this.desktop = true,
    this.web = true,
  });
}

class PageRegistry {
  static const List<PageDefinition> allPages = [
    PageDefinition(
      id: 'collection',
      title: '采集',
      icon: Icons.cloud_upload_outlined,
      activeIcon: Icons.cloud_upload,
      page: CollectionPage.new,
      mobile: true,
      tablet: true,
      desktop: true,
      web: true,
    ),
    PageDefinition(
      id: 'wisdom',
      title: '智库',
      icon: Icons.auto_stories,
      activeIcon: Icons.auto_stories,
      page: WisdomPage.new,
      mobile: true,
      tablet: true,
      desktop: true,
      web: true,
    ),
    PageDefinition(
      id: 'insight',
      title: '洞察',
      icon: Icons.insights,
      activeIcon: Icons.insights,
      page: InsightPage.new,
      mobile: true,
      tablet: true,
      desktop: true,
      web: true,
    ),
    PageDefinition(
      id: 'creation',
      title: '创作',
      icon: Icons.create,
      activeIcon: Icons.create,
      page: creation.CreationPage.new,
      mobile: true,
      tablet: true,
      desktop: true,
      web: true,
    ),
    PageDefinition(
      id: 'writing',
      title: '写作',
      icon: Icons.edit_note,
      activeIcon: Icons.edit_note,
      page: WritingPage.new,
      mobile: false,
      tablet: false,
      desktop: true,
      web: true,
    ),
    PageDefinition(
      id: 'profile',
      title: '我的',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      page: ProfilePage.new,
      mobile: true,
      tablet: true,
      desktop: true,
      web: true,
    ),
  ];

  static List<PageDefinition> getPages(BuildContext context) {
    final deviceType = PlatformConfig.getDeviceType(context);

    return allPages.where((page) {
      switch (deviceType) {
        case DeviceType.mobile:
          return page.mobile;
        case DeviceType.tablet:
          return page.tablet;
        case DeviceType.desktop:
          return page.desktop;
        case DeviceType.web:
          return page.web;
      }
    }).toList();
  }

  static int getHomeIndex(BuildContext context) {
    final pages = getPages(context);
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].id == 'collection') return i;
    }
    return 0;
  }
}