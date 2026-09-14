// lib/widgets/pet_avatar.dart
// 宠物头像组件 — PNG 图版（Spike 形象替换轮）
// ✅ 8 阶段 → 3 图（pet_happy / pet_sad / pet_blink）+ 阶段尺寸/光效
// ✅ 眨眼复用 _blinkController，切 pet_blink；呼吸 _breatheController 不动
// ⚠️ T-073：当前 PNG 可能 2048×2048，用于 70–80px 显示，容量浪费约 30 倍。
//    远期做图片压缩（多档尺寸），不阻塞本轮。

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetAvatar extends StatefulWidget {
  final Pet pet;
  final double size;
  final bool isActive;
  final VoidCallback? onTap;

  const PetAvatar({
    super.key,
    required this.pet,
    this.size = 80,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<PetAvatar> createState() => _PetAvatarState();
}

class _PetAvatarState extends State<PetAvatar>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _startBlinkTimer();
  }

  void _startBlinkTimer() {
    Future.delayed(Duration(seconds: 2 + Random().nextInt(3)), () {
      if (mounted) {
        _blinkController.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _blinkController.reverse();
          }
        });
        _startBlinkTimer();
      }
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          return Transform.scale(
            scale: _breatheAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: _buildPetByStage(widget.pet, widget.size),
            ),
          );
        },
      ),
    );
  }

  // ─── 3 图 + 阶段尺寸/光效 ─────────────────────────────

  Widget _buildPetByStage(Pet pet, double size) {
    final baseImageName = _selectImage(pet);
    final stageScale = _sizeForStage(pet.stage);
    final glow = _glowForStage(pet.stage);
    final isBrain = pet.stage == PetStage.brain;

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final isBlinking = _blinkController.value > 0.5;
        final actualImageName = isBlinking ? 'pet_blink' : baseImageName;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 光晕层（glowing / brain）
            if (glow) _buildGlowLayer(size, isBrain),

            // 主图（stage 决定尺寸）
            Transform.scale(
              scale: stageScale,
              child: Image.asset(
                'assets/images/pet/$actualImageName.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 图片缺失时降级为占位图标，避免真机白屏
                  return Icon(
                    Icons.cloud,
                    size: size * 0.7,
                    color: Colors.blue.shade200,
                  );
                },
              ),
            ),

            // 星点装饰（glowing / brain）
            if (glow) _buildStarDecoration(size, isBrain),

            // 星云脑额外光点（brain）
            if (isBrain) _buildBrainExtraGlow(size),
          ],
        );
      },
    );
  }

  String _selectImage(Pet pet) {
    if (pet.happiness <= 30) return 'pet_sad';
    return 'pet_happy';
  }

  double _sizeForStage(PetStage stage) {
    switch (stage) {
      case PetStage.droplet:
        return 0.4;
      case PetStage.steam:
        return 0.45;
      case PetStage.mist:
        return 0.5;
      case PetStage.cloud:
        return 0.7;
      case PetStage.sunny:
        return 0.7;
      case PetStage.rainy:
        return 0.7;
      case PetStage.glowing:
        return 0.8;
      case PetStage.brain:
        return 0.9;
    }
  }

  bool _glowForStage(PetStage stage) {
    return stage == PetStage.glowing || stage == PetStage.brain;
  }

  Widget _buildGlowLayer(double size, bool isBrain) {
    final glowColor = isBrain ? Colors.indigo : Colors.purple;
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        final opacity = 0.3 + _breatheAnimation.value * 0.1;
        return Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: opacity),
                blurRadius: size * 0.4,
                spreadRadius: size * 0.05,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarDecoration(double size, bool isBrain) {
    return Positioned(
      top: -size * 0.15,
      right: -size * 0.05,
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          final angle = _breatheController.value * 2 * 3.14159;
          return Transform.rotate(
            angle: angle,
            child: Text(
              isBrain ? '🌌' : '✨',
              style: TextStyle(fontSize: size * 0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrainExtraGlow(double size) {
    return Positioned(
      bottom: -size * 0.1,
      left: -size * 0.1,
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          final opacity = 0.3 + _breatheAnimation.value * 0.1;
          return Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: size * 0.3,
                  spreadRadius: size * 0.1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}