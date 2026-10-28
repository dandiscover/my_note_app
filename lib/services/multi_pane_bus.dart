// lib/services/multi_pane_bus.dart
import 'package:flutter/material.dart';

enum MultiPaneContext { empty, reader, note, clueBoard }

class MultiPaneBus {
  final String? Function() _findActiveBookId;
  final String? Function() _findActiveBookTitle;
  final void Function(String text) _sendToActiveNote;

  int? readerChapter;
  String? readerSelectedText;

  final ValueNotifier<MultiPaneContext> activeContext =
      ValueNotifier(MultiPaneContext.empty);

  MultiPaneBus({
    required String? Function() findActiveBookId,
    required String? Function() findActiveBookTitle,
    required void Function(String text) sendToActiveNote,
  })  : _findActiveBookId = findActiveBookId,
        _findActiveBookTitle = findActiveBookTitle,
        _sendToActiveNote = sendToActiveNote;

  static final MultiPaneBus instance = MultiPaneBus(
    findActiveBookId: () => null,
    findActiveBookTitle: () => null,
    sendToActiveNote: (text) {},
  );

  String? findActiveBookId() => _findActiveBookId();
  String? findActiveBookTitle() => _findActiveBookTitle();
  void sendToActiveNote(String text) => _sendToActiveNote(text);

  void updateContext({int? chapter, String? text}) {
    if (chapter != null) {
      readerChapter = chapter;
      debugPrint('DEBUG MultiPaneBus 收到章节: $chapter');
    }
    if (text != null) {
      readerSelectedText = text;
      debugPrint('DEBUG MultiPaneBus 收到划词: $text');
    }
  }

  void setContext(MultiPaneContext ctx) {
    activeContext.value = ctx;
  }

  void clearReaderState() {
    readerChapter = null;
    readerSelectedText = null;
    activeContext.value = MultiPaneContext.empty;
  }
}