// lib/services/file_service_interface.dart
// 文件操作服务接口

abstract class FileServiceInterface {
  Future<void> downloadFile(String content, String fileName, String mimeType);
  Future<String?> pickJsonFile();
}