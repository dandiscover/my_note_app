// lib/services/rest_reminder_service.dart

import 'dart:async';

class RestReminderService {
  Timer? _timer;
  int _minutes = 45;
  void Function()? onRemind;

  void start(int minutes, void Function() onRemind) {
    stop();
    _minutes = minutes;
    this.onRemind = onRemind;
    _timer = Timer.periodic(Duration(minutes: minutes), (_) {
      this.onRemind?.call();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  int get minutes => _minutes;
}