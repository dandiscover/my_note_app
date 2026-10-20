# lib/database/ — 数据层

**依据：** 换库方案 v1.2 · Phase 1

## 一 · 操作入口强边界（Phase 1 任务 21）

**规则：** 所有数据库操作必须走 `DatabaseService`。

- **禁止：** 业务代码直接 `AppDatabaseProvider().db` 拿实例操作。
- **允许：** 业务代码调 `DatabaseService().xxx()`——内部由 `DatabaseService` 走 Drift。
- **唯一入口：** `DatabaseService`（旧实现保留名，Phase 2 内部换成 Drift）。

**理由：** 保证事务边界一致、异常封装统一、未来加拦截器只改一处。

## 二 · 表变更评审规范（Phase 1 任务 22）

**开发期（Phase 1-4）：**

- 改表 = 改 `database.dart` + 重生成 `.g.dart` + 改本 README 表清单。
- **不升版本号**——`schemaVersion` 保持 1。
- commit 前核 `git status --short`——`.dart` + `.g.dart` 两文件都有 `M`。

**发布后（Phase 4 合并入 main 起）：**

- 改表 = 改 `database.dart` + **升 `schemaVersion`** + 写 `MigrationStrategy.onUpgrade` + 更新 `drift_schemas/`。
- 必须评审——小白酒审 + 老白九放行。
- **禁止**直接改表不升版本——线上老库不会自动变。

## 三 · 表清单（27 表）

| # | Drift 类 | SQL 表名 |
|---|---|---|
| 1 | `Notes` | `notes` |
| 2 | `Nodes` | `nodes` |
| 3 | `Books` | `books` |
| 4 | `BookAnnotations` | `book_annotations` |
| 5 | `BookHighlights` | `book_highlights` |
| 6 | `Tasks` | `tasks` |
| 7 | `Pets` | `pets` |
| 8 | `UserSettingsTable` | `user_settings` |
| 9 | `IsbnCache` | `isbn_cache` |
| 10 | `PdfDrawings` | `pdf_drawings` |
| 11 | `BoardViews` | `board_views` |
| 12 | `BoardNodes` | `board_nodes` |
| 13 | `BoardEdges` | `board_edges` |
| 14 | `BoardGroups` | `board_groups` |
| 15 | `BoardTexts` | `board_texts` |
| 16 | `BoardStrokes` | `board_strokes` |
| 17 | `BoardAlbums` | `board_albums` |
| 18 | `NoteBookLinks` | `note_book_links` |
| 19 | `NoteNoteLinks` | `note_note_links` |
| 20 | `Sparks` | `sparks` |
| 21 | `NodeAnnotations` | `node_annotations` |
| 22 | `TagIndex` | `tag_index` |
| 23 | `SearchIndex` | `search_index` |
| 24 | `WritingSessions` | `writing_sessions` |
| 25 | `FocusSessions` | `focus_sessions` |
| 26 | `BookBookmarks` | `book_bookmarks` |
| 27 | `ReadingStats` | `reading_stats` |

**不迁（走 prefs / 独立轮次）：** `Cards` / `Subtasks`（独立表）/ `shortcuts`。

## 四 · 版本对齐

| 项 | 版本 |
|---|---|
| `sqlite3` 包 | 3.5.2 |
| `sqlite3.wasm`（`web/`） | 3.5.2 |
| `drift` | 2.35.0+ |
| `schemaVersion` | 1 |