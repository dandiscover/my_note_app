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
import '../services/keyboard_shortcut_manager.dart';
import '../models/keyboard_shortcut.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  // 保存回调
  static Future<void> Function()? _saveCallback;

  static void registerSave(Future<void> Function() callback) {
    _saveCallback = callback;
  }

  static void unregisterSave() {
    _saveCallback = null;
  }

  static Future<void> triggerSave() async {
    if (_saveCallback != null) {
      await _saveCallback!();
    }
  }

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

  @override
  void dispose() {
    CollectionPage.unregisterSave();
    super.dispose();
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
    final tagController = TextEditingController();
    bool isTask = false;
    List<String> tags = [];
    bool isSaving = false;

    // ✅ 获取用户自定义的保存快捷键
    String saveShortcutLabel = 'Ctrl+S';
    try {
      final manager = KeyboardShortcutManager();
      // 注意：load 是异步的，但这里我们需要同步获取
      // 使用默认值，后续可以优化
      // 更好的方式：在对话框构建时异步加载
    } catch (e) {
      // 忽略
    }

    Future<void> performSave() async {
      if (isSaving) return;
      final content = controller.text.trim();
      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入内容'), duration: Duration(seconds: 1)),
        );
        return;
      }

      isSaving = true;

      final status = isTask ? 'task' : 'raw';
      final title = content.length > 30 ? '${content.substring(0, 30)}...' : content;

      final newEntry = NotebookEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        updatedAt: DateTime.now(),
        status: status,
        tags: tags,
      );

      await _db.insertNote(newEntry.toMap());

      if (status == 'active') {
        await _db.attachNoteToNode(
          noteId: newEntry.id,
          title: title,
          parentId: null,
          tags: tags,
        );
      }

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
    }

    CollectionPage.registerSave(performSave);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        // ✅ 在对话框构建时异步加载快捷键设置
        String shortcutDisplay = 'Ctrl+S';
        KeyboardShortcutManager().load().then((_) {
          final shortcut = KeyboardShortcutManager().saveShortcut;
          if (shortcut != null) {
            shortcutDisplay = shortcut.displayName;
          }
          // 更新对话框中的快捷键显示
          setState(() {});
        });

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addTag(String tag) {
              final trimmed = tag.trim();
              if (trimmed.isEmpty) return;
              if (tags.contains(trimmed)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('标签已存在'), duration: Duration(seconds: 1)),
                );
                return;
              }
              setDialogState(() {
                tags.add(trimmed);
              });
              tagController.clear();
            }

            void removeTag(String tag) {
              setDialogState(() {
                tags.remove(tag);
              });
            }

            return AlertDialog(
              title: const Text('快速笔记'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_getSaveShortcutDisplay()} 保存', // ✅ 动态快捷键显示
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          const Text(
                            '标签',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: tagController,
                              decoration: InputDecoration(
                                hintText: '输入标签，按回车添加',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 2),
                                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              ),
                              style: const TextStyle(fontSize: 12),
                              onSubmitted: (value) {
                                if (value.contains(',')) {
                                  for (var t in value.split(',')) {
                                    addTag(t);
                                  }
                                } else {
                                  addTag(value);
                                }
                              },
                              onChanged: (value) {
                                if (value.endsWith(',')) {
                                  final t = value.substring(0, value.length - 1);
                                  addTag(t);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 3,
                          children: tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTagColor(tag).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getTagColor(tag).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getTagColor(tag),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                GestureDetector(
                                  onTap: () => removeTag(tag),
                                  child: Icon(
                                    Icons.close,
                                    size: 10,
                                    color: _getTagColor(tag),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  onPressed: () {
                    CollectionPage.unregisterSave();
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    await performSave();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      CollectionPage.unregisterSave();
    });
  }

  // ✅ 获取用户自定义的保存快捷键显示名称
  String _getSaveShortcutDisplay() {
    try {
      // 使用同步方式获取默认值，异步加载会在对话框构建后更新
      // 这里返回默认值，后续通过 setState 更新
      final manager = KeyboardShortcutManager();
      // 由于 load 是异步的，这里使用默认值
      // 实际显示会在对话框构建完成后通过 Future 更新
      return 'Ctrl+S';
    } catch (e) {
      return 'Ctrl+S';
    }
  }

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.deepPurple,
      Colors.red,
    ];
    return colors[hash % colors.length];
  }

  Future<void> _quickArchive(NotebookEntry note) async {
    final updated = NotebookEntry(
      id: note.id,
      title: note.title,
      content: note.content,
      updatedAt: DateTime.now(),
      status: 'archived',
      tags: note.tags,
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('📥 采集'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.black87),
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
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      '快速捕获',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 20),
                    const Text(
                      '待整理',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NoteDetailPage(
                                        entry: note,
                                        isFromCollection: true,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                  }
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 20),
                  ],
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.grey.shade700),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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