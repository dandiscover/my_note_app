import 'package:flutter/material.dart';

/// 底栏——工作台零件 · 丁方案
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
  final String saveLabel;
  final bool isFromCollection;
  final bool compact;
  final bool appBarHasCardAction;

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
    this.compact = false,
    this.appBarHasCardAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final saveMin = compact ? const Size(64, 36) : const Size(100, 40);
    final saveH = compact ? 36.0 : 40.0;
    final showCard = !appBarHasCardAction && onGenerateCard != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!compact)
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
              if (showCard)
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
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              const SizedBox(width: 4),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!compact)
                      const Text('📝', style: TextStyle(fontSize: 14)),
                    Switch(
                      value: isMarkdown,
                      onChanged: onMarkdownChanged,
                      activeThumbColor: Colors.blue,
                      inactiveTrackColor: Colors.grey.shade300,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (!compact)
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
                height: saveH,
                child: ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    minimumSize: saveMin,
                    backgroundColor:
                        isFromCollection ? Colors.blue.shade700 : null,
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}