// lib/services/print/richtext_to_pdf.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../richtext_adapter/richtext_adapter.dart';
import '../richtext_adapter/shared/attributes.dart';
import 'note_pdf_builder.dart';
import 'pdf_image_loader.dart';

Future<Uint8List> buildRichtextPdf(
  String content, {
  required pw.ThemeData theme,
}) async {
  try {
    final structure = jsonDecode(content) as Map<String, dynamic>;
    final delta = RichtextAdapter.structureToDelta(structure).delta;

    final srcs = <String>{};
    for (final op in delta) {
      final ins = op['insert'];
      if (ins is Map) {
        final s = ins[DeltaAttributes.image];
        if (s is String && s.isNotEmpty) srcs.add(s);
      }
    }
    final images = await preloadImageMap(srcs);

    return await buildDoc(
      (ctx) => _deltaToPdf(delta, images),
      theme: theme,
    );
  } catch (e) {
    return buildErrorPdf('内容异常：$e', theme: theme);
  }
}

List<pw.Widget> _deltaToPdf(
  List<Map<String, dynamic>> delta,
  Map<String, pw.ImageProvider> images,
) {
  final out = <pw.Widget>[];
  final spans = <pw.InlineSpan>[];
  Map<String, dynamic>? blockAttrs;

  void flushBlock() {
    if (spans.isEmpty && blockAttrs == null) return;
    final plain = spans
        .whereType<pw.TextSpan>()
        .map((s) => s.text ?? '')
        .join();
    final rich = pw.RichText(text: pw.TextSpan(children: spans));

    if (blockAttrs != null) {
      final h = blockAttrs!['header'];
      final list = blockAttrs!['list'];
      final quote = blockAttrs!['blockquote'];
      final code = blockAttrs!['code-block'];
      if (h is int) {
        out.add(pw.Header(level: h, text: plain));
      } else if (list is String) {
        final prefix = list == 'ordered' ? '' : '• ';
        out.add(pw.Bullet(text: '$prefix$plain'));
      } else if (quote == true) {
        out.add(
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(width: 2, color: PdfColors.grey400),
              ),
            ),
            child: rich,
          ),
        );
      } else if (code == true) {
        out.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            color: PdfColors.grey200,
            child: rich,
          ),
        );
      } else {
        out.add(rich);
      }
    } else {
      out.add(rich);
    }
    spans.clear();
    blockAttrs = null;
  }

  for (final op in delta) {
    final ins = op['insert'];
    final attrs = op['attributes'];
    if (ins is String) {
      if (ins == '\n') {
        if (attrs is Map) blockAttrs = Map<String, dynamic>.from(attrs);
        flushBlock();
        continue;
      }
      spans.add(
        pw.TextSpan(
          text: ins,
          style: _pwStyle(attrs is Map ? Map<String, dynamic>.from(attrs) : null),
        ),
      );
    } else if (ins is Map) {
      if (ins.containsKey(DeltaAttributes.image)) {
        flushBlock();
        final src = ins[DeltaAttributes.image];
        final p = (src is String) ? images[src] : null;
        out.add(
          p == null
              ? imagePlaceholder(src is String ? src : '')
              : pw.Image(p, fit: pw.BoxFit.contain),
        );
      } else if (ins.containsKey(DeltaAttributes.divider)) {
        flushBlock();
        out.add(pw.Divider());
      } else if (ins.containsKey(DeltaAttributes.inkPlaceholder)) {
        flushBlock();
        out.add(imagePlaceholder('（画板内容不打印）'));
      }
    }
  }
  flushBlock();
  return out;
}

pw.TextStyle _pwStyle(Map<String, dynamic>? attrs) {
  if (attrs == null) return const pw.TextStyle();
  var weight = pw.FontWeight.normal;
  var style = pw.FontStyle.normal;
  if (attrs[DeltaAttributes.bold] == true) weight = pw.FontWeight.bold;
  if (attrs[DeltaAttributes.italic] == true) style = pw.FontStyle.italic;
  PdfColor? color;
  final c = attrs[DeltaAttributes.color];
  if (c is String) color = parseColorPdf(c);
  final underline = attrs[DeltaAttributes.underline] == true;
  final strike = attrs[DeltaAttributes.strike] == true;
  pw.TextDecoration? deco;
  if (strike && underline) {
    deco = pw.TextDecoration.combine([pw.TextDecoration.lineThrough, pw.TextDecoration.underline]);
  } else if (strike) {
    deco = pw.TextDecoration.lineThrough;
  } else if (underline) {
    deco = pw.TextDecoration.underline;
  }
  return pw.TextStyle(
    fontWeight: weight,
    fontStyle: style,
    color: color,
    decoration: deco,
  );
}