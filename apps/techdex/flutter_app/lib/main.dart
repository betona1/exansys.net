import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'dex_screen.dart';

void main() => runApp(const TechDexApp());

// EXANSYS 브랜드 색
const green = Color(0xFF0E5741);
const greenDeep = Color(0xFF0B3F30);
const lime = Color(0xFF9BE15D);
const paper = Color(0xFFF6F7FA);
const ink = Color(0xFF12141C);

class TechDexApp extends StatelessWidget {
  const TechDexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechDex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
        scaffoldBackgroundColor: paper,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [QuizScreen(), DexScreen()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('✦', style: TextStyle(color: greenDeep, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Text('TechDex', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports),
              label: '퀴즈'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '도감'),
        ],
      ),
    );
  }
}
