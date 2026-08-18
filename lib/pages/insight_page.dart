import 'dart:math';
import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/node.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/review_card.dart';
import '../models/user_settings.dart';
import '../models/pet.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../services/pet_service.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';
import 'tag_list_page.dart';
import '../widgets/insight/knowledge_graph.dart';
import 'insight/review_tab.dart';
import '../services/card_service.dart';
import '../widgets/pet_avatar.dart';

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
  final PetService _petService = PetService();

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
  // Tab 1：概览（宠物 + 热力图并排，精简卡片状态）
  // ============================================================

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 📊 卡片学习状态（精简版） ──────────────────────────
          FutureBuilder<Map<String, dynamic>>(
            future: CardService().getStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              }
              final stats = snapshot.data!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompactStat('📚', stats['total'] ?? 0, Colors.blue),
                    _buildCompactStat('✅', stats['mastered'] ?? 0, Colors.green),
                    _buildCompactStat('📖', stats['learning'] ?? 0, Colors.orange),
                    _buildCompactStat('🔔', stats['due'] ?? 0, Colors.red),
                    _buildCompactStat('📄', stats['reviewCards'] ?? 0, Colors.purple),
                    _buildCompactStat('📚', stats['indexCards'] ?? 0, Colors.teal),
                  ],
                ),
              );
            },
          ),

          // ─── 统计卡片行 ──────────────────────────
          Row(
            children: [
              _buildTotalStatCard(
                icon: Icons.task_alt,
                label: '任务',
                value: _taskCount,
                color: Colors.red.shade100,
                iconColor: Colors.red.shade700,
                onTap: () => _onStatTap('任务'),
              ),
              _buildTotalStatCard(
                icon: Icons.inbox,
                label: '待整理',
                value: _rawCount,
                color: Colors.orange.shade100,
                iconColor: Colors.orange.shade700,
                onTap: () => _onStatTap('待整理'),
              ),
              _buildTotalStatCard(
                icon: Icons.note_alt,
                label: '笔记',
                value: _noteCount,
                color: Colors.blue.shade100,
                iconColor: Colors.blue.shade700,
                onTap: () => _onStatTap('笔记'),
              ),
              _buildTotalStatCard(
                icon: Icons.auto_stories,
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
          const SizedBox(height: 8),

          // ─── 任务完成度 ──────────────────────────
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📋 任务完成度',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      GestureDetector(
                        onTap: widget.onSwitchToTaskTab,
                        child: Text(
                          '查看全部 →',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _taskCompletionRate,
                            backgroundColor: Colors.grey.shade200,
                            color: _taskCompletionRate >= 0.7
                                ? Colors.green.shade500
                                : Colors.orange.shade500,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_taskCompletionRate * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '已完成 ${_completedTaskCount} / 共 $_totalTaskCount 个任务',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ════════════════════════════════════════════════════════════
          // ─── 🐾 宠物 + 🔥 热力图 并排 ──────────────────────────────
          // ════════════════════════════════════════════════════════════
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 左侧：宠物 ──────────────────────────
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FutureBuilder<Pet?>(
                    future: _petService.getOrCreatePet(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          height: 130,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final pet = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        height: 130,
                        child: Row(
                          children: [
                            // 宠物形象（增大到80px）
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: PetAvatar(
                                pet: pet,
                                size: 80,
                                onTap: () async {
                                  await _petService.petInteraction();
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🐾 和小云互动了一下！'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 宠物信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '☁️ ${pet.name}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Lv.${pet.level}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text(
                                        '❤️ ',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pet.happiness / pet.maxHappiness,
                                            backgroundColor: Colors.grey.shade200,
                                            color: pet.happiness > 60
                                                ? Colors.green.shade400
                                                : pet.happiness > 30
                                                    ? Colors.orange.shade400
                                                    : Colors.red.shade400,
                                            minHeight: 5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${pet.happiness}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '经验 ${pet.exp}/${pet.nextLevelExp}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        pet.stageLabel,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.blue.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ─── 右侧：热力图（压缩版） ──────────────────────────
              Expanded(
                flex: 6,
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 热力图标题 + 切换
                        Row(
                          children: [
                            const Text(
                              '🔥 热力图',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleHeatmapMode,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _userSettings?.heatmapStatMode == HeatmapStatMode.count
                                            ? Colors.blue.shade700
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '📝 笔记',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          color: _userSettings?.heatmapStatMode == HeatmapStatMode.count
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _userSettings?.heatmapStatMode == HeatmapStatMode.words
                                            ? Colors.blue.shade700
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '📄 字数',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          color: _userSettings?.heatmapStatMode == HeatmapStatMode.words
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // 压缩热力图
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 70, maxHeight: 100),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildHeatmapHorizontal(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── 知识线索 ──────────────────────────
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🔍 知识线索',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showOnlyWithTags = !_showOnlyWithTags;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _showOnlyWithTags
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '🏷️',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _showOnlyWithTags
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _sortAscending ? '🔼' : '🔽',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索线索...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  ..._filteredContentNodes.take(4).map((node) {
                    final note = _allNotes.firstWhere(
                      (n) => n.id == node.targetId,
                      orElse: () => _allNotes.first,
                    );
                    return GestureDetector(
                      onTap: () => _openNode(node),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              node.iconEmoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                node.title,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (node.tags.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _getTagColor(node.tags.first).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  node.tags.first,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: _getTagColor(node.tags.first),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(note.updatedAt),
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_filteredContentNodes.length > 4)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: 跳转到知识线索全屏列表
                        },
                        child: Text(
                          '查看全部 ${_filteredContentNodes.length} 条 →',
                          style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─── 今日活跃 ──────────────────────────
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 今日活跃',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTodayStatCard(
                        icon: Icons.note_alt_outlined,
                        label: '笔记',
                        value: _todayNoteCount,
                        color: Colors.blue.shade50,
                        iconColor: Colors.blue.shade700,
                        onTap: () => _onStatTap('笔记'),
                      ),
                      _buildTodayStatCard(
                        icon: Icons.task_alt,
                        label: '任务',
                        value: _todayTaskCount,
                        color: Colors.red.shade50,
                        iconColor: Colors.red.shade700,
                        onTap: () => _onStatTap('任务'),
                      ),
                      _buildTodayStatCard(
                        icon: Icons.inbox,
                        label: '待整理',
                        value: _todayRawCount,
                        color: Colors.orange.shade50,
                        iconColor: Colors.orange.shade700,
                        onTap: () => _onStatTap('待整理'),
                      ),
                      _buildTodayStatCard(
                        icon: Icons.auto_stories,
                        label: '图书',
                        value: _todayBookCount,
                        color: Colors.green.shade50,
                        iconColor: Colors.green.shade700,
                        onTap: () => _onStatTap('图书'),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─── 最近编辑 ──────────────────────────
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🕐 最近编辑',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_recentlyEditedNodes.length} 条',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._recentlyEditedNodes.map((node) {
                    final note = _allNotes.firstWhere(
                      (n) => n.id == node.targetId,
                      orElse: () => _allNotes.first,
                    );
                    return GestureDetector(
                      onTap: () => _openNode(node),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              node.iconEmoji,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                node.title,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatDate(note.updatedAt),
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ─── 紧凑统计项 ──────────────────────────
  Widget _buildCompactStat(String icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── 统计卡片（总数-彩色） ──────────────────────────
  Widget _buildTotalStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
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
      ),
    );
  }

  // ─── 今日活跃卡片（浅色） ──────────────────────────
  Widget _buildTodayStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
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
      ),
    );
  }

  // ─── 统一样式的统计项（卡片学习状态用） ──────────────────────────
  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 切换热力图模式 ──────────────────────────
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

  // ─── 热力图（全年12个月 — 压缩版） ──────────────────────────
  Widget _buildHeatmapHorizontal() {
    final now = DateTime.now();
    final year = now.year;

    final months = List.generate(12, (i) => DateTime(year, i + 1, 1));

    final heatmapColors = _heatmapColors;
    final heatmapData = _heatmapData;
    final isWordMode = _userSettings?.heatmapStatMode == HeatmapStatMode.words;

    const cellSize = 12.0;
    const cellMargin = 1.0;
    const cellTotal = cellSize + cellMargin * 2;

    final totalCount = heatmapData.values.fold(0, (sum, v) => sum + v);

    if (totalCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          '📝 今年还没有写作记录',
          style: TextStyle(fontSize: 9, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份标题
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 14),
              ...months.asMap().entries.map((entry) {
                final index = entry.key;
                final month = entry.value;
                final isFirstMonth = index == 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFirstMonth)
                      Container(
                        width: 1,
                        height: 10,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                      ),
                    SizedBox(
                      width: cellTotal,
                      child: Text(
                        '${month.month}月',
                        style: TextStyle(
                          fontSize: 5,
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
          const SizedBox(height: 1),

          // 7行（星期一到星期日）
          ...List.generate(7, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  child: Text(
                    ['一', '二', '三', '四', '五', '六', '日'][row],
                    style: TextStyle(
                      fontSize: 5,
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
                          borderRadius: BorderRadius.circular(2),
                          border: isFirstDayOfMonth
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1,
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
          const SizedBox(height: 1),

          // 图例
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('少', style: TextStyle(fontSize: 5, color: Colors.grey)),
              ...heatmapColors.map((c) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(1),
                ),
              )),
              const Text('多', style: TextStyle(fontSize: 5, color: Colors.grey)),
              const SizedBox(width: 6),
              Text(
                isWordMode
                    ? '共 ${heatmapData.values.reduce((a, b) => a + b)} 字'
                    : '共 ${heatmapData.values.reduce((a, b) => a + b)} 条',
                style: TextStyle(fontSize: 5, color: Colors.grey.shade500),
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
    return const ReviewTab();
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