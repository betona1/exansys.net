import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'crossword_screen.dart';
import 'dex_screen.dart';
import 'sfx.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Sfx.init(); // 효과음 미리 로드
  runApp(const TechDexApp());
}

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
    const pages = [QuizScreen(), CrosswordScreen(), DexScreen()];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset('assets/icon/icon.png', width: 30, height: 30),
            ),
            const SizedBox(width: 9),
            const Text('TechDex', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
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
              icon: Icon(Icons.grid_on_outlined), selectedIcon: Icon(Icons.grid_on), label: '십자풀이'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '도감'),
        ],
      ),
    );
  }
}
