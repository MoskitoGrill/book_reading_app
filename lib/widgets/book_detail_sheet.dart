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

  void _showChaptersDialog(BuildContext context) {
    if (book.chapterNames == null || book.chapterNames!.isEmpty) {
      return; // když nejsou žádné názvy kapitol
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Seznam kapitol"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: book.chapterNames!.length,
            itemBuilder: (context, index) {
              final name = book.chapterNames![index];

              if (book.chapterEndPages != null && book.chapterEndPages!.length > index) {
                final startPage = (index == 0)
                    ? (book.startPage ?? 1)
                    : book.chapterEndPages![index - 1] + 1;
                final endPage = book.chapterEndPages![index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kapitola ${index + 1}: $name",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Začíná na straně $startPage a končí na straně $endPage",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              } else {
                // 🟢 Jen názvy (bez stránek)
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    "Kapitola ${index + 1}: $name",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Zavřít"),
          ),
        ],
      ),
    );
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
                  // ====== LEVÁ STRANA - TEXTY ======
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book.seriesName != null && book.seriesIndex != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SeriesDetailScreen(
                                      seriesName: book.seriesName!,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${book.seriesName!}: ${book.seriesIndex}. díl',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Název knihy
                        Text(
                          book.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Autoři 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: book.authorList.map((a) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AuthorBooksScreen(authorName: a),
                                  ),
                                );
                              },
                              child: Text(
                                a,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        // Žánr
                        if (book.genre.isNotEmpty)
                          Text(
                            "Žánr: ${book.genre}",
                            style:
                                const TextStyle(fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),

                  // ====== PRAVÁ STRANA - OBÁLKA + TLAČÍTKA ======
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (book.coverImagePath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(book.coverImagePath!),
                                width: 140, 
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 8),
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
                              IconButton(
                                icon: const Icon(Icons.schedule),
                                tooltip: "Plán čtení",
                                onPressed: () => _editReadingPlan(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                ],
              ),

              const SizedBox(height: 16),

              // Popis a základní info
              Text("Popis:"),
              Text(book.description),
              const SizedBox(height: 12),

              // Celkem kapitol (klikací)
              GestureDetector(
                onTap: () => _showChaptersDialog(context),
                child: Text(
                  "Celkem kapitol: ${book.totalChapters}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Celkem stránek
              Text(
                "Celkem stránek: ${book.totalPages}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // Začíná na straně
              if (book.startPage != null)
                Text(
                  "Začíná na straně: ${book.startPage}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

              const SizedBox(height: 16),

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
