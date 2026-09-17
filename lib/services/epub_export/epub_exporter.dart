// lib/services/epub_export/epub_exporter.dart
// EPUB 导出 — 门面
// 依据：第五轮方案 v6 §5.2 / §5.6 / §5.7 / §5.8 / §5.9 / §5.10
// v9 修正：UUID 生成器字符串拼接风格（prefer_interpolation_to_compose_strings）

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../../models/note.dart';
import 'epub_zipper.dart';
import 'opf_builder.dart';
import 'structure_to_xhtml.dart';
import 'styles_css.dart';

/// 导出结果（分别导出时逐本返回）
class ExportResult {
  final bool success;
  final String filename;
  final Uint8List? bytes;
  final String? errorMessage;
  const ExportResult({
    required this.success,
    required this.filename,
    this.bytes,
    this.errorMessage,
  });
}

/// 单本导出产物
class EpubBook {
  final Uint8List bytes;
  final String suggestedFilename;
  final String title;

  /// 合并导出时被跳过的笔记数
  final int skippedCount;

  const EpubBook({
    required this.bytes,
    required this.suggestedFilename,
    required this.title,
    this.skippedCount = 0,
  });
}

/// EPUB 导出门面
class EpubExporter {
  EpubExporter._();

  /// 合并导出：N 篇笔记 → 1 本 EPUB（N=1 即单篇）
  static EpubBook exportBook(List<NotebookEntry> notes) {
    if (notes.isEmpty) {
      throw EpubExportException('无笔记可导出');
    }

    final chapters = <Chapter>[];
    final allImages = <ImageRef>[];
    final seenSrc = <String, String>{};
    var skipped = 0;

    for (var n = 0; n < notes.length; n++) {
      final entry = notes[n];

      Map<String, dynamic> structure;
      try {
        final decoded = jsonDecode(entry.content);
        if (decoded is! Map) {
          skipped++;
          continue;
        }
        structure = decoded.cast<String, dynamic>();
      } catch (_) {
        skipped++;
        continue;
      }
      if (structure['version'] != 2) {
        skipped++;
        continue;
      }

      final chapterIndex = chapters.length + 1;
      final chapterTitle = _chapterTitle(entry, chapterIndex);

      final srcToPackaged = _makeSrcToPackaged(
        noteIndex: n + 1,
        seenSrc: seenSrc,
        allImages: allImages,
      );

      String xhtml;
      try {
        xhtml = StructureToXhtml.convert(
          structure: structure,
          chapterTitle: chapterTitle,
          srcToPackaged: srcToPackaged,
        );
      } catch (_) {
        skipped++;
        continue;
      }

      chapters.add(Chapter(title: chapterTitle, xhtml: xhtml));
    }

    if (chapters.isEmpty) {
      throw EpubExportException('无有效笔记可导出');
    }

    final title = _bookTitle(notes);
    final uuid = _genUuidV4();

    final containerXml = OpfBuilder.buildContainerXml();
    final contentOpf = OpfBuilder.buildContentOpf(
      uuid: uuid,
      title: title,
      chapters: chapters,
      allImages: allImages,
    );
    final navXhtml = OpfBuilder.buildNavXhtml(chapters: chapters);

    final chapterMap = <String, String>{};
    for (var i = 0; i < chapters.length; i++) {
      chapterMap['chapter_${i + 1}.xhtml'] = chapters[i].xhtml;
    }

    // 图片字节：由调用方预加载后传入
    // TODO（v6 记账，本轮接受）：调用方加载图片字节后注入
    final imageMap = <String, Uint8List>{};

    final bytes = EpubZipper.pack(
      containerXml: containerXml,
      contentOpf: contentOpf,
      navXhtml: navXhtml,
      stylesCss: kEpubStylesCss,
      chapters: chapterMap,
      images: imageMap,
    );

    final filename = _bookFilename(notes) + '.epub';
    return EpubBook(
      bytes: bytes,
      suggestedFilename: filename,
      title: title,
      skippedCount: skipped,
    );
  }

  /// 分别导出：N 篇笔记 → N 本 EPUB（每本独立）
  static List<ExportResult> exportSeparate(List<NotebookEntry> notes) {
    final results = <ExportResult>[];
    for (var i = 0; i < notes.length; i++) {
      final entry = notes[i];
      try {
        final book = exportBook([entry]);
        results.add(ExportResult(
          success: true,
          filename: book.suggestedFilename,
          bytes: book.bytes,
        ));
      } catch (e) {
        results.add(ExportResult(
          success: false,
          filename: '${_sanitizeFilename(_chapterTitle(entry, 1))}.epub',
          errorMessage: e.toString(),
        ));
      }
    }
    return results;
  }

  // ─── 内部工具 ─────────────────────────────────────

  /// 章节标题 — 裁定 11：有标题 → 笔记标题；无标题 → 「第 N 章」
  static String _chapterTitle(NotebookEntry entry, int index) {
    final t = entry.title.trim();
    return t.isEmpty ? '第 $index 章' : t;
  }

  static String _bookTitle(List<NotebookEntry> notes) {
    if (notes.length == 1) {
      return _chapterTitle(notes.first, 1);
    }
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '合并导出 $y-$m-$d';
  }

  static String _bookFilename(List<NotebookEntry> notes) {
    if (notes.length == 1) {
      return _sanitizeFilename(_chapterTitle(notes.first, 1));
    }
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '合并导出_$y$m$d$hh$mm$ss';
  }

  /// 生成 src → packagedName 闭包
  ///
  /// 跨篇相同 src 复用（不加前缀）；
  /// 同名冲突时加 n{n}_ 前缀（v6 §5.5）
  ///
  /// ⚠️ 记账 8（不阻塞）：v6 §5.5 说「同篇内加 `_1` `_2`」，
  ///   本实现统一用 `n{noteIndex}_` 前缀；语义偏差已记账。
  static String Function(String) _makeSrcToPackaged({
    required int noteIndex,
    required Map<String, String> seenSrc,
    required List<ImageRef> allImages,
  }) {
    return (String src) {
      if (seenSrc.containsKey(src)) {
        return seenSrc[src]!;
      }
      final original = path.basename(src);
      final baseName =
          original.isEmpty ? 'img_${allImages.length + 1}.png' : original;
      final existing = allImages.map((e) => e.packagedName).toSet();
      final packaged = _resolveName(
        name: baseName,
        noteIndex: noteIndex,
        existing: existing,
      );
      seenSrc[src] = packaged;
      allImages.add(ImageRef(src: src, packagedName: packaged));
      return packaged;
    };
  }

  static String _resolveName({
    required String name,
    required int noteIndex,
    required Set<String> existing,
  }) {
    if (!existing.contains(name)) return name;
    final prefixed = 'n${noteIndex}_$name';
    if (!existing.contains(prefixed)) return prefixed;
    var i = 1;
    while (existing.contains('n${noteIndex}_${i}_$name')) {
      i++;
    }
    return 'n${noteIndex}_${i}_$name';
  }

  static String _sanitizeFilename(String input) {
    final invalid = RegExp(r'[/\\:*?"<>|]');
    final sanitized = input.replaceAll(invalid, '_').trim();
    return sanitized.isEmpty ? '未命名' : sanitized;
  }

  static String _genUuidV4() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    final p1 = h.substring(0, 8);
    final p2 = h.substring(8, 12);
    final p3 = h.substring(12, 16);
    final p4 = h.substring(16, 20);
    final p5 = h.substring(20);
    return '$p1-$p2-$p3-$p4-$p5';
  }
}