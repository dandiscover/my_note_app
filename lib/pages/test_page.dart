// lib/pages/test_page.dart
// 测试页 — 诊断各功能状态

import 'package:flutter/material.dart';
import '../database_service.dart';
import '../services/supabase_service.dart';
import '../services/pet_service.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final DatabaseService _db = DatabaseService();
  final PetService _petService = PetService();

  bool _isLoading = false;
  String _dbStatus = '⏳ 检测中...';
  String _supabaseStatus = '⏳ 检测中...';
  String _petStatus = '⏳ 检测中...';
  String _booksCount = '⏳ 加载中...';
  String _notesCount = '⏳ 加载中...';
  String _nodesCount = '⏳ 加载中...';

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    setState(() => _isLoading = true);

    // 1. 数据库测试
    try {
      final books = await _db.getAllBooks();
      setState(() {
        _dbStatus = '✅ 正常';
        _booksCount = '${books.length} 本';
      });
    } catch (e) {
      setState(() => _dbStatus = '❌ 错误: $e');
    }

    // 2. 笔记测试
    try {
      final notes = await _db.getAllNotes(includeDeleted: false);
      setState(() {
        _notesCount = '${notes.length} 条';
      });
    } catch (e) {
      setState(() => _notesCount = '❌ $e');
    }

    // 3. 节点测试
    try {
      final nodes = await _db.getAllNodes();
      setState(() {
        _nodesCount = '${nodes.length} 个';
      });
    } catch (e) {
      setState(() => _nodesCount = '❌ $e');
    }

    // 4. Supabase 测试
    try {
      final isLoggedIn = SupabaseService().isLoggedIn;
      setState(() {
        _supabaseStatus = isLoggedIn ? '✅ 已登录' : '🟡 未登录';
      });
    } catch (e) {
      setState(() => _supabaseStatus = '❌ 错误: $e');
    }

    // 5. 宠物测试
    try {
      final pet = await _petService.getOrCreatePet();
      setState(() {
        _petStatus = '✅ Lv.${pet.level} ${pet.stageLabel}';
      });
    } catch (e) {
      setState(() => _petStatus = '❌ 错误: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('🧪 诊断测试'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runAllTests,
            tooltip: '重新测试',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 系统状态',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow('🗄️ 数据库', _dbStatus),
                  _buildStatusRow('☁️ Supabase', _supabaseStatus),
                  _buildStatusRow('🐾 宠物', _petStatus),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📚 数据统计',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow('📖 图书', _booksCount),
                  _buildStatusRow('📝 笔记', _notesCount),
                  _buildStatusRow('📂 节点', _nodesCount),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_dbStatus.contains('❌'))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ 数据库异常，Windows 端可能需要重启应用',
                        style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    final isError = value.contains('❌');
    final isWarning = value.contains('🟡');
    final color = isError
        ? Colors.red.shade700
        : isWarning
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}