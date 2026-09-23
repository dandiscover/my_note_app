// lib/services/weread_key_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WereadKeyStore {
  static const _k = 'weread_api_key';
  static const _storage = FlutterSecureStorage();

  Future<bool> hasKey() async {
    final v = await _storage.read(key: _k);
    return v != null && v.isNotEmpty;
  }

  Future<String?> read() => _storage.read(key: _k);

  Future<void> save(String key) => _storage.write(key: _k, value: key);

  Future<void> clear() => _storage.delete(key: _k);
}