import 'package:flutter/material.dart';

class WisdomLightToast {
  static void show(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
    );
  }
}