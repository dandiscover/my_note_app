import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../models/book.dart';
import 'book_detail_page.dart';

class WisdomPage extends StatefulWidget {
  const WisdomPage({super.key});

  @override
  State<WisdomPage> createState() => _WisdomPageState();
}

class _WisdomPageState extends State<WisdomPage> {
  final DatabaseService _db = DatabaseService();

  List<NotebookEntry> _activeNotes = [];
  List<NotebookEntry> _archivedNotes = [];
  List<Book> _books = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allNotes = await _db.getAllNotes(includeDeleted: false);
      final bookMaps = await _db.getAllBooks();

      setState(() {
        _activeNotes = allNotes
            .where((n) => n['status'] == 'active')
            .map((map) => NotebookEntry.fromMap(map))
            .toList();
        _archivedNotes = allNotes
            .where((n) => n['status'] == 'archived')
            .map((map) => NotebookEntry.fromMap(map))
            .toList();
        _books = bookMaps.map((map) => Book.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('加载智库数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveNote(NotebookEntry note) async {
    await _db.archiveNote(note.id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已归档')),
      );
    }
  }

  Future<void> _unarchiveNote(NotebookEntry note) async {
    await _db.unarchiveNote(note.id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消归档')),
      );
    }
  }

  Future<void> _deleteNote(NotebookEntry note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要永久删除「${note.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.hardDeleteNote(note.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已永久删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 智库'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.inbox : Icons.archive),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
            },
            tooltip: _showArchived ? '显示未归档' : '显示已归档',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_activeNotes.isEmpty && _archivedNotes.isEmpty && _books.isEmpty)
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_stories, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('智库还是空的'),
                      SizedBox(height: 8),
                      Text('去「采集」整理并收入智库吧'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!_showArchived) ...[
                      if (_activeNotes.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('📝 未归档', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ..._activeNotes.map((note) => Card(
                          child: ListTile(
                            title: Text(note.title),
                            subtitle: Text(
                              note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.archive_outlined, size: 20, color: Colors.grey),
                                  onPressed: () => _archiveNote(note),
                                  tooltip: '归档',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteNote(note),
                                  tooltip: '删除',
                                ),
                              ],
                            ),
                            onTap: () {
                              // TODO: 笔记详情
                            },
                          ),
                        )),
                      ],
                      if (_books.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('📚 图书', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ..._books.map((book) => Card(
                          child: ListTile(
                            title: Text(book.title),
                            subtitle: Text(book.author.isNotEmpty ? book.author : '未知作者'),
                            trailing: Text('${book.readingProgress}%'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailPage(bookId: book.id),
                                ),
                              );
                            },
                          ),
                        )),
                      ],
                    ],
                    if (_showArchived) ...[
                      if (_archivedNotes.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('📦 已归档', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ..._archivedNotes.map((note) => Card(
                          child: ListTile(
                            title: Text(note.title),
                            subtitle: Text(
                              note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.unarchive_outlined, size: 20, color: Colors.blue),
                                  onPressed: () => _unarchiveNote(note),
                                  tooltip: '取消归档',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteNote(note),
                                  tooltip: '永久删除',
                                ),
                              ],
                            ),
                            onTap: () {
                              // TODO: 笔记详情
                            },
                          ),
                        )),
                      ] else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              '暂无已归档的笔记',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
}