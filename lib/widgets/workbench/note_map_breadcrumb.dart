// lib/widgets/workbench/note_map_breadcrumb.dart
import 'package:flutter/material.dart';

class NoteMapBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final void Function(String nodeId) onTap;

  const NoteMapBreadcrumb({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(' / ',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              GestureDetector(
                onTap: i == items.length - 1
                    ? null
                    : () => onTap(items[i].nodeId),
                child: Text(
                  items[i].title,
                  style: TextStyle(
                    fontSize: 12,
                    color: i == items.length - 1
                        ? Colors.black87
                        : Colors.blue,
                    fontWeight: i == items.length - 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BreadcrumbItem {
  final String nodeId;
  final String title;
  const BreadcrumbItem({required this.nodeId, required this.title});
}