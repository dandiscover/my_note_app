import 'dart:typed_data';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/note.dart';
import 'markdown_to_pdf.dart';
import 'richtext_to_pdf.dart';
import 'pdf_font_loader.dart';

class NotePrintService {
  NotePrintService._();

  static Future<void> printNote(NotebookEntry entry) async {
    final font = await PdfFontLoader.loadNotoSansSC();
    final theme = font != null
        ? pw.ThemeData.withFont(base: font, bold: font, fontFallback: [font])
        : pw.ThemeData.base();

    final Uint8List bytes = entry.contentFormat == 'richtext'
        ? await buildRichtextPdf(entry.content, theme: theme)
        : await buildMarkdownPdf(
            entry.content,
            title: entry.title,
            theme: theme,
          );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: entry.title.isEmpty ? 'note_${entry.id}' : entry.title,
    );
  }
}