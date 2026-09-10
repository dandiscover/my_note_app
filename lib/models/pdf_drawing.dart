// lib/models/pdf_drawing.dart
// PDF 手绘划痕模型
// 存储：PDF 页面坐标（原点左下角，Y 轴朝上）

import 'dart:convert';
import 'package:flutter/material.dart';

class PdfDrawing {
  final String id;
  final String bookId;
  final int page;
  final List<Offset> pdfPoints;
  final String color;
  final DateTime createdAt;

  PdfDrawing({
    required this.id,
    required this.bookId,
    required this.page,
    required this.pdfPoints,
    this.color = '#FFA500',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookId': bookId,
        'page': page,
        // Offset → [dx, dy] 数组 → JSON 字符串
        'points': jsonEncode(pdfPoints.map((p) => [p.dx, p.dy]).toList()),
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PdfDrawing.fromMap(Map<String, dynamic> map) {
    // JSON 字符串 → List<dynamic> → List<Offset>
    final decoded = jsonDecode(map['points'] as String) as List;
    return PdfDrawing(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      page: (map['page'] as num).toInt(),
      pdfPoints: decoded.map((e) {
        final p = e as List;
        return Offset(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        );
      }).toList(),
      color: map['color'] as String? ?? '#FFA500',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  PdfDrawing copyWith({
    String? id,
    String? bookId,
    int? page,
    List<Offset>? pdfPoints,
    String? color,
    DateTime? createdAt,
  }) {
    return PdfDrawing(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      page: page ?? this.page,
      pdfPoints: pdfPoints ?? this.pdfPoints,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}