import 'package:flutter/material.dart';
import '../models/book.dart';
import '../screens/add_book_screen.dart';
import '../screens/edit_reading_plan_screen.dart';
import 'dart:io';
import '../screens/author_books_screen.dart';
import '../screens/series_detail_screen.dart';

class BookDetailSheet extends StatelessWidget {
  final Book book;
  final VoidCallback onUpdated;

  const BookDetailSheet({super.key, required this.book, required this.onUpdated});

  void _markAsFinished(BuildContext context) {
    book.status = BookStatus.finished;
    book.wasRead = true;
    // Pokud má kniha kapitoly, posuň se na konec
    if (book.totalChapters > 0) {
      book.currentChapter = book.totalChapters;
    } else if (book.totalPages > 0) {
      book.currentChapter = book.totalPages;
    }

    book.save();
    onUpdated();
    Navigator.of(context).pop();
  }


  void _editBook(BuildContext context) async {
    final updatedBook = await Navigator.push<Book>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBookScreen(existingBook: book),
      ),
    );
    if (updatedBook != null) {
      updatedBook.currentChapter = book.currentChapter;
      updatedBook.dailyGoal = book.dailyGoal;
      updatedBook.targetDate = book.targetDate;
      updatedBook.status = book.status;
      updatedBook.save();
      onUpdated();
      Navigator.of(context).pop();
    }
  }

  void _editReadingPlan(BuildContext context) async {
    // U přečtených knih nastavíme status a kapitolu znovu
    if (book.status == BookStatus.finished) {
      book.currentChapter = 0;
      book.status = BookStatus.reading;
    }

    final updatedBook = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => EditReadingPlanScreen(book: book)),
    );

    if (updatedBook != null) {
      onUpdated();
      Navigator.of(context).pop();
    }
  }

  void _deleteBook(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Smazat knihu"),
        content: const Text("Opravdu chcete tuto knihu smazat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Ne"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Ano"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      book.delete();
      onUpdated();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(book.title, style: Theme.of(context).textTheme.titleLarge),
                            ),
                            if (book.seriesName != null && book.seriesIndex != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SeriesDetailScreen(seriesName: book.seriesName!),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${book.seriesName!}: ${book.seriesIndex}. díl',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AuthorBooksScreen(authorName: book.author),
                              ),
                            );
                          },
                          child: Text(
                            book.author,
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Obálka (pokud existuje)
                  if (book.coverImagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(book.coverImagePath!),
                          width: 70,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  // Tlačítka
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: "Upravit",
                        onPressed: () => _editBook(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: "Smazat",
                        onPressed: () => _deleteBook(context),
                      ),
                    ],
                  ),
                ],
              ),

              if (book.genre.isNotEmpty) ...[
                Text("Žánr: ${book.genre}", style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              Text("Popis:"),
              Text(book.description),
              const SizedBox(height: 12),
              Text("Celkem kapitol: ${book.totalChapters}"),
              Text("Celkem stránek: ${book.totalPages}"),
              if (book.readingMode != null)
                Text(
                  "Režim čtení: ${book.readingMode == ReadingMode.chapters ? "Kapitoly" : "Stránky"}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (book.startPage != null)
              Text("Začíná na straně: ${book.startPage}"),

              const SizedBox(height: 8),
              if (book.status == BookStatus.reading || book.status == BookStatus.planned) ...[
                Text(
                  "Progres: ${book.readingMode == ReadingMode.pages && book.totalPages > 0 
                    ? ((book.currentChapter / book.totalChapters * book.totalPages).clamp(0, book.totalPages).round())
                    : book.currentChapter} / ${book.readingMode == ReadingMode.pages ? book.totalPages : book.totalChapters} ${book.readingMode == ReadingMode.pages ? "stránek" : "kapitol"}",
                ),
                Text("Denní cíl: ${book.calculatedDailyGoalChapters} kapitol / ${book.calculatedDailyGoalPages} stránek"),
                if (book.targetDate != null)
                  Text("Dokončit do: ${book.targetDate!.toLocal().toString().split(' ')[0]}")
                else if (book.estimatedEndDate != null)
                  Text("Odhadované dokončení: ${book.estimatedEndDate!.toLocal().toString().split(' ')[0]}"),
                if (book.startDate != null)
                  Text("Začít číst: ${formatStartDate(book.startDate!)}"),
              ],

              const SizedBox(height: 16),

              if (book.status == BookStatus.reading || book.status == BookStatus.planned)
                ElevatedButton.icon(
                  onPressed: () => _markAsFinished(context),
                  icon: const Icon(Icons.check),
                  label: const Text("Označit jako přečtené"),
                ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: () => _editReadingPlan(context),
                icon: const Icon(Icons.schedule),
                label: Text(
                  book.status == BookStatus.finished
                      ? "Znovu číst"
                      : book.status == BookStatus.planned
                          ? "Naplánovat čtení"
                          : "Upravit plán čtení",
                ),
              ),
            ],
          ),
        );
      },
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
