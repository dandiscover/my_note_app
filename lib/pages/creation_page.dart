import 'package:flutter/material.dart';

class CreationPage extends StatelessWidget {
  const CreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✍️ 创作'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.create, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '创作工作区',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '项目、任务、写作模式',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}