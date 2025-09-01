import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import 'add_book_screen.dart';
import '../widgets/book_card.dart';
import 'streak_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
  }

  // ✅ Tady je funkce správně
  int calculateGlobalStreak(List<Book> books) {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 1000; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final anyBookReadToday = books.any((book) =>
        book.readingDates.any((d) =>
          d.year == day.year && d.month == day.month && d.day == day.day));

      if (anyBookReadToday) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Book>('books').listenable(),
      builder: (context, Box<Book> box, _) {
        final now = DateTime.now();
        final allBooks = box.values.toList();
        final allKeys = box.keys.cast<dynamic>().toList();

        final List<MapEntry<dynamic, Book>> books = [];
        for (int i = 0; i < allBooks.length; i++) {
          final book = allBooks[i];
          final key = allKeys[i];
          if (book.status == BookStatus.reading ||
              (book.status == BookStatus.finished &&
               book.finishedAt != null &&
               now.difference(book.finishedAt!).inHours < 24)) {
            books.add(MapEntry(key, book));
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Moje čtení'),
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StreakCalendarScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${calculateGlobalStreak(allBooks)} dní',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          body: books.isEmpty
              ? const Center(child: Text('Zatím nemáš žádné knihy'))
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index].value;
                    final key = books[index].key;
                    final isRecentlyFinished = book.status == BookStatus.finished &&
                        book.finishedAt != null &&
                        now.difference(book.finishedAt!).inHours < 24;

                    return Column(
                      children: [
                        if (isRecentlyFinished)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              "🎉 Gratulujeme, kniha je přečtená!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        BookCard(
                          bookKey: key,
                          onChanged: () {},
                        ),
                      ],
                    );
                  },
                ),

          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final newBook = await Navigator.push<Book>(
                context,
                MaterialPageRoute(builder: (_) => const AddBookScreen()),
              );
              if (newBook != null) {
                box.add(newBook);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
