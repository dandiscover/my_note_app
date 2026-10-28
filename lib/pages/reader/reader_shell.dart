
// lib/pages/reader/reader_shell.dart
import 'package:flutter/material.dart';

class ReaderShell extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color backgroundColor;
  final bool isFocusMode;

  const ReaderShell({
    super.key,
    this.appBar,
    required this.body,
    required this.backgroundColor,
    this.isFocusMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFocusMode) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: body,
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
    );
  }
}