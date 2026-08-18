import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import 'wisdom_page.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final DatabaseService _db = DatabaseService();
  final List<NotebookEntry> _entries = [];
  int _currentTab = 0; // 0=笔记, 1=图书馆

  // ✅ 添加这个标志，用于追踪页面是否已被销毁
  bool _isDisposed = false;

  final List<NotebookEntry> _sampleEntries = [
    NotebookEntry(
      id: 'sample_1',
      title: '今日计划',
      content: '1. 完成 Flutter 笔记本页面\n2. 记录灵感和待办事项\n3. 休息并整理思路',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotebookEntry(
      id: 'sample_2',
      title: '灵感草稿',
      content: '做一个让人一眼就能安心书写的笔记本应用，界面温暖，功能简单直接。',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotebookEntry(
      id: 'sample_3',
      title: '购物清单',
      content: '纸笔、咖啡、草稿本、便签贴。',
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ 页面销毁时标记
    super.dispose();
  }

  Future<void> _loadNotes() async {
    // ✅ 如果页面已被销毁或不再挂载，直接返回
    if (_isDisposed || !mounted) return;

    try {
      final maps = await _db.getAllNotes();
      if (_isDisposed || !mounted) return;

      if (maps.isEmpty) {
        for (var entry in _sampleEntries) {
          await _db.insertNote(entry.toMap());
        }
        final newMaps = await _db.getAllNotes();
        if (_isDisposed || !mounted) return;
        setState(() {
          _entries.clear();
          _entries.addAll(newMaps.map((map) => NotebookEntry.fromMap(map)).toList());
        });
      } else {
        if (_isDisposed || !mounted) return;
        setState(() {
          _entries.clear();
          _entries.addAll(maps.map((map) => NotebookEntry.fromMap(map)).toList());
        });
      }
    } catch (e) {
      // ✅ 捕获异常，避免未处理的错误
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载笔记失败: $e')),
        );
      }
    }
  }

  Future<void> _openEditor({NotebookEntry? entry}) async {
    if (_isDisposed || !mounted) return;

    final controllerTitle = TextEditingController(text: entry?.title ?? '');
    final controllerContent = TextEditingController(text: entry?.content ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(entry == null ? '新建笔记' : '编辑笔记'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('title_field'),
                  controller: controllerTitle,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('content_field'),
                  controller: controllerContent,
                  maxLines: 8,
                  minLines: 4,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const ValueKey('save_note_button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    if (_isDisposed || !mounted) return;

    final title = controllerTitle.text.trim();
    final content = controllerContent.text.trim();
    if (title.isEmpty && content.isEmpty) {
      return;
    }

    setState(() {
      if (entry == null) {
        final newEntry = NotebookEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title.isEmpty ? '无标题笔记' : title,
          content: content.isEmpty ? '暂无内容' : content,
          updatedAt: DateTime.now(),
        );
        _entries.insert(0, newEntry);
        _db.insertNote(newEntry.toMap());
      } else {
        entry.title = title.isEmpty ? '无标题笔记' : title;
        entry.content = content.isEmpty ? '暂无内容' : content;
        entry.updatedAt = DateTime.now();
        _db.updateNote(entry.toMap());
      }
    });
  }

  Future<void> _deleteEntry(String id) async {
    if (_isDisposed || !mounted) return;

    await _db.deleteNote(id);
    if (_isDisposed || !mounted) return;
    setState(() {
      _entries.removeWhere((entry) => entry.id == id);
    });
  }

  Widget _buildNoteBody() {
    return _entries.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 56, color: Colors.amber),
                SizedBox(height: 12),
                Text('还没有笔记，点击右下角创建一个吧。'),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              final preview = entry.content.replaceAll('\n', ' ');
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '更新于 ${entry.updatedAt.toLocal().toString().split(' ')[0]}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: '删除笔记',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEntry(entry.id),
                  ),
                  onTap: () => _openEditor(entry: entry),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 如果页面已被销毁，不渲染任何内容
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 知识'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 搜索功能
            },
            tooltip: '搜索',
          ),
        ],
        bottom: TabBar(
          tabs: const [
            Tab(text: '笔记'),
            Tab(text: '图书馆'),
          ],
          onTap: (index) {
            if (mounted && !_isDisposed) {
              setState(() {
                _currentTab = index;
              });
            }
          },
        ),
      ),
      body: _currentTab == 0 ? _buildNoteBody() : const WisdomPage(),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              key: const ValueKey('add_note_fab'),
              onPressed: () => _openEditor(),
              tooltip: '添加笔记',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}