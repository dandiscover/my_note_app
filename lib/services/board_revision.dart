import 'package:flutter/foundation.dart';

class BoardRevision {
  static final ValueNotifier<int> revision = ValueNotifier(0);
  static void bump() => revision.value++;
}