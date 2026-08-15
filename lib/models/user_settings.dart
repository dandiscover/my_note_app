import 'package:flutter/material.dart';

enum ThemeModePreference {
  light,
  dark,
  system,
}

enum HeatmapColorScheme {
  natural,
  ocean,
  forest,
  sunset,
  custom,
}

// ✅ 新增：热力图统计模式
enum HeatmapStatMode {
  count,  // 按笔记数
  words,  // 按总字数
}

class UserSettings {
  // 个人资料
  String nickname;
  String bio;
  String avatarUrl;

  // 主题
  ThemeModePreference themeMode;

  // 编辑器
  bool defaultMarkdown;

  // 复习设置
  int reviewReminderHour;
  int reviewReminderMinute;
  double reviewFactor;
  int dailyReviewLimit;

  // 宠物
  bool showPet;
  String petSkin;
  bool petInFocusMode;
  String petName;

  // 插件
  List<String> enabledPlugins;

  // 社交
  Map<String, String> socialLinks;

  // 🔥 热力图设置
  HeatmapStatMode heatmapStatMode;      // ✅ 新增：统计模式
  int heatmapHighThreshold;             // 高产阈值（笔记数）
  int heatmapBurstThreshold;            // 爆发阈值（笔记数）
  int heatmapWordHighThreshold;         // ✅ 新增：字数高产阈值
  int heatmapWordBurstThreshold;        // ✅ 新增：字数爆发阈值
  HeatmapColorScheme heatmapColorScheme;
  String heatmapColorLow;
  String heatmapColorMid;
  String heatmapColorHigh;
  String heatmapColorBurst;

  UserSettings({
    this.nickname = '用户',
    this.bio = '爱学习的人',
    this.avatarUrl = '',
    this.themeMode = ThemeModePreference.system,
    this.defaultMarkdown = false,
    this.reviewReminderHour = 20,
    this.reviewReminderMinute = 0,
    this.reviewFactor = 2.0,
    this.dailyReviewLimit = 10,
    this.showPet = true,
    this.petSkin = 'default',
    this.petInFocusMode = true,
    this.petName = '小云',
    this.enabledPlugins = const [],
    this.socialLinks = const {},
    this.heatmapStatMode = HeatmapStatMode.count,  // ✅ 默认按笔记数
    this.heatmapHighThreshold = 5,
    this.heatmapBurstThreshold = 10,
    this.heatmapWordHighThreshold = 500,
    this.heatmapWordBurstThreshold = 2000,
    this.heatmapColorScheme = HeatmapColorScheme.natural,
    this.heatmapColorLow = '#E8F5E9',
    this.heatmapColorMid = '#66BB6A',
    this.heatmapColorHigh = '#FFB300',
    this.heatmapColorBurst = '#E53935',
  });

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'bio': bio,
      'avatar_url': avatarUrl,
      'theme_mode': themeMode.name,
      'default_markdown': defaultMarkdown ? 1 : 0,
      'review_reminder_hour': reviewReminderHour,
      'review_reminder_minute': reviewReminderMinute,
      'review_factor': reviewFactor,
      'daily_review_limit': dailyReviewLimit,
      'show_pet': showPet ? 1 : 0,
      'pet_skin': petSkin,
      'pet_in_focus_mode': petInFocusMode ? 1 : 0,
      'pet_name': petName,
      'enabled_plugins': enabledPlugins.join(','),
      'social_links': socialLinks.entries.map((e) => '${e.key}:${e.value}').join('|'),
      'heatmap_stat_mode': heatmapStatMode.name,
      'heatmap_high_threshold': heatmapHighThreshold,
      'heatmap_burst_threshold': heatmapBurstThreshold,
      'heatmap_word_high_threshold': heatmapWordHighThreshold,
      'heatmap_word_burst_threshold': heatmapWordBurstThreshold,
      'heatmap_color_scheme': heatmapColorScheme.name,
      'heatmap_color_low': heatmapColorLow,
      'heatmap_color_mid': heatmapColorMid,
      'heatmap_color_high': heatmapColorHigh,
      'heatmap_color_burst': heatmapColorBurst,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    final plugins = (map['enabled_plugins'] ?? '').toString().split(',').where((s) => s.isNotEmpty).toList();
    final socials = <String, String>{};
    for (var item in (map['social_links'] ?? '').toString().split('|')) {
      if (item.isEmpty) continue;
      final parts = item.split(':');
      if (parts.length == 2) {
        socials[parts[0]] = parts[1];
      }
    }
    return UserSettings(
      nickname: map['nickname'] ?? '用户',
      bio: map['bio'] ?? '爱学习的人',
      avatarUrl: map['avatar_url'] ?? '',
      themeMode: ThemeModePreference.values.firstWhere(
        (e) => e.name == map['theme_mode'],
        orElse: () => ThemeModePreference.system,
      ),
      defaultMarkdown: (map['default_markdown'] ?? 0) == 1,
      reviewReminderHour: map['review_reminder_hour'] ?? 20,
      reviewReminderMinute: map['review_reminder_minute'] ?? 0,
      reviewFactor: (map['review_factor'] ?? 2.0).toDouble(),
      dailyReviewLimit: map['daily_review_limit'] ?? 10,
      showPet: (map['show_pet'] ?? 1) == 1,
      petSkin: map['pet_skin'] ?? 'default',
      petInFocusMode: (map['pet_in_focus_mode'] ?? 1) == 1,
      petName: map['pet_name'] ?? '小云',
      enabledPlugins: plugins,
      socialLinks: socials,
      heatmapStatMode: HeatmapStatMode.values.firstWhere(
        (e) => e.name == map['heatmap_stat_mode'],
        orElse: () => HeatmapStatMode.count,
      ),
      heatmapHighThreshold: map['heatmap_high_threshold'] ?? 5,
      heatmapBurstThreshold: map['heatmap_burst_threshold'] ?? 10,
      heatmapWordHighThreshold: map['heatmap_word_high_threshold'] ?? 500,
      heatmapWordBurstThreshold: map['heatmap_word_burst_threshold'] ?? 2000,
      heatmapColorScheme: HeatmapColorScheme.values.firstWhere(
        (e) => e.name == map['heatmap_color_scheme'],
        orElse: () => HeatmapColorScheme.natural,
      ),
      heatmapColorLow: map['heatmap_color_low'] ?? '#E8F5E9',
      heatmapColorMid: map['heatmap_color_mid'] ?? '#66BB6A',
      heatmapColorHigh: map['heatmap_color_high'] ?? '#FFB300',
      heatmapColorBurst: map['heatmap_color_burst'] ?? '#E53935',
    );
  }

  int get currentHighThreshold {
    return heatmapStatMode == HeatmapStatMode.words
        ? heatmapWordHighThreshold
        : heatmapHighThreshold;
  }

  int get currentBurstThreshold {
    return heatmapStatMode == HeatmapStatMode.words
        ? heatmapWordBurstThreshold
        : heatmapBurstThreshold;
  }

  String get currentUnitLabel {
    return heatmapStatMode == HeatmapStatMode.words ? '字' : '条';
  }

  String get statModeLabel {
    return heatmapStatMode == HeatmapStatMode.words ? '📄 按总字数' : '📝 按笔记数';
  }

  List<Color> getHeatmapColors() {
    if (heatmapColorScheme == HeatmapColorScheme.custom) {
      return [
        _hexToColor(heatmapColorLow),
        _hexToColor(heatmapColorMid),
        _hexToColor(heatmapColorHigh),
        _hexToColor(heatmapColorBurst),
      ];
    }
    return _getPresetColors(heatmapColorScheme);
  }

  List<Color> _getPresetColors(HeatmapColorScheme scheme) {
    switch (scheme) {
      case HeatmapColorScheme.natural:
        return [
          Colors.grey.shade100,
          Colors.green.shade200,
          Colors.green.shade400,
          Colors.amber.shade600,
          Colors.red.shade600,
        ];
      case HeatmapColorScheme.ocean:
        return [
          Colors.grey.shade100,
          Colors.blue.shade200,
          Colors.blue.shade400,
          Colors.purple.shade400,
          Colors.pink.shade500,
        ];
      case HeatmapColorScheme.forest:
        return [
          Colors.grey.shade100,
          Colors.green.shade300,
          Colors.green.shade600,
          Colors.lime.shade600,
          Colors.deepOrange.shade600,
        ];
      case HeatmapColorScheme.sunset:
        return [
          Colors.grey.shade100,
          Colors.orange.shade200,
          Colors.orange.shade400,
          Colors.red.shade400,
          Colors.deepPurple.shade500,
        ];
      case HeatmapColorScheme.custom:
        return [
          Colors.grey.shade100,
          _hexToColor(heatmapColorLow),
          _hexToColor(heatmapColorMid),
          _hexToColor(heatmapColorHigh),
          _hexToColor(heatmapColorBurst),
        ];
    }
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7 || hex.length == 9) {
      buffer.write(hex.replaceFirst('#', ''));
    } else {
      return Colors.grey.shade300;
    }
    return Color(int.parse(buffer.toString(), radix: 16) + (hex.length == 7 ? 0xFF000000 : 0));
  }

  String getColorSchemeName(HeatmapColorScheme scheme) {
    switch (scheme) {
      case HeatmapColorScheme.natural:
        return '🌿 自然';
      case HeatmapColorScheme.ocean:
        return '🌊 海洋';
      case HeatmapColorScheme.forest:
        return '🌲 森林';
      case HeatmapColorScheme.sunset:
        return '🌅 日落';
      case HeatmapColorScheme.custom:
        return '🎨 自定义';
    }
  }
}