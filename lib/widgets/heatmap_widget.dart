// lib/widgets/heatmap_widget.dart
// 热力图组件（独立、可缓存）

import 'package:flutter/material.dart';
import '../models/user_settings.dart';

class HeatmapWidget extends StatefulWidget {
  final Map<DateTime, int> data;
  final UserSettings? settings;
  final Function(DateTime, List<dynamic>) onDayTap;

  const HeatmapWidget({
    super.key,
    required this.data,
    this.settings,
    required this.onDayTap,
  });

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget> {
  late Map<DateTime, int> _cachedData;
  late List<Color> _cachedColors;

  @override
  void initState() {
    super.initState();
    _cachedData = widget.data;
    _cachedColors = widget.settings?.getHeatmapColors() ?? [
      Colors.grey.shade100,
      Colors.green.shade200,
      Colors.green.shade400,
      Colors.amber.shade600,
      Colors.red.shade600,
    ];
  }

  @override
  void didUpdateWidget(HeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _cachedData = widget.data;
    }
    if (oldWidget.settings != widget.settings) {
      _cachedColors = widget.settings?.getHeatmapColors() ?? [
        Colors.grey.shade100,
        Colors.green.shade200,
        Colors.green.shade400,
        Colors.amber.shade600,
        Colors.red.shade600,
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final isWordMode = widget.settings?.heatmapStatMode == HeatmapStatMode.words;

    if (_cachedData.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          '📝 今年还没有写作记录',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final totalCount = _cachedData.values.fold(0, (sum, v) => sum + v);
    const cellSize = 12.0;
    const cellMargin = 1.0;
    const cellTotal = cellSize + cellMargin * 2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMonthLabels(year, cellTotal),
          const SizedBox(height: 2),
          _buildGrid(now, year, cellSize, cellMargin, cellTotal, isWordMode),
          const SizedBox(height: 2),
          _buildLegend(isWordMode, totalCount),
        ],
      ),
    );
  }

  Widget _buildMonthLabels(int year, double cellTotal) {
    final months = List.generate(12, (i) => DateTime(year, i + 1, 1));

    return Row(
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
                  style: TextStyle(fontSize: 5, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGrid(
    DateTime now,
    int year,
    double cellSize,
    double cellMargin,
    double cellTotal,
    bool isWordMode,
  ) {
    final heatmapColors = _cachedColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (row) {
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
            ...List.generate(12, (monthIndex) {
              final month = DateTime(year, monthIndex + 1, 1);
              final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
              final firstDayWeekday = DateTime(month.year, month.month, 1).weekday;
              final startOffset = (firstDayWeekday - 1) % 7;
              final dayIndex = row - startOffset;

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

              final count = _cachedData[date] ?? 0;
              final colorIndex = _getHeatmapColorIndex(count);
              final isFirstDayOfMonth = dayIndex == 0;

              return GestureDetector(
                onTap: () => widget.onDayTap(date, []),
                child: Tooltip(
                  message: '${date.month}/${date.day}: ${isWordMode ? '$count 字' : '$count 条'}',
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
    );
  }

  Widget _buildLegend(bool isWordMode, int totalCount) {
    final heatmapColors = _cachedColors;

    return Row(
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
              ? '共 ${_cachedData.values.reduce((a, b) => a + b)} 字'
              : '共 ${_cachedData.values.reduce((a, b) => a + b)} 条',
          style: TextStyle(fontSize: 5, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  int _getHeatmapColorIndex(int count) {
    if (widget.settings == null) {
      if (count == 0) return 0;
      if (count <= 2) return 1;
      if (count <= 5) return 2;
      if (count <= 10) return 3;
      return 4;
    }

    final high = widget.settings!.currentHighThreshold;
    final burst = widget.settings!.currentBurstThreshold;

    if (count == 0) return 0;
    if (count >= burst) return 4;
    if (count >= high) return 3;
    final ratio = count / high;
    if (ratio <= 0.3) return 1;
    if (ratio <= 0.6) return 2;
    return 3;
  }
}