// lib/services/sync/cloud_sync_service.dart
// 云端同步核心服务 — 完整版（含 deleteNote）

import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_service.dart';
import '../../models/note.dart';
import '../../models/node.dart';
import '../../models/task.dart';
import '../../models/card.dart';
import '../../models/book.dart';
import '../../models/pet.dart';
import '../../models/book_note.dart';
import '../../models/user_settings.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  SupabaseClient get _client => SupabaseService().client;
  String? get _userId => SupabaseService().currentUserId;

  bool get isLoggedIn => SupabaseService().isLoggedIn;

  // ═══════════════════════════════════════════════════════════════
  // 1. 笔记同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncNote(NotebookEntry note) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('notes').upsert({
        'id': note.id,
        'user_id': _userId!,
        'title': note.title,
        'content': note.content,
        'status': note.status,
        'editor_mode': note.editorMode,
        'is_locked': note.isLocked ? 1 : 0,
        'tags': note.tags,
        'updated_at': note.updatedAt.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('note', note.id, note.toMap());
    }
  }

  /// ✅ 删除笔记（云端同步）
  Future<void> deleteNote(String noteId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('notes').delete().eq('id', noteId);
    } catch (_) {}
  }

  Future<void> syncNotes(List<NotebookEntry> notes) async {
    if (!isLoggedIn || _userId == null) return;
    for (var note in notes) {
      await syncNote(note);
    }
  }

  Future<List<NotebookEntry>> pullNotes() async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('notes')
        .select()
        .eq('user_id', _userId!)
        .order('updated_at', ascending: false);

    return (response as List).map((m) => NotebookEntry(
      id: m['id'],
      title: m['title'],
      content: m['content'] ?? '',
      updatedAt: DateTime.parse(m['updated_at']),
      status: m['status'] ?? 'raw',
      editorMode: m['editor_mode'] ?? 'plain',
      tags: (m['tags'] as List?)?.cast<String>() ?? [],
      isLocked: (m['is_locked'] ?? 0) == 1,
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. 节点（文件夹）同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncNode(Node node) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('nodes').upsert({
        'id': node.id,
        'user_id': _userId!,
        'title': node.title,
        'parent_id': node.parentId,
        'is_folder': node.isFolder,
        'node_type': node.nodeType,
        'target_id': node.targetId,
        'sort_order': node.sortOrder,
        'tags': node.tags,
        'updated_at': node.updatedAt.toIso8601String(),
        'created_at': node.createdAt.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('node', node.id, node.toMap());
    }
  }

  Future<void> deleteNode(String nodeId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('nodes').delete().eq('id', nodeId);
    } catch (_) {}
  }

  Future<void> syncNodes(List<Node> nodes) async {
    if (!isLoggedIn || _userId == null) return;
    for (var node in nodes) {
      await syncNode(node);
    }
  }

  Future<List<Node>> pullNodes() async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('nodes')
        .select()
        .eq('user_id', _userId!)
        .order('sort_order', ascending: true);

    return (response as List).map((m) => Node(
      id: m['id'],
      title: m['title'],
      parentId: m['parent_id'],
      isFolder: m['is_folder'] ?? false,
      nodeType: m['node_type'] ?? 'folder',
      targetId: m['target_id'],
      sortOrder: m['sort_order'] ?? 0,
      tags: (m['tags'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(m['created_at']),
      updatedAt: DateTime.parse(m['updated_at']),
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. 图书同步（包括阅读进度）
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncBook(Book book) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('books').upsert({
        'id': book.id,
        'user_id': _userId!,
        'title': book.title,
        'author': book.author,
        'isbn': book.isbn,
        'cover_url': book.coverUrl,
        'file_path': book.filePath,
        'file_type': book.fileType,
        'file_name': book.fileName,
        'file_size': book.fileSize,
        'status': book.status,
        'reading_progress': book.readingProgress,
        'total_pages': book.totalPages,
        'created_at': book.createdAt.toIso8601String(),
        'last_read_at': book.lastReadAt?.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('book', book.id, book.toMap());
    }
  }

  Future<void> deleteBook(String bookId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('books').delete().eq('id', bookId);
    } catch (_) {}
  }

  Future<void> syncBooks(List<Book> books) async {
    if (!isLoggedIn || _userId == null) return;
    for (var book in books) {
      await syncBook(book);
    }
  }

  Future<void> syncBookProgress(String bookId, int progress, int totalPages) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('books').update({
        'reading_progress': progress,
        'total_pages': totalPages,
        'last_read_at': DateTime.now().toIso8601String(),
      }).eq('id', bookId).eq('user_id', _userId!);
    } catch (_) {}
  }

  Future<List<Book>> pullBooks() async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('books')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List).map((m) => Book(
      id: m['id'],
      title: m['title'],
      author: m['author'] ?? '',
      isbn: m['isbn'] ?? '',
      coverUrl: m['cover_url'] ?? '',
      filePath: m['file_path'] ?? '',
      fileType: m['file_type'] ?? 'none',
      fileName: m['file_name'] ?? '',
      fileSize: m['file_size'] ?? 0,
      status: m['status'] ?? 'want',
      readingProgress: m['reading_progress'] ?? 0,
      totalPages: m['total_pages'] ?? 0,
      createdAt: DateTime.parse(m['created_at']),
      lastReadAt: m['last_read_at'] != null
          ? DateTime.tryParse(m['last_read_at'])
          : null,
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. 卡片同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncCard(CardModel card) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('cards').upsert({
        'id': card.id,
        'user_id': _userId!,
        'card_type': card.cardType.name,
        'source_type': card.sourceType,
        'source_id': card.sourceId,
        'source_title': card.sourceTitle,
        'tags': card.tags,
        'front': card.front,
        'back': card.back,
        'index_title': card.indexTitle,
        'author': card.author,
        'highlight': card.highlight,
        'question': card.question,
        'answer': card.answer,
        'fill_question': card.fillQuestion,
        'fill_answer': card.fillAnswer,
        'choice_question': card.choiceQuestion,
        'choice_options': card.choiceOptions,
        'choice_correct_index': card.choiceCorrectIndex,
        'tf_statement': card.tfStatement,
        'tf_is_true': card.tfIsTrue,
        'importance': card.importance.name,
        'memory_level': card.memoryLevel,
        'related_ids': card.relatedIds,
        'stage': card.stage,
        'mastered': card.mastered,
        'total_reviews': card.totalReviews,
        'failed_count': card.failedCount,
        'last_review_date': card.lastReviewDate?.toIso8601String(),
        'next_review_date': card.nextReviewDate?.toIso8601String(),
        'updated_at': card.updatedAt.toIso8601String(),
        'created_at': card.createdAt.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('card', card.id, card.toJson());
    }
  }

  Future<void> deleteCard(String cardId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('cards').delete().eq('id', cardId);
    } catch (_) {}
  }

  Future<void> syncCards(List<CardModel> cards) async {
    if (!isLoggedIn || _userId == null) return;
    for (var card in cards) {
      await syncCard(card);
    }
  }

  Future<List<CardModel>> pullCards() async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('cards')
        .select()
        .eq('user_id', _userId!);

    return (response as List).map((m) => CardModel(
      id: m['id'],
      cardType: CardType.values.firstWhere(
        (e) => e.name == m['card_type'],
        orElse: () => CardType.review,
      ),
      sourceType: m['source_type'] ?? '',
      sourceId: m['source_id'] ?? '',
      sourceTitle: m['source_title'],
      tags: (m['tags'] as List?)?.cast<String>() ?? [],
      front: m['front'],
      back: m['back'],
      indexTitle: m['index_title'],
      author: m['author'],
      highlight: m['highlight'],
      question: m['question'],
      answer: m['answer'],
      fillQuestion: m['fill_question'],
      fillAnswer: m['fill_answer'],
      choiceQuestion: m['choice_question'],
      choiceOptions: (m['choice_options'] as List?)?.cast<String>(),
      choiceCorrectIndex: m['choice_correct_index'],
      tfStatement: m['tf_statement'],
      tfIsTrue: m['tf_is_true'],
      importance: Importance.values.firstWhere(
        (e) => e.name == m['importance'],
        orElse: () => Importance.medium,
      ),
      memoryLevel: (m['memory_level'] ?? 0.5).toDouble(),
      relatedIds: (m['related_ids'] as List?)?.cast<String>() ?? [],
      stage: m['stage'] ?? 0,
      mastered: m['mastered'] ?? false,
      totalReviews: m['total_reviews'] ?? 0,
      failedCount: m['failed_count'] ?? 0,
      lastReviewDate: m['last_review_date'] != null
          ? DateTime.tryParse(m['last_review_date'])
          : null,
      nextReviewDate: m['next_review_date'] != null
          ? DateTime.tryParse(m['next_review_date'])
          : null,
      createdAt: DateTime.parse(m['created_at']),
      updatedAt: DateTime.parse(m['updated_at']),
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. 任务同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncTask(Task task) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('tasks').upsert({
        'id': task.id,
        'user_id': _userId!,
        'title': task.title,
        'type': task.type.string,
        'description': task.description,
        'difficulty': task.difficulty.string,
        'urgency': task.urgency.string,
        'necessity': task.necessity.string,
        'is_done': task.isDone,
        'note_id': task.noteId,
        'subtask_ids': task.subtaskIds,
        'reminder_time': task.reminderTime?.toIso8601String(),
        'created_at': task.createdAt.toIso8601String(),
        'completed_at': task.completedAt?.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('task', task.id, task.toJson());
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('tasks').delete().eq('id', taskId);
    } catch (_) {}
  }

  Future<void> syncTasks(List<Task> tasks) async {
    if (!isLoggedIn || _userId == null) return;
    for (var task in tasks) {
      await syncTask(task);
    }
  }

  Future<List<Task>> pullTasks() async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List).map((m) => Task(
      id: m['id'],
      title: m['title'],
      type: TaskTypeExt.fromString(m['type'] ?? 'quick'),
      description: m['description'],
      difficulty: DifficultyExt.fromString(m['difficulty'] ?? 'medium'),
      urgency: UrgencyExt.fromString(m['urgency'] ?? 'medium'),
      necessity: NecessityExt.fromString(m['necessity'] ?? 'important'),
      isDone: m['is_done'] ?? false,
      createdAt: DateTime.parse(m['created_at']),
      completedAt: m['completed_at'] != null
          ? DateTime.tryParse(m['completed_at'])
          : null,
      noteId: m['note_id'],
      subtaskIds: (m['subtask_ids'] as List?)?.cast<String>() ?? [],
      reminderTime: m['reminder_time'] != null
          ? DateTime.tryParse(m['reminder_time'])
          : null,
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. 子任务同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncSubtask(Subtask subtask) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('subtasks').upsert({
        'id': subtask.id,
        'user_id': _userId!,
        'parent_task_id': subtask.parentTaskId,
        'title': subtask.title,
        'is_done': subtask.isDone,
        'created_at': subtask.createdAt.toIso8601String(),
        'completed_at': subtask.completedAt?.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('subtask', subtask.id, subtask.toJson());
    }
  }

  Future<void> deleteSubtask(String subtaskId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('subtasks').delete().eq('id', subtaskId);
    } catch (_) {}
  }

  Future<void> syncSubtasks(List<Subtask> subtasks) async {
    if (!isLoggedIn || _userId == null) return;
    for (var subtask in subtasks) {
      await syncSubtask(subtask);
    }
  }

  Future<List<Subtask>> pullSubtasks() async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('subtasks')
        .select()
        .eq('user_id', _userId!);

    return (response as List).map((m) => Subtask(
      id: m['id'],
      parentTaskId: m['parent_task_id'],
      title: m['title'],
      isDone: m['is_done'] ?? false,
      createdAt: DateTime.parse(m['created_at']),
      completedAt: m['completed_at'] != null
          ? DateTime.tryParse(m['completed_at'])
          : null,
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. 宠物同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncPet(Pet pet) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('pets').upsert({
        'user_id': _userId!,
        'name': pet.name,
        'level': pet.level,
        'exp': pet.exp,
        'stage': pet.stage.name,
        'happiness': pet.happiness,
        'last_fed': pet.lastFed,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('pet', _userId!, pet.toMap());
    }
  }

  Future<Pet?> pullPet() async {
    if (!isLoggedIn || _userId == null) return null;
    final response = await _client
        .from('pets')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return Pet(
      name: response['name'] ?? '小云',
      level: response['level'] ?? 1,
      exp: response['exp'] ?? 0,
      stage: PetStage.values.firstWhere(
        (e) => e.name == response['stage'],
        orElse: () => PetStage.droplet,
      ),
      happiness: response['happiness'] ?? 80,
      lastFed: response['last_fed'] ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 8. 阅读笔记同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncBookNote(BookNote note) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('book_notes').upsert({
        'id': note.id,
        'user_id': _userId!,
        'book_id': note.bookId,
        'page_number': note.pageNumber,
        'selected_text': note.selectedText,
        'comment': note.comment,
        'color': note.color,
        'is_highlight': note.isHighlight,
        'created_at': note.createdAt.toIso8601String(),
      });
    } catch (e) {
      _addToRetryQueue('book_note', note.id, note.toMap());
    }
  }

  Future<void> deleteBookNote(String noteId) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('book_notes').delete().eq('id', noteId);
    } catch (_) {}
  }

  Future<List<BookNote>> pullBookNotes(String bookId) async {
    if (!isLoggedIn || _userId == null) return [];
    final response = await _client
        .from('book_notes')
        .select()
        .eq('book_id', bookId)
        .eq('user_id', _userId!);

    return (response as List).map((m) => BookNote(
      id: m['id'],
      bookId: m['book_id'],
      pageNumber: m['page_number'] ?? 0,
      selectedText: m['selected_text'] ?? '',
      comment: m['comment'] ?? '',
      color: m['color'] ?? '#FFD93D',
      createdAt: DateTime.parse(m['created_at']),
      isHighlight: m['is_highlight'] ?? true,
    )).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 9. 用户设置同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncSettings(UserSettings settings) async {
    if (!isLoggedIn || _userId == null) return;
    try {
      await _client.from('user_settings').upsert({
        'user_id': _userId!,
        'nickname': settings.nickname,
        'bio': settings.bio,
        'avatar_url': settings.avatarUrl,
        'theme_mode': settings.themeMode.name,
        'default_markdown': settings.defaultMarkdown,
        'review_reminder_hour': settings.reviewReminderHour,
        'review_reminder_minute': settings.reviewReminderMinute,
        'daily_review_limit': settings.dailyReviewLimit,
        'review_factor': settings.reviewFactor,
        'heatmap_stat_mode': settings.heatmapStatMode.name,
        'heatmap_high_threshold': settings.heatmapHighThreshold,
        'heatmap_burst_threshold': settings.heatmapBurstThreshold,
        'heatmap_word_high_threshold': settings.heatmapWordHighThreshold,
        'heatmap_word_burst_threshold': settings.heatmapWordBurstThreshold,
        'heatmap_color_scheme': settings.heatmapColorScheme.name,
        'heatmap_color_low': settings.heatmapColorLow,
        'heatmap_color_mid': settings.heatmapColorMid,
        'heatmap_color_high': settings.heatmapColorHigh,
        'heatmap_color_burst': settings.heatmapColorBurst,
        'show_pet': settings.showPet,
        'pet_skin': settings.petSkin,
        'pet_name': settings.petName,
        'pet_in_focus_mode': settings.petInFocusMode,
        'raw_note_retention_days': settings.rawNoteRetentionDays,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<UserSettings?> pullSettings() async {
    if (!isLoggedIn || _userId == null) return null;
    final response = await _client
        .from('user_settings')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return UserSettings(
      nickname: response['nickname'] ?? '小云同学',
      bio: response['bio'] ?? '📚 知识探索者',
      avatarUrl: response['avatar_url'] ?? '',
      themeMode: ThemeModePreference.values.firstWhere(
        (e) => e.name == response['theme_mode'],
        orElse: () => ThemeModePreference.light,
      ),
      defaultMarkdown: response['default_markdown'] ?? false,
      reviewReminderHour: response['review_reminder_hour'] ?? 20,
      reviewReminderMinute: response['review_reminder_minute'] ?? 0,
      dailyReviewLimit: response['daily_review_limit'] ?? 20,
      reviewFactor: (response['review_factor'] ?? 2.5).toDouble(),
      heatmapStatMode: HeatmapStatMode.values.firstWhere(
        (e) => e.name == response['heatmap_stat_mode'],
        orElse: () => HeatmapStatMode.count,
      ),
      heatmapHighThreshold: response['heatmap_high_threshold'] ?? 3,
      heatmapBurstThreshold: response['heatmap_burst_threshold'] ?? 8,
      heatmapWordHighThreshold: response['heatmap_word_high_threshold'] ?? 300,
      heatmapWordBurstThreshold: response['heatmap_word_burst_threshold'] ?? 800,
      heatmapColorScheme: HeatmapColorScheme.values.firstWhere(
        (e) => e.name == response['heatmap_color_scheme'],
        orElse: () => HeatmapColorScheme.emerald,
      ),
      heatmapColorLow: response['heatmap_color_low'] ?? '#E8F5E9',
      heatmapColorMid: response['heatmap_color_mid'] ?? '#81C784',
      heatmapColorHigh: response['heatmap_color_high'] ?? '#FFD93D',
      heatmapColorBurst: response['heatmap_color_burst'] ?? '#FF6B6B',
      showPet: response['show_pet'] ?? true,
      petSkin: response['pet_skin'] ?? 'default',
      petName: response['pet_name'] ?? '小云',
      petInFocusMode: response['pet_in_focus_mode'] ?? true,
      rawNoteRetentionDays: response['raw_note_retention_days'] ?? 15,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 重试队列
  // ═══════════════════════════════════════════════════════════════

  final List<Map<String, dynamic>> _retryQueue = [];
  static const int _maxRetries = 5;

  void _addToRetryQueue(String table, String id, Map<String, dynamic> data) {
    _retryQueue.add({
      'table': table,
      'id': id,
      'data': data,
      'retries': 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> processRetryQueue() async {
    if (_retryQueue.isEmpty || !isLoggedIn || _userId == null) return;

    final toRetry = List<Map<String, dynamic>>.from(_retryQueue);
    _retryQueue.clear();

    for (var item in toRetry) {
      try {
        if (item['retries'] >= _maxRetries) continue;
        switch (item['table']) {
          case 'note':
            await syncNote(NotebookEntry.fromMap(item['data']));
            break;
          case 'node':
            await syncNode(Node.fromMap(item['data']));
            break;
          case 'book':
            await syncBook(Book.fromMap(item['data']));
            break;
          case 'card':
            await syncCard(CardModel.fromJson(item['data']));
            break;
          case 'task':
            await syncTask(Task.fromJson(item['data']));
            break;
          case 'subtask':
            await syncSubtask(Subtask.fromJson(item['data']));
            break;
          case 'pet':
            await syncPet(Pet.fromMap(item['data']));
            break;
          case 'book_note':
            await syncBookNote(BookNote.fromMap(item['data']));
            break;
        }
        item['retries'] = 0;
      } catch (_) {
        item['retries'] = item['retries'] + 1;
        if (item['retries'] < _maxRetries) {
          _retryQueue.add(item);
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 全量同步
  // ═══════════════════════════════════════════════════════════════

  Future<void> syncAll({
    required List<NotebookEntry> notes,
    required List<Node> nodes,
    required List<Book> books,
    required List<CardModel> cards,
    required List<Task> tasks,
    required List<Subtask> subtasks,
    required Pet pet,
    required UserSettings settings,
  }) async {
    if (!isLoggedIn || _userId == null) throw Exception('请先登录');

    await Future.wait([
      syncNotes(notes),
      syncNodes(nodes),
      syncBooks(books),
      syncCards(cards),
      syncTasks(tasks),
      syncSubtasks(subtasks),
      syncPet(pet),
      syncSettings(settings),
    ]);

    await processRetryQueue();
  }

  Future<SyncResult> pullAll() async {
    if (!isLoggedIn || _userId == null) throw Exception('请先登录');

    final results = await Future.wait([
      pullNotes(),
      pullNodes(),
      pullBooks(),
      pullCards(),
      pullTasks(),
      pullSubtasks(),
      pullPet(),
      pullSettings(),
    ]);

    return SyncResult(
      notes: results[0] as List<NotebookEntry>,
      nodes: results[1] as List<Node>,
      books: results[2] as List<Book>,
      cards: results[3] as List<CardModel>,
      tasks: results[4] as List<Task>,
      subtasks: results[5] as List<Subtask>,
      pet: results[6] as Pet?,
      settings: results[7] as UserSettings?,
    );
  }
}

/// 同步结果
class SyncResult {
  final List<NotebookEntry> notes;
  final List<Node> nodes;
  final List<Book> books;
  final List<CardModel> cards;
  final List<Task> tasks;
  final List<Subtask> subtasks;
  final Pet? pet;
  final UserSettings? settings;

  SyncResult({
    required this.notes,
    required this.nodes,
    required this.books,
    required this.cards,
    required this.tasks,
    required this.subtasks,
    this.pet,
    this.settings,
  });
}