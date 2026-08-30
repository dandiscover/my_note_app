// lib/widgets/template_editor.dart
import 'package:flutter/material.dart';
import '../models/thinking_template.dart';

class TemplateEditor extends StatefulWidget {
  final ThinkingTemplate template;
  final Function(Map<String, String>) onGenerateCard;

  const TemplateEditor({
    super.key,
    required this.template,
    required this.onGenerateCard,
  });

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    for (var q in widget.template.questions) {
      _controllers[q] = TextEditingController();
      _controllers[q]!.addListener(_validate);
    }
  }

  void _validate() {
    final hasContent = widget.template.questions.any((q) =>
        _controllers[q]!.text.trim().isNotEmpty);
    setState(() {
      _isValid = hasContent;
    });
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${widget.template.icon} ${widget.template.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(),
          ...widget.template.questions.map((q) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 4),
                TextField(
                  controller: _controllers[q],
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ],
            ),
          )),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isValid
                  ? () {
                      final result = <String, String>{};
                      for (var q in widget.template.questions) {
                        result[q] = _controllers[q]!.text.trim();
                      }
                      widget.onGenerateCard(result);
                    }
                  : null,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('写成卡片'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (!_isValid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '至少填写一个问题才能生成卡片',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}