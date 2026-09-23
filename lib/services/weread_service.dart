// lib/services/weread_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weread_key_store.dart';
import 'package:flutter/foundation.dart' show debugPrint;
class WereadService {
  static const String _endpoint = 'https://i.weread.qq.com/api/agent/gateway';
  static const String _defaultVersion = '1.0.4';

  final WereadKeyStore _keyStore;
  final String? _injectedKey;

  WereadService({WereadKeyStore? keyStore, String? injectedKey})
      : _keyStore = keyStore ?? WereadKeyStore(),
        _injectedKey = injectedKey;

  bool upgradeNotified = false;

  Future<bool> get isConfigured async {
    if (_injectedKey != null && _injectedKey.isNotEmpty) return true;
    return _keyStore.hasKey();
  }

  Future<String?> _readKey() async {
    if (_injectedKey != null && _injectedKey.isNotEmpty) return _injectedKey;
    return _keyStore.read();
  }

  Future<Map<String, dynamic>> _post(
    String apiName, {
    Map<String, dynamic>? params,
  }) async {
    final key = await _readKey();
    if (key == null || key.isEmpty) {
      throw const WereadException('WEREAD_API_KEY 未配置');
    }

    final body = <String, dynamic>{
      'api_name': apiName,
      'skill_version': _defaultVersion,
      ...?params,
    };

    const delays = [1, 2, 4];
    for (var i = 0; i <= delays.length; i++) {
      try {
        final res = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        if (res.statusCode == 401 || res.statusCode == 403) {
          throw const WereadException('KEY_INVALID');
        }
        if (res.statusCode == 429 && i < delays.length) {
          await Future.delayed(Duration(seconds: delays[i]));
          continue;
        }
        if (res.statusCode != 200) {
          debugPrint('=== WEREAD HTTP 错误 ===');
          debugPrint('api: $apiName');
          debugPrint('params: $params');
          debugPrint('status: ${res.statusCode}');
          debugPrint('body: ${res.body}');
          debugPrint('========================');
          throw WereadException(
  '网关错误 ${res.statusCode}\n'
  'api: $apiName\n'
  'body: ${res.body}',
);
        }

        final json = jsonDecode(res.body) as Map<String, dynamic>;

        if (json['upgrade_info'] != null) {
          upgradeNotified = true;
        }

        final errcode = json['errcode'];
        if (errcode != null && errcode != 0) {
          final msg = json['errmsg']?.toString() ?? '未知错误';
          if (msg.contains('key') || msg.contains('auth') || msg.contains('登录')) {
            throw const WereadException('KEY_INVALID');
          }
          throw WereadException(
  'errcode $errcode\n'
  'api: $apiName\n'
  'body: ${res.body}',
);
        }

        return json;
      } catch (e) {
        if (e is WereadException && e.message == 'KEY_INVALID') rethrow;
        if (i == delays.length) rethrow;
        await Future.delayed(Duration(seconds: delays[i]));
      }
    }
    throw const WereadException('重试耗尽');
  }

  Future<List<Map<String, dynamic>>> fetchShelf() async {
    final r = await _post('/shelf/sync');
    return (r['books'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<Map<String, dynamic>> fetchBookInfo(String bookId) async {
    return await _post('/book/info', params: {'bookId': bookId});
  }

  Future<List<Map<String, dynamic>>> fetchBookmarks(String bookId) async {
    final all = <Map<String, dynamic>>[];
    int? lastSort;
    while (true) {
      final r = await _post('/book/bookmarklist', params: {
        'bookId': bookId,
        'count': 100,
        if (lastSort != null) 'lastSort': lastSort,
      });
      final items =
          (r['updated'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      all.addAll(items);
      if (r['hasMore'] != 1 || items.isEmpty) break;
      lastSort = r['lastSort'] as int?;
      if (lastSort == null) break;
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> fetchReviews(String bookId) async {
    final all = <Map<String, dynamic>>[];
    int? synckey;
    while (true) {
      final r = await _post('/review/list/mine', params: {
        'bookid': bookId,
        'count': 100,
        if (synckey != null) 'synckey': synckey,
      });
      final items =
          (r['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      all.addAll(items);
      if (r['hasMore'] != 1 || items.isEmpty) break;
      synckey = r['synckey'] as int?;
      if (synckey == null) break;
    }
    return all;
  }
}

class WereadException implements Exception {
  final String message;
  const WereadException(this.message);
  @override
  String toString() => message;
}