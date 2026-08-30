// lib/widgets/insight/overview_tab.dart
// 洞察页 - 概览 Tab（优化版：添加标题、修复跳转、修正数据）

import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../models/node.dart';
import '../../models/pet.dart';
import '../../models/user_settings.dart';
import '../../services/pet_service.dart';
import '../../services/card_service.dart';
import '../../services/cache_manager.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/heatmap_widget.dart';
import '../../widgets/stats_card.dart';
import '../../utils/app_date_utils.dart';

class OverviewTab extends StatefulWidget {
  final List<Node> allNodes;
  final List<NotebookEntry> allNotes;
  final UserSettings? userSettings;
  final VoidCallback onSwitchToTaskTab;
  final VoidCallback? onSwitchToWisdom;

  const OverviewTab({
    super.key,
    required this.allNodes,
    required this.allNotes,
    required this.userSettings,
    required this.onSwitchToTaskTab,
    this.onSwitchToWisdom,
  });

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late PetService _petService;
  final CacheManager _cache = CacheManager();

  Map<DateTime, int>? _cachedHeatmapData;
  Map<String, dynamic>? _cachedCardStats;
  Pet? _cachedPet;

  static const String _cacheKeyCardStats = 'overview_card_stats';
  static const String _cacheKeyPet = 'overview_pet';

  @override
  void initState() {
    super.initState();
    _petService = PetService();
    _preloadData();
  }

  void _preloadData() {
    _cache.get(_cacheKeyPet, () => _petService.getOrCreatePet());
    _cache.get(_cacheKeyCardStats, () => CardService().getStats());
  }

  Future<Pet?> _getPet() async {
    if (_cachedPet != null) return _cachedPet;
    final pet = await _cache.get<Pet>(
      _cacheKeyPet,
      () => _petService.getOrCreatePet(),
      ttl: const Duration(minutes: 2),
    );
    _cachedPet = pet;
    return pet;
  }

  Future<Map<String, dynamic>> _getCardStats() async {
    if (_cachedCardStats != null) return _cachedCardStats!;
    final stats = await _cache.get<Map<String, dynamic>>(
      _cacheKeyCardStats,
      () => CardService().getStats(),
      ttl: const Duration(seconds: 30),
    );
    _cachedCardStats = stats;
    return stats;
  }

  Map<DateTime, int> get _heatmapData {
    if (_cachedHeatmapData != null) return _cachedHeatmapData!;
    final result = <DateTime, int>{};
    final now = DateTime.now();
    final year = now.year;
    final isWordMode = widget.userSettings?.heatmapStatMode == HeatmapStatMode.words;

    for (var note in widget.allNotes) {
      if (note.status == 'deleted') continue;
      final date = DateTime(note.updatedAt.year, note.updatedAt.month, note.updatedAt.day);
      if (date.year != year) continue;
      if (isWordMode) {
        result[date] = (result[date] ?? 0) + note.content.length;
      } else {
        result[date] = (result[date] ?? 0) + 1;
      }
    }
    _cachedHeatmapData = result;
    return result;
  }

  // ─── 统计值（修正数据源） ──────────────────────────────────

  int get _noteCount {
    return widget.allNotes.where((n) => n.status != 'deleted').length;
  }

  int get _bookCount {
    // 从 allNodes 中统计图书数量
    return widget.allNodes.where((n) => n.nodeType == 'book').length;
  }

  int get _taskCount {
    // 从 allNotes 中统计任务数量
    return widget.allNotes.where((n) => n.status == 'task').length;
  }

  int get _rawCount {
    return widget.allNotes.where((n) => n.status == 'raw').length;
  }

  int get _totalTags {
    final tags = <String>{};
    for (var node in widget.allNodes) {
      tags.addAll(node.tags);
    }
    return tags.length;
  }

  int get _completedTaskCount {
    return widget.allNotes.where((n) => n.status == 'deleted').length;
  }

  int get _totalTaskCount {
    return _taskCount + _completedTaskCount;
  }

  double get _taskCompletionRate {
    if (_totalTaskCount == 0) return 0;
    return _completedTaskCount / _totalTaskCount;
  }

  int get _todayNoteCount {
    final today = DateTime.now();
    return widget.allNotes.where((n) =>
      n.status != 'deleted' &&
      n.updatedAt.year == today.year &&
      n.updatedAt.month == today.month &&
      n.updatedAt.day == today.day
    ).length;
  }

  int get _todayTaskCount {
    final today = DateTime.now();
    return widget.allNotes.where((n) =>
      n.status == 'task' &&
      n.updatedAt.year == today.year &&
      n.updatedAt.month == today.month &&
      n.updatedAt.day == today.day
    ).length;
  }

  int get _todayRawCount {
    final today = DateTime.now();
    return widget.allNotes.where((n) =>
      n.status == 'raw' &&
      n.updatedAt.year == today.year &&
      n.updatedAt.month == today.month &&
      n.updatedAt.day == today.day
    ).length;
  }

  // ─── UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 添加标题
          const Text(
            '📊 卡片学习状态',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildCardStats(),
          const SizedBox(height: 8),
          const Text(
            '📈 数据概览',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _buildStatsRow(),
          const SizedBox(height: 8),
          _buildTaskProgress(),
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

  // ─── 卡片统计 ──────────────────────────────────────────────

  Widget _buildCardStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCardStats(),
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
          margin: const EdgeInsets.only(bottom: 8),
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
              _buildCompactStat('📄', stats['reviewCards'] ?? 0, Colors.purple),
              _buildCompactStat('📚', stats['indexCards'] ?? 0, Colors.teal),
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

  // ─── 统计行（添加跳转） ──────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        StatsCard(
          icon: '📝',
          label: '笔记',
          value: _noteCount,
          color: Colors.blue,
          onTap: () {
            widget.onSwitchToWisdom?.call();
          },
        ),
        StatsCard(
          icon: '📚',
          label: '图书',
          value: _bookCount,
          color: Colors.green,
          onTap: () {
            widget.onSwitchToWisdom?.call();
          },
        ),
        StatsCard(
          icon: '✅',
          label: '任务',
          value: _taskCount,
          color: Colors.red,
          onTap: widget.onSwitchToTaskTab,
        ),
        StatsCard(
          icon: '📥',
          label: '待整理',
          value: _rawCount,
          color: Colors.orange,
          onTap: () {
            // 切换到采集页
          },
        ),
        StatsCard(
          icon: '🏷️',
          label: '标签',
          value: _totalTags,
          color: Colors.purple,
          onTap: () {},
        ),
      ],
    );
  }

  // ─── 任务进度 ──────────────────────────────────────────────

  Widget _buildTaskProgress() {
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
                const Text('📋 任务完成度', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: widget.onSwitchToTaskTab,
                  child: Text(
                    '查看全部 →',
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
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
                      color: _taskCompletionRate >= 0.7 ? Colors.green.shade500 : Colors.orange.shade500,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_taskCompletionRate * 100).toInt()}%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              '已完成 $_completedTaskCount / 共 $_totalTaskCount 个任务',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 宠物 + 热力图 ──────────────────────────────────────────

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
            child: FutureBuilder<Pet?>(
              future: _getPet(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    height: 130,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final pet = snapshot.data!;
                return _buildPetCard(pet);
              },
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
                      settings: widget.userSettings,
                      onDayTap: _showDayNotesDialog,
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
                _cachedPet = null;
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
    final dayNotes = widget.allNotes.where((n) =>
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
                  final node = widget.allNodes.firstWhere(
                    (n) => n.targetId == note.id,
                    orElse: () => widget.allNodes.first,
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Text(node.iconEmoji, style: const TextStyle(fontSize: 20)),
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

  // ─── 知识线索 ──────────────────────────────────────────────

  Widget _buildKnowledgeClues() {
    final contentNodes = widget.allNodes
        .where((n) => !n.isFolder && (n.nodeType == 'note' || n.nodeType == 'book'))
        .toList();
    final displayNodes = contentNodes.take(4).toList();

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
              final note = widget.allNotes.firstWhere(
                (n) => n.id == node.targetId,
                orElse: () => widget.allNotes.first,
              );
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
            if (contentNodes.length > 4)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    '查看全部 ${contentNodes.length} 条 →',
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
                  ),
                ),
              ),
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
      Colors.deepPurple, Colors.red,
    ];
    return colors[hash % colors.length];
  }

  // ─── 今日活跃 ──────────────────────────────────────────────

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
                _buildTodayStat('📝', _todayNoteCount, '笔记', Colors.blue),
                _buildTodayStat('✅', _todayTaskCount, '任务', Colors.red),
                _buildTodayStat('📥', _todayRawCount, '待整理', Colors.orange),
                _buildTodayStat('📚', 0, '图书', Colors.green),
                _buildTodayStat('🏷️', 0, '标签', Colors.purple),
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

  // ─── 最近编辑 ──────────────────────────────────────────────

  Widget _buildRecentEdits() {
    var nodes = widget.allNodes.where((n) => !n.isFolder).toList();
    nodes.sort((a, b) {
      final noteA = widget.allNotes.firstWhere((n) => n.id == a.targetId, orElse: () => widget.allNotes.first);
      final noteB = widget.allNotes.firstWhere((n) => n.id == b.targetId, orElse: () => widget.allNotes.first);
      return noteB.updatedAt.compareTo(noteA.updatedAt);
    });
    final recentNodes = nodes.take(4).toList();

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
              final note = widget.allNotes.firstWhere(
                (n) => n.id == node.targetId,
                orElse: () => widget.allNotes.first,
              );
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
}