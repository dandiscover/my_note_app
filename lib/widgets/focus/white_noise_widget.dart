// lib/widgets/focus/white_noise_widget.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/white_noise_service.dart';
import '../../services/settings_service.dart';
import '../../models/user_settings.dart';
import 'add_noise_dialog.dart';

class WhiteNoiseWidget extends StatefulWidget {
  final VoidCallback onClose;
  const WhiteNoiseWidget({super.key, required this.onClose});

  @override
  State<WhiteNoiseWidget> createState() => _WhiteNoiseWidgetState();
}

class _WhiteNoiseWidgetState extends State<WhiteNoiseWidget> {
  final WhiteNoiseService _service = WhiteNoiseService();
  final SettingsService _settingsService = SettingsService();
  UserSettings? _settings;
  String _selected = 'rain';
  double _volume = 0.5;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _volume = s.whiteNoiseVolume;
    });
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _service.stop();
      if (!mounted) return;
      setState(() => _playing = false);
    } else {
      await _service.play(_selected, _volume);
      if (!mounted) return;
      setState(() => _playing = true);
    }
  }

  Future<void> _addSource() async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AddNoiseDialog(),
    );
    if (r == null || !mounted) return;
    final s = await _settingsService.load();
    s.customNoiseSources = [...s.customNoiseSources, r];
    await _settingsService.save(s);
    if (!mounted) return;
    setState(() => _settings = s);
  }

  Future<void> _removeCustom(int index) async {
    final s = await _settingsService.load();
    final item = s.customNoiseSources[index];
    final path = item['path'] as String?;
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    final mutable = List<Map<String, dynamic>>.from(s.customNoiseSources);
    mutable.removeAt(index);
    s.customNoiseSources = mutable;
    await _settingsService.save(s);
    if (!mounted) return;
    setState(() => _settings = s);
  }

  @override
  void dispose() {
    unawaited(_service.disposeAll());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builtIn = [
      {'key': 'rain', 'label': '🌧️ 雨声'},
      {'key': 'river1', 'label': '🌊 河流 A'},
      {'key': 'river2', 'label': '🌊 河流 B'},
      {'key': 'fire', 'label': '🔥 火堆'},
    ];
    final custom = _settings?.customNoiseSources ?? [];

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('白噪音',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: '添加音源',
                  onPressed: _addSource,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...builtIn.map((o) => ChoiceChip(
                      label: Text(o['label']!),
                      selected: _selected == o['key'],
                      onSelected: (_) {
                        setState(() => _selected = o['key']!);
                        if (_playing) _service.play(_selected, _volume);
                      },
                    )),
                ...custom.asMap().entries.map((e) {
                  final key = e.value['path'] as String;
                  final label = e.value['name'] as String;
                  return GestureDetector(
                    onLongPress: () => _removeCustom(e.key),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _selected == key,
                      onSelected: (_) {
                        setState(() => _selected = key);
                        if (_playing) _service.play(_selected, _volume);
                      },
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  onPressed: _toggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      _service.setVolume(v);
                    },
                    onChangeEnd: (v) async {
                      final s = await _settingsService.load();
                      s.whiteNoiseVolume = v;
                      await _settingsService.save(s);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}