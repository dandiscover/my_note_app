// lib/models/user_settings.dart
// 用户设置模型

import 'package:flutter/material.dart';

enum ThemeModePreference { light, dark, system }
enum HeatmapStatMode { count, words }
enum HeatmapColorScheme {
  emerald,
  ocean,
  sunset,
  lavender,
  custom,
}

class UserSettings {
  // ─── 常量 ──────────────────────────────────────
  static const int maxLockedNotes = 50;

  String nickname;
  String bio;
  String avatarUrl;
  ThemeModePreference themeMode;
  bool defaultMarkdown;
  int reviewReminderHour;
  int reviewReminderMinute;
  int dailyReviewLimit;
  double reviewFactor;
  HeatmapStatMode heatmapStatMode;
  int heatmapHighThreshold;
  int heatmapBurstThreshold;
  int heatmapWordHighThreshold;
  int heatmapWordBurstThreshold;
  HeatmapColorScheme heatmapColorScheme;
  String heatmapColorLow;
  String heatmapColorMid;
  String heatmapColorHigh;
  String heatmapColorBurst;
  bool showPet;
  String petSkin;
  String petName;
  bool petInFocusMode;
  int rawNoteRetentionDays;  // ✅ 这个字段必须有

  UserSettings({
    this.nickname = '小云同学',
    this.bio = '📚 知识探索者',
    this.avatarUrl = '',
    this.themeMode = ThemeModePreference.light,
    this.defaultMarkdown = false,
    this.reviewReminderHour = 20,
    this.reviewReminderMinute = 0,
    this.dailyReviewLimit = 20,
    this.reviewFactor = 2.5,
    this.heatmapStatMode = HeatmapStatMode.count,
    this.heatmapHighThreshold = 3,
    this.heatmapBurstThreshold = 8,
    this.heatmapWordHighThreshold = 300,
    this.heatmapWordBurstThreshold = 800,
    this.heatmapColorScheme = HeatmapColorScheme.emerald,
    this.heatmapColorLow = '#E8F5E9',
    this.heatmapColorMid = '#81C784',
    this.heatmapColorHigh = '#FFD93D',
    this.heatmapColorBurst = '#FF6B6B',
    this.showPet = true,
    this.petSkin = 'default',
    this.petName = '小云',
    this.petInFocusMode = true,
    this.rawNoteRetentionDays = 15,  // ✅ 必须有默认值
  });

  Map<String, dynamic> toMap() => {
    'nickname': nickname,
    'bio': bio,
    'avatarUrl': avatarUrl,
    'themeMode': themeMode.name,
    'defaultMarkdown': defaultMarkdown,
    'reviewReminderHour': reviewReminderHour,
    'reviewReminderMinute': reviewReminderMinute,
    'dailyReviewLimit': dailyReviewLimit,
    'reviewFactor': reviewFactor,
    'heatmapStatMode': heatmapStatMode.name,
    'heatmapHighThreshold': heatmapHighThreshold,
    'heatmapBurstThreshold': heatmapBurstThreshold,
    'heatmapWordHighThreshold': heatmapWordHighThreshold,
    'heatmapWordBurstThreshold': heatmapWordBurstThreshold,
    'heatmapColorScheme': heatmapColorScheme.name,
    'heatmapColorLow': heatmapColorLow,
    'heatmapColorMid': heatmapColorMid,
    'heatmapColorHigh': heatmapColorHigh,
    'heatmapColorBurst': heatmapColorBurst,
    'showPet': showPet,
    'petSkin': petSkin,
    'petName': petName,
    'petInFocusMode': petInFocusMode,
    'rawNoteRetentionDays': rawNoteRetentionDays,  // ✅ 必须有
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      nickname: map['nickname'] ?? '小云同学',
      bio: map['bio'] ?? '📚 知识探索者',
      avatarUrl: map['avatarUrl'] ?? '',
      themeMode: ThemeModePreference.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => ThemeModePreference.light,
      ),
      defaultMarkdown: map['defaultMarkdown'] ?? false,
      reviewReminderHour: map['reviewReminderHour'] ?? 20,
      reviewReminderMinute: map['reviewReminderMinute'] ?? 0,
      dailyReviewLimit: map['dailyReviewLimit'] ?? 20,
      reviewFactor: (map['reviewFactor'] ?? 2.5).toDouble(),
      heatmapStatMode: HeatmapStatMode.values.firstWhere(
        (e) => e.name == map['heatmapStatMode'],
        orElse: () => HeatmapStatMode.count,
      ),
      heatmapHighThreshold: map['heatmapHighThreshold'] ?? 3,
      heatmapBurstThreshold: map['heatmapBurstThreshold'] ?? 8,
      heatmapWordHighThreshold: map['heatmapWordHighThreshold'] ?? 300,
      heatmapWordBurstThreshold: map['heatmapWordBurstThreshold'] ?? 800,
      heatmapColorScheme: HeatmapColorScheme.values.firstWhere(
        (e) => e.name == map['heatmapColorScheme'],
        orElse: () => HeatmapColorScheme.emerald,
      ),
      heatmapColorLow: map['heatmapColorLow'] ?? '#E8F5E9',
      heatmapColorMid: map['heatmapColorMid'] ?? '#81C784',
      heatmapColorHigh: map['heatmapColorHigh'] ?? '#FFD93D',
      heatmapColorBurst: map['heatmapColorBurst'] ?? '#FF6B6B',
      showPet: map['showPet'] ?? true,
      petSkin: map['petSkin'] ?? 'default',
      petName: map['petName'] ?? '小云',
      petInFocusMode: map['petInFocusMode'] ?? true,
      rawNoteRetentionDays: map['rawNoteRetentionDays'] ?? 15,  // ✅ 必须有
    );
  }

  List<Color> getHeatmapColors() {
    final colors = {
      HeatmapColorScheme.emerald: ['#E8F5E9', '#A5D6A7', '#66BB6A', '#2E7D32', '#1B5E20'],
      HeatmapColorScheme.ocean: ['#E3F2FD', '#90CAF9', '#42A5F5', '#1565C0', '#0D47A1'],
      HeatmapColorScheme.sunset: ['#FFF3E0', '#FFCC80', '#FFA726', '#EF6C00', '#BF360C'],
      HeatmapColorScheme.lavender: ['#F3E5F5', '#CE93D8', '#AB47BC', '#6A1B9A', '#4A148C'],
    };
    return [
      _hexToColor(heatmapColorLow),
      _hexToColor(heatmapColorMid),
      _hexToColor(heatmapColorHigh),
      _hexToColor(heatmapColorBurst),
    ];
  }

  Color _hexToColor(String hex) {
    if (hex.isEmpty || hex.length < 7) {
      return Colors.grey.shade300;
    }
    final buffer = StringBuffer();
    if (hex.startsWith('#')) {
      buffer.write(hex.replaceFirst('#', ''));
    } else {
      buffer.write(hex);
    }
    if (buffer.length == 6) {
      return Color(int.parse(buffer.toString(), radix: 16) + 0xFF000000);
    } else if (buffer.length == 8) {
      return Color(int.parse(buffer.toString(), radix: 16));
    }
    return Colors.grey.shade300;
  }

  String getColorSchemeName(HeatmapColorScheme scheme) {
    switch (scheme) {
      case HeatmapColorScheme.emerald: return '翡翠绿';
      case HeatmapColorScheme.ocean: return '海洋蓝';
      case HeatmapColorScheme.sunset: return '日落橙';
      case HeatmapColorScheme.lavender: return '薰衣草紫';
      case HeatmapColorScheme.custom: return '自定义';
    }
  }

  int get currentHighThreshold {
    return heatmapStatMode == HeatmapStatMode.words ? heatmapWordHighThreshold : heatmapHighThreshold;
  }

  int get currentBurstThreshold {
    return heatmapStatMode == HeatmapStatMode.words ? heatmapWordBurstThreshold : heatmapBurstThreshold;
  }

  String get statModeLabel {
    return heatmapStatMode == HeatmapStatMode.words ? '字数统计' : '条数统计';
  }

  UserSettings copyWith({
    String? nickname,
    String? bio,
    String? avatarUrl,
    ThemeModePreference? themeMode,
    bool? defaultMarkdown,
    int? reviewReminderHour,
    int? reviewReminderMinute,
    int? dailyReviewLimit,
    double? reviewFactor,
    HeatmapStatMode? heatmapStatMode,
    int? heatmapHighThreshold,
    int? heatmapBurstThreshold,
    int? heatmapWordHighThreshold,
    int? heatmapWordBurstThreshold,
    HeatmapColorScheme? heatmapColorScheme,
    String? heatmapColorLow,
    String? heatmapColorMid,
    String? heatmapColorHigh,
    String? heatmapColorBurst,
    bool? showPet,
    String? petSkin,
    String? petName,
    bool? petInFocusMode,
    int? rawNoteRetentionDays,
  }) {
    return UserSettings(
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themeMode: themeMode ?? this.themeMode,
      defaultMarkdown: defaultMarkdown ?? this.defaultMarkdown,
      reviewReminderHour: reviewReminderHour ?? this.reviewReminderHour,
      reviewReminderMinute: reviewReminderMinute ?? this.reviewReminderMinute,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      reviewFactor: reviewFactor ?? this.reviewFactor,
      heatmapStatMode: heatmapStatMode ?? this.heatmapStatMode,
      heatmapHighThreshold: heatmapHighThreshold ?? this.heatmapHighThreshold,
      heatmapBurstThreshold: heatmapBurstThreshold ?? this.heatmapBurstThreshold,
      heatmapWordHighThreshold: heatmapWordHighThreshold ?? this.heatmapWordHighThreshold,
      heatmapWordBurstThreshold: heatmapWordBurstThreshold ?? this.heatmapWordBurstThreshold,
      heatmapColorScheme: heatmapColorScheme ?? this.heatmapColorScheme,
      heatmapColorLow: heatmapColorLow ?? this.heatmapColorLow,
      heatmapColorMid: heatmapColorMid ?? this.heatmapColorMid,
      heatmapColorHigh: heatmapColorHigh ?? this.heatmapColorHigh,
      heatmapColorBurst: heatmapColorBurst ?? this.heatmapColorBurst,
      showPet: showPet ?? this.showPet,
      petSkin: petSkin ?? this.petSkin,
      petName: petName ?? this.petName,
      petInFocusMode: petInFocusMode ?? this.petInFocusMode,
      rawNoteRetentionDays: rawNoteRetentionDays ?? this.rawNoteRetentionDays,
    );
  }
}