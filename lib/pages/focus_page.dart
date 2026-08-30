// lib/pages/focus_page.dart
// 专注模式页面 — 修复异步调用

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/focus_service.dart';
import '../widgets/pet_widget.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _seconds = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  int _focusMinutes = 25; // 默认25分钟

  final FocusService _focusService = FocusService();

  // ✅ 新增：统计数据状态变量
  int _todayTotal = 0;
  int _weekTotal = 0;
  int _totalSessions = 0;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (_controller.isCompleted) {
          _controller.reset();
        }
      });
    _loadSettings();
    _loadStats();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _focusService.getSettings();
    setState(() {
      _focusMinutes = settings['focusMinutes'] ?? 25;
      _totalSeconds = _focusMinutes * 60;
      _seconds = _totalSeconds;
    });
  }

  /// ✅ 新增：加载统计数据
  Future<void> _loadStats() async {
    setState(() => _isStatsLoading = true);
    try {
      final today = await _focusService.getTodayTotal();
      final week = await _focusService.getWeekTotal();
      final total = await _focusService.getTotalSessions();
      setState(() {
        _todayTotal = today;
        _weekTotal = week;
        _totalSessions = total;
        _isStatsLoading = false;
      });
    } catch (e) {
      setState(() => _isStatsLoading = false);
    }
  }

  void _startFocus() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _seconds = _totalSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
          _controller.forward(from: 0);
        } else {
          _onFocusComplete();
        }
      });
    });
  }

  void _pauseFocus() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetFocus() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _seconds = _totalSeconds;
    });
  }

  void _onFocusComplete() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    _focusService.recordFocusSession(_focusMinutes);
    // ✅ 专注完成后刷新统计数据
    _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 专注完成！太棒了！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? 1 - (_seconds / _totalSeconds) : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🧘 专注模式'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                _focusMinutes = value;
                _totalSeconds = value * 60;
                _seconds = _totalSeconds;
                _resetFocus();
              });
              _focusService.saveSettings({'focusMinutes': value});
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 15, child: Text('15 分钟')),
              PopupMenuItem(value: 25, child: Text('25 分钟')),
              PopupMenuItem(value: 45, child: Text('45 分钟')),
              PopupMenuItem(value: 60, child: Text('60 分钟')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主内容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 环形进度
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress.toDouble(),
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.8
                              ? Colors.green.shade400
                              : Colors.blue.shade400,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_seconds),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isRunning ? '⏳ 专注中...' : '⏸️ 已暂停',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 控制按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isRunning && _seconds < _totalSeconds)
                      ElevatedButton.icon(
                        onPressed: _resetFocus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重置'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseFocus : _startFocus,
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isRunning ? '暂停' : '开始'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ 修复：统计数据使用状态变量
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: _isStatsLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$_todayTotal',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '今日专注',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_weekTotal',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '本周专注',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$_totalSessions',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '总次数',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // 🐾 宠物（专注时显示）
          if (_isRunning)
            Positioned(
              bottom: 40,
              right: 20,
              child: const PetWidget(
                size: 80,
                isActive: true,
              ),
            ),
        ],
      ),
    );
  }
}