// lib/services/spark_service.dart
// B8 · 火花卡服务
// 表 sparks（DB 25 落）：id / content / anchor_note_id / anchor_location / status / created_at / updated_at

import '../database_service.dart';

class Spark {
  final String id;
  final String content;
  final String? anchorNoteId;
  final String? anchorLocation; // 字符 offset（String 形式）
  final String status; // 'pending' | 'done'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Spark({
    required this.id,
    required this.content,
    this.anchorNoteId,
    this.anchorLocation,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'anchor_note_id': anchorNoteId,
        'anchor_location': anchorLocation,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory Spark.fromMap(Map<String, dynamic> m) => Spark(
        id: m['id'] as String,
        content: m['content'] as String,
        anchorNoteId: m['anchor_note_id'] as String?,
        anchorLocation: m['anchor_location'] as String?,
        status: (m['status'] as String?) ?? 'pending',
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: m['updated_at'] != null
            ? DateTime.tryParse(m['updated_at'] as String)
            : null,
      );

  Spark copyWith({
    String? content,
    String? anchorNoteId,
    String? anchorLocation,
    String? status,
    DateTime? updatedAt,
  }) =>
      Spark(
        id: id,
        content: content ?? this.content,
        anchorNoteId: anchorNoteId ?? this.anchorNoteId,
        anchorLocation: anchorLocation ?? this.anchorLocation,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class SparkService {
  final DatabaseService _db = DatabaseService();

  Future<String> create(Spark spark) async {
    final db = await _db.database;
    await db.insert('sparks', spark.toMap());
    return spark.id;
  }

  Future<void> update(Spark spark) async {
    final db = await _db.database;
    await db.update(
      'sparks',
      spark.toMap(),
      where: 'id = ?',
      whereArgs: [spark.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('sparks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Spark?> get(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('sparks', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Spark.fromMap(rows.first);
  }

  Future<List<Spark>> getByNote(String noteId) async {
    final db = await _db.database;
    final rows = await db.query(
      'sparks',
      where: 'anchor_note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Spark.fromMap).toList();
  }

  Future<List<Spark>> getPendingByNote(String noteId) async {
    final db = await _db.database;
    final rows = await db.query(
      'sparks',
      where: 'anchor_note_id = ? AND status = ?',
      whereArgs: [noteId, 'pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(Spark.fromMap).toList();
  }

  Future<List<Spark>> getAllPending() async {
    final db = await _db.database;
    final rows = await db.query(
      'sparks',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at DESC',
    );
    return rows.map(Spark.fromMap).toList();
  }
}