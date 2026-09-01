// lib/widgets/floating_pet.dart
// 悬浮宠物 — 可拖动（纯UI，不包含Positioned）
// ✅ 新增文字气泡功能 + GlobalKey

import 'dart:async';  // ✅ 新增
import 'package:flutter/material.dart';
import '../models/pet.dart';
import 'pet_avatar.dart';

class FloatingPet extends StatefulWidget {
  final Pet pet;
  final double size;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanStart;
  final VoidCallback onPanEnd;

  const FloatingPet({
    super.key,
    required this.pet,
    required this.size,
    required this.onTap,
    required this.onPanUpdate,
    required this.onPanStart,
    required this.onPanEnd,
  });

  @override
  State<FloatingPet> createState() => FloatingPetState();
}

/// ✅ 公开 State，供外部调用 showMessage
class FloatingPetState extends State<FloatingPet> {
  String? _message;
  Timer? _timer;

  /// ✅ 显示文字气泡，3秒后自动消失
  void showMessage(String msg) {
    setState(() {
      _message = msg;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => widget.onPanStart(),
      onPanUpdate: (details) => widget.onPanUpdate(details.delta),
      onPanEnd: (details) => widget.onPanEnd(),
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PetAvatar(
            pet: widget.pet,
            size: widget.size,
          ),
          // ✅ 文字气泡（在宠物上方显示）
          if (_message != null && _message!.isNotEmpty)
            Positioned(
              bottom: widget.size + 8,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ✅ GlobalKey 定义在这里，避免循环依赖
final GlobalKey<FloatingPetState> floatingPetKey = GlobalKey<FloatingPetState>();