import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 回顾'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.autorenew, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '回顾工作区',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '间隔复习、知识图谱、统计',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}