// lib/pages/inquiry_page.dart
// 探究工作台 — 提问、拆解子任务、记录拐杖
// 第2轮：集成数据库，读写 NotebookEntry

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../models/note.dart';

class InquiryPage extends StatefulWidget {
  final NotebookEntry entry;

  const InquiryPage({
    super.key,
    required this.entry,
  });

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  final List<NoteSubtask> _subtasks = [];

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.entry.inquiryQuestion ?? '';
    _subtasks.addAll(widget.entry.subtasks);
  }

  @override
  void dispose() {
    _questionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  // ─── 子任务操作 ─────────────────────────────────────

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _subtasks.add(NoteSubtask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
      ));
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(String id) {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == id);
      if (index == -1) return;
      final old = _subtasks[index];
      _subtasks[index] = old.copyWith(
        isDone: !old.isDone,
        completedAt: old.isDone ? null : DateTime.now(),
      );
    });
  }

  void _deleteSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
  }

  // ─── 保存 ────────────────────────────────────────────

  Future<void> _saveAndReturn() async {
    final updated = NotebookEntry(
      id: widget.entry.id,
      title: widget.entry.title,
      content: widget.entry.content,
      updatedAt: DateTime.now(),
      status: widget.entry.status,
      editorMode: widget.entry.editorMode,
      tags: widget.entry.tags,
      isLocked: widget.entry.isLocked,
      inquiryQuestion: _questionController.text.trim().isNotEmpty
          ? _questionController.text.trim()
          : null,
      scaffoldSessions: widget.entry.scaffoldSessions,
      subtasks: List.from(_subtasks),
    );

    await _db.updateNote(updated.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 探究内容已保存')),
      );
      Navigator.pop(context, updated);
    }
  }

  // ─── UI ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧭 探究工作台'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 探究问题 ────────────────────────────
            const Text(
              '🎯 当前探究问题',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '现在最困扰我的是什么？',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── 子任务列表 ──────────────────────────
            Row(
              children: [
                const Text(
                  '📋 拆解步骤',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${_subtasks.length} 步',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 添加子任务输入行
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: InputDecoration(
                      hintText: '输入步骤...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.purple),
                  onPressed: _addSubtask,
                  tooltip: '添加步骤',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 子任务列表
            Expanded(
              child: _subtasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 40,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '还没有步骤，点击上方添加',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _subtasks.length,
                      itemBuilder: (context, index) {
                        final subtask = _subtasks[index];
                        return _buildSubtaskItem(subtask);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndReturn,
        icon: const Icon(Icons.save),
        label: const Text('保存并返回'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSubtaskItem(NoteSubtask subtask) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: subtask.isDone
            ? Colors.green.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subtask.isDone
              ? Colors.green.shade200
              : Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleSubtask(subtask.id),
            child: Icon(
              subtask.isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: subtask.isDone ? Colors.green : Colors.grey.shade500,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                fontSize: 14,
                decoration: subtask.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: subtask.isDone
                    ? Colors.grey.shade500
                    : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
            onPressed: () => _deleteSubtask(subtask.id),
            tooltip: '删除步骤',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}