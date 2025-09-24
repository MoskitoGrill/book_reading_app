import 'package:flutter/material.dart';
import '../models/book.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/edit_reading_plan_screen.dart';

class BookCard extends StatefulWidget {
  final VoidCallback onChanged;
  final dynamic bookKey;

  const BookCard({
    super.key,
    required this.bookKey,
    required this.onChanged,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}


class _BookCardState extends State<BookCard> {
  late int _currentChapter;
  late int _currentPage;
  Book get book => Hive.box<Book>('books').get(widget.bookKey)!;

  @override
  void initState() {
    super.initState();
    _currentChapter = book.currentChapter;
    _currentPage = book.currentPage;
  }

  @override
  void didUpdateWidget(covariant BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshState(); // načti nový stav z Hive
  }

void _refreshState() {
  final b = Hive.box<Book>('books').get(widget.bookKey);
  if (b != null) {
    setState(() {
      _currentChapter = b.currentChapter;
      _currentPage = b.currentPage;
    });
  }
}

  void _updateChapter(int newChapter) {

  print("Aktuální kapitola: ${book.currentChapter}, nová: $newChapter");

    final previousChapter = book.currentChapter;
    final delta = (newChapter - previousChapter);

    if (delta <= 0) return;

    setState(() {
      _currentChapter = newChapter;
      book.currentChapter = newChapter;
      _currentPage = book.currentPage;

      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      book.readingHistory ??= {};
      book.readingHistory![dateKey] =
          (book.readingHistory![dateKey] ?? 0) + delta;

      if (!book.readingDates.any((d) =>
          d.year == today.year && d.month == today.month && d.day == today.day)) {
        book.readingDates.add(DateTime(today.year, today.month, today.day));
      }

      if (_currentChapter >= book.totalChapters) {
        book.currentChapter = book.totalChapters;
        book.status = BookStatus.finished;
        book.finishedAt = DateTime.now();
        _askToContinueSeries(context, book);
      }

      book.save();
    });

    widget.onChanged(); 
  }

  void _askToContinueSeries(BuildContext context, Book? finishedBook) {
    if (finishedBook == null) return;

    final box = Hive.box<Book>('books');
    final booksInSeries = box.values
        .where((b) =>
            b.seriesName != null &&
            b.seriesName == finishedBook.seriesName &&
            b != finishedBook)
        .toList()
      ..sort((a, b) => (a.seriesIndex ?? 0).compareTo(b.seriesIndex ?? 0));

    Book? nextBook;
    try {
      nextBook = booksInSeries.firstWhere(
        (b) => (b.seriesIndex ?? 0) > (finishedBook.seriesIndex ?? 0),
      );
    } catch (_) {
      nextBook = null;
    }

    if (nextBook != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pokračovat v sérii?"),
          content: Text("Chceš pokračovat čtením dalšího dílu série:\n„${nextBook!.title}“?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Ne"),
            ),
            TextButton(
              onPressed: () {
              nextBook!.status = BookStatus.reading;
              nextBook.currentChapter = 0;
              nextBook.wasRead = false;
              nextBook.save();
              Navigator.of(context).pop(); // zavři dialog

              // Otevři plán čtení
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditReadingPlanScreen(book: nextBook!),
                ),
              );
            },

              child: const Text("Ano"),
            ),
          ],
        ),
      );
    }
  }

  void _completeDailyGoal() {
    //final book = this.book;

    final daily = book.readingMode == ReadingMode.pages
      ? book.calculatedDailyGoalPages
      : book.calculatedDailyGoalChapters;

  final max = book.readingMode == ReadingMode.pages
      ? book.totalPages
      : book.totalChapters;

  final newChapter = (_currentChapter + daily).clamp(0, max);
  _updateChapter(newChapter);

  widget.onChanged();
  }

  Widget _buildMiniCalendar(Book book) {
    final now = DateTime.now();
    final start = book.startDate != null
        ? DateTime(book.startDate!.year, book.startDate!.month, book.startDate!.day)
        : null;

    final today = DateTime(now.year, now.month, now.day);
    final history = book.readingHistory ?? {};

    // Pokud je startDate v budoucnu, mini kalendář neukazuj
    if (start != null && start.isAfter(today)) {
      return const SizedBox.shrink();
    }

    final daysSinceStart = start != null
        ? today.difference(start).inDays + 1
        : 7;

    final visibleDays = daysSinceStart.clamp(1, 7);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(visibleDays, (index) {
        final date = today.subtract(Duration(days: visibleDays - 1 - index));
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final read = history[key] ?? 0;

        Color color;
        IconData icon;

        if (read >= (book.readingMode == ReadingMode.pages
            ? book.calculatedDailyGoalPages
            : book.calculatedDailyGoalChapters)) {
          color = Colors.green;
          icon = Icons.check;
        } else if (read > 0) {
          color = Colors.orange;
          icon = Icons.remove;
        } else {
          color = Colors.red;
          icon = Icons.close;
        }

        return CircleAvatar(
          radius: 12,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 16),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = this.book;
    int chapterFromPage(int page) {
      if (book.chapterEndPages != null && book.startPage != null) {
        for (int i = 0; i < book.chapterEndPages!.length; i++) {
          if (page <= book.chapterEndPages![i]) return i;
        }
        return book.chapterEndPages!.length - 1;
      }

      if (book.totalChapters > 0 && book.totalPages > 0 && book.startPage != null) {
        final pagesPerChapter = (book.effectivePageCount / book.totalChapters).ceil();
        return ((page - book.startPage!) / pagesPerChapter).floor().clamp(0, book.totalChapters - 1);
      }

      return _currentChapter;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖊 Název + autor
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 🖼 Obálka (pokud existuje)
                if (book.coverImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(book.coverImagePath!),
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
              ],
            ),

            const SizedBox(height: 12),           
            const SizedBox(height: 8),
            Text(
              book.readingMode == ReadingMode.pages
                  ? 'Denní cíl: ${book.calculatedDailyGoalPages} stránek'
                  : 'Denní cíl: ${book.calculatedDailyGoalChapters} kapitol',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Režim čtení: ${book.readingMode == ReadingMode.pages ? 'Stránky' : 'Kapitoly'}',
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),

            if (book.targetDate != null)
              Text('Dokončit do: ${book.targetDate!.toLocal().toString().split(' ')[0]}')
            else if (book.dailyGoal != null && book.dailyGoal! > 0 && book.estimatedEndDate != null)
              Text('Odhadované dokončení: ${book.estimatedEndDate!.toLocal().toString().split(' ')[0]}'),

            if (book.startDate != null)
              Text('Začít číst: ${formatStartDate(book.startDate!)}'),

            const SizedBox(height: 8),
            Text("Aktivita za posledních 7 dní:"),
            const SizedBox(height: 4),
            _buildMiniCalendar(book),

            const SizedBox(height: 16),
            Text(
              book.readingMode == ReadingMode.pages
                  ? 'Aktuální strana: $_currentPage / ${book.totalPages}'
                  : 'Aktuální kapitola: $_currentChapter / ${book.totalChapters}'
            ),

            Slider(
              value: (book.readingMode == ReadingMode.pages
                  ? _currentPage.clamp(book.startPage ?? 1, book.totalPages)
                  : _currentChapter.clamp(0, book.totalChapters)
              ).toDouble(),
              min: (book.readingMode == ReadingMode.pages ? (book.startPage ?? 1) : 0).toDouble(),
              max: (book.readingMode == ReadingMode.pages ? book.totalPages : book.totalChapters).toDouble(),
              divisions: book.readingMode == ReadingMode.pages
                ? (book.totalPages - (book.startPage ?? 1)).clamp(1, book.totalPages)
                : book.totalChapters.clamp(1, book.totalChapters),

              label: (book.readingMode == ReadingMode.pages ? _currentPage : _currentChapter).toString(),
              onChanged: (value) {
                setState(() {
                  if (book.readingMode == ReadingMode.pages) {
                    final chapter = chapterFromPage(value.toInt());
                    _updateChapter(chapter);
                    _currentPage = value.toInt();
                  } else {
                    _updateChapter(value.toInt());
                  }
                });
              }, // ✅ správně uzavřeno
            ),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: (book.readingMode == ReadingMode.pages && _currentPage >= book.totalPages) ||
                      (book.readingMode == ReadingMode.chapters && _currentChapter >= book.totalChapters)
                ? null
                : _completeDailyGoal,
              icon: const Icon(Icons.check_circle),
              label: const Text("Splnil jsem denní cíl"),
            ),
          ],
        ),
      ),
    );
  }
}
String formatStartDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(date.year, date.month, date.day);

  if (start == today) {
    return 'Dnes';
  } else if (start == today.add(const Duration(days: 1))) {
    return 'Zítra';
  } else {
    return '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}';
  }
}
