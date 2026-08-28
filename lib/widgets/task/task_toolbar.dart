// lib/widgets/task/task_toolbar.dart
// 任务工具栏 — 筛选 + 视图切换

import 'package:flutter/material.dart';
import '../../pages/creation_page.dart';

class TaskToolbar extends StatelessWidget {
  final ViewMode viewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final String urgencyFilter;
  final ValueChanged<String> onUrgencyFilterChanged;
  final String necessityFilter;
  final ValueChanged<String> onNecessityFilterChanged;
  final VoidCallback onAddTask;

  const TaskToolbar({
    super.key,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.urgencyFilter,
    required this.onUrgencyFilterChanged,
    required this.necessityFilter,
    required this.onNecessityFilterChanged,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              ToggleButtons(
                isSelected: [viewMode == ViewMode.list, viewMode == ViewMode.quadrant],
                onPressed: (index) {
                  onViewModeChanged(index == 0 ? ViewMode.list : ViewMode.quadrant);
                },
                children: const [Icon(Icons.list, size: 20), Icon(Icons.grid_view, size: 20)],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '⚡ 添加速通任务...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => onAddTask(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAddTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                ),
                child: const Text('添加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('筛选：', style: TextStyle(fontSize: 13, color: Colors.grey)),
                _buildFilterChip('全部', urgencyFilter, onUrgencyFilterChanged),
                _buildFilterChip('高', urgencyFilter, onUrgencyFilterChanged),
                _buildFilterChip('中', urgencyFilter, onUrgencyFilterChanged),
                _buildFilterChip('低', urgencyFilter, onUrgencyFilterChanged),
                const SizedBox(width: 8),
                _buildFilterChip('必要', necessityFilter, onNecessityFilterChanged),
                _buildFilterChip('重要', necessityFilter, onNecessityFilterChanged),
                _buildFilterChip('可选', necessityFilter, onNecessityFilterChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String current, ValueChanged<String> onSelected) {
    final isSelected = current == label;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => onSelected(label),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}