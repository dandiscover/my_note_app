// lib/services/richtext_adapter/shared/attributes.dart
// Delta 属性名常量 — 适配层的属性名唯一出口
//
// 所有在结构 ↔ Delta 转换中用到的属性名，集中在这里。
//
// ⚠️ 待验证：以下属性名基于 Quill 惯例 + 第二轮方案 v4 约定。
//    第三轮开工第一件事：逐项在 flutter_quill 11.5.1 实测，
//    若不一致，只改本文件的常量值，不改适配层逻辑。
//    验证方式见第三轮方案 v2 第五节。

/// Delta 属性名常量集合。
class DeltaAttributes {
  DeltaAttributes._();

  // ─── 1. 行内格式 ─────────────────────────────
  static const String bold = 'bold';
  static const String italic = 'italic';
  static const String underline = 'underline';

  /// 删除线
  /// ⚠️ 待验证：flutter_quill 11.5.1 的实际属性名。
  ///    可能为 'strike'，也可能是别的（如 'strikethrough'）。
  static const String strike = 'strike';

  static const String code = 'code';

  // ─── 2. 行内样式 ─────────────────────────────
  static const String color = 'color';

  /// 背景高亮色（'#RRGGBB'）
  /// ⚠️ 待验证：flutter_quill 11.5.1 的实际属性名。
  ///    Quill 惯例是 'background'，本常量先写 'highlight'，
  ///    验证后若不一致，改常量值，不改调用方。
  static const String highlight = 'highlight';

  static const String link = 'link';

  // ─── 3. 块属性 ───────────────────────────────
  static const String header = 'header';
  static const String list = 'list';
  static const String blockquote = 'blockquote';

  /// 代码块
  /// 值为语言名（如 'dart'），或空字符串表示无语言
  /// ⚠️ 待验证：flutter_quill 11.5.1 可能用 'code-block-language' 分开存
  static const String codeBlock = 'code-block';

  // ─── 4. 嵌入对象键 ───────────────────────────
  static const String image = 'image';
  static const String divider = 'divider';
  static const String inkPlaceholder = 'ink-placeholder';
}

/// `list` 属性的取值常量。
///
/// ⚠️ 待验证：flutter_quill 11.5.1 的实际取值。
class DeltaListValues {
  DeltaListValues._();

  static const String bullet = 'bullet';
  static const String ordered = 'ordered';
  static const String unchecked = 'unchecked';
  static const String checked = 'checked';
}

/// 属性值常量（与具体属性名无关的通用值）。
class DeltaAttributeValues {
  DeltaAttributeValues._();

  /// 空语言（代码块无指定语言时）
  /// ⚠️ 待验证：flutter_quill 11.5.1 是要求空字符串 '',
  ///    还是要求属性不带该键（即 null）。
  ///    本常量先写 ''，验证后若不一致，改代码逻辑（在转换层判断），
  ///    不改本常量。
  static const String emptyLanguage = '';
}