// lib/models/clue_stroke.dart
import 'dart:convert';
import 'package:flutter/material.dart';

class ClueStroke {
  final String id;
  final String viewId;
  final String? groupId;
  final int zIndex;
  final List<Offset> points;
  final Color color;
  final double width;
  final DateTime createdAt;

  const ClueStroke({
    required this.id,
    required this.viewId,
    this.groupId,
    this.zIndex = 0,
    required this.points,
    required this.color,
    required this.width,
    required this.createdAt,
  });

  ClueStroke copyWith({
    String? id,
    String? viewId,
    String? groupId,
    int? zIndex,
    List<Offset>? points,
    Color? color,
    double? width,
  }) =>
      ClueStroke(
        id: id ?? this.id,
        viewId: viewId ?? this.viewId,
        groupId: groupId ?? this.groupId,
        zIndex: zIndex ?? this.zIndex,
        points: points ?? this.points,
        color: color ?? this.color,
        width: width ?? this.width,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap(String viewId) => {
        'id': id,
        'viewId': viewId,
        'groupId': groupId,
        'zIndex': zIndex,
        'points': jsonEncode(points.map((p) => [p.dx, p.dy]).toList()),
        'color':
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'width': width,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toAlbumJson() => {
        'id': id,
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'color':
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'width': width,
      };

  factory ClueStroke.fromMap(Map<String, dynamic> m) {
    final ptsRaw = jsonDecode(m['points'] as String) as List;
    final pts = ptsRaw.map((e) {
      final xy = e as List;
      return Offset((xy[0] as num).toDouble(), (xy[1] as num).toDouble());
    }).toList();
    final c = m['color'] as String;
    final colorInt = int.parse(c.replaceFirst('#', ''), radix: 16) | 0xFF000000;
    return ClueStroke(
      id: m['id'] as String,
      viewId: m['viewId'] as String,
      groupId: m['groupId'] as String?,
      zIndex: (m['zIndex'] as num?)?.toInt() ?? 0,
      points: pts,
      color: Color(colorInt),
      width: (m['width'] as num).toDouble(),
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }

  /// 画册反序列化专用
  /// `viewId: 'global'` —— 占位 —— 复制时 copyWith 覆盖
  /// `createdAt: DateTime.now()` —— 占位 —— album 不存时间
  factory ClueStroke.fromJson(Map<String, dynamic> j) {
    final ptsRaw = j['points'] as List;
    final pts = ptsRaw.map((e) {
      final xy = e as List;
      return Offset((xy[0] as num).toDouble(), (xy[1] as num).toDouble());
    }).toList();
    final c = j['color'] as String;
    final colorInt = int.parse(c.replaceFirst('#', ''), radix: 16) | 0xFF000000;
    return ClueStroke(
      id: j['id'] as String,
      viewId: 'global',
      points: pts,
      color: Color(colorInt),
      width: (j['width'] as num).toDouble(),
      createdAt: DateTime.now(),
    );
  }
}