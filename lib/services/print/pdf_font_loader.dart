// lib/services/print/pdf_font_loader.dart
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// 中文字体加载器。字体文件由用户自备，路径固定。
/// 加载失败返回 null，调用方走默认 theme（中文方块但不崩）。
class PdfFontLoader {
  PdfFontLoader._();

  static Future<pw.Font?>? _cache;

  static Future<pw.Font?> loadNotoSansSC() {
    _cache ??= _load();
    return _cache!;
  }

  static Future<pw.Font?> _load() async {
    try {
      final data = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
      return pw.Font.ttf(data);
    } catch (e) {
      debugPrint(
        '[print.font] 字体文件缺失或加载失败: $e。'
        '请将中文全量 .ttf 放到 assets/fonts/NotoSansSC-Regular.ttf。'
        '未放则中文可能显示为方块。',
      );
      return null;
    }
  }
}