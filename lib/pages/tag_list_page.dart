import 'dart:math'; // ✅ 新增导入
import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';
import '../models/note.dart';
import '../models/book.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';

class TagListPage extends StatefulWidget {
  final List<Node> allNodes;

  const TagListPage({
    super.key,
    required this.allNodes,
  });

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  final DatabaseService _db = DatabaseService();

  // 标签分组数据
  Map<String, List<Node>> get _tagGroups {
    final map = <String, List<Node>>{};
    for (var node in widget.allNodes) {
      for (var tag in node.tags) {
        map.putIfAbsent(tag, () => []).add(node);
      }
    }
    return map;
  }

  // 展开的标签
  Set<String> _expandedTags = {};

  @override
  Widget build(BuildContext context) {
    final tagGroups = _tagGroups;
    final sortedTags = tagGroups.keys.toList()
      ..sort((a, b) => tagGroups[b]!.length.compareTo(tagGroups[a]!.length));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🏷️ 所有标签'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_expandedTags.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _expandedTags.clear();
                });
              },
              child: const Text('收起全部'),
            ),
        ],
      ),
      body: sortedTags.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    '还没有标签',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '在智库中给笔记和图书打上标签吧',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: sortedTags.length,
              itemBuilder: (context, index) {
                final tag = sortedTags[index];
                final nodes = tagGroups[tag]!;
                final isExpanded = _expandedTags.contains(tag);

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // 标签头部（可点击展开/折叠）
                      ListTile(
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '#' + tag.substring(0, min(2, tag.length)), // ✅ min 现在可用
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getTagColor(tag),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          tag,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${nodes.length} 个关联内容',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isExpanded ? '收起' : '展开',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedTags.remove(tag);
                            } else {
                              _expandedTags.add(tag);
                            }
                          });
                        },
                      ),
                      // 展开内容
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Column(
                            children: nodes.map((node) {
                              return ListTile(
                                dense: true,
                                leading: node.isFolder
                                    ? const Icon(Icons.folder, size: 16, color: Colors.amber)
                                    : Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                                title: Text(
                                  node.title,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  node.isFolder
                                      ? '📂 文件夹'
                                      : '${node.nodeType == 'note' ? '📄 笔记' : '📘 图书'}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                onTap: () => _openNode(node),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
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

  Future<void> _openNode(Node node) async {
    if (node.isFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📂 文件夹「${node.title}」在智库中'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (node.nodeType == 'note') {
      final note = await _db.getNoteByNodeId(node.id);
      if (note != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteDetailPage(
              entry: note,
              isFromCollection: false,
              nodeId: node.id,
            ),
          ),
        );
      }
    } else if (node.nodeType == 'book') {
      final book = await _db.getBookByNodeId(node.id);
      if (book != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailPage(
              bookId: book.id,
              nodeId: node.id,
            ),
          ),
        );
      }
    }
  }
}