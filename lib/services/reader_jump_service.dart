// lib/services/reader_jump_service.dart
// 通用跳转协议，不绑 WebView。
// EPUB 用 JS；未来 PDF 用 pdfrx 坐标；TXT 用原生 offset。
import '../models/book_note.dart';

abstract class ReaderJumpService {
  Future<void> jumpToText(String text);
  Future<void> jumpToScroll(int top);
  Future<void> jumpToNote(BookNote note);
}