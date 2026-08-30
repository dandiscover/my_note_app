// lib/widgets/thinking_template_dialog.dart
import 'package:flutter/material.dart';
import '../models/thinking_template.dart';

class ThinkingTemplateDialog extends StatelessWidget {
  final Function(ThinkingTemplate) onSelect;

  const ThinkingTemplateDialog({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择思考模板'),
      content: SizedBox(
        width: 320,
        height: 360,
        child: ListView.separated(
          itemCount: ThinkingTemplate.all.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final template = ThinkingTemplate.all[index];
            return ListTile(
              leading: Text(template.icon, style: const TextStyle(fontSize: 22)),
              title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(template.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                onSelect(template);
              },
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}