import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import '../widgets/book_detail_sheet.dart';
import 'wishlist_screen.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'series_detail_screen.dart';
import 'add_book_screen.dart';

enum BookFilter { all, reading, planned, finished }
enum BookSort { alphabetical, recent }

String normalize(String text) {
  const diacriticsMap = {
    'á': 'a', 'ä': 'a', 'â': 'a', 'à': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
    'č': 'c', 'ć': 'c',
    'ď': 'd',
    'é': 'e', 'ě': 'e', 'ë': 'e', 'è': 'e', 'ê': 'e', 'ē': 'e',
    'í': 'i', 'ï': 'i', 'î': 'i', 'ì': 'i', 'ī': 'i',
    'ľ': 'l', 'ĺ': 'l', 'ł': 'l',
    'ň': 'n', 'ń': 'n',
    'ó': 'o', 'ö': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o',
    'ř': 'r',
    'š': 's', 'ś': 's', 'ș': 's',
    'ť': 't', 'ț': 't',
    'ú': 'u', 'ů': 'u', 'ü': 'u', 'ù': 'u', 'û': 'u', 'ū': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ž': 'z', 'ź': 'z', 'ż': 'z',
    'Á': 'a', 'Ä': 'a', 'Â': 'a', 'À': 'a', 'Ã': 'a', 'Å': 'a', 'Ā': 'a',
    'Č': 'c', 'Ć': 'c',
    'Ď': 'd',
    'É': 'e', 'Ě': 'e', 'Ë': 'e', 'È': 'e', 'Ê': 'e', 'Ē': 'e',
    'Í': 'i', 'Ï': 'i', 'Î': 'i', 'Ì': 'i', 'Ī': 'i',
    'Ľ': 'l', 'Ĺ': 'l', 'Ł': 'l',
    'Ň': 'n', 'Ń': 'n',
    'Ó': 'o', 'Ö': 'o', 'Ò': 'o', 'Ô': 'o', 'Õ': 'o', 'Ø': 'o', 'Ō': 'o',
    'Ř': 'r',
    'Š': 's', 'Ś': 's', 'Ș': 's',
    'Ť': 't', 'Ț': 't',
    'Ú': 'u', 'Ů': 'u', 'Ü': 'u', 'Ù': 'u', 'Û': 'u', 'Ū': 'u',
    'Ý': 'y', 'Ÿ': 'y',
    'Ž': 'z', 'Ź': 'z', 'Ż': 'z',
  };

  return text
      .split('')
      .map((char) => diacriticsMap[char] ?? char)
      .join()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '');
}


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isGridView = false;
  late Box<Book> bookBox;
  BookFilter _selectedFilter = BookFilter.all;
  BookSort _selectedSort = BookSort.recent;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box<Book>('books');
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('isGridView');
    if (saved != null) {
      setState(() {
        _isGridView = saved;
      });
    }
  }

  void _openBookDetail(Book book) async {
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBookGridTile(Book book) {
    return GestureDetector(
      onTap: () => _openBookDetail(book),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (book.coverImagePath != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.file(
                      File(book.coverImagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: const Icon(Icons.book, size: 40, color: Colors.white),
                  ),

                if (book.wasRead)
                  const Positioned(
                    bottom: 4,
                    right: 4,
                    child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (book.seriesName != null && book.seriesIndex != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeriesDetailScreen(seriesName: book.seriesName!),
                          ),
                        );
                      },
                      child: Text(
                        '${book.seriesIndex}. série ${book.seriesName!}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),

                  const SizedBox(height: 4),
                  Text(book.author, style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookTile(Book book) {
    Widget trailing;

    if (book.status == BookStatus.planned) {
      trailing = const Text("Naplánováno");
    } else if (book.status == BookStatus.finished) {
      trailing = const Icon(Icons.check, color: Colors.green);
    } else {
      // Rozečtené
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (book.wasRead)
            const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 4),
          Text("${book.progressPercent}%", style: const TextStyle(fontSize: 14)),
        ],
      );
    }

    return ListTile(
      leading: Icon(
        book.status == BookStatus.finished
            ? Icons.check_circle
            : book.status == BookStatus.planned
                ? Icons.hourglass_empty
                : Icons.menu_book,
        color: book.status == BookStatus.finished
            ? Colors.green
            : book.status == BookStatus.planned
                ? Colors.orange
                : Colors.blue,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.title),
        ],
      ),
      subtitle: Text(book.author),
      trailing: trailing,
      onTap: () => _openBookDetail(book),
    );
  }


  List<Book> _getBooks(BookStatus status) {
    final books = bookBox.values.where((b) => b.status == status).toList();
    return _sortBooks(books);
  }

  List<Book> _sortBooks(List<Book> books) {
    if (_selectedSort == BookSort.alphabetical) {
      books.sort((a, b) => normalize(a.title).compareTo(normalize(b.title)));
    } else {
      books.sort((a, b) => b.key.compareTo(a.key));
    }
    return books;
  }

  List<Book> _filteredBooks() {
    final allBooks = bookBox.values.toList();
    List<Book> filtered;

    switch (_selectedFilter) {
      case BookFilter.reading:
        filtered = allBooks.where((b) => b.status == BookStatus.reading).toList();
        break;
      case BookFilter.planned:
        filtered = allBooks.where((b) => b.status == BookStatus.planned).toList();
        break;
      case BookFilter.finished:
        filtered = allBooks.where((b) => b.status == BookStatus.finished).toList();
        break;
      case BookFilter.all:
      default:
        filtered = allBooks;
    }

    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = normalize(_searchQuery);
      filtered = filtered.where((b) =>
        normalize(b.title).contains(normalizedQuery) ||
        normalize(b.author).contains(normalizedQuery) ||
        normalize(b.genre ?? '').contains(normalizedQuery) ||
        normalize(b.seriesName ?? '').contains(normalizedQuery)
      ).toList();
    }

    return _sortBooks(filtered);
  }

  Widget _buildGridView(List<Book> books) {
    return GridView.count(
      shrinkWrap: true, // NEJDŮLEŽITĚJŠÍ pro vnořený GridView
      physics: const NeverScrollableScrollPhysics(), // Jinak scroll koliduje s ListView
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.66,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: books.map(_buildBookGridTile).toList(),
    );
  }

  List<Widget> _buildSection(String title, List<Book> books) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      if (books.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Žádné knihy', style: TextStyle(color: Colors.grey)),
        )
      else if (_isGridView)
        _buildGridView(books)
      else
        ...books.map(_buildBookTile),
    ];
  }

  List<Book> _filteredBooksFromBox(Box<Book> box) {
    final allBooks = box.values.toList();
    List<Book> filtered;

    switch (_selectedFilter) {
      case BookFilter.reading:
        filtered = allBooks.where((b) => b.status == BookStatus.reading).toList();
        break;
      case BookFilter.planned:
        filtered = allBooks.where((b) => b.status == BookStatus.planned).toList();
        break;
      case BookFilter.finished:
        filtered = allBooks.where((b) => b.status == BookStatus.finished).toList();
        break;
      case BookFilter.all:
      default:
        filtered = allBooks;
    }

    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = normalize(_searchQuery);
      filtered = filtered.where((b) =>
        normalize(b.title).contains(normalizedQuery) ||
        normalize(b.author).contains(normalizedQuery) ||
        normalize(b.genre ?? '').contains(normalizedQuery) ||
        normalize(b.seriesName ?? '').contains(normalizedQuery)
      ).toList();
    }

    return _sortBooks(filtered);
  }

  List<Book> _getBooksFromBox(Box<Book> box, BookStatus status) {
    final books = box.values.where((b) => b.status == status).toList();
    return _sortBooks(books);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Book>('books').listenable(),
      builder: (context, Box<Book> box, _) {
        final books = _filteredBooksFromBox(box);
        final readingBooks = _getBooksFromBox(box, BookStatus.reading);
        final plannedBooks = _getBooksFromBox(box, BookStatus.planned);
        final finishedBooks = _getBooksFromBox(box, BookStatus.finished);

        return Scaffold(
          appBar: AppBar(
            title: const Text("Knihovna"),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                tooltip: "Wishlist",
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Hledat knihu nebo autora',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SegmentedButton<BookFilter>(
                  showSelectedIcon: false, //
                  segments: const [
                    ButtonSegment(value: BookFilter.all, label: Text("Vše")),
                    ButtonSegment(value: BookFilter.reading, label: Text("Rozečtené")),
                    ButtonSegment(value: BookFilter.planned, label: Text("Nečtené")),
                    ButtonSegment(value: BookFilter.finished, label: Text("Přečtené")),
                  ],
                  selected: <BookFilter>{_selectedFilter},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedFilter = newSelection.first;
                    });
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<BookSort>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: BookSort.recent, label: Text("Poslední aktivita")),
                        ButtonSegment(value: BookSort.alphabetical, label: Text("Abecedně")),
                      ],
                      selected: <BookSort>{_selectedSort},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedSort = newSelection.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ToggleButtons(
                    isSelected: [_isGridView == false, _isGridView == true],
                    onPressed: (index) async {
                      final newValue = index == 1;
                      setState(() {
                        _isGridView = newValue;
                      });

                      final prefs = await SharedPreferences.getInstance();
                      prefs.setBool('isGridView', newValue);
                    },

                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                    children: const [
                      Icon(Icons.view_list), // seznam
                      Icon(Icons.grid_view), // mřížka
                    ],
                  ),
                ],
              ),
            ),

              Expanded(
                child: _searchQuery.isNotEmpty
                    ? (_filteredBooksFromBox(box).isEmpty
                        ? const Center(child: Text("Žádné výsledky"))
                        : (_isGridView
                            ? _buildGridView(_filteredBooksFromBox(box))
                            : ListView(children: _filteredBooksFromBox(box).map(_buildBookTile).toList())))
                    : (box.isEmpty
                        ? const Center(child: Text("Žádné knihy"))
                        : (_selectedFilter == BookFilter.all
                            ? ListView(
                                children: [
                                  ..._buildSection("Rozečtené knihy", readingBooks),
                                  ..._buildSection("Nečtené knihy", plannedBooks),
                                  ..._buildSection("Přečtené knihy", finishedBooks),
                                ],
                              )
                            : _isGridView
                                ? _buildGridView(books)
                                : ListView(children: books.map(_buildBookTile).toList()))),
              ),
            ],
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