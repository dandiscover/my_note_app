// lib/services/richtext_adapter/shared/attributes.dart
// Delta 属性名常量 — 适配层的属性名唯一出口
//
// 所有在结构 ↔ Delta 转换中用到的属性名，集中在这里。
//
// ✅ 已实测：code-block / list 属性名与值已对 flutter_quill 11.5.1 实测。
// ⚠️ 待验证：其余属性名基于 Quill 惯例，第三轮后续验证。

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
  ///
  /// ✅ 已实测（flutter_quill 11.5.1）：
  ///    值固定为 `true`，不带语言名。
  ///    例：{ "insert": "\n", "attributes": { "code-block": true } }
  ///
  /// ⚠️ flutter_quill 11.5.1 不支持在 Delta 里挂代码块语言名。
  ///    存储结构里 `code_block.language` 字段保留，
  ///    但转 Delta 时不写、回读时为 null。
  static const String codeBlock = 'code-block';

  // ─── 4. 嵌入对象键 ───────────────────────────
  static const String image = 'image';
  static const String divider = 'divider';
  static const String inkPlaceholder = 'ink-placeholder';
}

/// `list` 属性的取值常量。
///
/// ✅ 已实测（flutter_quill 11.5.1）：
///    - 未勾选待办：'unchecked'
///    - 有序列表：'ordered'
///    - 无序列表：'bullet'（推定，未单独验）
///    - 已勾选待办：'checked'（推定，与 unchecked 对称）
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
  ///
  /// ⚠️ 已废弃（第二轮 T-133 保留观察）。
  ///    flutter_quill 11.5.1 已实测：`code-block` 属性值为 `true`，
  ///    不支持挂语言名。因此本常量不再有使用场景。
  ///
  /// 保留不删的理由：若将来 flutter_quill 升级支持代码块语言，
  /// 可直接复用本常量，无需重新定义。
  ///
  /// ─── @Deprecated 说明（配合 T-197）───
  ///
  /// 本会话已核：structure_to_delta.dart / delta_to_structure.dart
  /// 里均不再引用 emptyLanguage。
  ///
  /// 执行侧注意：
  ///   1. 落盘后跑 flutter analyze。
  ///   2. 若报 deprecated_member_use —— 说明有未清理的引用残留，
  ///      那条引用要处理（改常量值，或改为不引用）。
  ///   3. 若零报 —— 废弃标注到位，T-197 可关闭。
  @Deprecated('flutter_quill 11.5.1 不支持代码块语言名')
  static const String emptyLanguage = '';
}