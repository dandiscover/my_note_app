// lib/services/epub_export/epub_platform_saver.dart
// EPUB 平台保存 — Web / Windows / Android 分流
// 依据：第五轮方案 v6 §5.6 / §5.8
// v9 修正：
//   - file_picker 12.2.0: FilePicker.saveFile（静态方法，返回 Uri?）
//   - share_plus 13.3.0: SharePlus.instance.share(ShareParams(...))

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// EPUB 平台保存工具
class EpubPlatformSaver {
  EpubPlatformSaver._();

  /// 保存单个 EPUB 到平台
  ///
  /// - Web：`SharePlus` 触发浏览器下载
  /// - Windows：`FilePicker.saveFile` 原生另存为对话框
  /// - Android：写应用文档目录 exports/ + `SharePlus` 分享
  /// - 其他：写应用文档目录兜底
  static Future<void> save(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: filename,
              mimeType: 'application/epub+zip',
            ),
          ],
          fileNameOverrides: [filename],
        ),
      );
      return;
    }

    if (Platform.isWindows) {
      // v9: file_picker 12.2.0 — saveFile 为静态方法，返回 Uri?
      await FilePicker.saveFile(
        dialogTitle: '保存 EPUB',
        fileName: filename,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['epub'],
        mimeType: 'application/epub+zip',
      );
      return;
    }

    if (Platform.isAndroid) {
      final file = await _writeToExportsDir(bytes, filename);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/epub+zip')],
          text: '导出 EPUB',
        ),
      );
      return;
    }

    // 兜底：写入文档目录
    await _writeToExportsDir(bytes, filename);
  }

  /// 批量保存（分别导出场景）
  ///
  /// 全部写入 `exports/` 目录，不弹分享
  /// 返回成功写入的文件路径列表
  static Future<List<String>> saveMany(
    List<({Uint8List bytes, String filename})> items,
  ) async {
    final savedPaths = <String>[];

    if (kIsWeb) {
      for (final item in items) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                item.bytes,
                name: item.filename,
                mimeType: 'application/epub+zip',
              ),
            ],
            fileNameOverrides: [item.filename],
          ),
        );
      }
      return savedPaths;
    }

    // Android / Windows / 兜底：写入 exports/ 目录
    final appDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${appDir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    for (final item in items) {
      final file = File('${exportsDir.path}/${item.filename}');
      await file.writeAsBytes(item.bytes);
      savedPaths.add(file.path);
    }
    return savedPaths;
  }

  static Future<File> _writeToExportsDir(
    Uint8List bytes,
    String filename,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${appDir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final file = File('${exportsDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}