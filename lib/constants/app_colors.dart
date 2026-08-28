// lib/constants/app_colors.dart
// 应用颜色系统

import 'package:flutter/material.dart';

class AppColors {
  // ─── 主色 ──────────────────────────────────────
  static const Color primary = Color(0xFF4A6CF7);
  static const Color primaryLight = Color(0xFFE8EDFD);
  static const Color primaryDark = Color(0xFF3A56C7);

  // ─── 辅助色 ──────────────────────────────────────
  static const Color secondary = Color(0xFF6C5CE7);
  static const Color secondaryLight = Color(0xFFF0EDFD);

  // ─── 状态色 ──────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFEAFAF1);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color danger = Color(0xFFE74C3C);
  static const Color dangerLight = Color(0xFFFDEDEC);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEBF5FB);

  // ─── 背景色 ──────────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);

  // ─── 文字色 ──────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A5A);
  static const Color textTertiary = Color(0xFF8E8EA0);
  static const Color textLight = Color(0xFFB0B0C0);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ─── 边框色 ──────────────────────────────────────
  static const Color border = Color(0xFFE8E8EE);
  static const Color borderLight = Color(0xFFF0F0F5);
  static const Color divider = Color(0xFFEEEEF5);

  // ─── 阴影色 ──────────────────────────────────────
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // ─── 功能色 ──────────────────────────────────────
  static const Color purple = Color(0xFF6C5CE7);
  static const Color purpleLight = Color(0xFFF0EDFD);
  static const Color orange = Color(0xFFF39C12);
  static const Color orangeLight = Color(0xFFFEF9E7);
  static const Color pink = Color(0xFFE84393);
  static const Color pinkLight = Color(0xFFFDE8F3);
  static const Color teal = Color(0xFF00B894);
  static const Color tealLight = Color(0xFFE8F8F5);

  // ─── 辅助方法（使用新 API） ────────────────────
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}