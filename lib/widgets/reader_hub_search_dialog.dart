import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database_service.dart';
import '../utils/debouncer.dart';

class ReaderHubSearchDialog extends StatefulWidget {
  final String initialText;
  final String bookId;
  final Future<List<Map<String, dynamic>>> Function(String query) onExecuteBookSearch;
  final void Function(Map<String, dynamic> payload) onJumpToBook;
  final void Function(String noteId) onOpenNote;
  final void Function(Map<String, dynamic> cardMap) onOpenCard;

  const ReaderHubSearchDialog({
    super.key,
    required this.initialText,
    required this.bookId,
    required this.onExecuteBookSearch,
    required this.onJumpToBook,
    required this.onOpenNote,
    required this.onOpenCard,
  });

  @override
  State<ReaderHubSearchDialog> createState() => _ReaderHubSearchDialogState();
}

class _ReaderHubSearchDialogState extends State<ReaderHubSearchDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final TabController _tabController;
  final Debouncer _debouncer = Debouncer(const Duration(milliseconds: 300));
  final DatabaseService _db = DatabaseService();

  List<Map<String, dynamic>> _bookResults = [];
  List<Map<String, dynamic>> _noteResults = [];
  List<Map<String, dynamic>> _cardResults = [];
  List<Map<String, dynamic>> _bookMetaResults = [];
  bool _loading = false;
  bool _dialogOpen = true;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _tabController = TabController(length: 3, vsync: this);
    _runSearch(widget.initialText);
  }

  @override
  void dispose() {
    _dialogOpen = false;
    _debouncer.cancel();
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTextChanged(String val) {
    _debouncer.run(() {
      if (!_dialogOpen) return;
      _runSearch(val.trim());
    });
  }

  Future<void> _runSearch(String kw) async {
    final gen = ++_searchGeneration;
    if (kw.isEmpty) {
      if (mounted) {
        setState(() {
          _bookResults = [];
          _noteResults = [];
          _cardResults = [];
          _bookMetaResults = [];
          _loading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = true);
    final bookRes = await widget.onExecuteBookSearch(kw);
    final noteRes = await _db.searchNotes(kw);
    final cardRes = await _db.searchCards(kw);
    final bookMetaRes = await _db.searchBooks(kw);
    if (!mounted || !_dialogOpen) return;
    if (gen != _searchGeneration) return;
    setState(() {
      _bookResults = bookRes;
      _noteResults = noteRes;
      _cardResults = cardRes;
      _bookMetaResults = bookMetaRes;
      _loading = false;
    });
  }

  Future<void> _openExternalSearch(String engine, String kw) async {
    final encoded = Uri.encodeComponent(kw);
    late final Uri uri;
    switch (engine) {
      case 'baidu':
        uri = Uri.parse('https://www.baidu.com/s?wd=$encoded');
        break;
      case 'bing':
        uri = Uri.parse('https://www.bing.com/search?q=$encoded');
        break;
      default:
        uri = Uri.parse('https://www.google.com/search?q=$encoded');
    }
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前平台不支持外跳')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final mediaW = MediaQuery.sizeOf(context).width;
    final mediaH = MediaQuery.sizeOf(context).height;
    final boxW = (mediaW * 0.85).clamp(280.0, 480.0);
    final boxH = (mediaH * 0.60).clamp(220.0, 360.0);
    final kw = _controller.text.trim();
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('全智库搜索'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onTextChanged,
            decoration: const InputDecoration(
              hintText: '输入关键词',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: '本书'),
              Tab(text: '智库'),
              Tab(text: '联网'),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: boxW,
        height: boxH,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBookTab(kw),
                  _buildWisdomTab(kw),
                  _buildWebTab(kw),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildBookTab(String kw) {
    if (kw.isEmpty) {
      return const Center(child: Text('输入关键词开始搜索', style: TextStyle(color: Colors.grey)));
    }
    if (_bookResults.isEmpty) {
      return const Center(child: Text('本书未找到结果', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: _bookResults.length,
      itemBuilder: (context, idx) {
        final r = _bookResults[idx];
        final title = (r['title'] as String?) ?? '';
        final snippet = (r['snippet'] as String?) ?? '';
        final pageNumber = ((r['index'] as int?) ?? 0) + 1;
        return ListTile(
          leading: const Icon(Icons.menu_book),
          title: Text(title),
          subtitle: Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () {
            Navigator.pop(context);
            widget.onJumpToBook({
              'bookId': widget.bookId,
              'pageNumber': pageNumber,
              'selectedText': kw,
            });
          },
        );
      },
    );
  }

  Widget _buildWisdomTab(String kw) {
    if (kw.isEmpty) {
      return const Center(child: Text('输入关键词开始搜索', style: TextStyle(color: Colors.grey)));
    }
    final total = _noteResults.length + _cardResults.length + _bookMetaResults.length;
    if (total == 0) {
      return const Center(child: Text('智库未找到结果', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      children: [
        if (_noteResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('📝 笔记', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._noteResults.map((n) {
            final title = (n['title'] as String?) ?? '';
            final content = (n['content'] as String?) ?? '';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.note),
              title: Text(title.isEmpty ? '无标题' : title),
              subtitle: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenNote((n['id'] as String?) ?? '');
              },
            );
          }),
        ],
        if (_cardResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('🗂 卡片', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._cardResults.map((c) {
            final front = (c['front'] as String?) ?? '';
            final back = (c['back'] as String?) ?? '';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.credit_card),
              title: Text(front, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(back, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenCard(c);
              },
            );
          }),
        ],
        if (_bookMetaResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('📖 书籍', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._bookMetaResults.map((b) {
            final title = (b['title'] as String?) ?? '';
            final author = (b['author'] as String?) ?? '';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.menu_book),
              title: Text(title.isEmpty ? '无书名' : title),
              subtitle: Text(author, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pop(context);
                widget.onJumpToBook({
                  'bookId': (b['id'] as String?) ?? '',
                  'selectedText': kw,
                });
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _buildWebTab(String kw) {
    if (kw.isEmpty) {
      return const Center(child: Text('输入关键词开始搜索', style: TextStyle(color: Colors.grey)));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('一键外跳搜索', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton(onPressed: () => _openExternalSearch('baidu', kw), child: const Text('百度')),
              ElevatedButton(onPressed: () => _openExternalSearch('bing', kw), child: const Text('Bing')),
              ElevatedButton(onPressed: () => _openExternalSearch('google', kw), child: const Text('Google')),
            ],
          ),
        ],
      ),
    );
  }
}
