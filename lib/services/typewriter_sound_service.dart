// lib/services/typewriter_sound_service.dart

import 'package:just_audio/just_audio.dart';

class TypewriterSoundService {
  final AudioPlayer _player = AudioPlayer();
  DateTime _lastPlay = DateTime.fromMillisecondsSinceEpoch(0);
  bool _enabled = false;
  bool _ready = false;

  Future<void> init() async {
    await _player.setAsset(
        'assets/audio/soul_serenity_sounds-typing-sound-02-229861.mp3');
    await _player.setVolume(0.3);
    _ready = true;
  }

  void setEnabled(bool v) => _enabled = v;
  bool get enabled => _enabled;

  void playKey() {
    if (!_enabled || !_ready) return;
    final now = DateTime.now();
    if (now.difference(_lastPlay).inMilliseconds < 100) return;
    _lastPlay = now;
    _player.seek(Duration.zero).then((_) => _player.play());
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}