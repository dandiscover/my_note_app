// lib/services/epub_export/opf_builder.dart
// OPF + nav.xhtml + container.xml 生成
// 依据：第五轮方案 v6 §5.4

import 'structure_to_xhtml.dart';

/// 章节数据（导出用）
class Chapter {
  final String title;
  final String xhtml;
  final List<ImageRef> images;
  const Chapter({
    required this.title,
    required this.xhtml,
    this.images = const [],
  });
}

/// OPF / nav / container 生成器
class OpfBuilder {
  OpfBuilder._();

  static String buildContainerXml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0"
           xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
              media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';
  }

  static String buildContentOpf({
    required String uuid,
    required String title,
    required List<Chapter> chapters,
    required List<ImageRef> allImages,
  }) {
    final now = DateTime.now().toUtc();
    final modified = '${now.toIso8601String().split('.').first}Z';

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<package xmlns="http://www.idpf.org/2007/opf"');
    buffer.writeln('         version="3.0"');
    buffer.writeln('         unique-identifier="pub-id">');
    buffer.writeln('  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">');
    buffer.writeln(
        '    <dc:identifier id="pub-id">urn:uuid:$uuid</dc:identifier>');
    buffer.writeln('    <dc:title>${_escape(title)}</dc:title>');
    buffer.writeln('    <dc:language>zh-CN</dc:language>');
    buffer.writeln('    <dc:creator>云脑计划</dc:creator>');
    buffer.writeln(
        '    <meta property="dcterms:modified">$modified</meta>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <manifest>');
    buffer.writeln(
        '    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>');
    buffer.writeln(
        '    <item id="css" href="styles.css" media-type="text/css"/>');
    for (var i = 0; i < chapters.length; i++) {
      final n = i + 1;
      buffer.writeln(
          '    <item id="chapter_$n" href="chapter_$n.xhtml" media-type="application/xhtml+xml"/>');
    }
    for (var i = 0; i < allImages.length; i++) {
      final img = allImages[i];
      final mediaType = mediaTypeFor(img.packagedName);
      if (mediaType == null) continue;
      buffer.writeln(
          '    <item id="img_$i" href="images/${img.packagedName}" media-type="$mediaType"/>');
    }
    buffer.writeln('  </manifest>');
    buffer.writeln('  <spine>');
    for (var i = 0; i < chapters.length; i++) {
      final n = i + 1;
      buffer.writeln('    <itemref idref="chapter_$n"/>');
    }
    buffer.writeln('  </spine>');
    buffer.writeln('</package>');
    return buffer.toString();
  }

  static String buildNavXhtml({required List<Chapter> chapters}) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html xmlns="http://www.w3.org/1999/xhtml"');
    buffer.writeln('      xmlns:epub="http://www.idpf.org/2007/ops">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8"/>');
    buffer.writeln('  <title>目录</title>');
    buffer.writeln('  <link rel="stylesheet" href="styles.css"/>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <nav epub:type="toc" id="toc">');
    buffer.writeln('    <h1>目录</h1>');
    buffer.writeln('    <ol>');
    for (var i = 0; i < chapters.length; i++) {
      final n = i + 1;
      buffer.writeln(
          '      <li><a href="chapter_$n.xhtml">${_escape(chapters[i].title)}</a></li>');
    }
    buffer.writeln('    </ol>');
    buffer.writeln('  </nav>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  /// 扩展名 → media-type；未知扩展名返回 null（跳过）
  ///
  /// ✅ 公开（v7）：供调用方过滤 imageMap，与 manifest 同源
  static String? mediaTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    // webp：EPUB 3.0 非标准，跳过（v6 记账）
    return null;
  }

  static String _escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}