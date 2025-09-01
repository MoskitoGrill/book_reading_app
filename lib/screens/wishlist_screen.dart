import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookBox = Hive.box<Book>('books');
    final wishlistBooks = bookBox.values.where((b) => b.status == BookStatus.planned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wishlist"),
      ),
      body: wishlistBooks.isEmpty
          ? const Center(child: Text("Žádné knihy ve wishlistu"))
          : ListView.builder(
              itemCount: wishlistBooks.length,
              itemBuilder: (context, index) {
                final book = wishlistBooks[index];
                return ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                );
              },
            ),
    );
  }
}
