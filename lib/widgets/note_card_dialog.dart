// lib/widgets/note_card_dialog.dart
// 从笔记生成卡片的对话框 — 支持6种卡片类型

import 'package:flutter/material.dart';
import '../models/card.dart';

class NoteCardDialog extends StatefulWidget {
  final String selectedText;
  final String comment;
  final String sourceId;
  final String sourceType;

  const NoteCardDialog({
    super.key,
    required this.selectedText,
    required this.comment,
    required this.sourceId,
    required this.sourceType,
  });

  @override
  State<NoteCardDialog> createState() => _NoteCardDialogState();
}

class _NoteCardDialogState extends State<NoteCardDialog> {
  CardType _selectedType = CardType.review;
  Importance _importance = Importance.medium;
  List<String> _tags = [];

  // ─── 所有卡片类型的控制器 ──────────────────────────────
  // 复习卡
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  // 索引卡
  final TextEditingController _indexTitleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _highlightController = TextEditingController();

  // 问答卡
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  // 填空卡
  final TextEditingController _fillQuestionController = TextEditingController();
  final TextEditingController _fillAnswerController = TextEditingController();

  // ✅ 选择题
  final TextEditingController _choiceQuestionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  int _selectedOptionIndex = 0;

  // 判断题
  final TextEditingController _tfStatementController = TextEditingController();
  bool _tfIsTrue = true;

  @override
  void initState() {
    super.initState();
    _initDefaultValues();
  }

  void _initDefaultValues() {
    // 复习卡
    _frontController.text = widget.selectedText;
    // 索引卡
    _indexTitleController.text = widget.selectedText.length > 50
        ? '${widget.selectedText.substring(0, 50)}...'
        : widget.selectedText;
    _highlightController.text = widget.selectedText;
    // 问答卡
    _questionController.text = widget.selectedText;
    // 填空卡
    _fillQuestionController.text = widget.selectedText.replaceAll(RegExp(r'\S+'), '____');
    // ✅ 选择题
    _choiceQuestionController.text = widget.selectedText;
    // 判断题
    _tfStatementController.text = widget.selectedText;
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _indexTitleController.dispose();
    _authorController.dispose();
    _highlightController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _fillQuestionController.dispose();
    _fillAnswerController.dispose();
    _choiceQuestionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _tfStatementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('📇 生成卡片'),
      content: SizedBox(
        width: 500,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── 卡片类型选择 ──────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: CardType.values.map((type) {
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    selectedColor: type.color.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: _selectedType == type ? type.color : Colors.grey.shade700,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // ─── 根据类型显示不同表单 ──────────────────
              ..._buildTypeSpecificForm(),

              const SizedBox(height: 8),

              // ─── 重要性 ──────────────────────────────
              Row(
                children: [
                  const Text('重要性：', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  ...Importance.values.map((imp) {
                    final labels = {'low': '⭐低', 'medium': '⭐⭐中', 'high': '⭐⭐⭐高', 'critical': '⭐⭐⭐⭐极高'};
                    return ChoiceChip(
                      label: Text(labels[imp.name] ?? imp.name),
                      selected: _importance == imp,
                      onSelected: (selected) {
                        setState(() {
                          _importance = imp;
                        });
                      },
                      selectedColor: Colors.blue.shade100,
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),

              // ─── 标签 ──────────────────────────────────
              Row(
                children: [
                  const Text('标签：', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: '标签1, 标签2, ...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onChanged: (value) {
                        _tags = value.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _onGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('生成卡片'),
        ),
      ],
    );
  }

  // ─── 根据类型构建表单 ──────────────────────────────────────

  List<Widget> _buildTypeSpecificForm() {
    switch (_selectedType) {
      case CardType.review:
        return _buildReviewForm();
      case CardType.indexCard:
        return _buildIndexCardForm();
      case CardType.qa:
        return _buildQaForm();
      case CardType.fill:
        return _buildFillForm();
      case CardType.choice:
        return _buildChoiceForm();  // ✅ 选择题表单
      case CardType.truefalse:
        return _buildTrueFalseForm();
    }
  }

  // ─── 复习卡表单 ──────────────────────────────────────────

  List<Widget> _buildReviewForm() {
    return [
      TextField(
        controller: _frontController,
        decoration: const InputDecoration(
          labelText: '正面',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _backController,
        decoration: const InputDecoration(
          labelText: '背面',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
    ];
  }

  // ─── 索引卡表单 ──────────────────────────────────────────

  List<Widget> _buildIndexCardForm() {
    return [
      TextField(
        controller: _indexTitleController,
        decoration: const InputDecoration(
          labelText: '标题',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _authorController,
        decoration: const InputDecoration(
          labelText: '作者',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _highlightController,
        decoration: const InputDecoration(
          labelText: '高光句',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
    ];
  }

  // ─── 问答卡表单 ──────────────────────────────────────────

  List<Widget> _buildQaForm() {
    return [
      TextField(
        controller: _questionController,
        decoration: const InputDecoration(
          labelText: '问题',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _answerController,
        decoration: const InputDecoration(
          labelText: '答案',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
    ];
  }

  // ─── 填空卡表单 ──────────────────────────────────────────

  List<Widget> _buildFillForm() {
    return [
      TextField(
        controller: _fillQuestionController,
        decoration: const InputDecoration(
          labelText: '题目（用 ____ 表示填空）',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _fillAnswerController,
        decoration: const InputDecoration(
          labelText: '答案',
          border: OutlineInputBorder(),
        ),
      ),
    ];
  }

  // ─── ✅ 选择题表单 ──────────────────────────────────────────

  List<Widget> _buildChoiceForm() {
    return [
      // 题目
      TextField(
        controller: _choiceQuestionController,
        decoration: const InputDecoration(
          labelText: '📝 题目',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 8),

      // 选项
      const Text('选项（至少2个）', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),

      // 选项 A
      TextField(
        controller: _optionAController,
        decoration: const InputDecoration(
          labelText: 'A. 选项 A',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (_) => _updateOptionCount(),
      ),
      const SizedBox(height: 4),

      // 选项 B
      TextField(
        controller: _optionBController,
        decoration: const InputDecoration(
          labelText: 'B. 选项 B',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (_) => _updateOptionCount(),
      ),
      const SizedBox(height: 4),

      // 选项 C
      TextField(
        controller: _optionCController,
        decoration: const InputDecoration(
          labelText: 'C. 选项 C（可选）',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (_) => _updateOptionCount(),
      ),
      const SizedBox(height: 4),

      // 选项 D
      TextField(
        controller: _optionDController,
        decoration: const InputDecoration(
          labelText: 'D. 选项 D（可选）',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: (_) => _updateOptionCount(),
      ),
      const SizedBox(height: 8),

      // 正确答案选择
      const Text('✅ 正确答案', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: [
          _buildOptionChip('A', 0),
          _buildOptionChip('B', 1),
          _buildOptionChip('C', 2),
          _buildOptionChip('D', 3),
        ],
      ),
    ];
  }

  void _updateOptionCount() {
    // 用于刷新 UI
    setState(() {});
  }

  Widget _buildOptionChip(String label, int index) {
    // 检查该选项是否有内容
    bool hasContent = false;
    switch (index) {
      case 0:
        hasContent = _optionAController.text.trim().isNotEmpty;
        break;
      case 1:
        hasContent = _optionBController.text.trim().isNotEmpty;
        break;
      case 2:
        hasContent = _optionCController.text.trim().isNotEmpty;
        break;
      case 3:
        hasContent = _optionDController.text.trim().isNotEmpty;
        break;
    }

    // 如果选项为空且不是 A 或 B（至少需要2个），禁用
    final isDisabled = !hasContent && index > 1;

    return ChoiceChip(
      label: Text(label),
      selected: _selectedOptionIndex == index,
      onSelected: isDisabled ? null : (selected) {
        setState(() {
          _selectedOptionIndex = index;
        });
      },
      selectedColor: Colors.green.shade200,
      backgroundColor: Colors.grey.shade100,
      disabledColor: Colors.grey.shade50,
      labelStyle: TextStyle(
        color: isDisabled ? Colors.grey.shade400 : Colors.black87,
        fontWeight: _selectedOptionIndex == index ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  // ─── 判断题表单 ──────────────────────────────────────────

  List<Widget> _buildTrueFalseForm() {
    return [
      TextField(
        controller: _tfStatementController,
        decoration: const InputDecoration(
          labelText: '陈述句',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          const Text('判断为：'),
          const SizedBox(width: 12),
          ChoiceChip(
            label: const Text('✅ 正确'),
            selected: _tfIsTrue,
            onSelected: (selected) {
              setState(() {
                _tfIsTrue = selected;
              });
            },
            selectedColor: Colors.green.shade100,
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('❌ 错误'),
            selected: !_tfIsTrue,
            onSelected: (selected) {
              setState(() {
                _tfIsTrue = !selected;
              });
            },
            selectedColor: Colors.red.shade100,
          ),
        ],
      ),
    ];
  }

  // ─── 生成卡片 ──────────────────────────────────────────────

  void _onGenerate() {
    final result = <String, dynamic>{
      'cardType': _selectedType,
      'tags': _tags,
      'importance': _importance,
    };

    switch (_selectedType) {
      case CardType.review:
        result['front'] = _frontController.text.trim();
        result['back'] = _backController.text.trim();
        break;
      case CardType.indexCard:
        result['indexTitle'] = _indexTitleController.text.trim();
        result['author'] = _authorController.text.trim();
        result['highlight'] = _highlightController.text.trim();
        break;
      case CardType.qa:
        result['question'] = _questionController.text.trim();
        result['answer'] = _answerController.text.trim();
        break;
      case CardType.fill:
        result['fillQuestion'] = _fillQuestionController.text.trim();
        result['fillAnswer'] = _fillAnswerController.text.trim();
        break;
      case CardType.choice:
        final options = [
          _optionAController.text.trim(),
          _optionBController.text.trim(),
          _optionCController.text.trim(),
          _optionDController.text.trim(),
        ].where((o) => o.isNotEmpty).toList();

        if (options.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请至少填写2个选项'), duration: Duration(seconds: 2)),
          );
          return;
        }

        if (_choiceQuestionController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请填写题目'), duration: Duration(seconds: 2)),
          );
          return;
        }

        result['choiceQuestion'] = _choiceQuestionController.text.trim();
        result['choiceOptions'] = options;
        result['choiceCorrectIndex'] = _selectedOptionIndex < options.length ? _selectedOptionIndex : 0;
        break;
      case CardType.truefalse:
        if (_tfStatementController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请填写陈述句'), duration: Duration(seconds: 2)),
          );
          return;
        }
        result['tfStatement'] = _tfStatementController.text.trim();
        result['tfIsTrue'] = _tfIsTrue;
        break;
    }

    Navigator.pop(context, result);
  }
}