import 'package:flutter/material.dart';
import '../models/review_card.dart';

class CardEditorDialog extends StatefulWidget {
  final ReviewCard? existingCard;
  final String? presetQuestion;
  final String? presetAnswer;
  final String? presetContext;
  final String? sourceNoteId;

  const CardEditorDialog({
    super.key,
    this.existingCard,
    this.presetQuestion,
    this.presetAnswer,
    this.presetContext,
    this.sourceNoteId,
  });

  @override
  State<CardEditorDialog> createState() => _CardEditorDialogState();
}

class _CardEditorDialogState extends State<CardEditorDialog> {
  late TextEditingController _questionController;
  late TextEditingController _answerController;
  late TextEditingController _contextController;
  late TextEditingController _optionAController;
  late TextEditingController _optionBController;
  late TextEditingController _optionCController;
  late TextEditingController _optionDController;
  int _selectedOptionIndex = 0;
  CardType _cardType = CardType.qa;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingCard != null;

    _questionController = TextEditingController(
      text: widget.existingCard?.question ?? widget.presetQuestion ?? '',
    );
    _answerController = TextEditingController(
      text: widget.existingCard?.answer ?? widget.presetAnswer ?? '',
    );
    _contextController = TextEditingController(
      text: widget.existingCard?.context ?? widget.presetContext ?? '',
    );
    _optionAController = TextEditingController(text: '');
    _optionBController = TextEditingController(text: '');
    _optionCController = TextEditingController(text: '');
    _optionDController = TextEditingController(text: '');
    _cardType = widget.existingCard?.cardType ?? CardType.qa;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _contextController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    super.dispose();
  }

  String _buildAnswerWithOptions() {
    final options = [
      _optionAController.text.trim(),
      _optionBController.text.trim(),
      _optionCController.text.trim(),
      _optionDController.text.trim(),
    ];
    final validOptions = options.where((o) => o.isNotEmpty).toList();
    if (validOptions.length < 2) return '';
    final correct = validOptions[_selectedOptionIndex];
    return validOptions.join('|') + '||' + correct;
  }

  @override
  Widget build(BuildContext context) {
    final isChoice = _cardType == CardType.choice;
    final isFill = _cardType == CardType.fill;
    final isTrueFalse = _cardType == CardType.truefalse;

    return AlertDialog(
      title: Text(_isEditing ? '✏️ 编辑卡片' : '🧠 生成复习卡片'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 卡片类型 ──────────────────────────
              const Text(
                '卡片类型',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              SegmentedButton<CardType>(
                segments: const [
                  ButtonSegment(value: CardType.qa, label: Text('问答')),
                  ButtonSegment(value: CardType.fill, label: Text('填空')),
                  ButtonSegment(value: CardType.choice, label: Text('选择')),
                  ButtonSegment(value: CardType.truefalse, label: Text('判断')),
                ],
                selected: {_cardType},
                onSelectionChanged: (set) {
                  setState(() {
                    _cardType = set.first;
                  });
                },
              ),
              const SizedBox(height: 12),

              // ─── 问题 ──────────────────────────
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: '问题 / 命题',
                  border: OutlineInputBorder(),
                  hintText: '输入问题或陈述...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              // ─── 答案 / 填空 / 选项 ──────────────────────────
              if (isFill) ...[
                // 填空卡
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: '答案（用 {{答案}} 标记填空位置）',
                    border: OutlineInputBorder(),
                    hintText: '例如：{{地球}} 是太阳系第三颗行星',
                  ),
                  maxLines: 2,
                ),
              ] else if (isChoice) ...[
                // 选择题
                const Text(
                  '选项（至少2个）',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _optionAController,
                  decoration: const InputDecoration(
                    labelText: '选项 A',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _optionBController,
                  decoration: const InputDecoration(
                    labelText: '选项 B',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _optionCController,
                  decoration: const InputDecoration(
                    labelText: '选项 C（可选）',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _optionDController,
                  decoration: const InputDecoration(
                    labelText: '选项 D（可选）',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '正确答案',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    _buildOptionChip('A', 0),
                    _buildOptionChip('B', 1),
                    _buildOptionChip('C', 2),
                    _buildOptionChip('D', 3),
                  ],
                ),
              ] else if (isTrueFalse) ...[
                // 判断题
                const Text(
                  '选择正确答案',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildTrueFalseChip('正确', true),
                    const SizedBox(width: 12),
                    _buildTrueFalseChip('错误', false),
                  ],
                ),
              ] else ...[
                // 问答卡
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: '答案',
                    border: OutlineInputBorder(),
                    hintText: '输入答案...',
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 10),

              // ─── 上下文 ──────────────────────────
              if (!_isEditing)
                TextField(
                  controller: _contextController,
                  decoration: const InputDecoration(
                    labelText: '上下文（可选）',
                    border: OutlineInputBorder(),
                    hintText: '记录这段文字的来源...',
                  ),
                  maxLines: 2,
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
        FilledButton(
          onPressed: () {
            final question = _questionController.text.trim();
            String answer = _answerController.text.trim();

            // 选择题构建答案
            if (_cardType == CardType.choice) {
              answer = _buildAnswerWithOptions();
              if (answer.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请至少填写2个选项')),
                );
                return;
              }
            }

            // 判断题
            if (_cardType == CardType.truefalse) {
              if (answer != 'true' && answer != 'false') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请选择正确答案')),
                );
                return;
              }
            }

            if (question.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请填写问题')),
              );
              return;
            }

            if (_cardType != CardType.choice && _cardType != CardType.truefalse && answer.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请填写答案')),
              );
              return;
            }

            final card = ReviewCard(
              id: widget.existingCard?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: question,
              answer: answer,
              sourceNoteId: widget.existingCard?.sourceNoteId ?? widget.sourceNoteId,
              cardType: _cardType,
              context: _contextController.text.trim().isNotEmpty
                  ? _contextController.text.trim()
                  : null,
              stability: widget.existingCard?.stability ?? 0.0,
              difficulty: widget.existingCard?.difficulty ?? 0.0,
              reps: widget.existingCard?.reps ?? 0,
              lapses: widget.existingCard?.lapses ?? 0,
              due: widget.existingCard?.due ?? DateTime.now(),
              lastReview: widget.existingCard?.lastReview,
              state: widget.existingCard?.state ?? 'New',
            );

            Navigator.pop(context, card);
          },
          child: Text(_isEditing ? '保存' : '生成卡片'),
        ),
      ],
    );
  }

  Widget _buildOptionChip(String label, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedOptionIndex == index,
        onSelected: (selected) {
          setState(() {
            _selectedOptionIndex = index;
          });
        },
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildTrueFalseChip(String label, bool value) {
    final isSelected = _answerController.text == value.toString();
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _answerController.text = value.toString();
        });
      },
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}