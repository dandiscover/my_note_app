import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/book.dart';
import '../widgets/file_tree_panel.dart';
import 'note_detail_page.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;
  final String? nodeId;
  final String? currentNodeId;

  const BookDetailPage({
    super.key,
    required this.bookId,
    this.nodeId,
    this.currentNodeId,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final DatabaseService _db = DatabaseService();
  Book? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final map = await _db.getBook(widget.bookId);
    if (map != null) {
      setState(() {
        _book = Book.fromMap(map);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_book == null) return;
    final updatedBook = _book!.copyWith(status: newStatus);
    await _db.updateBook(updatedBook.toMap());
    setState(() {
      _book = updatedBook;
    });
  }

  Future<void> _updateProgress(int newProgress) async {
    if (_book == null) return;
    final updatedBook = _book!.copyWith(readingProgress: newProgress);
    await _db.updateBook(updatedBook.toMap());
    setState(() {
      _book = updatedBook;
    });
  }

  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除《${_book?.title}》吗？此操作不可撤销。'),
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
    if (confirm == true && _book != null) {
      await _db.deleteBook(_book!.id);
      if (widget.nodeId != null) {
        await _db.deleteNode(widget.nodeId!);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: _book?.title ?? '');
    final authorController = TextEditingController(text: _book?.author ?? '');
    final isbnController = TextEditingController(text: _book?.isbn ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑书籍'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '书名'),
            ),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(labelText: '作者'),
            ),
            TextField(
              controller: isbnController,
              decoration: const InputDecoration(labelText: 'ISBN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true && _book != null) {
      final updatedBook = _book!.copyWith(
        title: titleController.text.trim().isNotEmpty
            ? titleController.text.trim()
            : _book!.title,
        author: authorController.text.trim(),
        isbn: isbnController.text.trim(),
      );
      await _db.updateBook(updatedBook.toMap());
      setState(() {
        _book = updatedBook;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已更新')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('图书详情'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('图书详情'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Center(child: Text('书籍不存在或已被删除')),
        ),
      );
    }

    final book = _book!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(book.title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.black87),
            onPressed: () => _toggleFileTree(context),
            tooltip: '文件树',
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black87),
            onPressed: _showEditDialog,
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteBook,
            tooltip: '删除',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                      image: book.coverUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(book.coverUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: book.coverUrl.isEmpty
                        ? const Icon(Icons.book, size: 36, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.author.isNotEmpty ? book.author : '未知作者',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (book.isbn.isNotEmpty)
                          Text(
                            'ISBN: ${book.isbn}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(book.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(book.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                '阅读状态',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildStatusChip('想读', 'want', book.status),
                  const SizedBox(width: 6),
                  _buildStatusChip('在读', 'reading', book.status),
                  const SizedBox(width: 6),
                  _buildStatusChip('读完', 'read', book.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    '阅读进度',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${book.readingProgress}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Slider(
                value: book.readingProgress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${book.readingProgress}%',
                onChanged: (value) => _updateProgress(value.round()),
              ),
              const SizedBox(height: 20),
              const Text(
                '关联笔记',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    '暂无关联笔记\n阅读并标注后会自动生成',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, String current) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _updateStatus(value),
      selectedColor: _getStatusColor(value).withOpacity(0.3),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? _getStatusColor(value) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'want':
        return Colors.orange;
      case 'reading':
        return Colors.blue;
      case 'read':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _toggleFileTree(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: FileTreePanel(
                currentNodeId: widget.nodeId,
                currentNodeName: _book?.title,
                currentFolderId: widget.currentNodeId,
                onNodeTap: (targetNodeId, nodeType) {
                  Navigator.pop(context);
                  if (nodeType == 'note') {
                    _openNote(context, targetNodeId);
                  } else if (nodeType == 'book') {
                    _openBook(context, targetNodeId);
                  }
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNote(BuildContext context, String targetNodeId) async {
    final note = await _db.getNoteByNodeId(targetNodeId);
    if (note != null) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteDetailPage(
            entry: note,
            isFromCollection: false,
            nodeId: targetNodeId,
          ),
        ),
      );
    }
  }

  Future<void> _openBook(BuildContext context, String targetNodeId) async {
    final node = await _db.getNode(targetNodeId);
    if (node != null && node.targetId != null) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(
            bookId: node.targetId!,
            nodeId: targetNodeId,
          ),
        ),
      );
    }
  }
}