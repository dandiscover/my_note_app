// lib/services/print/pdf_image_loader.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import '../image_path_service.dart';

/// 图片统一加载器。超时或失败均跳过，返回的 Map 里可能缺 key。
Future<Map<String, pw.ImageProvider>> preloadImageMap(
  Set<String> srcs, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final out = <String, pw.ImageProvider>{};
  for (final src in srcs) {
    try {
      final p = await _loadOne(src).timeout(timeout);
      if (p != null) out[src] = p;
    } catch (_) {
      // 超时 / 失败 / 路径不存在，跳过，调用方占位
    }
  }
  return out;
}

Future<pw.ImageProvider?> _loadOne(String src) async {
  final uri = Uri.tryParse(src);
  if (uri == null) return null;

  if (uri.hasScheme) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final r = await http.get(uri);
      if (r.statusCode != 200) return null;
      return pw.MemoryImage(r.bodyBytes);
    }
    if (uri.scheme == 'data') {
      final bytes = uri.data?.contentAsBytes();
      if (bytes == null || bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    }
    if (uri.scheme == 'file') {
      final f = File(uri.toFilePath());
      if (!await f.exists()) return null;
      return pw.MemoryImage(await f.readAsBytes());
    }
    return null;
  }

  final full = ImagePathService.instance.resolve(uri.path);
  final f = File(full);
  if (!await f.exists()) return null;
  return pw.MemoryImage(await f.readAsBytes());
}