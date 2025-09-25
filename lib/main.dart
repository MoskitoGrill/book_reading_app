import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/book.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(BookStatusAdapter());
  Hive.registerAdapter(BookAdapter());
  Hive.registerAdapter(ReadingModeAdapter()); // <- přidej

  // Otevřít box a uložit do proměnné
  await Hive.openBox<Book>('books');

  // ✅ Smazat všechna data (pouze při testování!)
  // await box.clear();

  runApp(const BookReadingApp());
}


class BookReadingApp extends StatelessWidget {
  const BookReadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Reading App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 216, 194)),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LibraryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),

      bottomNavigationBar: NavigationBar(
        key: ValueKey(_selectedIndex), 
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        indicatorColor: const Color.fromARGB(255, 13, 226, 205),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Domů',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Knihovna',
          ),
        ],
      ),
    );
  }
}
