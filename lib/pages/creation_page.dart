import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';
import '../widgets/fullscreen_editor.dart';

class CreationPage extends StatefulWidget {
  const CreationPage({super.key});

  @override
  State<CreationPage> createState() => CreationPageState();
}

// ✅ 公开 State 类，供 main.dart 调用
class CreationPageState extends State<CreationPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;

  List<NotebookEntry> _tasks = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  // ✅ 公开方法：切换到任务 Tab
  void switchToTaskTab() {
    _tabController.animateTo(1);
    _loadTasks();
  }

  Future<void> _completeTask(NotebookEntry task) async {
    final updated = NotebookEntry(
      id: task.id,
      title: task.title,
      content: task.content,
      updatedAt: DateTime.now(),
      status: 'deleted',
      tags: task.tags,
    );
    await _db.updateNote(updated.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 任务已完成')),
      );
      await _loadTasks();
    }
  }

  Future<void> _restoreTask(NotebookEntry task) async {
    final updated = NotebookEntry(
      id: task.id,
      title: task.title,
      content: task.content,
      updatedAt: DateTime.now(),
      status: 'task',
      tags: task.tags,
    );
    await _db.updateNote(updated.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('↩️ 已恢复任务')),
      );
      await _loadTasks();
    }
  }

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

  Future<bool> _saveNote(
    NotebookEntry entry,
    String title,
    String content,
    String editorMode,
    List<String> tags,
  ) async {
    if (_isSaving) return false;
    setState(() => _isSaving = true);

    try {
      final allNotes = await _db.getAllNotes(includeDeleted: true);
      final exists = allNotes.any((n) => n['id'] == entry.id);

      final updated = NotebookEntry(
        id: entry.id,
        title: title.isEmpty ? '无标题' : title,
        content: content.isEmpty ? '暂无内容' : content,
        updatedAt: DateTime.now(),
        status: entry.status,
        editorMode: editorMode,
        tags: tags,
      );

      if (exists) {
        await _db.updateNote(updated.toMap());
      } else {
        await _db.insertNote(updated.toMap());
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 已保存')),
        );
        await _loadTasks();
      }
      return true;
    } catch (e) {
      print('保存失败: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _openWritingMode({NotebookEntry? entry}) {
    final targetEntry = entry ?? NotebookEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      updatedAt: DateTime.now(),
      status: 'active',
      editorMode: 'plain',
      tags: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenEditor(
          entry: targetEntry,
          isFromCollection: false,
          onSave: _saveNote,
          isSaving: _isSaving,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadTasks();
      }
    });
  }

  Widget _buildWritingTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 56, color: Colors.grey),
            const SizedBox(height: 14),
            const Text(
              '专注写作模式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              '支持 Markdown 语法，可切换预览',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openWritingMode(),
              icon: const Icon(Icons.create),
              label: const Text('开始写作'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
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

  Widget _buildTaskTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeTasks = _tasks.where((t) => t.status == 'task').toList();
    final completedTasks = _tasks.where((t) => t.status == 'deleted').toList();

    if (activeTasks.isEmpty && completedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.checklist, size: 56, color: Colors.grey),
              const SizedBox(height: 14),
              const Text(
                '暂无任务',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          if (activeTasks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('📋 待办', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              child: Text('✅ 已完成', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('✍️ 创作'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.blue,
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