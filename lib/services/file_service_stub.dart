// lib/services/file_service_stub.dart
// 桌面端文件操作实现（使用 file_picker，无 dart:html）
// ✅ 修复：file_picker 12.x API 兼容（saveFile 需要 bytes 参数，返回 Uri?）

import 'dart:io' as io;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'file_service_interface.dart';

class FileService implements FileServiceInterface {
  @override
  Future<void> downloadFile(String content, String fileName, String mimeType) async {
    final bytes = utf8.encode(content);
    // ✅ file_picker 12.x: 必须传 bytes，返回 Uri?
    final Uri? outputUri = await FilePicker.saveFile(
      dialogTitle: '保存文件',
      fileName: fileName,
      bytes: bytes,
    );
    if (outputUri != null) {
      final file = io.File(outputUri.toFilePath());
      await file.writeAsBytes(bytes);
    }
  }

  @override
  Future<String?> pickJsonFile() async {
    // ✅ file_picker 12.x: pickFiles 返回 List<PlatformFile>?
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files == null || files.isEmpty) return null;
    final fileBytes = await files.first.xFile.readAsBytes();
    return utf8.decode(fileBytes);
  }
}