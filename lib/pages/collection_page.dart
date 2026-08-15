import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../database_service.dart';
import '../models/book.dart';
import '../models/note.dart';
import 'book_detail_page.dart';
import 'note_detail_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final DatabaseService _db = DatabaseService();
  List<NotebookEntry> _rawNotes = [];
  List<Book> _recentBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final noteMaps = await _db.getRawNotes();
      final bookMaps = await _db.getAllBooks();

      if (!mounted) return;
      setState(() {
        _rawNotes = noteMaps.map((map) => NotebookEntry.fromMap(map)).toList();
        _recentBooks = bookMaps.map((map) => Book.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('加载采集数据失败: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickNote() {
    final controller = TextEditingController();
    bool isTask = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('快速笔记'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: '输入你的想法...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isTask,
                        onChanged: (value) {
                          setDialogState(() {
                            isTask = value ?? false;
                          });
                        },
                      ),
                      const Text('转为任务（收入创作区）'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final content = controller.text.trim();
                    if (content.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }

                    final status = isTask ? 'task' : 'raw';

                    final newEntry = NotebookEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: content.length > 30 ? '${content.substring(0, 30)}...' : content,
                      content: content,
                      updatedAt: DateTime.now(),
                      status: status,
                    );

                    await _db.insertNote(newEntry.toMap());

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isTask ? '✅ 已转为任务，收入创作区' : '💡 已采集',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                      await _loadData();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _quickArchive(NotebookEntry note) async {
    final updated = NotebookEntry(
      id: note.id,
      title: note.title,
      content: note.content,
      updatedAt: DateTime.now(),
      status: 'archived',
    );
    await _db.updateNote(updated.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📦 已直接归档')),
      );
      await _loadData();
    }
  }

  void _voiceRecord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音记录功能开发中...')),
    );
  }

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('拍照记录功能开发中...')),
    );
  }

  void _drawBoard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画板功能开发中...')),
    );
  }

  Future<void> _importFile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能开发中...')),
    );
  }

  Future<void> _scanISBN() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('扫码功能开发中...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📥 采集'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: '添加',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _importFile();
                  break;
                case 'scan':
                  _scanISBN();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 12),
                    Text('导入电子版'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner),
                    SizedBox(width: 12),
                    Text('扫ISBN'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '快速捕获',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCaptureCard(
                        icon: Icons.edit_note,
                        label: '文字',
                        color: Colors.blue.shade100,
                        onTap: _quickNote,
                      ),
                      _buildCaptureCard(
                        icon: Icons.mic,
                        label: '语音',
                        color: Colors.green.shade100,
                        onTap: _voiceRecord,
                      ),
                      _buildCaptureCard(
                        icon: Icons.camera_alt,
                        label: '拍照',
                        color: Colors.orange.shade100,
                        onTap: _takePhoto,
                      ),
                      _buildCaptureCard(
                        icon: Icons.brush,
                        label: '画板',
                        color: Colors.purple.shade100,
                        onTap: _drawBoard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '待整理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_rawNotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '暂无待整理的内容\n点击「文字」快速记录',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._rawNotes.map((note) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(note.title),
                        subtitle: Text(
                          note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.archive_outlined, size: 20, color: Colors.grey),
                              onPressed: () => _quickArchive(note),
                              tooltip: '直接归档',
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, size: 20, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NoteDetailPage(
                                      entry: note,
                                      isFromCollection: true,
                                    ),
                                  ),
                                ).then((result) {
                                  if (result == true) _loadData();
                                });
                              },
                              tooltip: '整理',
                            ),
                          ],
                        ),
                      ),
                    )),
                  if (_recentBooks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '最近导入',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._recentBooks.map((book) => ListTile(
                      leading: const Icon(Icons.book, color: Colors.grey),
                      title: Text(book.title),
                      subtitle: Text(
                        book.author.isNotEmpty ? book.author : '未知作者',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailPage(bookId: book.id),
                          ),
                        );
                      },
                    )),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCaptureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.grey.shade700),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}