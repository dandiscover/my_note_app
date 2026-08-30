// lib/pages/insight_page.dart
// 洞察页 — 完整版（修复空数据崩溃）

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../database_service.dart';
import '../models/node.dart';
import '../models/note.dart';
import '../models/book.dart';
import '../models/pet.dart';
import '../models/card.dart';
import '../models/user_settings.dart';
import '../services/pet_service.dart';
import '../services/card_service.dart';
import '../services/settings_service.dart';
import '../services/cache_manager.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/stats_card.dart';
import '../widgets/insight/knowledge_graph.dart';
import '../widgets/insight/review_card_item.dart';
import '../widgets/insight/review_stats.dart';
import '../utils/app_date_utils.dart';
import 'note_detail_page.dart';
import 'book_detail_page.dart';
import 'tag_list_page.dart';

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
  final PetService _petService = PetService();
  final CardService _cardService = CardService();
  final SettingsService _settingsService = SettingsService();
  final CacheManager _cache = CacheManager();

  List<Node> _allNodes = [];
  List<NotebookEntry> _allNotes = [];
  List<Book> _allBooks = [];
  UserSettings? _userSettings;
  Pet? _pet;
  bool _isLoading = true;

  GraphData? _graphData;
  bool _isGraphReady = false;
  String? _focusNodeId;
  GraphLayoutMode _layoutMode = GraphLayoutMode.forceDirected;

  List<CardModel> _reviewCards = [];
  int _reviewIndex = 0;
  bool _isReviewing = false;

  late TabController _tabController;
  final Set<String> _hoveredNodeIds = {};

  static const String _cacheKeyNodes = 'insight_nodes';
  static const String _cacheKeyNotes = 'insight_notes';
  static const String _cacheKeyBooks = 'insight_books';
  static const String _cacheKeySettings = 'insight_settings';
  static const String _cacheKeyPet = 'insight_pet';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    _cache.invalidate(_cacheKeyNodes);
    _cache.invalidate(_cacheKeyNotes);
    _cache.invalidate(_cacheKeyBooks);
    _cache.invalidate(_cacheKeySettings);
    _cache.invalidate(_cacheKeyPet);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final nodes = await _cache.get<List<Node>>(
        _cacheKeyNodes,
        () => _db.getAllNodes(),
        ttl: const Duration(seconds: 30),
      );

      final notes = await _cache.get<List<NotebookEntry>>(
        _cacheKeyNotes,
        () async {
          final maps = await _db.getAllNotes(includeDeleted: false);
          return maps.map((m) => NotebookEntry.fromMap(m)).toList();
        },
        ttl: const Duration(seconds: 30),
      );

      final books = await _cache.get<List<Book>>(
        _cacheKeyBooks,
        () async {
          final maps = await _db.getAllBooks();
          return maps.map((m) => Book.fromMap(m)).toList();
        },
        ttl: const Duration(seconds: 30),
      );

      final settings = await _cache.get<UserSettings>(
        _cacheKeySettings,
        () => _settingsService.load(),
        ttl: const Duration(seconds: 30),
      );

      final pet = await _cache.get<Pet>(
        _cacheKeyPet,
        () => _petService.getOrCreatePet(),
        ttl: const Duration(minutes: 2),
      );

      setState(() {
        _allNodes = nodes;
        _allNotes = notes;
        _allBooks = books;
        _userSettings = settings;
        _pet = pet;
        _isLoading = false;
      });

      if (_allNodes.isNotEmpty && !_isGraphReady) {
        _prepareGraph();
      }
    } catch (e) {
      debugPrint('加载洞察数据失败: $e');
      setState(() => _isLoading = false);
    }
  }

  // ─── 知识图谱 ────────────────────────────────────────────────

  void _prepareGraph() {
    if (_allNodes.isEmpty) return;

    final validNodes = _allNodes.where((n) =>
      n.isFolder || n.nodeType == 'note' || n.nodeType == 'book'
    ).toList();

    if (validNodes.isEmpty) return;

    final noteContentMap = <String, String>{};
    for (var note in _allNotes) {
      noteContentMap[note.id] = note.content;
    }

    final rawGraph = GraphBuilder.build(validNodes, noteContents: noteContentMap);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);
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

  void _changeGraphMode(GraphLayoutMode mode) {
    if (_layoutMode == mode) return;
    setState(() {
      _layoutMode = mode;
      _focusNodeId = null;
    });
    _prepareGraph();
  }

  void _onGraphNodeTap(String nodeId) {
    if (_layoutMode == GraphLayoutMode.localFocus) {
      setState(() {
        _focusNodeId = nodeId;
      });
      _prepareGraph();
      return;
    }
    final node = _allNodes.firstWhereOrNull((n) => n.id == nodeId);
    if (node != null) _openNode(node);
  }

  // ─── 统计数据 ────────────────────────────────────────────────

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

  // ─── 导航 ────────────────────────────────────────────────────

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TagListPage(allNodes: _allNodes),
          ),
        ).then((_) => refreshData());
        break;
      case '待整理':
        widget.onTabChange?.call(0);
        break;
      case '任务':
        widget.onSwitchToTaskTab?.call();
        break;
    }
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
        await refreshData();
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
        await refreshData();
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

  // ─── 复习相关 ────────────────────────────────────────────────

  Future<void> _loadReviewCards() async {
    final cards = await _cardService.getDueCards();
    setState(() {
      _reviewCards = cards;
      _reviewIndex = 0;
      _isReviewing = false;
    });
  }

  void _startReview() {
    setState(() => _isReviewing = true);
  }

  void _onReviewComplete(CardModel card, bool remembered) async {
    if (remembered) {
      await _cardService.rateRemembered(card);
    } else {
      await _cardService.rateForgotten(card);
    }

    setState(() {
      _reviewCards.removeAt(_reviewIndex);
    });

    if (_reviewCards.isEmpty) {
      setState(() => _isReviewing = false);
      _loadReviewCards();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(remembered ? '✅ 记得很好！' : '🔄 再复习一次'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ─── UI 构建 ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildGraphTab(),
          _buildReviewTab(),
        ],
      ),
    );
  }

  // ─── 概览 Tab ─────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(),
          const SizedBox(height: 8),
          _buildCardStats(),
          const SizedBox(height: 8),
          _buildPetAndHeatmap(),
          const SizedBox(height: 8),
          _buildKnowledgeClues(),
          const SizedBox(height: 8),
          _buildTodayActivity(),
          const SizedBox(height: 8),
          _buildRecentEdits(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        StatsCard(
          icon: '📝',
          label: '笔记',
          value: _noteCount,
          color: Colors.blue,
          onTap: () => _onStatTap('笔记'),
        ),
        StatsCard(
          icon: '📚',
          label: '图书',
          value: _bookCount,
          color: Colors.green,
          onTap: () => _onStatTap('图书'),
        ),
        StatsCard(
          icon: '✅',
          label: '任务',
          value: 0,
          color: Colors.red,
          onTap: () => _onStatTap('任务'),
        ),
        StatsCard(
          icon: '📥',
          label: '待整理',
          value: _rawCount,
          color: Colors.orange,
          onTap: () => _onStatTap('待整理'),
        ),
        StatsCard(
          icon: '🏷️',
          label: '标签',
          value: _totalTags,
          color: Colors.purple,
          onTap: () => _onStatTap('标签'),
        ),
      ],
    );
  }

  Widget _buildCardStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _cardService.getStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 40,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStat(String icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildPetAndHeatmap() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: _pet != null
                ? _buildPetCard(_pet!)
                : Container(
                    height: 130,
                    alignment: Alignment.center,
                    child: const Text('🐾 小云加载中...'),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔥 热力图', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 70, maxHeight: 100),
                    child: HeatmapWidget(
                      data: _heatmapData,
                      settings: _userSettings,
                      onDayTap: (date, notes) => _showDayNotesDialog(date, notes),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 130,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: PetAvatar(
              pet: pet,
              size: 80,
              onTap: () async {
                await _petService.petInteraction();
                _cache.invalidate(_cacheKeyPet);
                refreshData();
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text('☁️ ${pet.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Lv.${pet.level}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('❤️ ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pet.happiness / pet.maxHappiness,
                          backgroundColor: Colors.grey.shade200,
                          color: pet.happiness > 60
                              ? Colors.green.shade400
                              : pet.happiness > 30 ? Colors.orange.shade400 : Colors.red.shade400,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pet.happiness}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('经验 ${pet.exp}/${pet.nextLevelExp}', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    const Spacer(),
                    Text(pet.stageLabel, style: TextStyle(fontSize: 9, color: Colors.blue.shade500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayNotesDialog(DateTime date, List<dynamic> notes) {
    final dayNotes = _allNotes.where((n) =>
      n.status != 'deleted' &&
      n.updatedAt.year == date.year &&
      n.updatedAt.month == date.month &&
      n.updatedAt.day == date.day
    ).toList();

    if (dayNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这天没有编辑笔记'), duration: Duration(seconds: 1)),
      );
      return;
    }

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
                    child: Text('${dayNotes.length}条', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: dayNotes.length,
                itemBuilder: (context, index) {
                  final note = dayNotes[index];
                  final node = _allNodes.firstWhereOrNull(
                    (n) => n.targetId == note.id,
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Text(node?.iconEmoji ?? '📄', style: const TextStyle(fontSize: 20)),
                      title: Text(note.title),
                      subtitle: Text(
                        note.content.length > 60 ? '${note.content.substring(0, 60)}...' : note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
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

  Widget _buildKnowledgeClues() {
    final contentNodes = _allNodes
        .where((n) => !n.isFolder && (n.nodeType == 'note' || n.nodeType == 'book'))
        .toList();
    final displayNodes = contentNodes.take(4).toList();

    if (displayNodes.isEmpty) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '暂无知识线索，开始记录吧',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
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
                const Text('🔍 知识线索', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Icon(Icons.local_offer, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Icon(Icons.sort, size: 12, color: Colors.grey.shade500),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...displayNodes.map((node) {
              final note = _allNotes.firstWhereOrNull(
                (n) => n.id == node.targetId,
              );
              if (note == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(node.iconEmoji, style: const TextStyle(fontSize: 14)),
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
                          color: _getTagColor(node.tags.first).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          node.tags.first,
                          style: TextStyle(fontSize: 8, color: _getTagColor(node.tags.first)),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      AppDateUtils.formatShort(note.updatedAt),
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blue, Colors.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.pink, Colors.indigo, Colors.cyan,
    ];
    return colors[hash % colors.length];
  }

  Widget _buildTodayActivity() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 今日活跃', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildTodayStat('📝', _todayCount, '新增', Colors.blue),
                _buildTodayStat('✅', 0, '任务', Colors.red),
                _buildTodayStat('📥', _rawCount, '待整理', Colors.orange),
                _buildTodayStat('📚', _bookCount, '图书', Colors.green),
                _buildTodayStat('🏷️', _totalTags, '标签', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStat(String icon, int value, String label, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        color: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 12, color: color)),
              const SizedBox(height: 2),
              Text(
                value.toString(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEdits() {
    var nodes = _allNodes.where((n) => !n.isFolder).toList();
    nodes.sort((a, b) {
      final noteA = _allNotes.firstWhereOrNull((n) => n.id == a.targetId);
      final noteB = _allNotes.firstWhereOrNull((n) => n.id == b.targetId);
      if (noteA == null && noteB == null) return 0;
      if (noteA == null) return 1;
      if (noteB == null) return -1;
      return noteB.updatedAt.compareTo(noteA.updatedAt);
    });
    final recentNodes = nodes.take(4).toList();

    if (recentNodes.isEmpty) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '暂无编辑记录',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
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
                const Text('🕐 最近编辑', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${recentNodes.length} 条', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 4),
            ...recentNodes.map((node) {
              final note = _allNotes.firstWhereOrNull(
                (n) => n.id == node.targetId,
              );
              if (note == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(node.iconEmoji, style: const TextStyle(fontSize: 13)),
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
                      AppDateUtils.formatShort(note.updatedAt),
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── 知识图谱 Tab ────────────────────────────────────────────

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
      return const Center(
        child: Text('图谱数据不足，至少需要2个节点', style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final graphWidth = max(screenWidth, 600.0);
    final graphHeight = max(screenHeight * 0.6, 400.0);
    final size = Size(graphWidth, graphHeight);

    return Column(
      children: [
        _buildGraphToolbar(),
        Expanded(
          child: SizedBox(
            width: graphWidth,
            height: graphHeight,
            child: InteractiveViewer(
              minScale: 0.2,
              maxScale: 3.0,
              constrained: false,
              child: SizedBox(
                width: graphWidth,
                height: graphHeight,
                child: KnowledgeGraphWidget(
                  graph: ForceDirectedLayout.layout(graph, size, mode: _layoutMode, focusNodeId: _focusNodeId),
                  onNodeTap: _onGraphNodeTap,
                  mode: _layoutMode,
                ),
              ),
            ),
          ),
        ),
        _buildGraphFooter(graph),
      ],
    );
  }

  Widget _buildGraphToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeChip('🌐 力导向', GraphLayoutMode.forceDirected),
          const SizedBox(width: 6),
          _buildModeChip('📂 分组', GraphLayoutMode.groupByType),
          const SizedBox(width: 6),
          _buildModeChip('🎯 聚焦', GraphLayoutMode.localFocus),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, GraphLayoutMode mode) {
    final isSelected = _layoutMode == mode;
    return GestureDetector(
      onTap: () => _changeGraphMode(mode),
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

  Widget _buildGraphFooter(GraphData graph) {
    return Container(
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
    );
  }

  // ─── 复习 Tab ─────────────────────────────────────────────────

  Widget _buildReviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _cardService.getStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data!;
        final dueCount = stats['due'] ?? 0;

        if (dueCount == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('🎉 所有卡片已掌握！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  '共 ${stats['total']} 张卡片，${stats['mastered']} 张已掌握',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadReviewCards,
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ReviewStats(
              totalCards: stats['total'] ?? 0,
              dueCards: dueCount,
              reviewedToday: 0,
              remaining: dueCount,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _reviewCards.length,
                itemBuilder: (context, index) {
                  final card = _reviewCards[index];
                  return ReviewCardItem(
                    card: card,
                    isReviewing: _isReviewing && index == 0,
                    onReview: (quality) {
                      _onReviewComplete(card, quality > 0);
                    },
                  );
                },
              ),
            ),
            if (_reviewCards.isNotEmpty && !_isReviewing)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _startReview,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始复习'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}