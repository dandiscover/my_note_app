import 'package:flutter/material.dart';

class WisdomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged; // ✅ 改为可空

  const WisdomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: Colors.grey, width: 1.5),
    );
  }
}