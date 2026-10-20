# 老 sqflite 库升级逻辑存档

本文件保存老 sqflite 库升级逻辑。当前 `lib/` 已无 sqflite。正式发版前补「老 sqflite 库 → 新 Drift 库」迁移路径时，参考本文件。见 `白-账-002`。

## 一 · `_onUpgrade`（原 `database_service.dart:1754-2140`）

```dart
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { try { await db.execute('ALTER TABLE notes ADD COLUMN status TEXT DEFAULT "raw"'); } catch (_) {} }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE books ADD COLUMN cover_image TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN pdf_path TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_type TEXT DEFAULT "none"'); } catch (_) {}
    }
    if (oldVersion < 4) { try { await db.execute('ALTER TABLE notes ADD COLUMN editorMode TEXT DEFAULT "plain"'); } catch (_) {} }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT DEFAULT ""'); } catch (_) {}
      try { await db.execute('ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS nodes(
            id TEXT PRIMARY KEY, title TEXT, parent_id TEXT,
            is_folder INTEGER DEFAULT 0, node_type TEXT DEFAULT 'folder',
            target_id TEXT, sort_order INTEGER DEFAULT 0, tags TEXT DEFAULT '',
            created_at TEXT, updated_at TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE books ADD COLUMN cover_url TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_path TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_name TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN file_size INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE books ADD COLUMN last_read_at TEXT'); } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS book_annotations(
            id TEXT PRIMARY KEY, book_id TEXT, page_number INTEGER,
            quote TEXT, note TEXT, color TEXT, created_at TEXT,
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN inquiry_question TEXT');
        await db.execute('ALTER TABLE notes ADD COLUMN scaffold_sessions TEXT DEFAULT "[]"');
        await db.execute('ALTER TABLE notes ADD COLUMN subtasks TEXT DEFAULT "[]"');
      } catch (_) {}
    }
    if (oldVersion < 10) { try { await db.execute('ALTER TABLE notes ADD COLUMN new_understanding TEXT'); } catch (_) {} }
    if (oldVersion < 11) { try { await db.execute('ALTER TABLE notes ADD COLUMN explore_tasks TEXT DEFAULT "[]"'); } catch (_) {} }
    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS isbn_cache(
            isbn TEXT PRIMARY KEY, title TEXT, author TEXT,
            cover_url TEXT, source TEXT, updated_at TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      try { await db.execute("ALTER TABLE books ADD COLUMN source TEXT DEFAULT ''"); } catch (_) {}
      try { await db.execute("UPDATE books SET source = 'import' WHERE file_path IS NOT NULL AND file_path != ''"); } catch (_) {}
      try { await db.execute("UPDATE books SET source = 'scan' WHERE file_path IS NULL OR file_path = ''"); } catch (_) {}
    }
    if (oldVersion < 14) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pdf_drawings(
            id TEXT PRIMARY KEY, book_id TEXT, page INTEGER,
            points TEXT, color TEXT, created_at TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_views(
            id TEXT PRIMARY KEY, name TEXT, type TEXT,
            owner_id TEXT, created_at TEXT, updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_nodes(
            id TEXT PRIMARY KEY, view_id TEXT, card_id TEXT,
            x REAL, y REAL, z_index INTEGER
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_nodes_view ON board_nodes(view_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_edges(
            id TEXT PRIMARY KEY, view_id TEXT,
            source_node_id TEXT, target_node_id TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_edges_view ON board_edges(view_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_groups(
            id TEXT PRIMARY KEY, view_id TEXT, node_ids TEXT, color TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_groups_view ON board_groups(view_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS board_texts(
            id TEXT PRIMARY KEY, view_id TEXT, x REAL, y REAL, content TEXT
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_board_texts_view ON board_texts(view_id)');
      } catch (_) {}
    }
    if (oldVersion < 16) {
      for (final sql in SearchIndexService.getCreateTableSql()) {
        await db.execute(sql);
      }

      final cols = await db.rawQuery('PRAGMA table_info(notes)');
      final hasContentFormat =
          cols.any((c) => c['name'] == 'content_format');
      if (!hasContentFormat) {
        await db.execute(
          "ALTER TABLE notes ADD COLUMN content_format TEXT DEFAULT 'markdown'",
        );
      }
    }
    // ✅ 第四轮批 1：版本 16 → 17：tag_index 加 sourceType 列，noteId 改名 sourceId
    if (oldVersion < 17) {
      try {
        final cols = await db.rawQuery('PRAGMA table_info(tag_index)');
        final hasTable = cols.isNotEmpty;
        final hasNoteId = cols.any((c) => c['name'] == 'noteId');
        final hasSourceId = cols.any((c) => c['name'] == 'sourceId');

        if (!hasTable) {
          for (final sql in SearchIndexService.getCreateTableSql()) {
            await db.execute(sql);
          }
        } else if (hasSourceId) {
          // 已是新 schema：跳过
        } else if (hasNoteId) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tag_index_new(
              id TEXT PRIMARY KEY,
              sourceType TEXT NOT NULL DEFAULT 'note',
              sourceId TEXT NOT NULL,
              type TEXT NOT NULL,
              tag TEXT NOT NULL,
              blockId TEXT,
              text TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
          await db.execute('''
            INSERT INTO tag_index_new (id, sourceType, sourceId, type, tag, blockId, text, createdAt)
            SELECT id, 'note', noteId, type, tag, blockId, text, createdAt FROM tag_index
          ''');
          await db.execute('DROP TABLE tag_index');
          await db.execute('ALTER TABLE tag_index_new RENAME TO tag_index');
          await db.execute('DROP INDEX IF EXISTS idx_tag_index_note');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_index_tag ON tag_index(tag)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_index_source ON tag_index(sourceId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_tag_index_type ON tag_index(type)');
        }
      } catch (e) {
        debugPrint('tag_index 16→17 迁移失败: $e');
      }
    }
    // ✅ 批 1a：版本 17 → 18：note_book_links 表（笔记↔书关联）
    if (oldVersion < 18) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS note_book_links(
            id TEXT PRIMARY KEY,
            note_id TEXT NOT NULL,
            book_id TEXT NOT NULL,
            link_type TEXT NOT NULL,
            context TEXT,
            created_at TEXT NOT NULL,
            UNIQUE(note_id, book_id, link_type)
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_nbl_note ON note_book_links(note_id)');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_nbl_book ON note_book_links(book_id)');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_nbl_type ON note_book_links(link_type)');

        // L2 → L3 迁移（老白裁：丙，_onUpgrade 里跑）
        await _migrateBookReadingNoteIdToLinks(db);
      } catch (e) {
        debugPrint('note_book_links 17→18 迁移失败: $e');
      }
    }
        if (oldVersion < 18) {
      try {
        // 批 1a：note_book_links 表（笔记↔书关联）
      } catch (e) {
        debugPrint('note_book_links 17→18 迁移失败: $e');
      }
    }
    // 批 BUG-003：19 —— nodes 加 system_tag（测试数据可删——不回填）
    if (oldVersion < 19) {
      try {
        await db.execute('ALTER TABLE nodes ADD COLUMN system_tag TEXT');
      } catch (e) {
        debugPrint('nodes 18→19 迁移失败: $e');
      }
    }
        // 导入批：20 —— book_highlights 表
    if (oldVersion < 20) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS book_highlights(
            ...
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_bh_book ON book_highlights(book_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_bh_source ON book_highlights(source)');
      } catch (e) {
        debugPrint('book_highlights 19→20 迁移失败: $e');
      }
    }
    // A5-2：21 —— board_nodes 加 type / note_id
    if (oldVersion < 21) {
      try {
        await db.execute(
          "ALTER TABLE board_nodes ADD COLUMN type TEXT DEFAULT 'card'",
        );
        await db.execute(
          "ALTER TABLE board_nodes ADD COLUMN note_id TEXT",
        );
      } catch (e) {
        debugPrint('board_nodes 20→21 迁移失败: $e');
      }
    }
        if (oldVersion < 22) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS note_note_links(
            id TEXT PRIMARY KEY,
            source_note_id TEXT NOT NULL,
            target_note_id TEXT NOT NULL,
            link_type TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(source_note_id, target_note_id, link_type)
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_nnl_source ON note_note_links(source_note_id)');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_nnl_target ON note_note_links(target_note_id)');
      } catch (e) {
        debugPrint('note_note_links 21→22 迁移失败: $e');
      }
    }
         if (oldVersion < 23) {
    try {
      await db.execute(
        'ALTER TABLE note_note_links ADD COLUMN link_text TEXT');
    } catch (e) {
      debugPrint('note_note_links 22→23 迁移失败: $e');
    }
  }
      if (oldVersion < 24) {
        try {
          await db.execute(
            'ALTER TABLE note_book_links ADD COLUMN link_text TEXT');
        } catch (e) {
          debugPrint('note_book_links 23→24 迁移失败: $e');
        }
      }
      if (oldVersion < 25) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sparks(
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              anchor_note_id TEXT,
              anchor_location TEXT,
              status TEXT DEFAULT 'pending',
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sparks_note ON sparks(anchor_note_id)');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sparks_status ON sparks(status)');
        } catch (e) {
          debugPrint('sparks 24→25 迁移失败: $e');
        }
      }
            if (oldVersion < 26) {
        try {
          await db.execute('ALTER TABLE notes ADD COLUMN created_at TEXT');
        } catch (e) {
          debugPrint('notes 25→26 created_at 迁移失败: $e');
        }
      }
            if (oldVersion < 27) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS board_strokes(
              id TEXT PRIMARY KEY,
              view_id TEXT NOT NULL,
              group_id TEXT,
              z_index INTEGER DEFAULT 0,
              points TEXT NOT NULL,
              color TEXT NOT NULL,
              width REAL NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_board_strokes_view ON board_strokes(view_id)');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_board_strokes_group ON board_strokes(group_id)');
        } catch (e) {
          debugPrint('board_strokes 26→27 迁移失败: $e');
        }
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS board_albums(
              id TEXT PRIMARY KEY,
              title TEXT,
              source_view_id TEXT,
              strokes_json TEXT NOT NULL,
              thumbnail_base64 TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');
        } catch (e) {
          debugPrint('board_albums 26→27 迁移失败: $e');
        }
      }
          // R-12a：28 —— 节点批注表（画布节点展开后的笔迹）
    if (oldVersion < 28) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS node_annotations(
            id TEXT PRIMARY KEY,
            node_id TEXT NOT NULL,
            strokes_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_na_node ON node_annotations(node_id)');
      } catch (e) {
        debugPrint('node_annotations 27→28 迁移失败: $e');
      }
    }
    if (oldVersion < 29) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS writing_sessions(
            id TEXT PRIMARY KEY,
            note_id TEXT NOT NULL,
            start_at TEXT NOT NULL,
            end_at TEXT NOT NULL,
            word_count INTEGER NOT NULL DEFAULT 0,
            paused_seconds INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_ws_note ON writing_sessions(note_id)');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_ws_start ON writing_sessions(start_at)');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS focus_sessions(
            id TEXT PRIMARY KEY,
            start_at TEXT NOT NULL,
            minutes INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_fs_start ON focus_sessions(start_at)');
      } catch (e) {
        debugPrint('writing_sessions/focus_sessions 28→29 迁移失败: $e');
      }
    }
  }
```

## 二 · `_migrateBookReadingNoteIdToLinks`（原 `database_service.dart:2146-2167`）

```dart
  Future<void> _migrateBookReadingNoteIdToLinks(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    final books = await db.query('books', columns: ['id']);
    for (final b in books) {
      final bookId = b['id'] as String;
      final noteId = prefs.getString('book_reading_note_id_$bookId');
      if (noteId == null || noteId.isEmpty) continue;
      await db.insert(
        'note_book_links',
        {
          // 后缀 bookId：同微秒多本循环不撞主键
          'id': '${DateTime.now().microsecondsSinceEpoch}_$bookId',
          'note_id': noteId,
          'book_id': bookId,
          'link_type': 'reading',
          'context': null,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
```
