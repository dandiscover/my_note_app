// VM / 移动端连接——不依赖 Web 库，避免 flutter test 拉入 wasm 依赖链
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openConnection() {
  return driftDatabase(name: 'my_note_app');
}