import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';

class CreationPage extends StatefulWidget {
  const CreationPage({super.key});

  @override
  State<CreationPage> createState() => _CreationPageState();
}

class _CreationPageState extends State<CreationPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;

  List<NotebookEntry> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 监听 Tab 切换，切换到任务Tab时刷新
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _loadTasks();
      }
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final taskMaps = await _db.getTasks();
      setState(() {
        _tasks = taskMaps.map((map) => NotebookEntry.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('加载任务失败: $e');
      setState(() => _isLoading = false);
    }
  }

  // ---- 标记任务完成 ----
  Future<void> _completeTask(NotebookEntry task) async {
    final updated = NotebookEntry(
      id: task.id,
      title: task.title,
      content: task.content,
      updatedAt: DateTime.now(),
      status: 'deleted',
    );
    await _db.updateNote(updated.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 任务已完成')),
      );
      await _loadTasks();
    }
  }

  // ---- 恢复任务 ----
  Future<void> _restoreTask(NotebookEntry task) async {
    final updated = NotebookEntry(
      id: task.id,
      title: task.title,
      content: task.content,
      updatedAt: DateTime.now(),
      status: 'task',
    );
    await _db.updateNote(updated.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('↩️ 已恢复任务')),
      );
      await _loadTasks();
    }
  }

  // ---- 永久删除任务 ----
  Future<void> _deleteTaskPermanently(NotebookEntry task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认永久删除'),
        content: Text('确定要永久删除「${task.title}」吗？'),
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
      await _db.hardDeleteNote(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已永久删除')),
        );
        await _loadTasks();
      }
    }
  }

  // ---- 写作模式 ----
  void _openWritingMode({NotebookEntry? entry}) {
    final titleController = TextEditingController(text: entry?.title ?? '');
    final contentController = TextEditingController(text: entry?.content ?? '');
    final isEditing = entry != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? '编辑笔记' : '✍️ 写作模式',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: '关闭',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: contentController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: '开始写作...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '字数: ${contentController.text.length}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();
                            if (title.isEmpty && content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('标题和内容不能都为空')),
                              );
                              return;
                            }

                            if (isEditing && entry != null) {
                              final updated = NotebookEntry(
                                id: entry.id,
                                title: title.isEmpty ? '无标题' : title,
                                content: content.isEmpty ? '暂无内容' : content,
                                updatedAt: DateTime.now(),
                                status: entry.status,
                              );
                              await _db.updateNote(updated.toMap());
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ 已更新')),
                                );
                                Navigator.pop(context);
                                await _loadTasks();
                              }
                            } else {
                              final newEntry = NotebookEntry(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: title.isEmpty ? '无标题' : title,
                                content: content.isEmpty ? '暂无内容' : content,
                                updatedAt: DateTime.now(),
                                status: 'active',
                              );
                              await _db.insertNote(newEntry.toMap());
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✅ 已存入智库')),
                                );
                                Navigator.pop(context);
                                await _loadTasks();
                              }
                            }
                          },
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---- 写作Tab ----
  Widget _buildWritingTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '专注写作模式',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮进入全屏无干扰写作',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openWritingMode(),
              icon: const Icon(Icons.create),
              label: const Text('开始写作'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                final notes = await _db.getActiveNotes();
                if (notes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('暂无智库笔记可引用')),
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '选择笔记作为素材',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...notes.take(5).map((note) {
                            final entry = NotebookEntry.fromMap(note);
                            return ListTile(
                              title: Text(entry.title),
                              subtitle: Text(
                                entry.content.length > 40
                                    ? '${entry.content.substring(0, 40)}...'
                                    : entry.content,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _openWritingMode(entry: entry);
                              },
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.library_books),
              label: const Text('引用智库笔记写作'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 任务Tab ----
  Widget _buildTaskTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 过滤出未完成的任务（status == 'task'）
    final activeTasks = _tasks.where((t) => t.status == 'task').toList();
    final completedTasks = _tasks.where((t) => t.status == 'deleted').toList();

    if (activeTasks.isEmpty && completedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.checklist, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '暂无任务',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '在「采集」页面的快速笔记中勾选「转为任务」',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                '或在这里新建任务',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openWritingMode(),
                icon: const Icon(Icons.add),
                label: const Text('新建任务'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeTasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('📋 待办', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...activeTasks.map((task) => Card(
            child: ListTile(
              title: Text(task.title),
              subtitle: Text(
                task.content.length > 50 ? '${task.content.substring(0, 50)}...' : task.content,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => _completeTask(task),
                tooltip: '标记完成',
              ),
              onTap: () => _openWritingMode(entry: task),
            ),
          )),
        ],
        const SizedBox(height: 16),
        if (completedTasks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('✅ 已完成', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...completedTasks.map((task) => Card(
            color: Colors.grey.shade50,
            child: ListTile(
              title: Text(
                task.title,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              subtitle: Text(
                task.content.length > 50 ? '${task.content.substring(0, 50)}...' : task.content,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.restore, size: 20, color: Colors.blue),
                    onPressed: () => _restoreTask(task),
                    tooltip: '恢复',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _deleteTaskPermanently(task),
                    tooltip: '永久删除',
                  ),
                ],
              ),
            ),
          )),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => _openWritingMode(),
            icon: const Icon(Icons.add),
            label: const Text('新建任务'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✍️ 创作'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: '写作'),
            Tab(icon: Icon(Icons.list_alt), text: '任务'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWritingTab(),
          _buildTaskTab(),
        ],
      ),
    );
  }
}