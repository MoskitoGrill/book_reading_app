import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import '../widgets/book_detail_sheet.dart';

class SeriesDetailScreen extends StatefulWidget {
  final String seriesName;

  const SeriesDetailScreen({super.key, required this.seriesName});

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  late List<Book> booksInSeries;

  @override
  void initState() {
    super.initState();
    final bookBox = Hive.box<Book>('books');
    booksInSeries = bookBox.values
        .where((b) => b.seriesName == widget.seriesName)
        .toList()
      ..sort((a, b) => (a.seriesIndex ?? 0).compareTo(b.seriesIndex ?? 0));
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final book = booksInSeries.removeAt(oldIndex);
    booksInSeries.insert(newIndex, book);

    // Aktualizuj indexy a ulož změny
    for (int i = 0; i < booksInSeries.length; i++) {
      booksInSeries[i].seriesIndex = i + 1;
      await booksInSeries[i].save();
    }

    setState(() {}); // Obnov UI
  }

  void _openBookDetail(BuildContext context, Book book) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookDetailSheet(
        book: book,
        onUpdated: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Série: ${widget.seriesName}')),
      body: booksInSeries.isEmpty
          ? const Center(child: Text('Žádné knihy v této sérii'))
          : ReorderableListView(
              onReorder: _onReorder,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (int i = 0; i < booksInSeries.length; i++)
                  ReorderableDelayedDragStartListener(
                    key: ValueKey(booksInSeries[i].key),
                    index: i,
                    child: ListTile(
                      leading: booksInSeries[i].coverImagePath != null
                          ? Image.file(
                              File(booksInSeries[i].coverImagePath!),
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.book),
                      title: Text(booksInSeries[i].title),
                      subtitle: Text('Pořadí: ${booksInSeries[i].seriesIndex ?? i + 1}'),
                      onTap: () => _openBookDetail(context, booksInSeries[i]),
                    ),
                  ),
              ],
            ),
    );
  }
}
