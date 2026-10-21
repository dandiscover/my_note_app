// lib/services/print/markdown_to_pdf.dart
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
    final nodes = doc.parseLines(content.split('\n'));

    final srcs = <String>{};
    for (final n in nodes) _collectMdImages(n, srcs);
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
      for (final c in kids) _collectMdImages(c, out);
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
      return [pw.Header(level: level, text: node.textContent)];

    case 'p':
      return [pw.Paragraph(text: node.textContent)];

    case 'ul':
      return [
        for (final li in node.children ?? <md.Node>[])
          if (li is md.Element) pw.Bullet(text: li.textContent),
      ];

    case 'ol':
      final items = node.children ?? <md.Node>[];
      return [
        for (var i = 0; i < items.length; i++)
          if (items[i] is md.Element)
            pw.Bullet(text: '${i + 1}. ${(items[i] as md.Element).textContent}'),
      ];

    case 'blockquote':
      return [
        pw.Container(
          padding: const pw.EdgeInsets.only(left: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 2, color: PdfColors.grey400),
            ),
          ),
          child: pw.Text(node.textContent),
        ),
      ];

    case 'pre':
      return [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          color: PdfColors.grey200,
          child: pw.Text(node.textContent),
        ),
      ];

    case 'img':
      final src = node.attributes['src'] ?? '';
      final p = images[src];
      return [p == null ? imagePlaceholder(src) : pw.Image(p, fit: pw.BoxFit.contain)];

    case 'styledspan':
      return [_mdStyledSpanToPdf(node)];

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

pw.Widget _mdStyledSpanToPdf(md.Element el) {
  final styleStr = el.attributes['style'] ?? '';
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

  final raw = el.textContent;
  final spans = <pw.InlineSpan>[];
  final buf = StringBuffer();

  void flush() {
    if (buf.isNotEmpty) {
      spans.add(
        pw.TextSpan(
          text: buf.toString(),
          style: pw.TextStyle(color: color, background: bg != null ? pw.BoxDecoration(color: bg) : null),
        ),
      );
      buf.clear();
    }
  }

  var i = 0;
  while (i < raw.length) {
    if (i + 1 < raw.length && raw[i] == '*' && raw[i + 1] == '*') {
      final end = raw.indexOf('**', i + 2);
      if (end > i) {
        flush();
        spans.add(
          pw.TextSpan(
            text: raw.substring(i + 2, end),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: color,
              background: bg != null ? pw.BoxDecoration(color: bg) : null,
            ),
          ),
        );
        i = end + 2;
        continue;
      }
    }
    if (raw[i] == '*') {
      final end = raw.indexOf('*', i + 1);
      if (end > i) {
        flush();
        spans.add(
          pw.TextSpan(
            text: raw.substring(i + 1, end),
            style: pw.TextStyle(
              fontStyle: pw.FontStyle.italic,
              color: color,
              background: bg != null ? pw.BoxDecoration(color: bg) : null,
            ),
          ),
        );
        i = end + 1;
        continue;
      }
    }
    if (raw[i] == '`') {
      final end = raw.indexOf('`', i + 1);
      if (end > i) {
        flush();
        spans.add(
          pw.TextSpan(
            text: raw.substring(i + 1, end),
            style: pw.TextStyle(
              font: pw.Font.courier(),
              background: pw.BoxDecoration(color: PdfColors.grey200),
            ),
          ),
        );
        i = end + 1;
        continue;
      }
    }
    buf.write(raw[i]);
    i++;
  }
  flush();

  return pw.RichText(text: pw.TextSpan(children: spans));
}