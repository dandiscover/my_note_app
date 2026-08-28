// lib/services/cache_manager.dart
// 全局数据缓存管理器

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _expiry = {};
  static const Duration _defaultTTL = Duration(minutes: 5);

  /// 获取缓存数据，如果过期或不存在则通过 loader 加载
  Future<T> get<T>(
    String key,
    Future<T> Function() loader, {
    Duration? ttl,
  }) async {
    // 检查缓存是否存在且未过期
    if (_cache.containsKey(key)) {
      final expiry = _expiry[key];
      if (expiry == null || DateTime.now().isBefore(expiry)) {
        return _cache[key] as T;
      }
      // 已过期，清除
      _cache.remove(key);
      _expiry.remove(key);
    }

    // 加载数据
    final result = await loader();
    _cache[key] = result;
    _expiry[key] = DateTime.now().add(ttl ?? _defaultTTL);
    return result;
  }

  /// 清除指定缓存
  void invalidate(String key) {
    _cache.remove(key);
    _expiry.remove(key);
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
    _expiry.clear();
  }

  /// 检查缓存是否存在
  bool has(String key) => _cache.containsKey(key);
}