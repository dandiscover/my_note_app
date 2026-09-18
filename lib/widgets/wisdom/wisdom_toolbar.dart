// lib/widgets/wisdom/wisdom_toolbar.dart
// 智库工具栏 — 从 wisdom_page 引用枚举

import 'package:flutter/material.dart';
import '../../pages/wisdom_page.dart';

class WisdomToolbar extends StatelessWidget {
  final WisdomViewMode currentMode;
  final ValueChanged<WisdomViewMode> onModeChanged;
  final bool isSelectMode;
  final VoidCallback onToggleSelectMode;
  final int selectedCount;
  final VoidCallback onBatchDelete;
  final VoidCallback onBatchMove;
  final VoidCallback onBatchExport;
  final VoidCallback onTagFilter;
  final int selectedTagCount;

  const WisdomToolbar({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.isSelectMode,
    required this.onToggleSelectMode,
    required this.selectedCount,
    required this.onBatchDelete,
    required this.onBatchMove,
    required this.onBatchExport,
    required this.onTagFilter,
    this.selectedTagCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (!isSelectMode)
            Row(
              children: [
                _buildModeIcon(Icons.list, WisdomViewMode.list),
                const SizedBox(width: 4),
                _buildModeIcon(Icons.grid_view, WisdomViewMode.grid),
                const SizedBox(width: 4),
                _buildModeIcon(Icons.grid_on, WisdomViewMode.large),
                const SizedBox(width: 4),
                _buildModeIcon(Icons.view_column, WisdomViewMode.split),
                const SizedBox(width: 4),
                _buildModeIcon(Icons.dashboard_outlined, WisdomViewMode.cardWall),
                const SizedBox(width: 4),
                _buildModeIcon(Icons.timeline, WisdomViewMode.timeline),
                const SizedBox(width: 4),
                _buildModeIcon(Icons.photo_library_outlined, WisdomViewMode.gallery),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onTagFilter,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selectedTagCount > 0 ? Colors.teal.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 20,
                          color: selectedTagCount > 0 ? Colors.teal.shade700 : Colors.grey.shade600,
                        ),
                        if (selectedTagCount > 0) ...[
                          const SizedBox(width: 2),
                          Text(
                            '$selectedTagCount',
                            style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const Spacer(),
          if (isSelectMode)
            Row(
              children: [
                Text('已选 $selectedCount',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.ios_share, size: 20),
                  onPressed: selectedCount > 0 ? onBatchExport : null,
                  tooltip: '导出 EPUB',
                ),
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outlined, size: 20),
                  onPressed: selectedCount > 0 ? onBatchMove : null,
                  tooltip: '批量移动',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: selectedCount > 0 ? onBatchDelete : null,
                  tooltip: '批量删除',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onToggleSelectMode,
                  tooltip: '退出选择',
                ),
              ],
            )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: onToggleSelectMode,
                  tooltip: '选择模式',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(IconData icon, WisdomViewMode mode) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}