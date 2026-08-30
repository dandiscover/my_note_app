// lib/web_stub.dart
// Web 端 API 的空桩（仅用于桌面端编译）

// 这个文件在桌面端编译时作为 dart:html 的替代
// 所有方法都是空实现

class Blob {
  Blob(List content, String mimeType);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({required String href});
  void click() {}
  set download(String value) {}
}

class FileUploadInputElement {
  List<File>? files;
  void click() {}
  Stream<Event> get onChange => Stream.empty();
}

class FileReader {
  void readAsText(File file) {}
  Stream<Event> get onLoad => Stream.empty();
  String? get result => null;
}

class File {}
class Event {}