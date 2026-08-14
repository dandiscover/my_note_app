import 'package:flutter/material.dart';
import 'database_service.dart';
import 'pages/library_page.dart';
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notebook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 238, 241, 242)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 155, 194, 236),
      ),
      home: const NotebookPage(),
    );
  }
}

class NotebookEntry {
   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 从数据库 Map 创建对象
  factory NotebookEntry.fromMap(Map<String, dynamic> map) {
    return NotebookEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
  NotebookEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  final String id;
  String title;
  String content;
  DateTime updatedAt;
}

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  final DatabaseService _db = DatabaseService();
  final List<NotebookEntry> _entries = [];
  int _currentIndex = 0; // 0=笔记, 1=图书馆

  // 👇 示例数据定义
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

  // 👇 修改后的加载方法（数据库为空时自动插入示例）
  Future<void> _loadNotes() async {
    final maps = await _db.getAllNotes();
    if (maps.isEmpty) {
      // 数据库为空，插入示例笔记
      for (var entry in _sampleEntries) {
        await _db.insertNote(entry.toMap());
      }
      // 重新加载示例数据
      final newMaps = await _db.getAllNotes();
      setState(() {
        _entries.clear();
        _entries.addAll(newMaps.map((map) => NotebookEntry.fromMap(map)).toList());
      });
    } else {
      setState(() {
        _entries.clear();
        _entries.addAll(maps.map((map) => NotebookEntry.fromMap(map)).toList());
      });
    }
  }

  Future<void> _openEditor({NotebookEntry? entry}) async {
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
  await _db.deleteNote(id);
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
  return Scaffold(
    appBar: AppBar(
      title: const Text('云脑计划'),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: '关于',
          onPressed: () {
            showAboutDialog(
              context: context,
              applicationName: '云脑计划',
              applicationVersion: 'v1.0.0',
              applicationLegalese: '© 2026 三少爷',
              children: const [
                Text('一个稳定智慧的外脑。'),
              ],
            );
          },
          icon: const Icon(Icons.info_outline),
        ),
      ],
    ),
    body: _currentIndex == 0 ? _buildNoteBody() : const LibraryPage(),
    floatingActionButton: _currentIndex == 0
        ? FloatingActionButton(
            key: const ValueKey('add_note_fab'),
            onPressed: () => _openEditor(),
            tooltip: '添加笔记',
            child: const Icon(Icons.add),
          )
        : null,
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.note),
          label: '笔记',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: '图书馆',
        ),
      ],
    ),
  );
}
}
