// lib/widgets/reader/reading_guide_card.dart
// 指导卡 — 三层提问 UI
// 第一层：字面阅读（3 问）
// 第二层：解释性阅读（4 问）
// 第三层：批判性阅读（4 问）
// 每层结束问"继续往下走吗？"，用户主动收口即算"使用一次"
// 保存：拼接 markdown，回调给父级（父级处理写入笔记 + 首次机制 + usageCount）
// ✅ 5.1：全空时点"停下"直接关面板，不保存
// ✅ 5.2：onCompleted 用途明确为"保存成功后的回调"，父级据此处理首次机制
// ✅ 5.3：组件内部返回 DraggableScrollableSheet，父级用 showModalBottomSheet 包裹
// ✅ 老白裁定：第三层只显示"完成"，不显示"停下"
// ✅ 修复（问题2）：内部加实心白色背景 + 顶部圆角（原 showModalBottomSheet 背景透明）

import 'package:flutter/material.dart';

class ReadingGuideCard extends StatefulWidget {
  final String selectedText;
  final Future<void> Function(String markdown) onFinish;

  /// 保存成功后的回调。
  /// 用途：父级处理首次机制（首次使用指导卡时提示"这是你的第一张指导卡。"）。
  /// 组件本身不直接调 CardService，保持 UI 与业务解耦。
  final VoidCallback? onCompleted;

  const ReadingGuideCard({
    super.key,
    required this.selectedText,
    required this.onFinish,
    this.onCompleted,
  });

  @override
  State<ReadingGuideCard> createState() => _ReadingGuideCardState();
}

class _ReadingGuideCardState extends State<ReadingGuideCard> {
  int _currentLayer = 1; // 1 / 2 / 3
  bool _isSaving = false;
  final List<List<_GuideQuestion>> _layers = [];

  @override
  void initState() {
    super.initState();
    _layers.addAll([
      [
        _GuideQuestion(label: '关键词', question: '这句话的关键词是哪个？'),
        _GuideQuestion(label: '在说谁、说什么', question: '这句话在说谁、说什么？'),
        _GuideQuestion(label: '换成你的话', question: '换成你自己的话，这句话是什么意思？'),
      ],
      [
        _GuideQuestion(label: '为什么用这个词', question: '作者为什么用这个词，而不是另一个？'),
        _GuideQuestion(label: '和上一句的关系', question: '这句话和上一句（或上一段）是什么关系？'),
        _GuideQuestion(label: '想让读者产生什么反应', question: '作者说这句话，是想让读者产生什么反应？'),
        _GuideQuestion(label: '作者假设了什么', question: '这句话背后，作者假设了什么？'),
      ],
      [
        _GuideQuestion(label: '我同意哪部分', question: '你同意这句话吗？同意哪部分，不同意哪部分？'),
        _GuideQuestion(label: '作者可能错在哪', question: '如果作者错了，他可能错在哪？'),
        _GuideQuestion(label: '想到什么', question: '这句话让你想到什么？和你的什么经历或知识有关？'),
        _GuideQuestion(label: '我会改哪个词', question: '如果让你改这句话，你会改哪个词？'),
      ],
    ]);
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      for (final q in layer) {
        q.dispose();
      }
    }
    super.dispose();
  }

  // ─── 层切换 ─────────────────────────────────
  void _goNext() {
    if (_currentLayer < 3) {
      setState(() => _currentLayer++);
    } else {
      _finish();
    }
  }

  // ─── 保存 ─────────────────────────────────
  Future<void> _finish() async {
    if (_isSaving) return;

    final markdown = _buildMarkdown();

    // ✅ 5.1：全空（只有标题行）不保存，直接关面板
    if (_isMarkdownEmpty(markdown)) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onFinish(markdown);
      // ✅ 5.2：onCompleted 是"保存成功"的信号，父级据此处理首次机制
      widget.onCompleted?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ 5.1：判断 markdown 是否只有标题行
  bool _isMarkdownEmpty(String markdown) {
    final nonEmptyLines = markdown
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    return nonEmptyLines.length <= 1;
  }

  // ─── Markdown 拼接 ─────────────────────────────────
  String _buildMarkdown() {
    final buf = StringBuffer();
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    buf.writeln('## 📖 读透：${widget.selectedText}（$dateStr）');
    buf.writeln();

    const layerTitles = ['字面阅读', '解释性阅读', '批判性阅读'];

    for (int i = 0; i < _currentLayer && i < 3; i++) {
      final filled = _layers[i]
          .where((q) => q.controller.text.trim().isNotEmpty)
          .toList();
      if (filled.isEmpty) continue;
      buf.writeln('**${layerTitles[i]}**');
      for (final q in filled) {
        buf.writeln('- ${q.label}：${q.controller.text.trim()}');
      }
      buf.writeln();
    }

    return buf.toString().trimRight();
  }

  // ─── UI ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const layerTitles = ['字面阅读', '解释性阅读', '批判性阅读'];
    final layerIndex = _currentLayer - 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        // ✅ 修复（问题2）：内部加实心白色背景 + 顶部圆角
        // 原因：父级用 showModalBottomSheet(backgroundColor: Colors.transparent)，
        // 不包实心背景时，卡片内容会透出底下的阅读器页面，颜色辨认不清。
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // 头部
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        const Text('📖 ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '读透',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.selectedText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '第 $_currentLayer / 3 层',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  // 层标题
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '【${layerTitles[layerIndex]}】',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 问题列表
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _layers[layerIndex].map((q) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.question,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: q.controller,
                                  maxLines: null,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '写下你的回答（可跳过）',
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // 底部：继续 / 停下（✅ 老白裁定：第三层只显示"完成"，不显示"停下"）
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currentLayer < 3 ? '继续往下走吗？' : '读完了。',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        if (_isSaving)
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else ...[
                          // ✅ 第三层不显示"停下"
                          if (_currentLayer < 3)
                            TextButton(
                              onPressed: _finish,
                              child: const Text('停下', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: _goNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 36),
                            ),
                            child: Text(
                              _currentLayer < 3 ? '继续' : '完成',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── 问题单元 ─────────────────────────────────
class _GuideQuestion {
  final String label;
  final String question;
  final TextEditingController controller;

  _GuideQuestion({required this.label, required this.question})
      : controller = TextEditingController();

  void dispose() => controller.dispose();
}