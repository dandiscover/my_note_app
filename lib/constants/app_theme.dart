// lib/constants/app_theme.dart
// 应用主题

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  // ─── 亮色主题 ──────────────────────────────────────
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        background: AppColors.background,
        error: AppColors.danger,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textWhite,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: _cardTheme(),
      appBarTheme: _appBarTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
      dividerTheme: _dividerTheme(),
      chipTheme: _chipTheme(),
      switchTheme: _switchTheme(),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(),
    );
  }

  // ─── 暗色主题 ──────────────────────────────────────
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF1E1E2E),
        background: const Color(0xFF14141E),
        error: AppColors.danger,
        onPrimary: AppColors.textWhite,
        onSecondary: AppColors.textWhite,
        onSurface: AppColors.textWhite,
        onBackground: AppColors.textWhite,
        onError: AppColors.textWhite,
      ),
      scaffoldBackgroundColor: const Color(0xFF14141E),
      cardTheme: _cardThemeDark(),
      appBarTheme: _appBarThemeDark(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      textButtonTheme: _textButtonThemeDark(),
      outlinedButtonTheme: _outlinedButtonThemeDark(),
      inputDecorationTheme: _inputDecorationThemeDark(),
      dividerTheme: _dividerThemeDark(),
      chipTheme: _chipThemeDark(),
      switchTheme: _switchTheme(),
      bottomNavigationBarTheme: _bottomNavigationBarThemeDark(),
    );
  }

  // ─── 卡片主题 ──────────────────────────────────────
  static CardThemeData _cardTheme() {
    return CardThemeData(
      color: AppColors.card,
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    );
  }

  static CardThemeData _cardThemeDark() {
    return CardThemeData(
      color: const Color(0xFF1E1E2E),
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    );
  }

  // ─── AppBar主题 ──────────────────────────────────────
  static AppBarTheme _appBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headline4,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
    );
  }

  static AppBarTheme _appBarThemeDark() {
    return AppBarTheme(
      backgroundColor: const Color(0xFF1E1E2E),
      foregroundColor: AppColors.textWhite,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headline4.copyWith(
        color: AppColors.textWhite,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textWhite,
        size: 24,
      ),
    );
  }

  // ─── 按钮主题 ──────────────────────────────────────
  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(88, 40),
        padding: AppSpacing.paddingHMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(88, 40),
        padding: AppSpacing.paddingHMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    );
  }

  static TextButtonThemeData _textButtonThemeDark() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(88, 40),
        padding: AppSpacing.paddingHMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.buttonMedium.copyWith(
          color: AppColors.textWhite,
        ),
        foregroundColor: AppColors.textWhite,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 40),
        padding: AppSpacing.paddingHMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: AppColors.border),
        textStyle: AppTextStyles.buttonMedium,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonThemeDark() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(88, 40),
        padding: AppSpacing.paddingHMD,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: const BorderSide(color: Color(0xFF3A3A4A)),
        textStyle: AppTextStyles.buttonMedium.copyWith(
          color: AppColors.textWhite,
        ),
        foregroundColor: AppColors.textWhite,
      ),
    );
  }

  // ─── 输入框主题 ──────────────────────────────────────
  static InputDecorationTheme _inputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: AppSpacing.paddingMD,
      isDense: true,
    );
  }

  static InputDecorationTheme _inputDecorationThemeDark() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A3E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: AppSpacing.paddingMD,
      isDense: true,
    );
  }

  // ─── 分割线主题 ──────────────────────────────────────
  static DividerThemeData _dividerTheme() {
    return DividerThemeData(
      color: AppColors.divider,
      thickness: 0.5,
      space: 0,
    );
  }

  static DividerThemeData _dividerThemeDark() {
    return DividerThemeData(
      color: const Color(0xFF2A2A3E),
      thickness: 0.5,
      space: 0,
    );
  }

  // ─── Chip主题 ──────────────────────────────────────
  static ChipThemeData _chipTheme() {
    return ChipThemeData(
      backgroundColor: AppColors.surface,
      disabledColor: AppColors.surface,
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: AppTextStyles.label,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ChipThemeData _chipThemeDark() {
    return ChipThemeData(
      backgroundColor: const Color(0xFF2A2A3E),
      disabledColor: const Color(0xFF2A2A3E),
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.textWhite),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ─── Switch主题 ──────────────────────────────────────
  static SwitchThemeData _switchTheme() {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          // ✅ 使用 withValues 替代 withOpacity
          return AppColors.primary.withValues(alpha: 0.5);
        }
        return Colors.grey.shade300;
      }),
    );
  }

  // ─── 底部导航栏主题 ──────────────────────────────────────
  static BottomNavigationBarThemeData _bottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    );
  }

  static BottomNavigationBarThemeData _bottomNavigationBarThemeDark() {
    return const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E2E),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 10),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    );
  }
}