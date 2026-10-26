class MultiPaneBus {
  final String? Function() _findActiveBookId;
  final String? Function() _findActiveBookTitle;
  final void Function(String text) _sendToActiveNote;

  MultiPaneBus({
    required String? Function() findActiveBookId,
    required String? Function() findActiveBookTitle,
    required void Function(String text) sendToActiveNote,
  })  : _findActiveBookId = findActiveBookId,
        _findActiveBookTitle = findActiveBookTitle,
        _sendToActiveNote = sendToActiveNote;

  String? findActiveBookId() => _findActiveBookId();
  String? findActiveBookTitle() => _findActiveBookTitle();
  void sendToActiveNote(String text) => _sendToActiveNote(text);
}