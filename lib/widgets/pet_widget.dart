// lib/widgets/pet_widget.dart
// 悬浮宠物组件 — 适配8阶段进化 + 对话气泡 + 拖拽

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

  // ─── 对话库 ──────────────────────────────────────────

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

  // 阶段专属对话
  final Map<PetStage, List<String>> _stageMessages = {
    PetStage.droplet: ['💧 我是小水滴...', '想长大！'],
    PetStage.steam: ['♨️ 我在蒸发！', '越来越轻了~'],
    PetStage.mist: ['🌫️ 我变成雾了...', '好朦胧~'],
    PetStage.cloud: ['☁️ 我是一朵云！', '飘啊飘~'],
    PetStage.sunny: ['🌤️ 今天天气真好！', '阳光明媚~'],
    PetStage.rainy: ['🌦️ 要下雨了...', '滋润万物~'],
    PetStage.glowing: ['⛅✨ 我在发光！', '好耀眼~'],
    PetStage.brain: ['🌌 星云脑！', '宇宙在我心中~'],
  };

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

  // ─── 对话逻辑 ──────────────────────────────────────────

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

    // 优先显示阶段专属对话
    final stageMsgs = _stageMessages[pet.stage];
    if (stageMsgs != null && Random().nextBool()) {
      setState(() {
        _bubbleText = stageMsgs[Random().nextInt(stageMsgs.length)];
        _showBubble = true;
      });
    } else {
      // 否则显示心情对话
      final messages = pet.happiness <= 30 ? _sadMessages : _happyMessages;
      setState(() {
        _bubbleText = messages[Random().nextInt(messages.length)];
        _showBubble = true;
      });
    }

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

    // 点击时显示专属对话
    final pet = widget.pet;
    if (pet != null) {
      final stageMsgs = _stageMessages[pet.stage];
      if (stageMsgs != null) {
        setState(() {
          _bubbleText = stageMsgs[Random().nextInt(stageMsgs.length)];
          _showBubble = true;
        });
      } else {
        setState(() {
          _bubbleText = '嘿嘿 😊';
          _showBubble = true;
        });
      }
    } else {
      setState(() {
        _bubbleText = '嘿嘿 😊';
        _showBubble = true;
      });
    }

    setState(() {
      _scale = 1.3;
    });
    _bounceController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
        });
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showBubble = false;
        });
      }
    });
  }

  // ─── UI ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;

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
                  _buildPetBody(pet),
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
                              color: Colors.black.withValues(alpha: 0.1),
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

  // ─── 8阶段主体绘制 ─────────────────────────────────────

  Widget _buildPetBody(Pet? pet) {
    final size = widget.size;

    if (pet == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          shape: BoxShape.circle,
        ),
        child: const Center(child: Text('😊', style: TextStyle(fontSize: 30))),
      );
    }

    switch (pet.stage) {
      // 💧 水滴
      case PetStage.droplet:
        return _buildDroplet(
          size: size * 0.4,
          color: Colors.blue.shade300,
          emotion: pet.emoji,
          count: 1,
        );
      // ♨️ 蒸汽
      case PetStage.steam:
        return _buildDroplet(
          size: size * 0.45,
          color: Colors.blue.shade200,
          emotion: pet.emoji,
          count: 2,
        );
      // 🌫️ 雾
      case PetStage.mist:
        return _buildDroplet(
          size: size * 0.5,
          color: Colors.grey.shade300,
          emotion: pet.emoji,
          count: 3,
        );
      // ☁️ 云
      case PetStage.cloud:
        return _buildCloud(
          size: size * 0.7,
          color: Colors.grey.shade300,
          emotion: pet.emoji,
          count: 3,
        );
      // 🌤️ 晴
      case PetStage.sunny:
        return _buildCloud(
          size: size * 0.7,
          color: Colors.yellow.shade100,
          emotion: pet.emoji,
          count: 3,
        );
      // 🌦️ 雨
      case PetStage.rainy:
        return _buildCloud(
          size: size * 0.7,
          color: Colors.blue.shade200,
          emotion: pet.emoji,
          count: 4,
        );
      // ⛅✨ 辉光云
      case PetStage.glowing:
        return _buildCloudBrain(
          size: size * 0.8,
          emotion: pet.emoji,
          glow: true,
        );
      // 🌌 星云脑
      case PetStage.brain:
        return _buildCloudBrain(
          size: size * 0.9,
          emotion: pet.emoji,
          glow: true,
          isBrain: true,
        );
    }
  }

  // ─── 水滴绘制 ──────────────────────────────────────────

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
              color: color.withValues(alpha: 1.0 - i * 0.1),
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
            color.withValues(alpha: 0.3),
          ],
          center: const Alignment(0.3, 0.3),
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
    } else if (count == 4) {
      positions.add(Offset(-radius * 0.3, -radius * 0.3));
      positions.add(Offset(radius * 0.3, -radius * 0.3));
      positions.add(Offset(-radius * 0.3, radius * 0.3));
      positions.add(Offset(radius * 0.3, radius * 0.3));
    } else {
      for (var i = 0; i < 6; i++) {
        final angle = i * 60 * 3.14159 / 180;
        positions.add(Offset(
          radius * 0.6 * cos(angle),
          radius * 0.6 * sin(angle) + radius * 0.2,
        ));
      }
    }

    // 居中偏移
    final center = baseSize / 2;
    final offsetX = -positions.map((p) => p.dx).reduce((a, b) => a + b) / positions.length + center;
    final offsetY = -positions.map((p) => p.dy).reduce((a, b) => a + b) / positions.length + center;

    return positions.map((p) => Offset(p.dx + offsetX, p.dy + offsetY)).toList();
  }

  // ─── 云朵绘制 ──────────────────────────────────────────

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
      // 底部圆（云朵更蓬松）
      Positioned(
        bottom: -size * 0.15,
        left: size * 0.1,
        child: Container(
          width: size * 0.2,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
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
            color: color.withValues(alpha: 0.8),
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

  // ─── 云脑绘制（辉光云 + 星云脑） ──────────────────────

  Widget _buildCloudBrain({
    required double size,
    required String emotion,
    bool glow = false,
    bool isBrain = false,
  }) {
    final s = size;
    final glowColor = isBrain ? Colors.indigo : Colors.purple;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3),
                  blurRadius: s * 0.3,
                  spreadRadius: s * 0.05,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 云朵身体（更精致）
          Container(
            width: s * 0.7,
            height: s * 0.55,
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
          // 顶部凸起
          Positioned(
            top: -s * 0.15,
            left: s * 0.1,
            child: Container(
              width: s * 0.25,
              height: s * 0.25,
              decoration: BoxDecoration(
                color: isBrain ? const Color(0xFFD1C4E9) : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -s * 0.1,
            left: s * 0.45,
            child: Container(
              width: s * 0.3,
              height: s * 0.3,
              decoration: BoxDecoration(
                color: isBrain ? const Color(0xFFC5B4E3) : const Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -s * 0.08,
            left: s * 0.7,
            child: Container(
              width: s * 0.2,
              height: s * 0.2,
              decoration: BoxDecoration(
                color: isBrain ? const Color(0xFFBA9FD8) : const Color(0xFFECECEC),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 表情
          Positioned(
            top: s * 0.1,
            left: s * 0.35,
            child: Text(
              emotion,
              style: TextStyle(fontSize: s * 0.25),
            ),
          ),
          // 辉光装饰
          if (glow)
            Positioned(
              top: -s * 0.1,
              right: -s * 0.05,
              child: Text(
                isBrain ? '🌌' : '✨',
                style: TextStyle(fontSize: s * 0.18),
              ),
            ),
        ],
      ),
    );
  }
}