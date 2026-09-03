// lib/pages/inquiry_page.dart
// 深度笔记 — 提问、拆解行动、记录拐杖
// 第2轮：集成数据库，读写 NotebookEntry
// ✅ 新增：最小一步卡展开（三问 + 存 scaffoldSessions）
// ✅ 修复：最小一步卡展开后子任务区域 RenderFlex 溢出
// ✅ 改名：探究工作台 → 深度笔记，拆解步骤 → 行动

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

  // ─── 最小一步卡状态 ─────────────────────────────
  List<Map<String, dynamic>> _scaffoldSessions = [];
  bool _isScaffoldEditing = false;
  late TextEditingController _q1Controller;
  late TextEditingController _q2Controller;
  late TextEditingController _q3Controller;

  @override
  void initState() {
    super.initState();
    _questionController.text = widget.entry.inquiryQuestion ?? '';
    _subtasks.addAll(widget.entry.subtasks);
    _scaffoldSessions = List.from(widget.entry.scaffoldSessions);

    _q1Controller = TextEditingController();
    _q2Controller = TextEditingController();
    _q3Controller = TextEditingController();

    _initializeScaffoldFields();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _subtaskController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  // ─── 最小一步卡：字段初始化 ─────────────────────

  void _initializeScaffoldFields() {
    final existing = _findMinimalStepSession();
    if (existing != null) {
      final fields = existing['fields'] as List<dynamic>;
      _q1Controller.text = fields[0]['value'] ?? '';
      _q2Controller.text = fields[1]['value'] ?? '';
      _q3Controller.text = fields[2]['value'] ?? '';
    } else {
      _q1Controller.clear();
      _q2Controller.clear();
      _q3Controller.clear();
    }
  }

  Map<String, dynamic>? _findMinimalStepSession() {
    try {
      return _scaffoldSessions.firstWhere(
        (s) => s['scaffoldCardType'] == 'minimal_step',
      );
    } catch (_) {
      return null;
    }
  }

  // ─── 最小一步卡：保存 ────────────────────────────

  void _saveScaffold() {
    final q1 = _q1Controller.text.trim();
    final q2 = _q2Controller.text.trim();
    final q3 = _q3Controller.text.trim();

    // 空答案拦截
    if (q1.isEmpty && q2.isEmpty && q3.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('还没写任何内容'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final fields = [
      {'label': '现在最困扰我的是什么？', 'value': q1},
      {'label': '我能做的最小一步是什么？', 'value': q2},
      {'label': '做完这一步会怎样？', 'value': q3},
    ];

    final now = DateTime.now().toIso8601String();

    setState(() {
      final existing = _findMinimalStepSession();
      if (existing != null) {
        // 替换已有记录（sessionId 保持不变）
        final index = _scaffoldSessions.indexWhere(
          (s) => s['scaffoldCardType'] == 'minimal_step',
        );
        _scaffoldSessions[index] = {
          'sessionId': existing['sessionId'],
          'scaffoldCardType': 'minimal_step',
          'fields': fields,
          'createdAt': existing['createdAt'] ?? now,
        };
      } else {
        // 新增一条
        _scaffoldSessions.add({
          'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
          'scaffoldCardType': 'minimal_step',
          'fields': fields,
          'createdAt': now,
        });
      }
      _isScaffoldEditing = false;
    });
  }

  // ─── 行动操作 ─────────────────────────────────────

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
      scaffoldSessions: List.from(_scaffoldSessions),
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
        title: const Text('📖 深度笔记'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),

              // ─── 最小一步卡 ──────────────────────────
              _buildScaffoldCard(),

              const SizedBox(height: 16),

              // ─── 行动列表 ──────────────────────────
              Row(
                children: [
                  const Text(
                    '🚀 行动',
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

              // 添加行动输入行
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: InputDecoration(
                        hintText: '输入行动...',
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
                    tooltip: '添加行动',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 行动列表
              if (_subtasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '还没有行动，点击上方添加',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subtasks.length,
                  itemBuilder: (context, index) {
                    final subtask = _subtasks[index];
                    return _buildSubtaskItem(subtask);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAndReturn,
        icon: const Icon(Icons.save),
        label: const Text('保存'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─── 最小一步卡 UI ──────────────────────────────

  Widget _buildScaffoldCard() {
    final existing = _findMinimalStepSession();
    final isDone = existing != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200, width: 0.5),
      ),
      child: _isScaffoldEditing
          ? _buildScaffoldEditor()
          : _buildScaffoldCardContent(isDone, existing),
    );
  }

  Widget _buildScaffoldCardContent(bool isDone, Map<String, dynamic>? existing) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _initializeScaffoldFields();
          _isScaffoldEditing = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text('🧭 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最小一步卡',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                  if (isDone) ...[
                    const SizedBox(height: 4),
                    Text(
                      '✅ 已完成',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildPreviewText(existing!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      '💡 点我开始',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  String _buildPreviewText(Map<String, dynamic> existing) {
    final fields = existing['fields'] as List<dynamic>;
    final parts = <String>[];
    for (var field in fields) {
      final value = field['value'] as String?;
      if (value != null && value.isNotEmpty) {
        final preview = value.length > 20 ? '${value.substring(0, 20)}...' : value;
        parts.add(preview);
      }
    }
    return parts.join(' ｜ ');
  }

  Widget _buildScaffoldEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧭 最小一步卡 — 三问',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuestionInput(
            label: '1. 现在最困扰我的是什么？',
            controller: _q1Controller,
          ),
          const SizedBox(height: 8),
          _buildQuestionInput(
            label: '2. 我能做的最小一步是什么？',
            controller: _q2Controller,
          ),
          const SizedBox(height: 8),
          _buildQuestionInput(
            label: '3. 做完这一步会怎样？',
            controller: _q3Controller,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _initializeScaffoldFields();
                    _isScaffoldEditing = false;
                  });
                },
                child: const Text('取消', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveScaffold,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('保存', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
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
            tooltip: '删除行动',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}