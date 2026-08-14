import 'package:flutter/material.dart';
import 'database_service.dart';
import 'pages/inspiration_page.dart';
import 'pages/reading_page.dart';
import 'pages/knowledge_page.dart';
import 'pages/creation_page.dart';
import 'pages/review_page.dart';
import 'pages/library_page.dart';  // ✅ 新增导入
import 'models/note.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notebook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 238, 241, 242)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 155, 194, 236),
      ),
      home: const NotebookPage(),
    );
  }
}

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  int _currentIndex = 0; // 0=灵感, 1=阅读, 2=知识, 3=图书馆, 4=创作, 5=回顾

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云脑计划'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '关于',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: '云脑计划',
                applicationVersion: 'v1.0.0',
                applicationLegalese: '© 2026 三少爷',
                children: const [
                  Text('一个稳定智慧的外脑。'),
                ],
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          InspirationPage(),
          ReadingPage(),
          KnowledgePage(),
          LibraryPage(),     // ✅ 独立标签
          CreationPage(),
          ReviewPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: '灵感',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '阅读',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: '知识',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: '图书馆',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: '创作',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.autorenew),
            label: '回顾',
          ),
        ],
      ),
    );
  }
}