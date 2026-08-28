// lib/widgets/wisdom/wisdom_search_bar.dart
// 智库搜索栏（修复搜索功能）

import 'package:flutter/material.dart';

class WisdomSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const WisdomSearchBar({
    super.key,
    this.initialQuery = '',
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<WisdomSearchBar> createState() => _WisdomSearchBarState();
}

class _WisdomSearchBarState extends State<WisdomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索知识...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    widget.onClear();
                  },
                )
              : null,
        ),
        onChanged: widget.onChanged,
        onSubmitted: (value) {
          widget.onChanged(value);
        },
      ),
    );
  }
}