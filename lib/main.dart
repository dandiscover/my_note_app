import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F2E7),
      ),
      home: const NotebookPage(),
    );
  }
}

class NotebookEntry {
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
  final List<NotebookEntry> _entries = [
    NotebookEntry(
      id: '1',
      title: '今日计划',
      content: '1. 完成 Flutter 笔记本页面\n2. 记录灵感和待办事项\n3. 休息并整理思路',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotebookEntry(
      id: '2',
      title: '灵感草稿',
      content: '做一个让人一眼就能安心书写的笔记本应用，界面温暖，功能简单直接。',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotebookEntry(
      id: '3',
      title: '购物清单',
      content: '纸笔、咖啡、草稿本、便签贴。',
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

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
        _entries.insert(
          0,
          NotebookEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title.isEmpty ? '无标题笔记' : title,
            content: content.isEmpty ? '暂无内容' : content,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        entry.title = title.isEmpty ? '无标题笔记' : title;
        entry.content = content.isEmpty ? '暂无内容' : content;
        entry.updatedAt = DateTime.now();
      }
    });
  }

  void _deleteEntry(String id) {
    setState(() {
      _entries.removeWhere((entry) => entry.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的笔记本'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '新建笔记',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.note_add_rounded),
          ),
        ],
      ),
      body: _entries.isEmpty
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
            ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add_note_fab'),
        onPressed: () => _openEditor(),
        tooltip: '添加笔记',
        child: const Icon(Icons.add),
      ),
    );
  }
}
