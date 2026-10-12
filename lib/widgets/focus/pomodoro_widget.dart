// lib/widgets/focus/pomodoro_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/focus_service.dart';

class PomodoroWidget extends StatefulWidget {
  final VoidCallback onClose;
  const PomodoroWidget({super.key, required this.onClose});

  @override
  State<PomodoroWidget> createState() => _PomodoroWidgetState();
}

enum _Phase { focus, break_, idle }

class _PomodoroWidgetState extends State<PomodoroWidget> {
  final FocusService _service = FocusService();
  _Phase _phase = _Phase.idle;
  int _seconds = 25 * 60;
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _service.getSettings();
    if (!mounted) return;
    setState(() {
      _focusMinutes = s['focusMinutes'] ?? 25;
      _seconds = _focusMinutes * 60;
    });
  }

  void _start() {
    _timer?.cancel();
    if (_phase == _Phase.idle) {
      setState(() {
        _phase = _Phase.focus;
        _seconds = _focusMinutes * 60;
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _onPhaseEnd();
      }
    });
  }

  void _pause() => _timer?.cancel();

  void _reset() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _seconds = _focusMinutes * 60;
    });
  }

  void _onPhaseEnd() {
    _timer?.cancel();
    if (_phase == _Phase.focus) {
      _service.recordFocusSession(_focusMinutes);
      setState(() {
        _phase = _Phase.break_;
        _seconds = _breakMinutes * 60;
      });
      _showDialog('番茄完成', '开始 5 分钟休息？',
          onConfirm: _start, onSkip: _skipBreak);
    } else {
      setState(() {
        _phase = _Phase.focus;
        _seconds = _focusMinutes * 60;
      });
      _showDialog('休息结束', '开始下一轮？', onConfirm: _start, onSkip: _reset);
    }
  }

  void _skipBreak() {
    setState(() {
      _phase = _Phase.focus;
      _seconds = _focusMinutes * 60;
    });
  }

  void _showDialog(String title, String msg,
      {required VoidCallback onConfirm, required VoidCallback onSkip}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onSkip();
            },
            child: const Text('跳过'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        _phase == _Phase.break_ ? _breakMinutes * 60 : _focusMinutes * 60;
    final progress = total > 0 ? _seconds / total : 0.0;
    final isBreak = _phase == _Phase.break_;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1 - progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      isBreak ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  Text(_fmt(_seconds),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phase == _Phase.idle
                      ? '待开始'
                      : (isBreak ? '休息中' : '专注中'),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_timer?.isActive == true
                          ? Icons.pause
                          : Icons.play_arrow),
                      iconSize: 20,
                      onPressed:
                          _timer?.isActive == true ? _pause : _start,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      iconSize: 20,
                      onPressed: _reset,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}