// lib/services/file_service_stub.dart
// 桌面端文件操作实现（使用 file_picker，无 dart:html）

import 'dart:io' as io;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'file_service_interface.dart';

class FileService implements FileServiceInterface {
  @override
  Future<void> downloadFile(String content, String fileName, String mimeType) async {
    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '保存文件',
      fileName: fileName,
    );
    if (outputFile != null) {
      final file = io.File(outputFile);
      await file.writeAsString(content);
    }
  }

  @override
  Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return null;
    final fileBytes = result.files.first.bytes;
    return utf8.decode(fileBytes!);
  }
}