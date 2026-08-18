// lib/widgets/floating_pet.dart
// 悬浮宠物 — 在所有页面之上飘动

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pet.dart';

class FloatingPet extends StatefulWidget {
  final Pet pet;
  final double size;
  final VoidCallback onInteract;

  const FloatingPet({
    super.key,
    required this.pet,
    this.size = 70,
    required this.onInteract,
  });

  @override
  State<FloatingPet> createState() => _FloatingPetState();
}

class _FloatingPetState extends State<FloatingPet>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  Offset _position = const Offset(0, 0);
  bool _isDragging = false;
  bool _showBubble = false;
  String? _bubbleText;
  double _scale = 1.0;

  final List<String> _messages = [
    '加油！💪',
    '继续努力！🌟',
    '我会一直陪着你 ☁️',
    '好开心！😊',
    '我们一起成长吧！🌱',
    '你今天真棒！✨',
  ];

  @override
  void initState() {
    super.initState();
    // 🔧 修复1：去掉 const，因为 Random().nextInt 是运行时计算
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2 + Random().nextInt(2)),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _startRandomBubble();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _startRandomBubble() {
    Future.delayed(Duration(seconds: 5 + Random().nextInt(3)), () {
      if (mounted) {
        setState(() {
          _bubbleText = _messages[Random().nextInt(_messages.length)];
          _showBubble = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showBubble = false;
            });
          }
        });
        _startRandomBubble();
      }
    });
  }

  void _onTap() {
    widget.onInteract();
    setState(() {
      _scale = 1.3;
      _bubbleText = '嘿嘿 😊';
      _showBubble = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _scale = 1.0;
      });
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showBubble = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDroplet = widget.pet.stage == PetStage.droplet || widget.pet.stage == PetStage.droplets;
    final isCloud = widget.pet.stage == PetStage.cloudlet || widget.pet.stage == PetStage.cloud;

    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) {
        setState(() {
          _position += details.delta;
        });
      },
      onPanEnd: (_) => setState(() => _isDragging = false),
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final floatValue = _floatAnimation.value;
          return Transform.translate(
            offset: Offset(0, floatValue),
            child: Transform.scale(
              scale: _scale,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ─── 宠物主体 ──────────────────────────
                  _buildPetBody(widget.pet, isDroplet, isCloud),
                  // ─── 对话气泡 ──────────────────────────
                  if (_showBubble && _bubbleText != null)
                    Positioned(
                      top: -35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _bubbleText!,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPetBody(Pet pet, bool isDroplet, bool isCloud) {
    final size = widget.size;

    if (isDroplet) {
      return Container(
        width: size * 0.7,
        height: size * 0.8,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade100,
            ],
            center: const Alignment(0.3, 0.3),
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200.withOpacity(0.4),
              blurRadius: size * 0.3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            pet.emoji,
            style: TextStyle(fontSize: size * 0.4),
          ),
        ),
      );
    } else if (isCloud) {
      return SizedBox(
        width: size,
        height: size * 0.7,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🔧 修复2：移除所有 const
            Container(
              width: size * 0.5,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(size * 0.2),
              ),
            ),
            Positioned(
              top: -size * 0.2,
              left: size * 0.15,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -size * 0.15,
              left: size * 0.45,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: size * 0.05,
              left: size * 0.25,
              child: Text(
                pet.emoji,
                style: TextStyle(fontSize: size * 0.25),
              ),
            ),
          ],
        ),
      );
    }

    // 默认
    return Container(
      width: size * 0.7,
      height: size * 0.8,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          pet.emoji,
          style: TextStyle(fontSize: size * 0.4),
        ),
      ),
    );
  }
}