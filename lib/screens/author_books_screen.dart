import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/book.dart';
import '../widgets/book_detail_sheet.dart';

class AuthorBooksScreen extends StatelessWidget {
  final String authorName;

  const AuthorBooksScreen({super.key, required this.authorName});

  @override
  Widget build(BuildContext context) {
    final bookBox = Hive.box<Book>('books');
    final authorBooks = bookBox.values
        .where((book) => book.author.toLowerCase() == authorName.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(authorName)),
      body: ListView.builder(
        itemCount: authorBooks.length,
        itemBuilder: (context, index) {
          final book = authorBooks[index];
          return ListTile(
            title: Text(book.title),
            subtitle: Text(book.author),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => BookDetailSheet(
                  book: book,
                  onUpdated: () => Navigator.pop(context),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
