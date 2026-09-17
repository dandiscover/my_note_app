// lib/services/epub_export/structure_to_xhtml.dart
// 结构 JSON → 完整 XHTML 文档
// 依据：第五轮方案 v6 §5.3；文档一《自定义存储结构定义 v2》

/// 图片引用（结构中的 src → 打包后的文件名）
class ImageRef {
  final String src;
  final String packagedName;
  const ImageRef({required this.src, required this.packagedName});
}

/// EPUB 导出异常
class EpubExportException implements Exception {
  final String message;
  EpubExportException(this.message);
  @override
  String toString() => 'EpubExportException: $message';
}

/// 单章结构 → 完整 XHTML 文档
class StructureToXhtml {
  StructureToXhtml._();

  /// [structure] 来自 entry.content 的 jsonDecode（顶层 {version, blocks}）
  /// [chapterTitle] 章节标题，用于 <title> 和 <h1 class="chapter-title">
  /// [srcToPackaged] 把结构中的原始 src 映射到打包后的文件名
  ///
  /// 抛：[EpubExportException] version != 2 或 blocks 缺失
  static String convert({
    required Map<String, dynamic> structure,
    required String chapterTitle,
    required String Function(String src) srcToPackaged,
  }) {
    final version = structure['version'];
    if (version != 2) {
      throw EpubExportException('笔记格式不支持导出（version=$version）');
    }
    final blocks = structure['blocks'];
    if (blocks is! List) {
      throw EpubExportException('笔记结构非法：blocks 缺失或类型错');
    }

    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block is! Map) continue;
      buffer.write(_blockToXhtml(
        block.cast<String, dynamic>(),
        srcToPackaged,
      ));
    }

    final escapedTitle = _escapeXml(chapterTitle);
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops">
<head>
  <meta charset="UTF-8"/>
  <title>$escapedTitle</title>
  <link rel="stylesheet" href="styles.css"/>
</head>
<body>
  <h1 class="chapter-title">$escapedTitle</h1>
$buffer</body>
</html>
''';
  }

  static String _blockToXhtml(
    Map<String, dynamic> block,
    String Function(String) srcToPackaged,
  ) {
    final type = block['type'] as String?;
    switch (type) {
      case 'paragraph':
        return '  <p>${_inlinesToXhtml(block['inlines'], srcToPackaged)}</p>\n';
      case 'heading':
        final level = (block['level'] as int?)?.clamp(1, 6) ?? 1;
        return '  <h$level>${_inlinesToXhtml(block['inlines'], srcToPackaged)}</h$level>\n';
      case 'list':
        return _listToXhtml(block, srcToPackaged);
      case 'blockquote':
        return _blockquoteToXhtml(block, srcToPackaged);
      case 'code_block':
        final lang = block['language'] as String?;
        final text = block['text'] as String? ?? '';
        final langAttr = (lang != null && lang.isNotEmpty)
            ? ' class="language-${_escapeXml(lang)}"'
            : '';
        return '  <pre><code$langAttr>${_escapeXml(text)}</code></pre>\n';
      case 'image':
        final src = block['src'] as String? ?? '';
        final alt = block['alt'] as String? ?? '';
        final packaged = srcToPackaged(src);
        return '  <img src="images/$packaged" alt="${_escapeXml(alt)}"/>\n';
      case 'todo':
        final checked = block['checked'] == true;
        final mark = checked ? '☑' : '☐';
        return '  <p class="todo">$mark ${_inlinesToXhtml(block['inlines'], srcToPackaged)}</p>\n';
      case 'divider':
        return '  <hr/>\n';
      case 'table':
        return _tableToXhtml(block, srcToPackaged);
      case 'ink':
        // 方案 v6 §5.3：跳过
        return '';
      default:
        return '';
    }
  }

  static String _listToXhtml(
    Map<String, dynamic> block,
    String Function(String) srcToPackaged,
  ) {
    final ordered = block['ordered'] == true;
    final tag = ordered ? 'ol' : 'ul';
    final items = block['items'];
    if (items is! List) return '';
    final buffer = StringBuffer('  <$tag>\n');
    for (final item in items) {
      if (item is! Map) continue;
      final itemBlocks = item['blocks'];
      if (itemBlocks is! List) continue;
      buffer.write('    <li>');
      for (final b in itemBlocks) {
        if (b is! Map) continue;
        buffer.write(
          _blockToXhtml(b.cast<String, dynamic>(), srcToPackaged).trim(),
        );
      }
      buffer.write('</li>\n');
    }
    buffer.write('  </$tag>\n');
    return buffer.toString();
  }

  static String _blockquoteToXhtml(
    Map<String, dynamic> block,
    String Function(String) srcToPackaged,
  ) {
    final children = block['children'];
    if (children is! List) return '';
    final buffer = StringBuffer('  <blockquote>\n');
    for (final child in children) {
      if (child is! Map) continue;
      buffer.write(
        _blockToXhtml(child.cast<String, dynamic>(), srcToPackaged),
      );
    }
    buffer.write('  </blockquote>\n');
    return buffer.toString();
  }

  static String _tableToXhtml(
    Map<String, dynamic> block,
    String Function(String) srcToPackaged,
  ) {
    final rows = block['rows'];
    if (rows is! List) return '';
    final headerRow = block['headerRow'] == true;
    final buffer = StringBuffer('  <table>\n');
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is! Map) continue;
      final cells = row['cells'];
      if (cells is! List) continue;
      final isHeader = headerRow && i == 0;
      buffer.write(isHeader ? '    <thead><tr>' : '    <tr>');
      for (final cell in cells) {
        if (cell is! Map) continue;
        final cellBlocks = cell['blocks'];
        final cellTag = isHeader ? 'th' : 'td';
        buffer.write('<$cellTag>');
        if (cellBlocks is List) {
          for (final b in cellBlocks) {
            if (b is! Map) continue;
            buffer.write(
              _blockToXhtml(b.cast<String, dynamic>(), srcToPackaged).trim(),
            );
          }
        }
        buffer.write('</$cellTag>');
      }
      buffer.write(isHeader ? '</tr></thead>\n' : '</tr>\n');
    }
    buffer.write('  </table>\n');
    return buffer.toString();
  }

  static String _inlinesToXhtml(
    dynamic inlines,
    String Function(String) srcToPackaged,
  ) {
    if (inlines is! List) return '';
    final buffer = StringBuffer();
    for (final inline in inlines) {
      if (inline is! Map) continue;
      final map = inline.cast<String, dynamic>();
      var text = _escapeXml(map['text'] as String? ?? '');
      if (map['code'] == true) text = '<code>$text</code>';
      if (map['bold'] == true) text = '<strong>$text</strong>';
      if (map['italic'] == true) text = '<em>$text</em>';
      if (map['underline'] == true) text = '<u>$text</u>';
      if (map['strike'] == true) text = '<del>$text</del>';
      final color = map['color'];
      if (color is String && color.isNotEmpty) {
        text = '<span style="color:${_escapeXml(color)}">$text</span>';
      }
      final highlight = map['highlight'];
      if (highlight is String && highlight.isNotEmpty) {
        text = '<mark style="background:${_escapeXml(highlight)}">$text</mark>';
      }
      final link = map['link'];
      if (link is String && link.isNotEmpty) {
        text = '<a href="${_escapeXml(link)}">$text</a>';
      }
      buffer.write(text);
    }
    return buffer.toString();
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}