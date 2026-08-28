// lib/pages/insight_page.dart
// 洞察页 — 概览 + 知识图谱（状态类公开，供 GlobalKey 使用）

import 'dart:math';
import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../widgets/insight/knowledge_graph.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';

class InsightPage extends StatefulWidget {
  final void Function(int tabIndex)? onTabChange;
  final VoidCallback? onRefreshWisdom;
  final VoidCallback? onSwitchToTaskTab;
  final VoidCallback? onSwitchToFocusMode;

  const InsightPage({
    super.key,
    this.onTabChange,
    this.onRefreshWisdom,
    this.onSwitchToTaskTab,
    this.onSwitchToFocusMode,
  });

  @override
  State<InsightPage> createState() => InsightPageState(); // ✅ 返回公开状态类
}

// ✅ 类名改为公开，供 GlobalKey 使用
class InsightPageState extends State<InsightPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();

  List<Node> _allNodes = [];
  List<NotebookEntry> _allNotes = [];
  List<Book> _allBooks = [];
  bool _isLoading = true;

  GraphData? _graphData;
  bool _isGraphReady = false;

  late TabController _tabController;
  Set<String> _hoveredNodeIds = {};

  // ✅ 公开刷新方法（供外部调用）
  Future<void> refreshData() async {
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_isGraphReady && !_isLoading) {
        _prepareGraph();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final nodes = await _db.getAllNodes();
      final notes = await _db.getAllNotes(includeDeleted: false);
      final books = await _db.getAllBooks();

      setState(() {
        _allNodes = nodes;
        _allNotes = notes.map((m) => NotebookEntry.fromMap(m)).toList();
        _allBooks = books.map((m) => Book.fromMap(m)).toList();
        _isLoading = false;
      });

      if (!_isGraphReady && _allNodes.isNotEmpty) {
        _prepareGraph();
      }
    } catch (e) {
      debugPrint('❌ 加载洞察数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  void _prepareGraph() {
    if (_allNodes.isEmpty) {
      setState(() => _isGraphReady = false);
      return;
    }

    final validNodes = _allNodes.where((n) =>
      n.isFolder || n.nodeType == 'note' || n.nodeType == 'book'
    ).toList();

    if (validNodes.isEmpty) {
      setState(() => _isGraphReady = false);
      return;
    }

    final rawGraph = GraphBuilder.build(validNodes);
    final size = Size(800, 600);
    final layouted = ForceDirectedLayout.layout(rawGraph, size);

    setState(() {
      _graphData = layouted;
      _isGraphReady = true;
    });
  }

  // ============================================================
  // 统计数据
  // ============================================================

  int get _noteCount => _allNotes.where((n) => n.status != 'deleted').length;
  int get _bookCount => _allBooks.length;
  int get _folderCount => _allNodes.where((n) => n.isFolder).length;
  int get _totalTags {
    final tags = <String>{};
    for (var node in _allNodes) {
      tags.addAll(node.tags);
    }
    return tags.length;
  }
  int get _todayCount {
    final today = DateTime.now();
    return _allNodes.where((n) {
      final created = n.createdAt;
      return created.year == today.year &&
          created.month == today.month &&
          created.day == today.day;
    }).length;
  }
  int get _rawCount => _allNotes.where((n) => n.status == 'raw').length;

  // ============================================================
  // 点击卡片跳转
  // ============================================================

  void _onStatTap(String type) {
    switch (type) {
      case '笔记':
      case '图书':
      case '文件夹':
      case '今日新增':
        widget.onTabChange?.call(1);
        widget.onRefreshWisdom?.call();
        break;
      case '标签':
        // 跳转标签列表（若实现）
        break;
      case '待整理':
        widget.onTabChange?.call(0);
        break;
      case '任务':
        widget.onSwitchToTaskTab?.call();
        break;
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('📊 洞察'),
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
            Tab(icon: Icon(Icons.dashboard), text: '概览'),
            Tab(icon: Icon(Icons.bubble_chart), text: '知识图谱'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildGraphTab(),
              ],
            ),
    );
  }

  // ============================================================
  // Tab 1：统计看板
  // ============================================================

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 你的知识积累',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 6,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: [
              _buildMiniStatCard(
                icon: Icons.note,
                label: '笔记',
                value: _noteCount,
                color: Colors.blue.shade100,
                iconColor: Colors.blue.shade700,
                onTap: () => _onStatTap('笔记'),
              ),
              _buildMiniStatCard(
                icon: Icons.book,
                label: '图书',
                value: _bookCount,
                color: Colors.green.shade100,
                iconColor: Colors.green.shade700,
                onTap: () => _onStatTap('图书'),
              ),
              _buildMiniStatCard(
                icon: Icons.folder,
                label: '文件夹',
                value: _folderCount,
                color: Colors.amber.shade100,
                iconColor: Colors.amber.shade700,
                onTap: () => _onStatTap('文件夹'),
              ),
              _buildMiniStatCard(
                icon: Icons.local_offer,
                label: '标签',
                value: _totalTags,
                color: Colors.purple.shade100,
                iconColor: Colors.purple.shade700,
                onTap: () => _onStatTap('标签'),
              ),
              _buildMiniStatCard(
                icon: Icons.today,
                label: '今日新增',
                value: _todayCount,
                color: Colors.orange.shade100,
                iconColor: Colors.orange.shade700,
                onTap: () => _onStatTap('今日新增'),
              ),
              _buildMiniStatCard(
                icon: Icons.pending_actions,
                label: '待整理',
                value: _rawCount,
                color: Colors.red.shade100,
                iconColor: Colors.red.shade700,
                onTap: () => _onStatTap('待整理'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '📌 最近活动',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ..._allNodes
              .where((n) => !n.isFolder)
              .take(4)
              .map((node) => Card(
                    margin: const EdgeInsets.only(bottom: 3),
                    child: ListTile(
                      dense: true,
                      leading: Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                      title: Text(
                        node.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        _formatDate(node.createdAt),
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 14),
                      onTap: () => _openNode(node),
                    ),
                  )),
          if (_allNodes.where((n) => !n.isFolder).isEmpty)
            const Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: Text(
                  '还没有内容，去采集吧',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Tab 2：知识图谱
  // ============================================================

  Widget _buildGraphTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allNodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bubble_chart, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text('还没有内容', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('去采集页创建一些笔记和图书吧', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_isGraphReady || _graphData == null) {
      if (_allNodes.isNotEmpty && !_isGraphReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _prepareGraph();
        });
      }
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text('正在构建知识图谱...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    final graph = _graphData!;
    if (graph.isEmpty) {
      return const Center(
        child: Text('图谱数据不足，至少需要2个节点', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    return InteractiveViewer(
      minScale: 0.3,
      maxScale: 2.0,
      constrained: false,
      child: Container(
        width: double.infinity,
        height: 600,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              max(constraints.maxWidth, 600.0),
              max(constraints.maxHeight, 400.0),
            );
            final relayouted = ForceDirectedLayout.layout(graph, size);

            return GestureDetector(
              onTapDown: (_) {
                setState(() {
                  _hoveredNodeIds = {};
                });
              },
              child: CustomPaint(
                painter: KnowledgeGraphPainter(
                  graph: relayouted,
                  onNodeTap: _onNodeTap,
                  hoveredNodeId: _hoveredNodeIds.isNotEmpty ? _hoveredNodeIds.first : null,
                ),
                size: size,
              ),
            );
          },
        ),
      ),
    );
  }

  void _onNodeTap(String nodeId) {
    final node = _allNodes.firstWhere((n) => n.id == nodeId);
    _openNode(node);
  }

  // ============================================================
  // 辅助方法
  // ============================================================

  Future<void> _openNode(Node node) async {
    if (node.isFolder) {
      widget.onTabChange?.call(1);
      widget.onRefreshWisdom?.call();
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
        await _loadData();
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
        await _loadData();
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}