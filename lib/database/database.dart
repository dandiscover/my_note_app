// lib/database/database.dart
// Drift 数据库定义 — 换库 Phase 1（25 表）
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'connection_web.dart' if (dart.library.io) 'connection_native.dart';

part 'database.g.dart';

// ═══════════════════════════════════════════════════════════════
// 1. 笔记 + 节点
// ═══════════════════════════════════════════════════════════════

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get updatedAt => text().named('updated_at').nullable()();
  TextColumn get status => text().withDefault(const Constant('raw'))();
  TextColumn get editorMode =>
      text().named('editor_mode').withDefault(const Constant('plain'))();
  IntColumn get isLocked =>
      integer().named('is_locked').withDefault(const Constant(0))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get inquiryQuestion =>
      text().named('inquiry_question').nullable()();
  TextColumn get inquiryConclusion =>
      text().named('inquiry_conclusion').nullable()();
  TextColumn get exploreTasks =>
      text().named('explore_tasks').withDefault(const Constant('[]'))();
  TextColumn get contentFormat =>
      text().named('content_format').withDefault(const Constant('markdown'))();
  TextColumn get createdAt => text().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NodeRow')
class Nodes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get parentId => text().named('parent_id').nullable()();
  BoolColumn get isFolder =>
      boolean().named('is_folder').withDefault(const Constant(false))();
  TextColumn get nodeType =>
      text().named('node_type').withDefault(const Constant('folder'))();
  TextColumn get targetId => text().named('target_id').nullable()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get systemTag => text().named('system_tag').nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
  TextColumn get updatedAt => text().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 2. 图书 + 批注 + 高亮
// ═══════════════════════════════════════════════════════════════

@DataClassName('BookRow')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get isbn => text().withDefault(const Constant(''))();
  TextColumn get coverUrl => text().named('cover_url').nullable()();
  TextColumn get filePath => text().named('file_path').nullable()();
  TextColumn get fileType =>
      text().named('file_type').withDefault(const Constant('none'))();
  TextColumn get fileName => text().named('file_name').nullable()();
  IntColumn get fileSize =>
      integer().named('file_size').withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('want'))();
  IntColumn get readingProgress =>
      integer().named('reading_progress').withDefault(const Constant(0))();
  IntColumn get totalPages =>
      integer().named('total_pages').withDefault(const Constant(0))();
  TextColumn get createdAt => text().named('created_at').nullable()();
  TextColumn get lastReadAt => text().named('last_read_at').nullable()();
  TextColumn get source => text().withDefault(const Constant(''))();
  TextColumn get summary => text().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get review => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookAnnotations extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().named('book_id').nullable()();
  IntColumn get pageNumber => integer().named('page_number').nullable()();
  TextColumn get quote => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BookHighlightRow')
class BookHighlights extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().named('book_id').nullable()();
  TextColumn get chapter => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get textContent => text().named('text').nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
  TextColumn get source => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookBookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().named('book_id')();
  TextColumn get location => text()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 3. 任务（卡片 / 子任务走 prefs——独立轮次迁）
// ═══════════════════════════════════════════════════════════════

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text().withDefault(const Constant('quick'))();
  TextColumn get description => text().nullable()();
  TextColumn get difficulty => text().withDefault(const Constant('medium'))();
  TextColumn get urgency => text().withDefault(const Constant('medium'))();
  TextColumn get necessity => text().withDefault(const Constant('important'))();
  BoolColumn get isDone =>
      boolean().named('is_done').withDefault(const Constant(false))();
  TextColumn get noteId => text().named('note_id').nullable()();
  TextColumn get subtaskIds =>
      text().named('subtask_ids').withDefault(const Constant('[]'))();
  TextColumn get reminderTime => text().named('reminder_time').nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
  TextColumn get completedAt => text().named('completed_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 4. 宠物 + 用户设置
// ═══════════════════════════════════════════════════════════════

@DataClassName('PetRow')
class Pets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('小云'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get exp => integer().withDefault(const Constant(0))();
  TextColumn get stage => text().withDefault(const Constant('droplet'))();
  IntColumn get happiness => integer().withDefault(const Constant(80))();
  IntColumn get lastFed =>
      integer().named('last_fed').withDefault(const Constant(0))();
  TextColumn get updatedAt => text().named('updated_at').nullable()();
}

class UserSettingsTable extends Table {
  @override
  String get tableName => 'user_settings';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get nickname => text().withDefault(const Constant('小云同学'))();
  TextColumn get bio => text().withDefault(const Constant('📚 知识探索者'))();
  TextColumn get avatarUrl =>
      text().named('avatar_url').withDefault(const Constant(''))();
  TextColumn get themeMode =>
      text().named('theme_mode').withDefault(const Constant('light'))();
  BoolColumn get defaultMarkdown =>
      boolean().named('default_markdown').withDefault(const Constant(false))();
  IntColumn get reviewReminderHour =>
      integer().named('review_reminder_hour').withDefault(const Constant(20))();
  IntColumn get reviewReminderMinute => integer()
      .named('review_reminder_minute')
      .withDefault(const Constant(0))();
  IntColumn get dailyReviewLimit =>
      integer().named('daily_review_limit').withDefault(const Constant(20))();
  RealColumn get reviewFactor =>
      real().named('review_factor').withDefault(const Constant(2.5))();
  TextColumn get heatmapStatMode =>
      text().named('heatmap_stat_mode').withDefault(const Constant('count'))();
  IntColumn get heatmapHighThreshold =>
      integer().named('heatmap_high_threshold').withDefault(const Constant(3))();
  IntColumn get heatmapBurstThreshold => integer()
      .named('heatmap_burst_threshold')
      .withDefault(const Constant(8))();
  IntColumn get heatmapWordHighThreshold => integer()
      .named('heatmap_word_high_threshold')
      .withDefault(const Constant(300))();
  IntColumn get heatmapWordBurstThreshold => integer()
      .named('heatmap_word_burst_threshold')
      .withDefault(const Constant(800))();
  TextColumn get heatmapColorScheme =>
      text().named('heatmap_color_scheme').withDefault(const Constant('emerald'))();
  TextColumn get heatmapColorLow =>
      text().named('heatmap_color_low').withDefault(const Constant('#E8F5E9'))();
  TextColumn get heatmapColorMid =>
      text().named('heatmap_color_mid').withDefault(const Constant('#81C784'))();
  TextColumn get heatmapColorHigh =>
      text().named('heatmap_color_high').withDefault(const Constant('#FFD93D'))();
  TextColumn get heatmapColorBurst =>
      text().named('heatmap_color_burst').withDefault(const Constant('#FF6B6B'))();
  BoolColumn get showPet =>
      boolean().named('show_pet').withDefault(const Constant(true))();
  TextColumn get petSkin =>
      text().named('pet_skin').withDefault(const Constant('default'))();
  TextColumn get petName =>
      text().named('pet_name').withDefault(const Constant('小云'))();
  BoolColumn get petInFocusMode =>
      boolean().named('pet_in_focus_mode').withDefault(const Constant(true))();
  IntColumn get rawNoteRetentionDays => integer()
      .named('raw_note_retention_days')
      .withDefault(const Constant(15))();
  IntColumn get dailyWordTarget =>
      integer().named('daily_word_target').withDefault(const Constant(0))();
  BoolColumn get typewriterSound =>
      boolean().named('typewriter_sound').withDefault(const Constant(false))();
  RealColumn get whiteNoiseVolume =>
      real().named('white_noise_volume').withDefault(const Constant(0.5))();
  BoolColumn get restReminderOn =>
      boolean().named('rest_reminder_on').withDefault(const Constant(false))();
  IntColumn get restReminderMinutes => integer()
      .named('rest_reminder_minutes')
      .withDefault(const Constant(45))();
  TextColumn get customNoiseSources => text()
      .named('custom_noise_sources')
      .withDefault(const Constant('[]'))();
  IntColumn get focusMinutes =>
      integer().named('focus_minutes').withDefault(const Constant(25))();

  // ─── 阅读器全局偏好（Phase 1 补）───
  RealColumn get readerFontSize =>
      real().named('reader_font_size').withDefault(const Constant(16.0))();
  RealColumn get readerLineHeight =>
      real().named('reader_line_height').withDefault(const Constant(1.6))();
  TextColumn get readerFontFamily =>
      text().named('reader_font_family').withDefault(const Constant(''))();
  TextColumn get readerThemeMode =>
      text().named('reader_theme_mode').withDefault(const Constant('light'))();
  TextColumn get readerCustomBg =>
      text().named('reader_custom_bg').withDefault(const Constant(''))();
  TextColumn get readerCustomText =>
      text().named('reader_custom_text').withDefault(const Constant(''))();
  TextColumn get readerHighlightColor => text()
      .named('reader_highlight_color')
      .withDefault(const Constant('#FFD93D'))();
  IntColumn get readerDailyGoal =>
      integer().named('reader_daily_goal').withDefault(const Constant(0))();
  BoolColumn get readerReminderEnabled => boolean()
      .named('reader_reminder_enabled')
      .withDefault(const Constant(false))();
  IntColumn get readerReminderInterval => integer()
      .named('reader_reminder_interval')
      .withDefault(const Constant(30))();
}

// ═══════════════════════════════════════════════════════════════
// 5. ISBN / PDF / 画布
// ═══════════════════════════════════════════════════════════════

class IsbnCache extends Table {
  TextColumn get isbn => text()();
  TextColumn get title => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get coverUrl => text().named('cover_url').nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get updatedAt => text().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {isbn};
}

@DataClassName('PdfDrawingRow')
class PdfDrawings extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().named('book_id').nullable()();
  IntColumn get page => integer().nullable()();
  TextColumn get points => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardViews extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get ownerId => text().named('owner_id').nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
  TextColumn get updatedAt => text().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardNodes extends Table {
  TextColumn get id => text()();
  TextColumn get viewId => text().named('view_id').nullable()();
  TextColumn get cardId => text().named('card_id').nullable()();
  TextColumn get type => text().withDefault(const Constant('card'))();
  TextColumn get noteId => text().named('note_id').nullable()();
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();
  IntColumn get zIndex => integer().named('z_index').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardEdges extends Table {
  TextColumn get id => text()();
  TextColumn get viewId => text().named('view_id').nullable()();
  TextColumn get sourceNodeId => text().named('source_node_id').nullable()();
  TextColumn get targetNodeId => text().named('target_node_id').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardGroups extends Table {
  TextColumn get id => text()();
  TextColumn get viewId => text().named('view_id').nullable()();
  TextColumn get nodeIds => text().named('node_ids').nullable()();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardTexts extends Table {
  TextColumn get id => text()();
  TextColumn get viewId => text().named('view_id').nullable()();
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();
  TextColumn get content => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardStrokes extends Table {
  TextColumn get id => text()();
  TextColumn get viewId => text().named('view_id')();
  TextColumn get groupId => text().named('group_id').nullable()();
  IntColumn get zIndex =>
      integer().named('z_index').withDefault(const Constant(0))();
  TextColumn get points => text()();
  TextColumn get color => text()();
  RealColumn get width => real()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class BoardAlbums extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().nullable()();
  TextColumn get sourceViewId => text().named('source_view_id').nullable()();
  TextColumn get strokesJson => text().named('strokes_json')();
  TextColumn get thumbnailBase64 =>
      text().named('thumbnail_base64').nullable()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 6. 链接 / 火花 / 批注
// ═══════════════════════════════════════════════════════════════

class NoteBookLinks extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().named('note_id')();
  TextColumn get bookId => text().named('book_id')();
  TextColumn get linkType => text().named('link_type')();
  TextColumn get linkText => text().named('link_text').nullable()();
  TextColumn get context => text().nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class NoteNoteLinks extends Table {
  TextColumn get id => text()();
  TextColumn get sourceNoteId => text().named('source_note_id')();
  TextColumn get targetNoteId => text().named('target_note_id')();
  TextColumn get linkType => text().named('link_type')();
  TextColumn get linkText => text().named('link_text').nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SparkRow')
class Sparks extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get anchorNoteId => text().named('anchor_note_id').nullable()();
  TextColumn get anchorLocation =>
      text().named('anchor_location').nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NodeAnnotations extends Table {
  TextColumn get id => text()();
  TextColumn get nodeId => text().named('node_id')();
  TextColumn get strokesJson => text().named('strokes_json')();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 7. 搜索索引
// ═══════════════════════════════════════════════════════════════

class TagIndex extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType =>
      text().named('source_type').withDefault(const Constant('note'))();
  TextColumn get sourceId => text().named('source_id')();
  TextColumn get type => text()();
  TextColumn get tag => text()();
  TextColumn get blockId => text().named('block_id').nullable()();
  TextColumn get textContent => text().named('text').nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class SearchIndex extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType => text().named('source_type')();
  TextColumn get sourceId => text().named('source_id')();
  TextColumn get subId => text().named('sub_id').nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get kind => text()();
  TextColumn get searchText => text().named('search_text')();
  TextColumn get rawText => text().named('raw_text').nullable()();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// 8. 写作会话 / 番茄钟
// ═══════════════════════════════════════════════════════════════

@DataClassName('WritingSessionRow')
class WritingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().named('note_id')();
  TextColumn get startAt => text().named('start_at')();
  TextColumn get endAt => text().named('end_at')();
  IntColumn get wordCount =>
      integer().named('word_count').withDefault(const Constant(0))();
  IntColumn get pausedSeconds =>
      integer().named('paused_seconds').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FocusSessionRow')
class FocusSessions extends Table {
  TextColumn get id => text()();
  TextColumn get startAt => text().named('start_at')();
  IntColumn get minutes => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReadingStats extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  IntColumn get minutes => integer().withDefault(const Constant(0))();
  IntColumn get pages => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════════════
// AppDatabase 主入口 + 单例
// ═══════════════════════════════════════════════════════════════

@DriftDatabase(tables: [
  Notes, Nodes,
  Books, BookAnnotations, BookHighlights, BookBookmarks,
  Tasks,
  Pets, UserSettingsTable,
  IsbnCache, PdfDrawings,
  BoardViews, BoardNodes, BoardEdges, BoardGroups, BoardTexts,
  BoardStrokes, BoardAlbums,
  NoteBookLinks, NoteNoteLinks, Sparks, NodeAnnotations,
  TagIndex, SearchIndex,
  WritingSessions, FocusSessions, ReadingStats,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// 测试专用：注入内存库或自定义 QueryExecutor。
  /// 业务层禁止使用；仅 test/ 下调用。
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

/// 单例锁定——全项目唯一 AppDatabase 实例。
/// 业务层禁止直接 new AppDatabase()——必须走此 provider。
class AppDatabaseProvider {
  AppDatabaseProvider._();
  static final AppDatabaseProvider _instance = AppDatabaseProvider._();
  factory AppDatabaseProvider() => _instance;

  AppDatabase? _db;
  AppDatabase get db => _db ??= AppDatabase();
}