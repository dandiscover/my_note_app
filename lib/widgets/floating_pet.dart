// lib/widgets/floating_pet.dart
// 悬浮宠物 — 可拖动（纯UI，不包含Positioned）

import 'package:flutter/material.dart';
import '../models/pet.dart';
import 'pet_avatar.dart';

class FloatingPet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onPanStart(),
      onPanUpdate: (details) => onPanUpdate(details.delta),
      onPanEnd: (details) => onPanEnd(),
      onTap: onTap,
      child: PetAvatar(
        pet: pet,
        size: size,
      ),
    );
  }
}