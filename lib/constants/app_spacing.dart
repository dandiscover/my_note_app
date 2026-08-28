// lib/constants/app_spacing.dart
// 间距系统
import 'package:flutter/material.dart';
class AppSpacing {
  // ─── 基础间距 ──────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ─── 内边距 ──────────────────────────────────────
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  static const EdgeInsets paddingHXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHXL = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVXL = EdgeInsets.symmetric(vertical: xl);

  // ─── 外边距 ──────────────────────────────────────
  static const EdgeInsets marginXS = EdgeInsets.all(xs);
  static const EdgeInsets marginSM = EdgeInsets.all(sm);
  static const EdgeInsets marginMD = EdgeInsets.all(md);
  static const EdgeInsets marginLG = EdgeInsets.all(lg);
  static const EdgeInsets marginXL = EdgeInsets.all(xl);

  // ─── 间隙 ──────────────────────────────────────
  static const SizedBox gapXS = SizedBox(height: xs, width: xs);
  static const SizedBox gapSM = SizedBox(height: sm, width: sm);
  static const SizedBox gapMD = SizedBox(height: md, width: md);
  static const SizedBox gapLG = SizedBox(height: lg, width: lg);
  static const SizedBox gapXL = SizedBox(height: xl, width: xl);

  // ─── 分割线 ──────────────────────────────────────
  static const double dividerHeight = 0.5;
}