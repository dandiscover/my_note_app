// lib/services/supabase_service.dart
// Supabase 云存储服务（简化版，一次上传）

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static bool _initialized = false;

  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  SupabaseClient get client => Supabase.instance.client;

  /// 上传文件到 Storage
  Future<String> uploadFile({
    required String bucketName,
    required String path,
    required Uint8List fileBytes,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final totalBytes = fileBytes.length;

      // ✅ 一次上传即可（Supabase SDK 内部处理大文件分块）
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(contentType: contentType),
      );

      // ✅ 上传完成回调
      onProgress?.call(totalBytes, totalBytes);

      return client.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      throw Exception('上传文件失败: $e');
    }
  }

  /// 从 Storage 下载文件
  Future<Uint8List?> downloadFile({
    required String bucketName,
    required String path,
  }) async {
    try {
      final response = await client.storage.from(bucketName).download(path);
      return response;
    } catch (e) {
      return null;
    }
  }

  /// 删除文件
  Future<void> deleteFile({
    required String bucketName,
    required String path,
  }) async {
    try {
      await client.storage.from(bucketName).remove([path]);
    } catch (_) {}
  }

  bool get isLoggedIn => client.auth.currentUser != null;
  String? get currentUserId => client.auth.currentUser?.id;
  String? get currentUserEmail => client.auth.currentUser?.email;

  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> ensureBucket(String bucketName) async {
    try {
      await client.storage.createBucket(
        bucketName,
        BucketOptions(public: true),
      );
    } catch (_) {}
  }
}