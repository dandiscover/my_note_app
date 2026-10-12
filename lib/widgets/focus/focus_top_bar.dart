// lib/widgets/focus/focus_top_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pet_action_notifier.dart';
import 'pomodoro_widget.dart';

class FocusTopBar extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onToggleMaterial;
  const FocusTopBar({
    super.key,
    required this.onExit,
    required this.onToggleMaterial,
  });

  @override
  State<FocusTopBar> createState() => _FocusTopBarState();
}

class _FocusTopBarState extends State<FocusTopBar> {
  bool _pomodoroOpen = false;
  StreamSubscription<PetAction>? _petSub;

  @override
  void initState() {
    super.initState();
    _petSub = PetActionNotifier.stream.listen((a) {
      if (!mounted) return;
      if (a == PetAction.openPomodoro) {
        setState(() => _pomodoroOpen = true);
      }
    });
  }

  @override
  void dispose() {
    _petSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: '番茄钟',
                onPressed: () => setState(() => _pomodoroOpen = !_pomodoroOpen),
              ),
              IconButton(
                icon: const Icon(Icons.water_drop_outlined),
                tooltip: '白噪音',
                onPressed: () => PetActionNotifier.trigger(PetAction.openNoise),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: '素材库',
                onPressed: widget.onToggleMaterial,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen_exit),
                tooltip: '退出专注',
                onPressed: widget.onExit,
              ),
            ],
          ),
        ),
        if (_pomodoroOpen)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PomodoroWidget(
                onClose: () => setState(() => _pomodoroOpen = false),
              ),
            ),
          ),
      ],
    );
  }
}