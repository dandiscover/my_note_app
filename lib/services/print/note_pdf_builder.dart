// lib/services/print/note_pdf_builder.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildDoc(
  List<pw.Widget> Function(pw.Context) builder, {
  required pw.ThemeData theme,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: theme,
      build: builder,
    ),
  );
  return doc.save();
}

Future<Uint8List> buildErrorPdf(
  String msg, {
  required pw.ThemeData theme,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: theme,
      build: (ctx) => pw.Center(child: pw.Text(msg)),
    ),
  );
  return doc.save();
}

pw.Widget imagePlaceholder(String src) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: PdfColors.grey400,
        style: pw.BorderStyle.dashed,
      ),
    ),
    child: pw.Text('[图片加载失败: $src]'),
  );
}

/// 与 markdown_custom_syntax._parseColor 逻辑同源，改一处须同步。
PdfColor? parseColorPdf(String raw) {
  var s = raw.trim().toLowerCase();
  if (s.isEmpty) return null;

  const named = {
    'red': 0xFFFF0000,
    'teal': 0xFF008080,
    'yellow': 0xFFFFFF00,
    'maroon': 0xFF800000,
    'tan': 0xFFD2B48C,
    'gray': 0xFF808080,
    'grey': 0xFF808080,
    'silver': 0xFFC0C0C0,
    'blue': 0xFF0000FF,
    'green': 0xFF008000,
    'orange': 0xFFFFA500,
    'purple': 0xFF800080,
  };
  if (named.containsKey(s)) return PdfColor.fromInt(named[s]!);

  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) {
    s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
  }
  if (s.length != 6) return null;
  try {
    return PdfColor.fromInt(0xFF000000 | int.parse(s, radix: 16));
  } catch (_) {
    return null;
  }
}