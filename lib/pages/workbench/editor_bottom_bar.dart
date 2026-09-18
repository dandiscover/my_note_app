import 'package:flutter/material.dart';

/// 底栏——工作台零件 · 丁方案
///
/// 布局：左（字数/行数/标签数）+ 右（生成卡片 / Markdown 开关 / 取消 / 保存）
class EditorBottomBar extends StatelessWidget {
  final int wordCount;
  final int lineCount;
  final int tagCount;
  final bool isMarkdown;
  final ValueChanged<bool> onMarkdownChanged;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onGenerateCard;
  final bool isGeneratingCard;
  final String saveLabel;  // '💾 保存' / '📥 收入智库'
  final bool isFromCollection;

  const EditorBottomBar({
    super.key,
    required this.wordCount,
    required this.lineCount,
    required this.tagCount,
    required this.isMarkdown,
    required this.onMarkdownChanged,
    required this.isSaving,
    required this.onSave,
    this.onCancel,
    this.onGenerateCard,
    this.isGeneratingCard = false,
    this.saveLabel = '💾 保存',
    this.isFromCollection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('📝 $wordCount 字',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              if (isMarkdown)
                Text('📄 $lineCount 行',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 16),
              if (tagCount > 0)
                Text('🏷️ $tagCount',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              if (onGenerateCard != null)
                Tooltip(
                  message: '生成复习卡片',
                  child: IconButton(
                    icon: isGeneratingCard
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.purple))
                        : const Icon(Icons.auto_awesome,
                            size: 20, color: Colors.purple),
                    onPressed: isGeneratingCard ? null : onGenerateCard,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              const SizedBox(width: 4),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 14)),
                    Switch(
                      value: isMarkdown,
                      onChanged: onMarkdownChanged,
                      activeThumbColor: Colors.blue,
                      inactiveTrackColor: Colors.grey.shade300,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('📄', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              if (onCancel != null)
                TextButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('取消'),
                ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 40),
                    backgroundColor: isFromCollection
                        ? Colors.blue.shade700
                        : null,
                    foregroundColor:
                        isFromCollection ? Colors.white : null,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(saveLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}