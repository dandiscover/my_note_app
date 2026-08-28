// lib/widgets/pet_avatar.dart
// 宠物头像组件 — 适配8阶段进化（💧→♨️→🌫️→☁️→🌤️→🌦️→⛅✨→🌌）

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
  bool _isBlinking = false;

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

  // ─── 8阶段路由 ──────────────────────────────────────────

  Widget _buildPetByStage(Pet pet, double size) {
    switch (pet.stage) {
      // 💧 水滴阶段
      case PetStage.droplet:
        return _buildDroplet(size, pet.emoji, 1, Colors.blue.shade300);
      // ♨️ 蒸汽阶段
      case PetStage.steam:
        return _buildDroplet(size, pet.emoji, 2, Colors.blue.shade200);
      // 🌫️ 雾阶段
      case PetStage.mist:
        return _buildDroplet(size, pet.emoji, 3, Colors.grey.shade300);
      // ☁️ 云阶段
      case PetStage.cloud:
        return _buildCloud(size, pet.emoji, false, Colors.grey.shade300);
      // 🌤️ 晴阶段
      case PetStage.sunny:
        return _buildCloud(size, pet.emoji, false, Colors.yellow.shade100);
      // 🌦️ 雨阶段
      case PetStage.rainy:
        return _buildCloud(size, pet.emoji, true, Colors.blue.shade200);
      // ⛅✨ 辉光云阶段
      case PetStage.glowing:
        return _buildCloudBrain(size, pet.emoji, glow: true);
      // 🌌 星云脑阶段
      case PetStage.brain:
        return _buildCloudBrain(size, pet.emoji, glow: true, isBrain: true);
    }
  }

  // ─── 水滴绘制 ──────────────────────────────────────────

  Widget _buildDroplet(double size, String emotion, int count, Color color) {
    final droplets = <Widget>[];
    final colors = [
      color,
      color.withOpacity(0.7),
      color.withOpacity(0.5),
    ];

    for (var i = 0; i < count && i < colors.length; i++) {
      final offsetX = (i - (count - 1) / 2) * size * 0.25;
      final offsetY = (i % 2 == 0 ? -1 : 1) * size * 0.1;
      final s = size * (0.5 - i * 0.05);
      droplets.add(
        Positioned(
          left: size / 2 - s / 2 + offsetX,
          top: size / 2 - s * 0.6 + offsetY,
          child: _dropShape(s, colors[i % colors.length], i == 0 ? emotion : null),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: droplets,
    );
  }

  Widget _dropShape(double size, Color color, String? emotion) {
    return Container(
      width: size,
      height: size * 1.2,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.3)],
          center: const Alignment(0.3, 0.3),
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: emotion != null
          ? Center(
              child: Text(
                emotion,
                style: TextStyle(fontSize: size * 0.5),
              ),
            )
          : null,
    );
  }

  // ─── 云朵绘制 ──────────────────────────────────────────

  Widget _buildCloud(double size, String emotion, bool isBig, Color color) {
    final scale = isBig ? 1.3 : 1.0;
    final s = size * 0.8 * scale;
    final mainColor = color;

    return SizedBox(
      width: s,
      height: s * 0.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 主体
          Container(
            width: s * 0.6,
            height: s * 0.35,
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(s * 0.2),
            ),
          ),
          // 顶部凸起
          Positioned(
            top: -s * 0.2,
            left: s * 0.1,
            child: Container(
              width: s * 0.3,
              height: s * 0.3,
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -s * 0.15,
            left: s * 0.45,
            child: Container(
              width: s * 0.35,
              height: s * 0.35,
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -s * 0.1,
            left: s * 0.75,
            child: Container(
              width: s * 0.25,
              height: s * 0.25,
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 表情
          Positioned(
            top: s * 0.05,
            left: s * 0.3,
            child: Text(
              emotion,
              style: TextStyle(fontSize: s * 0.25),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 云脑绘制（辉光云 + 星云脑） ──────────────────────

  Widget _buildCloudBrain(double size, String emotion, {bool glow = false, bool isBrain = false}) {
    final s = size * 0.9;
    final glowColor = isBrain ? Colors.indigo : Colors.purple;

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final isBlinking = _blinkController.value > 0.5;
        final eyeScale = isBlinking ? 0.1 : 1.0;

        return Container(
          width: s,
          height: s * 1.1,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.4),
                      blurRadius: s * 0.4,
                      spreadRadius: s * 0.05,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ─── 云朵身体 ──────────────────────────
              Container(
                width: s * 0.65,
                height: s * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBrain
                        ? [const Color(0xFFD1C4E9), const Color(0xFFB39DDB)]
                        : [const Color(0xFFF5F5F5), const Color(0xFFE8E8E8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(s * 0.2),
                ),
              ),
              // 顶部蓬松
              Positioned(
                top: -s * 0.25,
                left: s * 0.05,
                child: Container(
                  width: s * 0.35,
                  height: s * 0.35,
                  decoration: BoxDecoration(
                    color: isBrain ? const Color(0xFFD1C4E9) : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -s * 0.2,
                left: s * 0.45,
                child: Container(
                  width: s * 0.4,
                  height: s * 0.4,
                  decoration: BoxDecoration(
                    color: isBrain ? const Color(0xFFC5B4E3) : const Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -s * 0.15,
                left: s * 0.75,
                child: Container(
                  width: s * 0.3,
                  height: s * 0.3,
                  decoration: BoxDecoration(
                    color: isBrain ? const Color(0xFFBA9FD8) : const Color(0xFFECECEC),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ─── 眼睛 ──────────────────────────
              Positioned(
                top: s * 0.02,
                left: s * 0.25,
                child: Transform.scale(
                  scale: eyeScale,
                  child: Container(
                    width: s * 0.13,
                    height: s * 0.15,
                    decoration: BoxDecoration(
                      color: isBrain ? Colors.indigo.shade900 : Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: s * 0.04,
                        height: s * 0.04,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: s * 0.02,
                left: s * 0.55,
                child: Transform.scale(
                  scale: eyeScale,
                  child: Container(
                    width: s * 0.13,
                    height: s * 0.15,
                    decoration: BoxDecoration(
                      color: isBrain ? Colors.indigo.shade900 : Colors.black87,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: s * 0.04,
                        height: s * 0.04,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── 腮红 ──────────────────────────
              Positioned(
                top: s * 0.15,
                left: s * 0.1,
                child: Container(
                  width: s * 0.12,
                  height: s * 0.07,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB6C1).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(s * 0.06),
                  ),
                ),
              ),
              Positioned(
                top: s * 0.15,
                right: s * 0.1,
                child: Container(
                  width: s * 0.12,
                  height: s * 0.07,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB6C1).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(s * 0.06),
                  ),
                ),
              ),

              // ─── 嘴巴 ──────────────────────────
              Positioned(
                top: s * 0.18,
                left: s * 0.43,
                child: AnimatedBuilder(
                  animation: _breatheController,
                  builder: (context, child) {
                    final mouthScale = 1.0 + _breatheAnimation.value * 0.05;
                    return Transform.scale(
                      scaleY: mouthScale,
                      child: Container(
                        width: s * 0.08,
                        height: s * 0.06,
                        decoration: BoxDecoration(
                          color: isBrain ? Colors.indigo.shade300 : Colors.red.shade300,
                          borderRadius: BorderRadius.circular(s * 0.04),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ─── 辉光/星星装饰 ──────────────────────────
              if (glow)
                Positioned(
                  top: -s * 0.15,
                  right: -s * 0.05,
                  child: AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      final angle = _breatheController.value * 2 * 3.14159;
                      return Transform.rotate(
                        angle: angle,
                        child: Text(
                          isBrain ? '🌌' : '✨',
                          style: TextStyle(fontSize: s * 0.2),
                        ),
                      );
                    },
                  ),
                ),

              // ─── 星云脑额外光晕 ──────────────────────────
              if (isBrain)
                Positioned(
                  bottom: -s * 0.1,
                  left: -s * 0.1,
                  child: AnimatedBuilder(
                    animation: _breatheController,
                    builder: (context, child) {
                      final opacity = 0.3 + _breatheAnimation.value * 0.1;
                      return Container(
                        width: s * 0.3,
                        height: s * 0.3,
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(opacity),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.3),
                              blurRadius: s * 0.3,
                              spreadRadius: s * 0.1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}