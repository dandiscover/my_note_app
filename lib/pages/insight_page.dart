import 'dart:math';
import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/review_card.dart';
import '../models/user_settings.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';
import 'tag_list_page.dart';
import '../widgets/insight/knowledge_graph.dart';

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
  State<InsightPage> createState() => InsightPageState();
}

class InsightPageState extends State<InsightPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final ReviewService _reviewService = ReviewService();
  final SettingsService _settingsService = SettingsService();

  List<Node> _allNodes = [];
  List<NotebookEntry> _allNotes = [];
  List<Book> _allBooks = [];
  bool _isLoading = true;

  UserSettings? _userSettings;

  GraphData? _graphData;
  bool _isGraphReady = false;
  String? _focusNodeId;
  GraphLayoutMode _layoutMode = GraphLayoutMode.forceDirected;

  List<ReviewCard> _dueCards = [];
  List<ReviewCard> _allCards = [];
  bool _isReviewLoading = false;
  String? _reviewingCardId;

  String _searchQuery = '';
  bool _showOnlyWithTags = false;
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_isGraphReady && !_isLoading) {
        _prepareGraph();
      }
      if (_tabController.index == 2 && !_isLoading) {
        _loadReviewData();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void refreshData() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final nodes = await _db.getAllNodes();
      final notes = await _db.getAllNotes(includeDeleted: false);
      final books = await _db.getAllBooks();
      final settings = await _settingsService.load();

      setState(() {
        _allNodes = nodes;
        _allNotes = notes.map((m) => NotebookEntry.fromMap(m)).toList();
        _allBooks = books.map((m) => Book.fromMap(m)).toList();
        _userSettings = settings;
        _isLoading = false;
      });

      if (!_isGraphReady && _allNodes.isNotEmpty) {
        _prepareGraph();
      }
      if (_tabController.index == 2) {
        _loadReviewData();
      }
    } catch (e) {
      print('❌ 加载洞察数据失败: $e');
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

    final noteContentMap = <String, String>{};
    for (var note in _allNotes) {
      noteContentMap[note.id] = note.content;
    }

    final rawGraph = GraphBuilder.build(validNodes, noteContents: noteContentMap);
    final graphWidth = max(MediaQuery.of(context).size.width, 600.0);
    final graphHeight = max(MediaQuery.of(context).size.height * 0.6, 450.0);
    final size = Size(graphWidth, graphHeight);

    final layouted = ForceDirectedLayout.layout(
      rawGraph,
      size,
      mode: _layoutMode,
      focusNodeId: _focusNodeId,
      localHopCount: 2,
    );

    setState(() {
      _graphData = layouted;
      _isGraphReady = true;
    });
  }

  Future<void> _loadReviewData() async {
    setState(() => _isReviewLoading = true);
    try {
      _allCards = await _reviewService.loadAll();
      _dueCards = await _reviewService.getDueCards();
    } catch (e) {
      print('加载复习数据失败: $e');
    }
    setState(() => _isReviewLoading = false);
  }

  // ============================================================
  // 统计数据
  // ============================================================

  int get _noteCount => _allNotes.where((n) => n.status != 'deleted').length;
  int get _bookCount => _allBooks.length;
  int get _taskCount => _allNotes.where((n) => n.status == 'task').length;
  int get _completedTaskCount => _allNotes.where((n) => n.status == 'deleted').length;
  int get _totalTaskCount => _taskCount + _completedTaskCount;
  double get _taskCompletionRate {
    if (_totalTaskCount == 0) return 0;
    return _completedTaskCount / _totalTaskCount;
  }
  int get _totalTags {
    final tags = <String>{};
    for (var node in _allNodes) {
      tags.addAll(node.tags);
    }
    return tags.length;
  }
  int get _rawCount => _allNotes.where((n) => n.status == 'raw').length;

  int get _todayNoteCount {
    final today = DateTime.now();
    return _allNotes.where((n) =>
      n.status != 'deleted' &&
      n.updatedAt.year == today.year &&
      n.updatedAt.month == today.month &&
      n.updatedAt.day == today.day
    ).length;
  }
  int get _todayTaskCount {
    final today = DateTime.now();
    return _allNotes.where((n) =>
      n.status == 'task' &&
      n.updatedAt.year == today.year &&
      n.updatedAt.month == today.month &&
      n.updatedAt.day == today.day
    ).length;
  }
  int get _todayRawCount {
    final today = DateTime.now();
    return _allNotes.where((n) =>
      n.status == 'raw' &&
      n.updatedAt.year == today.year &&
      n.updatedAt.month == today.month &&
      n.updatedAt.day == today.day
    ).length;
  }
  int get _todayBookCount => 0;
  int get _todayTagCount => 0;

  int get _todayWordCount {
    final today = DateTime.now();
    return _allNotes
        .where((n) =>
            n.status != 'deleted' &&
            n.updatedAt.year == today.year &&
            n.updatedAt.month == today.month &&
            n.updatedAt.day == today.day)
        .fold(0, (sum, n) => sum + n.content.length);
  }

  void _onStatTap(String type) {
    switch (type) {
      case '笔记':
      case '图书':
        widget.onTabChange?.call(1);
        widget.onRefreshWisdom?.call();
        break;
      case '任务':
        widget.onSwitchToTaskTab?.call();
        break;
      case '标签':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TagListPage(allNodes: _allNodes),
          ),
        ).then((_) => _loadData());
        break;
      case '待整理':
        widget.onTabChange?.call(0);
        break;
    }
  }

  Future<void> _handleReview(String cardId, int quality) async {
    setState(() => _reviewingCardId = cardId);
    try {
      await _reviewService.reviewCard(cardId, quality);
      await _loadReviewData();
      if (_dueCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 今日复习全部完成！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('复习失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复习失败，请重试')),
      );
    }
    setState(() => _reviewingCardId = null);
  }

  // ============================================================
  // 热力图数据
  // ============================================================

  Map<DateTime, int> get _heatmapData {
    final result = <DateTime, int>{};
    final now = DateTime.now();
    final year = now.year;

    final isWordMode = _userSettings?.heatmapStatMode == HeatmapStatMode.words;

    for (var note in _allNotes) {
      if (note.status == 'deleted') continue;
      final date = DateTime(note.updatedAt.year, note.updatedAt.month, note.updatedAt.day);
      if (date.year != year) continue;
      if (isWordMode) {
        result[date] = (result[date] ?? 0) + note.content.length;
      } else {
        result[date] = (result[date] ?? 0) + 1;
      }
    }
    return result;
  }

  List<NotebookEntry> _getNotesForDay(DateTime day) {
    return _allNotes.where((n) =>
      n.status != 'deleted' &&
      n.updatedAt.year == day.year &&
      n.updatedAt.month == day.month &&
      n.updatedAt.day == day.day
    ).toList();
  }

  // ============================================================
  // 热力图颜色
  // ============================================================

  List<Color> get _heatmapColors {
    if (_userSettings == null) {
      return [
        Colors.grey.shade100,
        Colors.green.shade200,
        Colors.green.shade400,
        Colors.amber.shade600,
        Colors.red.shade600,
      ];
    }
    return _userSettings!.getHeatmapColors();
  }

  int _getHeatmapColorIndex(int count) {
    if (_userSettings == null) {
      if (count == 0) return 0;
      if (count <= 2) return 1;
      if (count <= 5) return 2;
      if (count <= 10) return 3;
      return 4;
    }

    final high = _userSettings!.currentHighThreshold;
    final burst = _userSettings!.currentBurstThreshold;

    if (count == 0) return 0;
    if (count >= burst) return 4;
    if (count >= high) return 3;
    final ratio = count / high;
    if (ratio <= 0.3) return 1;
    if (ratio <= 0.6) return 2;
    return 3;
  }

  // ============================================================
  // 过滤和排序
  // ============================================================

  List<Node> get _filteredContentNodes {
    var nodes = _allNodes
        .where((n) => !n.isFolder && (n.nodeType == 'note' || n.nodeType == 'book'))
        .toList();

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      nodes = nodes.where((node) {
        if (node.title.toLowerCase().contains(query)) return true;
        if (node.tags.any((t) => t.toLowerCase().contains(query))) return true;
        final note = _allNotes.firstWhere(
          (n) => n.id == node.targetId,
          orElse: () => _allNotes.first,
        );
        return note.content.toLowerCase().contains(query);
      }).toList();
    }

    if (_showOnlyWithTags) {
      nodes = nodes.where((n) => n.tags.isNotEmpty).toList();
    }

    nodes.sort((a, b) {
      final noteA = _allNotes.firstWhere((n) => n.id == a.targetId, orElse: () => _allNotes.first);
      final noteB = _allNotes.firstWhere((n) => n.id == b.targetId, orElse: () => _allNotes.first);
      if (_sortAscending) {
        return noteA.updatedAt.compareTo(noteB.updatedAt);
      } else {
        return noteB.updatedAt.compareTo(noteA.updatedAt);
      }
    });

    return nodes;
  }

  List<Node> get _recentlyEditedNodes {
    var nodes = _allNodes.where((n) => !n.isFolder).toList();
    nodes.sort((a, b) {
      final noteA = _allNotes.firstWhere((n) => n.id == a.targetId, orElse: () => _allNotes.first);
      final noteB = _allNotes.firstWhere((n) => n.id == b.targetId, orElse: () => _allNotes.first);
      return noteB.updatedAt.compareTo(noteA.updatedAt);
    });
    return nodes.take(4).toList();
  }

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
            Tab(icon: Icon(Icons.psychology), text: '复习'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildGraphTab(),
                _buildReviewTab(),
              ],
            ),
    );
  }

  // ============================================================
  // Tab 1：概览
  // ============================================================

  Widget _buildOverviewTab() {
    final contentNodes = _filteredContentNodes;
    final isWordMode = _userSettings?.heatmapStatMode == HeatmapStatMode.words;
    final taskRate = _taskCompletionRate;
    final totalTasks = _totalTaskCount;

    // 任务完成度文案
    String taskMessage;
    Color taskColor;
    if (totalTasks == 0) {
      taskMessage = '今天很轻松哦 🐾';
      taskColor = Colors.grey.shade500;
    } else if (taskRate >= 1.0) {
      taskMessage = '🎉 全部完成！太棒了！';
      taskColor = Colors.green.shade700;
    } else {
      taskMessage = '完成 ${(taskRate * 100).toInt()}%';
      taskColor = Colors.blue.shade700;
    }

    int petHealth = (taskRate * 100).toInt();
    if (totalTasks == 0) petHealth = 0;

    if (_allNodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              '还没有内容',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              '去采集页创建一些笔记吧',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 增加底部 padding 避免溢出
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 任务完成度 + 宠物健康值 + 热力图
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧两个盒子
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.onSwitchToTaskTab?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8), // 减小内边距
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🎯 任务完成度',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalTasks == 0 ? '-' : '${(taskRate * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: taskColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalTasks == 0 ? 0 : taskRate.clamp(0, 1),
                                    minHeight: 5,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(taskColor),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$totalTasks 个任务',
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.task, size: 10, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        '👆 点击管理任务',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.onSwitchToFocusMode?.call();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🐾 宠物健康值',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalTasks == 0 ? '0%' : '${petHealth}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: petHealth > 70
                                        ? Colors.green.shade700
                                        : (petHealth > 30
                                            ? Colors.orange.shade700
                                            : Colors.red.shade700),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalTasks == 0 ? 0 : (petHealth / 100).clamp(0, 1),
                                    minHeight: 5,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      petHealth > 70
                                          ? Colors.green
                                          : (petHealth > 30
                                              ? Colors.orange
                                              : Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🐾', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '👆 查看宠物',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 右侧热力图
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _toggleHeatmapMode(),
                          child: Row(
                            children: [
                              const Text(
                                '📅 写作热力图',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isWordMode ? '📄 字数' : '📝 条数',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildHeatmapHorizontal(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // 知识积累
          const Text(
            '📈 知识积累',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 5,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _buildTotalStatCard(
                icon: Icons.task,
                label: '任务',
                value: _taskCount,
                color: Colors.purple.shade100,
                iconColor: Colors.purple.shade700,
                onTap: () => _onStatTap('任务'),
              ),
              _buildTotalStatCard(
                icon: Icons.pending_actions,
                label: '待整理',
                value: _rawCount,
                color: Colors.red.shade100,
                iconColor: Colors.red.shade700,
                onTap: () => _onStatTap('待整理'),
              ),
              _buildTotalStatCard(
                icon: Icons.note,
                label: '笔记',
                value: _noteCount,
                color: Colors.blue.shade100,
                iconColor: Colors.blue.shade700,
                onTap: () => _onStatTap('笔记'),
              ),
              _buildTotalStatCard(
                icon: Icons.book,
                label: '图书',
                value: _bookCount,
                color: Colors.green.shade100,
                iconColor: Colors.green.shade700,
                onTap: () => _onStatTap('图书'),
              ),
              _buildTotalStatCard(
                icon: Icons.local_offer,
                label: '标签',
                value: _totalTags,
                color: Colors.purple.shade100,
                iconColor: Colors.purple.shade700,
                onTap: () => _onStatTap('标签'),
              ),
            ],
          ),
          const Divider(height: 20),

          // 知识线索
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '🧵 知识线索 (${contentNodes.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '🔍 搜索线索...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                tooltip: _sortAscending ? '从旧到新' : '从新到旧',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: Icon(
                  _showOnlyWithTags ? Icons.local_offer : Icons.local_offer_outlined,
                  size: 16,
                ),
                onPressed: () {
                  setState(() {
                    _showOnlyWithTags = !_showOnlyWithTags;
                  });
                },
                tooltip: _showOnlyWithTags ? '显示全部' : '只显示有标签的',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (contentNodes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: Text(
                  '还没有线索，创建笔记吧',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            )
          else
            ...contentNodes.take(10).map((node) {
              final note = _allNotes.firstWhere(
                (n) => n.id == node.targetId,
                orElse: () => _allNotes.first,
              );
              final isMatch = _searchQuery.trim().isNotEmpty &&
                  (node.title.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
                      node.tags.any((t) => t.toLowerCase().contains(_searchQuery.trim().toLowerCase())) ||
                      note.content.toLowerCase().contains(_searchQuery.trim().toLowerCase()));

              return Card(
                margin: const EdgeInsets.only(bottom: 3),
                child: ListTile(
                  dense: true,
                  leading: Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                  title: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isMatch ? FontWeight.w600 : FontWeight.normal,
                      color: isMatch ? Colors.blue.shade700 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        _formatDate(note.updatedAt),
                        style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                      ),
                      if (node.tags.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        ...node.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 7, color: _getTagColor(tag)),
                          ),
                        )),
                        if (node.tags.length > 2)
                          Text(
                            '+${node.tags.length - 2}',
                            style: TextStyle(fontSize: 7, color: Colors.grey.shade400),
                          ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 14),
                  onTap: () => _openNode(node),
                ),
              );
            }),
          if (contentNodes.length > 10)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '还有 ${contentNodes.length - 10} 条线索...',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          const Divider(height: 20),

          // 今日活跃
          const Text(
            '📌 今日活跃',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 5,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _buildTodayStatCard(
                icon: Icons.task,
                label: '任务',
                value: _todayTaskCount,
                color: Colors.purple.shade50,
                iconColor: Colors.purple.shade700,
                onTap: () => widget.onSwitchToTaskTab?.call(),
              ),
              _buildTodayStatCard(
                icon: Icons.pending_actions,
                label: '待整理',
                value: _todayRawCount,
                color: Colors.red.shade50,
                iconColor: Colors.red.shade700,
                onTap: () => widget.onTabChange?.call(0),
              ),
              _buildTodayStatCard(
                icon: Icons.note,
                label: '笔记',
                value: _todayNoteCount,
                color: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
                onTap: () => widget.onTabChange?.call(1),
              ),
              _buildTodayStatCard(
                icon: Icons.book,
                label: '图书',
                value: _todayBookCount,
                color: Colors.green.shade50,
                iconColor: Colors.green.shade700,
                onTap: () => widget.onTabChange?.call(1),
              ),
              _buildTodayStatCard(
                icon: Icons.local_offer,
                label: '标签',
                value: _todayTagCount,
                color: Colors.purple.shade50,
                iconColor: Colors.purple.shade700,
                onTap: () => _onStatTap('标签'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 最近编辑
          const Text(
            '📌 最近编辑',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ..._recentlyEditedNodes.map((node) {
            final note = _allNotes.firstWhere(
              (n) => n.id == node.targetId,
              orElse: () => _allNotes.first,
            );
            return Card(
              margin: const EdgeInsets.only(bottom: 3),
              child: ListTile(
                dense: true,
                leading: Text(node.iconEmoji, style: const TextStyle(fontSize: 16)),
                title: Text(
                  node.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                subtitle: Text(
                  _formatDate(note.updatedAt),
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                ),
                trailing: const Icon(Icons.chevron_right, size: 14),
                onTap: () => _openNode(node),
              ),
            );
          }),
          if (_allNodes.where((n) => !n.isFolder).isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
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

  // ============================================================
  // 统计卡片（总数-彩色）
  // ============================================================

  Widget _buildTotalStatCard({
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
  // 统计卡片（今日活跃-浅色）
  // ============================================================

  Widget _buildTodayStatCard({
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
        color: color,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
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
  // 切换热力图模式
  // ============================================================

  void _toggleHeatmapMode() async {
    if (_userSettings == null) return;
    final current = _userSettings!.heatmapStatMode;
    final newMode = current == HeatmapStatMode.count
        ? HeatmapStatMode.words
        : HeatmapStatMode.count;
    _userSettings!.heatmapStatMode = newMode;
    await _settingsService.save(_userSettings!);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newMode == HeatmapStatMode.words ? '📄 切换到字数统计' : '📝 切换到条数统计',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ============================================================
  // 热力图（全年12个月）
  // ============================================================

  Widget _buildHeatmapHorizontal() {
    final now = DateTime.now();
    final year = now.year;

    final months = List.generate(12, (i) => DateTime(year, i + 1, 1));

    final heatmapColors = _heatmapColors;
    final heatmapData = _heatmapData;
    final isWordMode = _userSettings?.heatmapStatMode == HeatmapStatMode.words;

    const cellSize = 18.0;
    const cellMargin = 1.0;
    const cellTotal = cellSize + cellMargin * 2;

    final totalCount = heatmapData.values.fold(0, (sum, v) => sum + v);

    if (totalCount == 0) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const Text(
          '📝 今年还没有写作记录',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 22),
              ...months.asMap().entries.map((entry) {
                final index = entry.key;
                final month = entry.value;
                final isFirstMonth = index == 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFirstMonth)
                      Container(
                        width: 1.5,
                        height: 14,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    SizedBox(
                      width: cellTotal,
                      child: Text(
                        '${month.month}月',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 3),

          ...List.generate(7, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    ['一', '二', '三', '四', '五', '六', '日'][row],
                    style: TextStyle(
                      fontSize: 7,
                      color: row >= 5 ? Colors.red.shade300 : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...months.map((month) {
                  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
                  final firstDayWeekday = DateTime(month.year, month.month, 1).weekday;
                  final startOffset = (firstDayWeekday - 1) % 7;
                  final dayIndex = row - startOffset;
                  final isFirstDayOfMonth = dayIndex == 0;

                  if (dayIndex < 0 || dayIndex >= daysInMonth) {
                    return Container(
                      width: cellTotal,
                      height: cellTotal,
                      margin: EdgeInsets.all(cellMargin),
                      decoration: const BoxDecoration(color: Colors.transparent),
                    );
                  }
                  final date = DateTime(month.year, month.month, dayIndex + 1);
                  if (date.isAfter(DateTime(now.year, now.month, now.day))) {
                    return Container(
                      width: cellTotal,
                      height: cellTotal,
                      margin: EdgeInsets.all(cellMargin),
                      decoration: const BoxDecoration(color: Colors.transparent),
                    );
                  }
                  final count = heatmapData[date] ?? 0;
                  final colorIndex = _getHeatmapColorIndex(count);

                  return GestureDetector(
                    onTap: () {
                      final dayNotes = _getNotesForDay(date);
                      if (dayNotes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('这天没有编辑笔记'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }
                      _showDayNotesDialog(date, dayNotes);
                    },
                    child: Tooltip(
                      message: '${date.month}/${date.day}: ${isWordMode ? count.toString() + ' 字' : count.toString() + ' 条'}',
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.all(cellMargin),
                        decoration: BoxDecoration(
                          color: heatmapColors[colorIndex],
                          borderRadius: BorderRadius.circular(3),
                          border: isFirstDayOfMonth
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
          const SizedBox(height: 3),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('少', style: TextStyle(fontSize: 7, color: Colors.grey)),
              ...heatmapColors.map((c) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const Text('多', style: TextStyle(fontSize: 7, color: Colors.grey)),
              const SizedBox(width: 10),
              Text(
                isWordMode
                    ? '共 ${heatmapData.values.reduce((a, b) => a + b)} 字'
                    : '共 ${heatmapData.values.reduce((a, b) => a + b)} 条',
                style: TextStyle(fontSize: 7, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 10),
              if (_userSettings != null)
                Text(
                  isWordMode
                      ? '高产: ≥${_userSettings!.heatmapWordHighThreshold}字'
                      : '高产: ≥${_userSettings!.heatmapHighThreshold}条',
                  style: TextStyle(fontSize: 6, color: Colors.grey.shade400),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDayNotesDialog(DateTime date, List<NotebookEntry> notes) {
    final isWordMode = _userSettings?.heatmapStatMode == HeatmapStatMode.words;
    final totalWords = notes.fold(0, (sum, n) => sum + n.content.length);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${date.year}年${date.month}月${date.day}日',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isWordMode
                          ? '${totalWords}字 · ${notes.length}条'
                          : '${notes.length}条',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final node = _allNodes.firstWhere(
                    (n) => n.targetId == note.id,
                    orElse: () => _allNodes.first,
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Text(node.iconEmoji, style: const TextStyle(fontSize: 20)),
                      title: Text(note.title),
                      subtitle: Row(
                        children: [
                          Text(
                            '${note.content.length}字',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note.content.length > 60 ? '${note.content.substring(0, 60)}...' : note.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(context);
                        await _openNode(node);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Tab 2：知识图谱
  // ============================================================

  Widget _buildGraphTab() {
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _prepareGraph());
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
      return const Center(child: Text('图谱数据不足，至少需要2个节点', style: TextStyle(fontSize: 12, color: Colors.grey)));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeChip(
                label: '🌐 力导向',
                mode: GraphLayoutMode.forceDirected,
                isSelected: _layoutMode == GraphLayoutMode.forceDirected,
                onTap: () {
                  setState(() {
                    _layoutMode = GraphLayoutMode.forceDirected;
                    _focusNodeId = null;
                    _isGraphReady = false;
                  });
                  _prepareGraph();
                },
              ),
              const SizedBox(width: 6),
              _buildModeChip(
                label: '📂 分组',
                mode: GraphLayoutMode.groupByType,
                isSelected: _layoutMode == GraphLayoutMode.groupByType,
                onTap: () {
                  setState(() {
                    _layoutMode = GraphLayoutMode.groupByType;
                    _focusNodeId = null;
                    _isGraphReady = false;
                  });
                  _prepareGraph();
                },
              ),
              const SizedBox(width: 6),
              _buildModeChip(
                label: '🎯 聚焦',
                mode: GraphLayoutMode.localFocus,
                isSelected: _layoutMode == GraphLayoutMode.localFocus,
                onTap: () {
                  setState(() {
                    _layoutMode = GraphLayoutMode.localFocus;
                    _isGraphReady = false;
                  });
                  _prepareGraph();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            width: graphWidth,
            height: graphHeight,
            child: InteractiveViewer(
              minScale: 0.2,
              maxScale: 3.0,
              constrained: false,
              child: Container(
                width: graphWidth,
                height: graphHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = max(constraints.maxWidth, graphWidth);
                    final height = max(constraints.maxHeight, graphHeight);
                    final size = Size(width, height);
                    final relayouted = ForceDirectedLayout.layout(
                      graph,
                      size,
                      mode: _layoutMode,
                      focusNodeId: _focusNodeId,
                      localHopCount: 2,
                    );
                    return KnowledgeGraphWidget(
                      graph: relayouted,
                      onNodeTap: _onNodeTap,
                      mode: _layoutMode,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🖱️ 悬停查看 · 点击跳转 · 滚轮缩放',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
              Text(
                '${graph.nodes.length} 节点 · ${graph.edges.length} 边',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required GraphLayoutMode mode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  void _onNodeTap(String nodeId) {
    if (_layoutMode == GraphLayoutMode.localFocus) {
      setState(() {
        _focusNodeId = nodeId;
        _isGraphReady = false;
      });
      _prepareGraph();
      return;
    }
    final node = _allNodes.firstWhere(
      (n) => n.id == nodeId,
      orElse: () => _allNodes.first,
    );
    _openNode(node);
  }

  // ============================================================
  // Tab 3：复习
  // ============================================================

  Widget _buildReviewTab() {
    if (_isReviewLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              '还没有复习卡片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '在笔记详情中点击「🧠 制卡」创建复习卡片',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                widget.onTabChange?.call(1);
                widget.onRefreshWisdom?.call();
              },
              icon: const Icon(Icons.auto_stories),
              label: const Text('去智库'),
            ),
          ],
        ),
      );
    }

    final stats = _dueCards.length;
    final total = _allCards.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: '待复习',
                value: stats,
                color: stats > 0 ? Colors.orange : Colors.green,
              ),
              _buildStatItem(
                label: '总卡片',
                value: total,
                color: Colors.blue,
              ),
              _buildStatItem(
                label: '进度',
                value: total > 0 ? ((total - stats) / total * 100).round() : 0,
                suffix: '%',
                color: Colors.purple,
              ),
            ],
          ),
        ),
        Expanded(
          child: stats == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        '🎉 今日复习全部完成！',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '休息一下，明天再来',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _dueCards.length,
                  itemBuilder: (context, index) {
                    final card = _dueCards[index];
                    final isReviewing = _reviewingCardId == card.id;
                    return _buildReviewCardItem(card, isReviewing);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    String suffix = '',
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          '$value$suffix',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCardItem(ReviewCard card, bool isReviewing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: card.isNew ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    card.isNew ? '新' : '复习',
                    style: TextStyle(
                      fontSize: 10,
                      color: card.isNew ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              card.answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (!isReviewing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReviewButton(
                    label: '忘记',
                    color: Colors.red,
                    onTap: () => _handleReview(card.id, 0),
                  ),
                  _buildReviewButton(
                    label: '模糊',
                    color: Colors.orange,
                    onTap: () => _handleReview(card.id, 1),
                  ),
                  _buildReviewButton(
                    label: '记得',
                    color: Colors.green,
                    onTap: () => _handleReview(card.id, 2),
                  ),
                ],
              )
            else
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 辅助方法
  // ============================================================

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