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
    _refreshState();
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

  int chapterFromPage(int page) {
    // 1) Mám přesné konce kapitol -> najdu první chapterEndPage >= page
    if (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty) {
      for (int i = 0; i < book.chapterEndPages!.length; i++) {
        if (page <= book.chapterEndPages![i]) return i;
      }
      return book.chapterEndPages!.length - 1;
    }

    // 2) Nemám přesné konce, ale mám počty -> odhad podle průměru stránek na kapitolu
    if (book.totalChapters > 0 && book.totalPages > 0 && book.startPage != null) {
      final pagesPerChapter = (book.effectivePageCount / book.totalChapters).ceil();
      return ((page - book.startPage!) / pagesPerChapter)
          .floor()
          .clamp(0, book.totalChapters - 1);
    }

    // 3) Fallback
    return _currentChapter;
  }

  /// Aktualizace po změně STRÁNKY (slider jede po stránkách)
  /// - v režimu PAGES sčítáme stránky
  /// - v režimu CHAPTERS jen přepočítáme kapitolu z aktuální stránky
  /// - zápis do readingHistory je VŽDY v jednotkách denního cíle:
  ///   PAGES -> stránky, CHAPTERS -> kapitoly (viz _updateProgressByChapter)
  void _updateProgress(int newPage) {
    final prevPage = _currentPage;
    final prevChapter = book.currentChapter;
    final newChap = chapterFromPage(newPage);

    setState(() {
      _currentPage = newPage;
      _currentChapter = newChap;
      book.lastPage = newPage;
      book.currentChapter = newChap;

      final today = DateTime.now();
      final dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      book.readingHistory ??= {};

      if (book.readingMode == ReadingMode.pages) {
        // ➕/➖ delta stránek
        final deltaPages = newPage - prevPage;
        if (deltaPages != 0) {
          book.readingHistory![dateKey] =
              (book.readingHistory![dateKey] ?? 0) + deltaPages;
        }
      } else {
        // Režim KAPITOL: počítej delta kapitol dle přepočtu z aktuální stránky
        final deltaCh = newChap - prevChapter;
        if (deltaCh != 0) {
          book.readingHistory![dateKey] =
              (book.readingHistory![dateKey] ?? 0) + deltaCh;
        }
      }

      // ✅ Dopočti, jestli pro dnešek něco zbývá
      final totalToday = book.readingHistory![dateKey] ?? 0;

      if (totalToday <= 0) {
        // nic/nebo čistý návrat zpět -> vymaž záznam dne
        book.readingHistory!.remove(dateKey);
        book.readingDates.removeWhere((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day);
      } else {
        // něco přečteno -> zajisti den v readingDates
        if (!book.readingDates.any((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day)) {
          book.readingDates.add(DateTime(today.year, today.month, today.day));
        }
      }

      book.save();
    });

    widget.onChanged();
  }

  /// Aktualizace po změně KAPITOLY (slider jede po kapitolách)
  /// - v režimu KAPITOL sčítáme kapitoly
  void _updateProgressByChapter(int newChapter) {
    final prevChapter = _currentChapter;
    if (newChapter < 0 || newChapter == prevChapter) return;

    setState(() {
      _currentChapter = newChapter;
      book.currentChapter = newChapter;

      final today = DateTime.now();
      final dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      book.readingHistory ??= {};

      final deltaCh = newChapter - prevChapter;
      if (deltaCh != 0) {
        book.readingHistory![dateKey] =
            (book.readingHistory![dateKey] ?? 0) + deltaCh;
      }

      final totalToday = book.readingHistory![dateKey] ?? 0;
      if (totalToday <= 0) {
        book.readingHistory!.remove(dateKey);
        book.readingDates.removeWhere((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day);
      } else {
        if (!book.readingDates.any((d) =>
            d.year == today.year && d.month == today.month && d.day == today.day)) {
          book.readingDates.add(DateTime(today.year, today.month, today.day));
        }
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
          content: Text(
              "Chceš pokračovat čtením dalšího dílu série:\n„${nextBook!.title}“?"),
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
                Navigator.of(context).pop();

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
    final maxPages = book.totalPages;
    final maxChapters = book.totalChapters;

    if (book.readingMode == ReadingMode.pages) {
      final daily = book.calculatedDailyGoalPages;
      final newPage = (_currentPage + daily);
      _updateProgress(newPage >= maxPages ? maxPages : newPage);
    } else {
      final dailyChapters =
          book.calculatedDailyGoalChapters > 0 ? book.calculatedDailyGoalChapters : 1;

      if (book.chapterEndPages == null || book.startPage == null) {
        final newChapter = (_currentChapter + dailyChapters);
        _updateProgressByChapter(newChapter >= maxChapters ? maxChapters : newChapter);
      } else {
        int currentIndex = chapterFromPage(_currentPage);
        bool atChapterEnd = _currentPage == book.chapterEndPages![currentIndex];

        int targetChapterIndex;
        if (atChapterEnd) {
          targetChapterIndex = (currentIndex + dailyChapters).clamp(0, maxChapters - 1);
        } else {
          targetChapterIndex = (currentIndex + dailyChapters - 1).clamp(0, maxChapters - 1);
        }

        if (targetChapterIndex >= maxChapters - 1) {
          _updateProgress(maxPages);
        } else {
          int endPage = book.chapterEndPages![targetChapterIndex];
          _updateProgress(endPage);
        }
      }
    }
  }

  Widget _buildMiniCalendar(Book book) {
    final now = DateTime.now();
    final start = book.startDate != null
        ? DateTime(book.startDate!.year, book.startDate!.month, book.startDate!.day)
        : null;

    final today = DateTime(now.year, now.month, now.day);
    final history = book.readingHistory ?? {};

    if (start != null && start.isAfter(today)) {
      return const SizedBox.shrink();
    }

    final daysSinceStart = start != null ? today.difference(start).inDays + 1 : 7;
    final visibleDays = daysSinceStart.clamp(1, 7);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(visibleDays, (index) {
        final date = today.subtract(Duration(days: visibleDays - 1 - index));
        final key =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final read = history[key] ?? 0;

        final goal = book.readingMode == ReadingMode.pages
            ? book.calculatedDailyGoalPages
            : book.calculatedDailyGoalChapters;

        Color color;
        IconData icon;

        if (read <= 0) {
          color = Colors.red;
          icon = Icons.close;
        } else if (goal > 0 && read < goal) {
          color = Colors.orange;
          icon = Icons.remove;
        } else {
          color = Colors.green;
          icon = Icons.check;
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
                // Název + autor + kapitoly
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      if (book.chapterNames != null && book.chapterNames!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Kapitola ${_currentChapter + 1}: ${book.chapterNames![_currentChapter]}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (_currentChapter + 1 < book.chapterNames!.length)
                          Text(
                            "Následuje: ${book.chapterNames![_currentChapter + 1]}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Obálka
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
            Text(
              "Režim: ${book.readingMode == ReadingMode.pages ? 'Stránky' : 'Kapitoly'}",
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),

            // Denní cíl / plán do data
            Builder(
              builder: (context) {
                if (book.readingMode == ReadingMode.pages) {
                  if (book.targetDate != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dnes nutno přečíst ${book.adaptiveDailyGoalPages} stránek",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text("Plánované datum dokončení: ${formatStartDate(book.targetDate!)}"),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Denní cíl: ${book.adaptiveDailyGoalPages} stránek",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (book.estimatedEndDate != null)
                          Text("Datum dočtení: ${formatStartDate(book.estimatedEndDate!)}"),
                      ],
                    );
                  }
                } else {
                  int chapters = (book.targetDate != null
                          ? book.adaptiveDailyGoalChapters
                          : book.calculatedDailyGoalChapters)
                      .clamp(1, 1 << 30);
                  final pages = book.pagesForDailyGoalChapters(chapters);

                  if (book.targetDate != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dnes nutno přečíst $chapters kapitol, tedy $pages stránek",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text("Plánované datum dokončení: ${formatStartDate(book.targetDate!)}"),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Denní cíl: $chapters kapitol, tedy $pages stránek",
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (book.estimatedEndDate != null)
                          Text("Datum dočtení: ${formatStartDate(book.estimatedEndDate!)}"),
                      ],
                    );
                  }
                }
              },
            ),

            if (book.startDate != null)
              Text('Začít číst: ${formatStartDate(book.startDate!)}'),

            const SizedBox(height: 8),
            const Text("Aktivita za posledních 7 dní:"),
            const SizedBox(height: 4),
            _buildMiniCalendar(book),

            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                if (book.readingMode == ReadingMode.pages) {
                  return Text('Aktuální strana: $_currentPage / ${book.totalPages}');
                } else {
                  if (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty) {
                    final ch = chapterFromPage(_currentPage);
                    return Text(
                        'Aktuální kapitola: ${ch + 1} / ${book.totalChapters} a strana: $_currentPage / ${book.totalPages}');
                  } else {
                    return Text('Aktuální kapitola: $_currentChapter / ${book.totalChapters}');
                  }
                }
              },
            ),

            Slider(
              value: (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty
                      ? _currentPage.clamp(book.safeStartPage, book.totalPages)
                      : (book.readingMode == ReadingMode.pages
                          ? _currentPage.clamp(book.startPage ?? 1, book.totalPages)
                          : _currentChapter.clamp(0, book.totalChapters)))
                  .toDouble(),
              min: (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty)
                  ? book.safeStartPage.toDouble()
                  : (book.readingMode == ReadingMode.pages
                      ? (book.startPage ?? 1).toDouble()
                      : 0.0),
              max: (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty)
                  ? book.totalPages.toDouble()
                  : (book.readingMode == ReadingMode.pages
                      ? book.totalPages.toDouble()
                      : book.totalChapters.toDouble()),
              divisions: (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty)
                  ? (book.totalPages - book.safeStartPage + 1)
                  : (book.readingMode == ReadingMode.pages
                      ? (book.totalPages - (book.startPage ?? 1) + 1).clamp(1, book.totalPages)
                      : book.totalChapters.clamp(1, book.totalChapters)),
              label: (book.chapterEndPages != null && book.chapterEndPages!.isNotEmpty)
                  ? _currentPage.toString()
                  : (book.readingMode == ReadingMode.pages
                      ? _currentPage.toString()
                      : _currentChapter.toString()),
              onChanged: (value) {
                if (book.readingMode == ReadingMode.chapters &&
                    (book.chapterEndPages == null || book.startPage == null)) {
                  _updateProgressByChapter(value.toInt());
                } else {
                  _updateProgress(value.toInt());
                }
              },
            ),

            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: (_currentPage >= book.totalPages && _currentChapter >= book.totalChapters)
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
  final d = DateTime(date.year, date.month, date.day);

  if (d == today) {
    return 'Dnes';
  } else if (d == today.add(const Duration(days: 1))) {
    return 'Zítra';
  } else {
    return '${d.day.toString().padLeft(2, '0')}. ${d.month.toString().padLeft(2, '0')}. ${d.year}';
  }
}
