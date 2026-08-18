// lib/widgets/pet_widget.dart
// 宠物小部件 — 水滴→云朵 成长型 + 飘动动画

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetWidget extends StatefulWidget {
  final double size;
  final bool isActive;
  final Pet? pet;
  final VoidCallback? onTap;

  const PetWidget({
    super.key,
    this.size = 80,
    this.isActive = false,
    this.pet,
    this.onTap,
  });

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool _isDragging = false;
  Offset _position = const Offset(0, 0);
  String? _bubbleText;
  bool _showBubble = false;
  double _scale = 1.0;

  // 水滴数量（根据等级）
  int get _dropletCount {
    final pet = widget.pet;
    if (pet == null) return 1;
    if (pet.level <= 2) return 1;
    if (pet.level <= 4) return 3;
    if (pet.level <= 6) return 6;
    return 9;
  }

  // 对话库
  final List<String> _happyMessages = [
    '加油！继续努力 💪',
    '今天也要好好成长 🌱',
    '我会一直陪着你 ☁️',
    '好开心！😊',
    '我们一起变成云朵吧！☁️',
  ];
  final List<String> _sadMessages = [
    '我好渴... 完成任务给我力量吧 💧',
    '需要你的帮助 🤗',
    '再完成一个任务吧！',
    '我好小... 快让我长大 🌱',
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    if (widget.pet != null) {
      _startRandomBubble();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _startRandomBubble() {
  Future.delayed(Duration(seconds: 5 + Random().nextInt(3)), () {
      if (mounted && widget.pet != null) {
        _showRandomMessage();
        _startRandomBubble();
      }
    });
  }

  void _showRandomMessage() {
    if (widget.pet == null) return;
    final pet = widget.pet!;
    List<String> messages;
    if (pet.happiness <= 30) {
      messages = _sadMessages;
    } else {
      messages = _happyMessages;
    }
    setState(() {
      _bubbleText = messages[Random().nextInt(messages.length)];
      _showBubble = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showBubble = false;
        });
      }
    });
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
    setState(() {
      _scale = 1.3;
      _bubbleText = '嘿嘿 😊';
      _showBubble = true;
    });
    _bounceController.forward(from: 0);
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
    final pet = widget.pet;
    final isDroplet = pet == null || pet.stage == PetStage.droplet || pet.stage == PetStage.droplets;
    final isCloud = pet != null && (pet.stage == PetStage.cloudlet || pet.stage == PetStage.cloud);

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
                  _buildPetBody(pet, isDroplet, isCloud),
                  // ─── 对话气泡 ──────────────────────────
                  if (_showBubble && _bubbleText != null)
                    Positioned(
                      top: -50,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _bubbleText!,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  // ─── 阶段名称 ──────────────────────────
                  if (pet != null)
                    Positioned(
                      bottom: -16,
                      child: Text(
                        pet.stageLabel,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500,
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

  Widget _buildPetBody(Pet? pet, bool isDroplet, bool isCloud) {
    final size = widget.size;

    if (isDroplet) {
      // ─── 水滴阶段 ──────────────────────────
      return _buildDroplet(
        size: size * (0.4 + (pet?.level ?? 1) * 0.04),
        color: pet != null && pet.happiness > 50
            ? Colors.blue.shade300
            : Colors.blue.shade100,
        emotion: pet?.emoji ?? '😊',
        count: _dropletCount,
      );
    } else if (isCloud) {
      // ─── 云朵阶段 ──────────────────────────
      return _buildCloud(
        size: size * 0.7,
        color: pet != null && pet.happiness > 50
            ? Colors.grey.shade300
            : Colors.grey.shade200,
        emotion: pet?.emoji ?? '😊',
        count: _dropletCount,
      );
    }

    // ─── 默认 ──────────────────────────
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          pet?.emoji ?? '😊',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildDroplet({
    required double size,
    required Color color,
    required String emotion,
    required int count,
  }) {
    final droplets = <Widget>[];

    if (count <= 1) {
      droplets.add(
        Positioned(
          left: 0,
          top: 0,
          child: _singleDroplet(size: size, color: color, emotion: emotion),
        ),
      );
    } else {
      final positions = _getDropletPositions(count, size);
      for (var i = 0; i < count && i < positions.length; i++) {
        final pos = positions[i];
        final dropletSize = size * (0.5 + (i % 3) * 0.06);
        droplets.add(
          Positioned(
            left: pos.dx,
            top: pos.dy,
            child: _singleDroplet(
              size: dropletSize,
              color: color,
              emotion: i == 0 ? emotion : null,
            ),
          ),
        );
      }
    }

    return SizedBox(
      width: size * 1.2,
      height: size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: droplets,
      ),
    );
  }

  Widget _singleDroplet({
    required double size,
    required Color color,
    String? emotion,
  }) {
    return Container(
      width: size,
      height: size * 1.2,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.3),
          ],
          center: const Alignment(0.3, 0.3),
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: size * 0.3,
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

  List<Offset> _getDropletPositions(int count, double baseSize) {
    final positions = <Offset>[];
    final center = baseSize / 2;
    final radius = baseSize * 0.4;

    if (count <= 1) {
      positions.add(Offset.zero);
      return positions;
    }

    if (count == 2) {
      positions.add(Offset(-radius * 0.5, -radius * 0.2));
      positions.add(Offset(radius * 0.5, radius * 0.2));
    } else if (count == 3) {
      positions.add(Offset(0, -radius * 0.4));
      positions.add(Offset(-radius * 0.5, radius * 0.3));
      positions.add(Offset(radius * 0.5, radius * 0.3));
    } else if (count == 6) {
      for (var i = 0; i < 6; i++) {
        final angle = i * 60 * 3.14159 / 180;
        positions.add(Offset(
          radius * 0.6 * cos(angle),
          radius * 0.6 * sin(angle) + radius * 0.2,
        ));
      }
    } else {
      for (var i = 0; i < 9; i++) {
        final angle = i * 40 * 3.14159 / 180;
        final r = radius * (0.2 + (i % 3) * 0.25);
        positions.add(Offset(
          r * cos(angle),
          r * sin(angle) + radius * 0.2,
        ));
      }
    }

    // 居中偏移
    final offsetX = -positions.map((p) => p.dx).reduce((a, b) => a + b) / positions.length + center;
    final offsetY = -positions.map((p) => p.dy).reduce((a, b) => a + b) / positions.length + center;

    return positions.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList();
  }

  Widget _buildCloud({
    required double size,
    required Color color,
    required String emotion,
    required int count,
  }) {
    final circles = <Widget>[
      // 主体
      Container(
        width: size * 0.6,
        height: size * 0.4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
      ),
      // 顶部圆
      Positioned(
        top: -size * 0.25,
        left: size * 0.15,
        child: Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: -size * 0.2,
        left: size * 0.45,
        child: Container(
          width: size * 0.35,
          height: size * 0.35,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: -size * 0.15,
        left: size * 0.75,
        child: Container(
          width: size * 0.25,
          height: size * 0.25,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
      // 底部圆
      Positioned(
        bottom: -size * 0.15,
        left: size * 0.1,
        child: Container(
          width: size * 0.2,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -size * 0.1,
        right: size * 0.1,
        child: Container(
          width: size * 0.15,
          height: size * 0.15,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // 表情
      Positioned(
        top: size * 0.1,
        left: size * 0.35,
        child: Text(
          emotion,
          style: TextStyle(fontSize: size * 0.25),
        ),
      ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: circles,
      ),
    );
  }
}