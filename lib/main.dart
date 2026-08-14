import 'package:flutter/material.dart';
import 'database_service.dart';
import 'pages/collection_page.dart';
import 'pages/wisdom_page.dart';
import 'pages/insight_page.dart';
import 'pages/creation_page.dart';
import 'pages/profile_page.dart';
import 'models/note.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云脑计划',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 238, 241, 242),
        ),
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
  int _currentIndex = 0;

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
  children: <Widget>[
    const CollectionPage(),
    const WisdomPage(),
    const InsightPage(),
    const CreationPage(),
    const ProfilePage(),
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
            icon: Icon(Icons.cloud_upload_outlined),
            label: '采集',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: '智库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: '洞察',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: '创作',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }
}