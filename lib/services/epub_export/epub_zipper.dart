// lib/services/epub_export/epub_zipper.dart
// EPUB ZIP 打包 — mimetype STORED，其余 DEFLATE
// 依据：第五轮方案 v6 §5.4
// v9 修正：ZipEncoder.encode() 返回 List<int>? — 加 null 检查

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'structure_to_xhtml.dart';

/// EPUB 打包器
class EpubZipper {
  EpubZipper._();

  /// 打包为 EPUB 字节流
  ///
  /// [mimetype] 必须第一个 + STORED（用 ArchiveFile.noCompress）
  static Uint8List pack({
    required String containerXml,
    required String contentOpf,
    required String navXhtml,
    required String stylesCss,
    required Map<String, String> chapters,
    required Map<String, Uint8List> images,
  }) {
    final archive = Archive();

    // 1. mimetype 必须第一个 + STORED
    final mimetypeBytes = utf8.encode('application/epub+zip');
    archive.addFile(ArchiveFile.noCompress(
      'mimetype',
      mimetypeBytes.length,
      mimetypeBytes,
    ));

    // 2. META-INF/container.xml
    final containerBytes = utf8.encode(containerXml);
    archive.addFile(ArchiveFile(
      'META-INF/container.xml',
      containerBytes.length,
      containerBytes,
    ));

    // 3. OEBPS/content.opf
    final opfBytes = utf8.encode(contentOpf);
    archive.addFile(
      ArchiveFile('OEBPS/content.opf', opfBytes.length, opfBytes),
    );

    // 4. OEBPS/nav.xhtml
    final navBytes = utf8.encode(navXhtml);
    archive.addFile(
      ArchiveFile('OEBPS/nav.xhtml', navBytes.length, navBytes),
    );

    // 5. OEBPS/styles.css
    final cssBytes = utf8.encode(stylesCss);
    archive.addFile(
      ArchiveFile('OEBPS/styles.css', cssBytes.length, cssBytes),
    );

    // 6. chapters
    chapters.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile('OEBPS/$name', bytes.length, bytes));
    });

    // 7. images
    images.forEach((name, bytes) {
      archive.addFile(
        ArchiveFile('OEBPS/images/$name', bytes.length, bytes),
      );
    });

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw EpubExportException('ZIP 打包失败：ZipEncoder 返回 null');
    }
    return Uint8List.fromList(zipData);
  }
}