// lib/services/pdf_drawing_service.dart
// PDF 手绘划痕服务层
// 依赖 DatabaseService 的三个方法：
//   savePdfDrawing / getPdfDrawingsByBook / deletePdfDrawingsByBook

import '../database_service.dart';
import '../models/pdf_drawing.dart';

class PdfDrawingService {
  final DatabaseService _db = DatabaseService();

  /// 存或更新一条划痕
  Future<void> save(PdfDrawing drawing) async {
    await _db.savePdfDrawing(drawing);
  }

  /// 按 bookId 读取全部划痕
  Future<List<PdfDrawing>> getByBook(String bookId) async {
    return await _db.getPdfDrawingsByBook(bookId);
  }

  /// 按 bookId 清空全部划痕
  Future<void> deleteByBook(String bookId) async {
    await _db.deletePdfDrawingsByBook(bookId);
  }
}