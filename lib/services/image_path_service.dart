// lib/services/image_path_service.dart
// R-3：图片本地路径解析

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImagePathService {
  ImagePathService._();
  static final ImagePathService instance = ImagePathService._();

  String? _docsPath;
  String? get docsPath => _docsPath;

  static const String imageSubDir = 'note_images';

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _docsPath = dir.path;
  }

  void _ensureInit() {
    if (_docsPath == null) {
      throw StateError(
        'ImagePathService 未 init —— main() 里是否漏调 ImagePathService.instance.init()？',
      );
    }
  }

  String resolve(String relPath) {
    _ensureInit();
    return p.join(_docsPath!, relPath);
  }

  String get imageDir {
    _ensureInit();
    return p.join(_docsPath!, imageSubDir);
  }

  String targetPath(String filename) => p.join(imageDir, filename);

  bool exists(String relPath) => File(resolve(relPath)).existsSync();
}