import 'dart:typed_data';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../utils/markdown_custom_syntax.dart';
import 'note_pdf_builder.dart';
import 'pdf_image_loader.dart';

Future<Uint8List> buildMarkdownPdf(
  String content, {
  String? title,
  required pw.ThemeData theme,
}) async {
  try {
    final doc = md.Document(extensionSet: buildMarkdownExtensionSet());
    // 修复列表失效：清理 Windows 的 \r 换行符
    final lines = content.split('\n').map((line) => line.replaceAll('\r', '')).toList();
    final nodes = doc.parseLines(lines);

    final srcs = <String>{};
    for (final n in nodes) {
      _collectMdImages(n, srcs);
    }
    final images = await preloadImageMap(srcs);

    return await buildDoc(
      (ctx) => [
        if (title != null && title.isNotEmpty)
          pw.Header(level: 1, text: title),
        for (final n in nodes) ..._mdNodeToPdf(n, images),
      ],
      theme: theme,
    );
  } catch (e) {
    return buildErrorPdf('内容异常：$e', theme: theme);
  }
}

void _collectMdImages(md.Node node, Set<String> out) {
  if (node is md.Element) {
    if (node.tag == 'img') {
      final src = node.attributes['src'];
      if (src != null && src.isNotEmpty) out.add(src);
    }
    final kids = node.children;
    if (kids != null) {
      for (final c in kids) {
        _collectMdImages(c, out);
      }
    }
  }
}

List<pw.Widget> _mdNodeToPdf(
  md.Node node,
  Map<String, pw.ImageProvider> images,
) {
  if (node is! md.Element) return const [];

  switch (node.tag) {
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
      final level = int.parse(node.tag.substring(1));
      final size = 24.0 - (level * 2);
      return [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
          child: pw.RichText(
            text: pw.TextSpan(
              children: _parseInlineToPdfSpans(
                node,
                style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        ),
      ];

    case 'p':
      return [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(
              children: _parseInlineToPdfSpans(node),
            ),
          ),
        ),
      ];

    case 'ul':
      return [
        for (final li in node.children ?? <md.Node>[])
          if (li is md.Element)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 12, child: pw.Text('•')),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(children: _parseInlineToPdfSpans(li)),
                    ),
                  ),
                ],
              ),
            ),
      ];

    case 'ol':
      final items = node.children ?? <md.Node>[];
      return [
        for (var i = 0; i < items.length; i++)
          if (items[i] is md.Element)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(width: 18, child: pw.Text('${i + 1}. ')),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: _parseInlineToPdfSpans(items[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ];

    case 'blockquote':
      return [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6, top: 4),
          padding: const pw.EdgeInsets.only(left: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 2, color: PdfColors.grey400),
            ),
          ),
          child: pw.RichText(
            text: pw.TextSpan(
              children: _parseInlineToPdfSpans(node),
            ),
          ),
        ),
      ];

    case 'pre':
      return [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6, top: 4),
          padding: const pw.EdgeInsets.all(6),
          color: PdfColors.grey200,
          child: pw.RichText(
            text: pw.TextSpan(
              children: _parseInlineToPdfSpans(node),
            ),
          ),
        ),
      ];

    case 'img':
      final src = node.attributes['src'] ?? '';
      final p = images[src];
      return [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: p == null
              ? imagePlaceholder(src)
              : pw.Image(p, fit: pw.BoxFit.contain),
        )
      ];

    case 'hr':
      return [pw.Divider()];

    default:
      final kids = node.children;
      if (kids != null) {
        final out = <pw.Widget>[];
        for (final c in kids) {
          out.addAll(_mdNodeToPdf(c, images));
        }
        if (out.isNotEmpty) return out;
      }
      final text = node.textContent;
      return text.isEmpty ? const [] : [pw.Text(text)];
  }
}

List<pw.InlineSpan> _parseInlineToPdfSpans(
  md.Node node, {
  pw.TextStyle? style,
}) {
  final spans = <pw.InlineSpan>[];
  if (node is md.Text) {
    var text = node.text;
    text = text.replaceAll('&gt;', '>').replaceAll('&lt;', '<').replaceAll('&amp;', '&');
    spans.add(pw.TextSpan(text: text, style: style));
  } else if (node is md.Element) {
    final currentStyle = style ?? const pw.TextStyle();

    switch (node.tag) {
      case 'strong':
      case 'b':
        final newStyle = currentStyle.copyWith(fontWeight: pw.FontWeight.bold);
        for (final c in node.children ?? <md.Node>[]) {
          spans.addAll(_parseInlineToPdfSpans(c, style: newStyle));
        }
        break;
      case 'em':
      case 'i':
        final newStyle = currentStyle.copyWith(fontStyle: pw.FontStyle.italic);
        for (final c in node.children ?? <md.Node>[]) {
          spans.addAll(_parseInlineToPdfSpans(c, style: newStyle));
        }
        break;
      case 'code':
        final newStyle = currentStyle.copyWith(
          font: pw.Font.courier(),
          background: pw.BoxDecoration(color: PdfColors.grey200),
        );
        for (final c in node.children ?? <md.Node>[]) {
          spans.addAll(_parseInlineToPdfSpans(c, style: newStyle));
        }
        break;
      case 'a':
        final newStyle = currentStyle.copyWith(
          color: PdfColors.blue,
          decoration: pw.TextDecoration.underline,
        );
        for (final c in node.children ?? <md.Node>[]) {
          spans.addAll(_parseInlineToPdfSpans(c, style: newStyle));
        }
        break;
      case 'styledspan':
        var newStyle = currentStyle;
        final styleStr = node.attributes['style'] ?? '';
        PdfColor? color;
        PdfColor? bg;
        for (final prop in styleStr.split(';')) {
          final p = prop.trim();
          if (p.isEmpty) continue;
          final idx = p.indexOf(':');
          if (idx < 0) continue;
          final k = p.substring(0, idx).trim().toLowerCase();
          final v = p.substring(idx + 1).trim();
          if (k == 'color') color = parseColorPdf(v);
          if (k == 'background') bg = parseColorPdf(v);
        }
        if (color != null) newStyle = newStyle.copyWith(color: color);
        if (bg != null) newStyle = newStyle.copyWith(background: pw.BoxDecoration(color: bg));

        final raw = node.textContent;
        final buf = StringBuffer();
        var i = 0;
        while (i < raw.length) {
          if (i + 1 < raw.length && raw[i] == '*' && raw[i + 1] == '*') {
            final end = raw.indexOf('**', i + 2);
            if (end > i) {
              if (buf.isNotEmpty) { spans.add(pw.TextSpan(text: buf.toString(), style: newStyle)); buf.clear(); }
              spans.add(pw.TextSpan(
                text: raw.substring(i + 2, end),
                style: newStyle.copyWith(fontWeight: pw.FontWeight.bold),
              ));
              i = end + 2;
              continue;
            }
          }
          if (raw[i] == '*') {
            final end = raw.indexOf('*', i + 1);
            if (end > i) {
              if (buf.isNotEmpty) { spans.add(pw.TextSpan(text: buf.toString(), style: newStyle)); buf.clear(); }
              spans.add(pw.TextSpan(
                text: raw.substring(i + 1, end),
                style: newStyle.copyWith(fontStyle: pw.FontStyle.italic),
              ));
              i = end + 1;
              continue;
            }
          }
          buf.write(raw[i]);
          i++;
        }
        if (buf.isNotEmpty) { spans.add(pw.TextSpan(text: buf.toString(), style: newStyle)); }
        break;
      default:
        for (final c in node.children ?? <md.Node>[]) {
          spans.addAll(_parseInlineToPdfSpans(c, style: currentStyle));
        }
    }
  }
  return spans;
}