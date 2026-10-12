// lib/services/white_noise_service.dart

import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class WhiteNoiseService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentSource;

  static const Map<String, String> _builtIn = {
    'rain': 'assets/audio/dragon-studio-relaxing-rain-444802.mp3',
    'river1': 'assets/audio/grk8567-river-sounds-215254.mp3',
    'river2': 'assets/audio/nils_vega-river-sounds-450695.mp3',
    'fire': 'assets/audio/soundreality-fire-crackling-sound-499636.mp3',
  };

  static const List<String> _allowedExt = ['.mp3', '.wav', '.m4a', '.ogg'];
  static const int _maxBytes = 50 * 1024 * 1024;

  Map<String, String> get builtIn => _builtIn;

  Future<Directory> _customDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final d = Directory('${dir.path}/white_noise');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<String> addFromUrl(String name, String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) throw Exception('下载失败：${resp.statusCode}');
    if (resp.bodyBytes.length > _maxBytes) throw Exception('文件超过 50MB');
    final ext = _extOf(url);
    if (!_allowedExt.contains(ext)) throw Exception('不支持的格式：$ext');
    final d = await _customDir();
    final path = '${d.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(path).writeAsBytes(resp.bodyBytes);
    return path;
  }

  Future<String> addFromFile(String name, String srcPath) async {
    final file = File(srcPath);
    if (!await file.exists()) throw Exception('文件不存在');
    if (await file.length() > _maxBytes) throw Exception('文件超过 50MB');
    final ext = _extOf(srcPath);
    if (!_allowedExt.contains(ext)) throw Exception('不支持的格式：$ext');
    final d = await _customDir();
    final path = '${d.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
    await file.copy(path);
    return path;
  }

  String _extOf(String s) {
    final i = s.lastIndexOf('.');
    return i < 0 ? '' : s.substring(i).toLowerCase();
  }

  Future<void> play(String key, double volume) async {
    final asset = _builtIn[key];
    if (asset != null) {
      await _player.setAsset(asset);
    } else {
      await _player.setFilePath(key);
    }
    _currentSource = key;
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(volume);
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSource = null;
  }

  Future<void> setVolume(double v) async {
    await _player.setVolume(v);
  }

  Future<void> disposeAll() async {
    await _player.stop();
    await _player.dispose();
    _currentSource = null;
  }

  String? get currentSource => _currentSource;
}
