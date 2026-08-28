// lib/utils/app_string_utils.dart
// 字符串工具类

class AppStringUtils {
  /// 截断文本，超过长度加省略号
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 是否为空或空白
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// 安全地获取字符串
  static String safeString(String? text, {String defaultValue = ''}) {
    return text ?? defaultValue;
  }

  /// 从文件路径提取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    final fileName = parts.last;
    final lastDot = fileName.lastIndexOf('.');
    return lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
  }

  /// 首字母大写
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// 从文本中提取标签
  static List<String> extractTags(String text) {
    final regExp = RegExp(r'#([\w\u4e00-\u9fa5]+)');
    return regExp.allMatches(text).map((m) => m.group(1) ?? '').where((t) => t.isNotEmpty).toList();
  }
}