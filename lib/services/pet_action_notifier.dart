// lib/services/pet_action_notifier.dart

import 'dart:async';

enum PetAction { openPomodoro, openNoise, openLog }

class PetActionNotifier {
  static final StreamController<PetAction> _controller =
      StreamController<PetAction>.broadcast();
  static Stream<PetAction> get stream => _controller.stream;
  static void trigger(PetAction a) => _controller.add(a);
}