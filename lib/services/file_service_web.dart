// lib/services/file_service_web.dart
// Web 端文件操作实现

import 'dart:html' as html;
import 'file_service_interface.dart';

class FileService implements FileServiceInterface {
  @override
  Future<void> downloadFile(String content, String fileName, String mimeType) async {
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Future<String?> pickJsonFile() async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();
    await input.onChange.first;
    if (input.files!.isEmpty) return null;
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    return reader.result as String?;
  }
}