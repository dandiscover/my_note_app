// lib/services/weread_import_service.dart
import '../models/book.dart';
import '../models/book_highlight.dart';
import '../models/card.dart';
import '../models/note.dart';
import '../database_service.dart'; 
import 'book_highlight_service.dart';

 // ← 对import 'book_highlight_service.dart';
import 'card_service.dart';
import 'note_book_link_service.dart';
import 'sync/cloud_sync_service.dart';
import 'weread_service.dart';

class WereadImportService {
  final WereadService _weread;
  final DatabaseService _db = DatabaseService();
  final BookHighlightService _highlights = BookHighlightService();
  final CardService _cardService = CardService();
  final NoteBookLinkService _nbl = NoteBookLinkService();
  final CloudSyncService _cloud = CloudSyncService();

  final void Function(String phase, int current, int total, String label)
      onProgress;

  WereadImportService({
    required WereadService weread,
    required this.onProgress,
  }) : _weread = weread;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  Future<void> importBooks(
    List<String> bookIds, {
    bool alsoGenerateCards = false,
  }) async {
    if (_isImporting) throw StateError('已有导入任务进行中');
    _isImporting = true;
    final newCards = <CardModel>[];
    final newNotes = <NotebookEntry>[];
    try {
      final total = bookIds.length;
      for (var i = 0; i < total; i++) {
        onProgress('local', i + 1, total,
            '正在写入本地：第 ${i + 1}/$total 本');
        await _importOne(
          bookIds[i],
          alsoGenerateCards: alsoGenerateCards,
          newCardsOut: newCards,
          newNotesOut: newNotes,
        );
      }
      if (_cloud.isLoggedIn && (newCards.isNotEmpty || newNotes.isNotEmpty)) {
        await _syncInBatches(newCards, newNotes);
      }
    } finally {
      _isImporting = false;
    }
  }

  Future<void> _importOne(
    String bookId, {
    required bool alsoGenerateCards,
    required List<CardModel> newCardsOut,
    required List<NotebookEntry> newNotesOut,
  }) async {
    final info = await _weread.fetchBookInfo(bookId);
    final remoteBook = _mapBook(info);

    // 去重 —— title 归一化 + author 三态辅助
    final allBooks = await _db.getAllBooks();
    final existing = _matchBook(allBooks, remoteBook.title, remoteBook.author);
    final localBookId = (existing?['id'] as String?) ?? remoteBook.id;
    if (existing == null) {
      await _db.insertBook(remoteBook.toMap());
      // 挂到图书馆节点——照搬 scan_isbn_page
      final libraryFolderId = await _db.ensureLibraryFolder();
      await _db.attachBookToNode(
        bookId: remoteBook.id,
        title: remoteBook.title,
        parentId: libraryFolderId,
      );
    }

    // 高亮
    final bookmarks = await _weread.fetchBookmarks(bookId);
    final highlights =
        bookmarks.map((b) => _mapHighlight(localBookId, b)).toList();
    await _highlights.addHighlights(highlights);

    // 可选卡片
    if (alsoGenerateCards && bookmarks.isNotEmpty) {
      final cards = bookmarks
          .map((b) => _mapCard(remoteBook.title, localBookId, b))
          .toList();
      await _cardService.addCardsSilent(cards);
      newCardsOut.addAll(cards);
    }

    // 想法 / 书评
    final allNotes = await _db.getAllNotes(includeDeleted: true);
    final existingIds = allNotes.map((m) => m['id'] as String).toSet();

    final reviews = await _weread.fetchReviews(bookId);
    for (final r in reviews) {
      final note = _mapReview(remoteBook.title, r);
      if (existingIds.contains(note.id)) continue;
      await _db.insertNote(note.toMap());
      existingIds.add(note.id);
      try {
        await _nbl.addLink(
          noteId: note.id,
          bookId: localBookId,
          linkType: NoteBookLinkService.linkTypeImport,
          context: _extractAbstract(r),
        );
      } catch (_) {}
      newNotesOut.add(note);
    }
  }

  Future<void> _syncInBatches(
    List<CardModel> cards,
    List<NotebookEntry> notes,
  ) async {
    const batchSize = 50;
    final total = cards.length + notes.length;
    var done = 0;
    for (var i = 0; i < cards.length; i += batchSize) {
      final batch = cards.sublist(i, (i + batchSize).clamp(0, cards.length));
      try { await _cloud.syncCards(batch); } catch (_) {}
      done += batch.length;
      onProgress('cloud', done, total, '正在同步云端');
      if (done < total) await Future.delayed(const Duration(milliseconds: 500));
    }
    for (var i = 0; i < notes.length; i += batchSize) {
      final batch = notes.sublist(i, (i + batchSize).clamp(0, notes.length));
      try { await _cloud.syncNotes(batch); } catch (_) {}
      done += batch.length;
      onProgress('cloud', done, total, '正在同步云端');
      if (done < total) await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Map<String, dynamic>? _matchBook(
    List<Map<String, dynamic>> allBooks,
    String remoteTitle,
    String remoteAuthor,
  ) {
    final rt = _normalizeTitle(remoteTitle);
    if (rt.isEmpty) return null;
    final ra = _normalizeAuthor(remoteAuthor);
    for (final b in allBooks) {
      final lt = _normalizeTitle((b['title'] as String?) ?? '');
      if (lt.isEmpty || lt != rt) continue;
      final la = _normalizeAuthor((b['author'] as String?) ?? '');
      if (ra.isEmpty || la.isEmpty) return b;
      if (ra == la) return b;
    }
    return null;
  }

  String _normalizeTitle(String t) {
    var s = t.trim();
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[\[【(（][^\]】)）]*[\]】)）]'), '');
    s = s.replaceAll(RegExp(r'(著|编著|主编|译|著者)$'), '');
    return s.toLowerCase();
  }

  String _normalizeAuthor(String a) {
    var s = a.trim();
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[\[【(（][^\]】)）]*[\]】)）]'), '');
    s = s.replaceAll(RegExp(r'(著|编著|主编|译|著者)$'), '');
    return s.toLowerCase();
  }

  Book _mapBook(Map<String, dynamic> info) {
    final finishReading = info['finishReading'] as int? ?? 0;
    final readUpdateTime = info['readUpdateTime'] as int?;
    return Book(
      id: info['bookId'] as String,
      title: info['title'] as String? ?? '',
      author: info['author'] as String? ?? '',
      isbn: info['isbn'] as String? ?? '',
      coverUrl: info['cover'] as String? ?? '',
      filePath: '',
      fileType: 'weread',
      fileName: '',
      fileSize: 0,
      status: finishReading == 1 ? 'finished' : 'reading',
      readingProgress: info['readingProgress'] as int? ?? 0,
      totalPages: 0,
      createdAt: DateTime.now(),
      lastReadAt: readUpdateTime != null
          ? DateTime.fromMillisecondsSinceEpoch(readUpdateTime * 1000)
          : null,
      source: 'import',
    );
  }

  BookHighlight _mapHighlight(String bookId, Map<String, dynamic> b) {
    return BookHighlight(
      id: 'wr_${b['bookmarkId']}',
      bookId: bookId,
      chapter: b['chapterTitle'] as String?,
      location: b['range']?.toString(),
      text: (b['markText'] ?? b['bookmarkText'] ?? '') as String,
      color: null,
      note: b['abstract'] as String?,
      createdAt: _parseTime(b['createTime']),
      source: 'weread',
    );
  }

  CardModel _mapCard(String sourceTitle, String bookId, Map<String, dynamic> b) {
    final chapter = b['chapterTitle'] as String?;
    final text = (b['markText'] ?? b['bookmarkText'] ?? '') as String;
    return CardModel(
      id: 'wr_card_${b['bookmarkId']}',
      cardType: CardType.indexCard,
      sourceType: 'book',
      sourceId: bookId,
      sourceTitle: sourceTitle,
      tags: [
        if (chapter != null && chapter.isNotEmpty) chapter,
        '微读',
      ],
      front: text,
      highlight: text,
      createdAt: _parseTime(b['createTime']),
    );
  }

  NotebookEntry _mapReview(String bookTitle, Map<String, dynamic> r) {
    final inner = (r['review'] as Map<String, dynamic>?) ?? r;
    final abstract = inner['abstract'] as String?;
    final content = (inner['content'] ?? inner['htmlContent'] ?? '') as String;
    final merged = (abstract != null && abstract.isNotEmpty)
        ? '> $abstract\n\n$content'
        : content;
    final reviewId = inner['reviewId'] ?? r['reviewId'];
    return NotebookEntry(
      id: 'wr_$reviewId',
      title: '$bookTitle·想法',
      content: merged,
      updatedAt: _parseTime(inner['createTime']),
      status: 'raw',
      editorMode: 'plain',
      tags: [bookTitle],
      contentFormat: 'markdown',
    );
  }

  String? _extractAbstract(Map<String, dynamic> r) {
    final inner = (r['review'] as Map<String, dynamic>?) ?? r;
    return inner['abstract'] as String?;
  }

  DateTime _parseTime(dynamic t) {
    if (t is int) return DateTime.fromMillisecondsSinceEpoch(t * 1000);
    if (t is String) return DateTime.tryParse(t) ?? DateTime.now();
    return DateTime.now();
  }
}