// lib/utils/markdown_image_builder.dart
// R-3：MarkdownBody imageBuilder 公共实现

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_path_service.dart';

Widget buildMarkdownImage(Uri uri) {
  // ── 有 scheme：网络 / data / file ──
  if (uri.hasScheme) {
    final scheme = uri.scheme;
    if (scheme == 'http' || scheme == 'https') {
      return Image.network(
        uri.toString(),
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 48),
      );
    }
    if (scheme == 'data') {
      return Image.network(
        uri.toString(),
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 48),
      );
    }
    if (scheme == 'file') {
      return Image.file(
        File(uri.toFilePath()),
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 48),
      );
    }
    return Image.network(
      uri.toString(),
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 48),
    );
  }

  // ── 相对路径 —— 用 uri.path（已解码）──
  final relPath = uri.path;
  final fullPath = ImagePathService.instance.resolve(relPath);
  return Image.file(
    File(fullPath),
    errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, size: 48),
  );
}