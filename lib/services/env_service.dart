// lib/services/env_service.dart
// 环境变量加载工具

class EnvService {
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get supabaseUrl {
    if (_supabaseUrl.isEmpty) {
      throw Exception(
        '❌ SUPABASE_URL 未设置！\n'
        '请运行: flutter run -d edge --dart-define-from-file=.env'
      );
    }
    return _supabaseUrl;
  }

  static String get supabaseAnonKey {
    if (_supabaseAnonKey.isEmpty) {
      throw Exception(
        '❌ SUPABASE_ANON_KEY 未设置！\n'
        '请运行: flutter run -d edge --dart-define-from-file=.env'
      );
    }
    return _supabaseAnonKey;
  }
}