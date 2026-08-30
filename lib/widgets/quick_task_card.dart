// lib/widgets/quick_task_card.dart
// 速通任务卡片（优化版 + AutomaticKeepAlive）

import 'package:flutter/material.dart';
import '../models/task.dart';

class QuickTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onSetReminder;

  const QuickTaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
    required this.onSetReminder,
  });

  @override
  State<QuickTaskCard> createState() => _QuickTaskCardState();
}

class _QuickTaskCardState extends State<QuickTaskCard>
    with AutomaticKeepAliveClientMixin {
  bool _isHovered = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hasReminder = widget.task.reminderTime != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _buildPriorityBadges(),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.task.title,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildReminderButton(hasReminder),
            const SizedBox(width: 4),
            _buildCompleteButton(),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: widget.onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '删除任务',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadges() {
    final urgencyColors = {
      Urgency.high: Colors.red,
      Urgency.medium: Colors.orange,
      Urgency.low: Colors.green,
    };
    final necessityColors = {
      Necessity.critical: Colors.red.shade700,
      Necessity.important: Colors.blue,
      Necessity.optional: Colors.grey,
    };
    final urgencyColor = urgencyColors[widget.task.urgency] ?? Colors.grey;
    final necessityColor = necessityColors[widget.task.necessity] ?? Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip(_urgencyLabel(widget.task.urgency), urgencyColor),
        const SizedBox(width: 4),
        _buildChip(_necessityLabel(widget.task.necessity), necessityColor),
        const SizedBox(width: 4),
        _buildChip(widget.task.difficulty.label, Colors.grey),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _urgencyLabel(Urgency u) {
    switch (u) {
      case Urgency.high: return '高';
      case Urgency.medium: return '中';
      case Urgency.low: return '低';
    }
  }

  String _necessityLabel(Necessity n) {
    switch (n) {
      case Necessity.critical: return '必要';
      case Necessity.important: return '重要';
      case Necessity.optional: return '可选';
    }
  }

  Widget _buildReminderButton(bool hasReminder) {
    return Tooltip(
      message: hasReminder ? '⏰ ${_formatTime(widget.task.reminderTime!)}' : '设置提醒',
      child: GestureDetector(
        onTap: widget.onSetReminder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: hasReminder ? Colors.orange.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasReminder ? Colors.orange.shade300 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasReminder ? Icons.alarm : Icons.alarm_outlined,
                size: 16,
                color: hasReminder ? Colors.orange : Colors.grey.shade400,
              ),
              if (hasReminder) ...[
                const SizedBox(width: 2),
                Text(
                  _formatTime(widget.task.reminderTime!),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCompleteButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onComplete,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.green.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? Colors.green.shade400 : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isHovered ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: _isHovered ? Colors.green.shade600 : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                _isHovered ? '完成' : '待办',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _isHovered ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}