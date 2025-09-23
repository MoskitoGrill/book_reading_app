
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import '../models/book.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'chapter_page_assignment_screen.dart';
import 'chapter_rename_screen.dart';
import 'package:hive/hive.dart';

enum GoalMode { dailyGoal, targetDate }

class AddBookScreen extends StatefulWidget {
  final Book? existingBook;

  const AddBookScreen({super.key, this.existingBook});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _genreController;
  late TextEditingController _seriesNameController;
  int _seriesIndex = 1;
  List<String> _availableSeries = [];
  late int _chapterCount;
  late int _pageCount;
  File? _coverImage;
  bool _chaptersEnabled = true;
  bool _pagesEnabled = false;
  late bool _chaptersToggleLocked;
  late bool _pagesToggleLocked;
  int _startPage = 1;
  bool _customStartPageEnabled = false;

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Z galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotoaparát'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024);
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(picked.path);
        final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');

        setState(() {
          _coverImage = savedImage;
        });
      }
    }
  }

  int? _dailyGoal;
  DateTime? _targetDate;
  DateTime? _startDate;
  late GoalMode _goalMode;
  bool _planningEnabled = false;
  late ReadingMode _readingMode;
  List<int>? _chapterEndPages;
  List<String>? _chapterNames;

  @override
  void initState() {
    super.initState();
    final book = widget.existingBook;
    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _descriptionController = TextEditingController(text: book?.description ?? '');
    _genreController = TextEditingController(text: book?.genre ?? '');
    _chapterCount = (book?.totalChapters ?? 0);
    if (_chapterCount <= 0) _chapterCount = 10;
    _pageCount = (book?.totalPages ?? 0);
    if (_pageCount <= 0) _pageCount = 100;
    _dailyGoal = book?.dailyGoal ?? 1;
    _targetDate = book?.targetDate;
    _goalMode = book?.targetDate != null ? GoalMode.targetDate : GoalMode.dailyGoal;
    _planningEnabled = book?.targetDate != null || book?.dailyGoal != null;
    _startDate = DateTime.now();
    _chaptersEnabled = (book?.totalChapters ?? 0) > 0;
    _pagesEnabled = (book?.totalPages ?? 0) > 0;
    _chaptersToggleLocked = _chaptersEnabled;
    _pagesToggleLocked = _pagesEnabled;
    _chapterEndPages = widget.existingBook?.chapterEndPages;
    _chapterNames = widget.existingBook?.chapterNames;
    _startPage = widget.existingBook?.startPage ?? 1;
    _customStartPageEnabled = widget.existingBook?.startPage != null;
    _readingMode = book?.readingMode ?? ReadingMode.chapters;
    _seriesNameController = TextEditingController(text: widget.existingBook?.seriesName ?? '');
    final currentSeriesName = _seriesNameController.text.trim();
    if (currentSeriesName.isNotEmpty) {
      final books = Hive.box<Book>('books')
          .values
          .where((b) => b.seriesName == currentSeriesName)
          .toList();
      _seriesIndex = books.length + 1;
    }

    _seriesIndex = widget.existingBook?.seriesIndex ?? 1;
    _availableSeries = Hive.box<Book>('books')
      .values
      .map((b) => b.seriesName)
      .whereType<String>()
      .toSet() // odstraní duplicity
      .toList()
      ..sort(); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _genreController.dispose();
    _seriesNameController.dispose();
    super.dispose();
  }

  void _pickTargetDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() => _targetDate = selected);
    }
  }

  void _pickStartDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }
  
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 1200);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = p.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
      setState(() => _coverImage = savedImage);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final description = _descriptionController.text.trim();
    final chapters = _chaptersEnabled ? (_chapterCount < 1 ? 1 : _chapterCount) : 0;
    final pages = _pagesEnabled ? (_pageCount < 1 ? 1 : _pageCount) : 0;

    if (title.isEmpty || (!_chaptersEnabled && !_pagesEnabled)) return;

    if (widget.existingBook != null) {
      // 🟢 ÚPRAVA EXISTUJÍCÍ KNIHY
      final book = widget.existingBook!;
      book.title = title;
      book.author = author;
      book.description = description;
      book.totalChapters = _chaptersEnabled ? _chapterCount : 0;
      book.totalPages = _pagesEnabled ? _pageCount : 0;
      book.dailyGoal = _planningEnabled && _goalMode == GoalMode.dailyGoal ? _dailyGoal : null;
      book.targetDate = _planningEnabled && _goalMode == GoalMode.targetDate ? _targetDate : null;
      book.genre = _genreController.text.trim(); 
      book.startDate = _planningEnabled ? _startDate : null;
      book.coverImagePath = _coverImage?.path;
      book.chapterEndPages = _chapterEndPages;
      book.chapterNames = _chapterNames;
      book.startPage = _customStartPageEnabled ? _startPage : null;
      book.readingMode = _readingMode;
      book.seriesName = _seriesNameController.text.trim().isEmpty ? null : _seriesNameController.text.trim();
      if (book.seriesName != null) {
        final allBooks = Hive.box<Book>('books').values
            .where((b) => b.seriesName == book.seriesName)
            .toList();
        book.seriesIndex = allBooks.length + 1;
      } else {
        book.seriesIndex = null;
      }


      if (book.status == BookStatus.planned) {
        book.status = _planningEnabled ? BookStatus.reading : BookStatus.planned;
      }

      book.save();
      Navigator.of(context).pop(book);
    } else {
      // 🟢 NOVÁ KNIHA
      final newBook = Book(
        title: title,
        author: author,
        description: description,
        totalChapters: chapters,
        totalPages: pages,
        dailyGoal: _planningEnabled && _goalMode == GoalMode.dailyGoal ? _dailyGoal : null,
        targetDate: _planningEnabled && _goalMode == GoalMode.targetDate ? _targetDate : null,
        startDate: _planningEnabled ? _startDate : null, // 🟢 PŘIDEJ TOTO
        status: _planningEnabled ? BookStatus.reading : BookStatus.planned,
        genre: _genreController.text.trim(),
        coverImagePath: _coverImage?.path,
        chapterEndPages: _chapterEndPages,
        chapterNames: _chapterNames,
        startPage: _customStartPageEnabled ? _startPage : null,
        readingMode: _readingMode,
        seriesName: _seriesNameController.text.trim().isEmpty ? null : _seriesNameController.text.trim(),
        seriesIndex: _seriesNameController.text.trim().isNotEmpty
            ? Hive.box<Book>('books').values.where((b) => b.seriesName == _seriesNameController.text.trim()).length + 1
            : null,
      );

      Navigator.of(context).pop(newBook);
    }
  }

  Widget _buildGoalPlanning() {
    if (!_planningEnabled) return const SizedBox.shrink();

    final daysUntilTarget = _targetDate?.difference(_startDate ?? DateTime.now()).inDays ?? 0;

    final calculatedDailyChapters = (_goalMode == GoalMode.targetDate &&
            daysUntilTarget > 0 &&
            _readingMode == ReadingMode.chapters &&
            _chapterCount > 0)
        ? (_chapterCount / daysUntilTarget).ceil()
        : (_readingMode == ReadingMode.chapters ? (_dailyGoal ?? 1) : null);

    final calculatedDailyPages = (_goalMode == GoalMode.targetDate &&
            daysUntilTarget > 0 &&
            _readingMode == ReadingMode.pages &&
            _pageCount > 0)
        ? (_pageCount / daysUntilTarget).ceil()
        : (_readingMode == ReadingMode.pages ? (_dailyGoal ?? 1) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _goalMode = GoalMode.dailyGoal;
                  _targetDate = null;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goalMode == GoalMode.dailyGoal ? Colors.green : Colors.grey[300],
                  foregroundColor: _goalMode == GoalMode.dailyGoal ? Colors.white : Colors.black,
                ),
                child: const Text('Denní cíl'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _goalMode = GoalMode.targetDate;
                  _dailyGoal = null;
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goalMode == GoalMode.targetDate ? Colors.green : Colors.grey[300],
                  foregroundColor: _goalMode == GoalMode.targetDate ? Colors.white : Colors.black,
                ),
                child: const Text('Datum dokončení'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _chaptersEnabled
                    ? () => setState(() => _readingMode = ReadingMode.chapters)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _readingMode == ReadingMode.chapters
                      ? Colors.green
                      : Colors.grey[300],
                  foregroundColor: _readingMode == ReadingMode.chapters
                      ? Colors.white
                      : Colors.black,
                ),
                child: const Text('Kapitoly'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _pagesEnabled
                    ? () => setState(() => _readingMode = ReadingMode.pages)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _readingMode == ReadingMode.pages
                      ? Colors.green
                      : Colors.grey[300],
                  foregroundColor: _readingMode == ReadingMode.pages
                      ? Colors.white
                      : Colors.black,
                ),
                child: const Text('Stránky'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_goalMode == GoalMode.dailyGoal)
          Column(
            children: [
              Text("Denní cíl (${_readingMode == ReadingMode.chapters ? 'kapitoly' : 'stránky'})"),
              NumberPicker(
                value: _dailyGoal ?? 1,
                minValue: 1,
                maxValue: _readingMode == ReadingMode.chapters ? _chapterCount : _pageCount,
                onChanged: (value) => setState(() => _dailyGoal = value),
              ),
            ],
          )
        else
          TextButton.icon(
            onPressed: _pickTargetDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(_targetDate == null
                ? 'Vyber datum dokončení'
                : 'Zvolené datum: ${_targetDate!.toLocal().toString().split(' ')[0]}'),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _pickStartDate,
          icon: const Icon(Icons.play_arrow),
          label: Text("Začít od: ${_startDate?.toLocal().toString().split(' ')[0] ?? 'Dnes'}"),
        ),
        TextButton(
          onPressed: () => setState(() => _startDate = DateTime.now().add(const Duration(days: 1))),
          child: const Text("Začít od zítřka"),
        ),
        const SizedBox(height: 12),

        if (_readingMode == ReadingMode.chapters && calculatedDailyChapters != null)
          Text(
            "Denně číst cca $calculatedDailyChapters kapitol",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

        if (_readingMode == ReadingMode.pages && calculatedDailyPages != null)
          Text(
            "Denně číst cca $calculatedDailyPages stránek",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingBook != null ? 'Upravit knihu' : 'Přidat knihu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_coverImage != null)
              Center(child: Image.file(_coverImage!, height: 150)),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Název knihy'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Autor'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Žánr'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Vybrat obálku'),
              onPressed: _pickCoverImage,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _seriesNameController,
                    decoration: const InputDecoration(labelText: 'Název série'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                if (_seriesNameController.text.length < 15) // ← uprav si limit podle potřeby
                  TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.add),
                                  title: const Text("Nová série"),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() => _seriesNameController.text = '');
                                  },
                                ),
                                ..._availableSeries.map((name) => ListTile(
                                      title: Text(name),
                                      onTap: () {
                                        Navigator.pop(context);
                                        setState(() => _seriesNameController.text = name);
                                      },
                                    )),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.collections_bookmark),
                    label: const Text("Přidat do série"),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Popis / obsah'),
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),

            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final selectedSet = <bool>{};
                if (_chaptersEnabled) selectedSet.add(true);
                if (_pagesEnabled) selectedSet.add(false);

                // 🔧 Pokud je prázdné, nastavíme default (třeba kapitoly)
                if (selectedSet.isEmpty) {
                  selectedSet.add(true);
                  _chaptersEnabled = true;
                }

                return SegmentedButton<bool>(
                  showSelectedIcon: false,
                  emptySelectionAllowed: false,
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: const Text("Kapitoly"),
                      enabled: !_chaptersToggleLocked || !_chaptersEnabled,
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: const Text("Stránky"),
                      enabled: !_pagesToggleLocked || !_pagesEnabled,
                    ),
                  ],
                  selected: selectedSet,
                  multiSelectionEnabled: true,
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _chaptersEnabled = selection.contains(true);
                      _pagesEnabled = selection.contains(false);

                      if (_chaptersEnabled && _chapterCount < 1) _chapterCount = 10;
                      if (_pagesEnabled && _pageCount < 1) _pageCount = 100;
                      if (_chapterCount < 1 && _chaptersEnabled) _chapterCount = 1;
                      if (_pageCount < 1 && _pagesEnabled) _pageCount = 1;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              label: Text(_customStartPageEnabled
                  ? "Zrušit přizpůsobení začátku knihy"
                  : "Kniha nezačíná na straně 1"),
              onPressed: () {
                setState(() {
                  _customStartPageEnabled = !_customStartPageEnabled;
                  _startPage = _customStartPageEnabled ? 2 : 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),

            if (_customStartPageEnabled && _pageCount > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Počáteční strana knihy"),
                  Slider(
                    value: _startPage.toDouble().clamp(2, _pageCount.toDouble()),
                    min: 2,
                    max: _pageCount.toDouble(),
                    divisions: _pageCount - 1,
                    label: _startPage.toString(),
                    onChanged: (value) {
                      setState(() {
                        _startPage = value.round();
                      });
                    },
                  ),
                ],
              ),

            const SizedBox(height: 24),
            if (_chaptersEnabled && _pagesEnabled)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Počet kapitol"),
                        NumberPicker(
                          value: _chapterCount,
                          minValue: 1,
                          maxValue: 1000,
                          onChanged: (value) => setState(() => _chapterCount = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Počet stránek"),
                        NumberPicker(
                          value: _pageCount,
                          minValue: 1,
                          maxValue: 5000,
                          onChanged: (value) => setState(() => _pageCount = value),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else if (_chaptersEnabled)
              Column(
                children: [
                  const Text("Počet kapitol"),
                  NumberPicker(
                    value: _chapterCount < 1 ? 1 : _chapterCount,
                    minValue: 1,
                    maxValue: 1000,
                    onChanged: (value) => setState(() => _chapterCount = value),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterRenameScreen(
                            totalChapters: _chapterCount,
                            existingNames: _chapterNames,
                            onSaved: (List<String> names) {
                              setState(() {
                                _chapterNames = names;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Přejmenovat kapitoly"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              )

            else if (_pagesEnabled)
              Center(
                child: Column(
                  children: [
                    const Text("Počet stránek"),
                    NumberPicker(
                      value: _pageCount < 1 ? 1 : _pageCount,
                      minValue: 1,
                      maxValue: 5000,
                      onChanged: (value) => setState(() => _pageCount = value),
                    ),
                  ],
                ),
              ),

            if (_chaptersEnabled && _pagesEnabled)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChapterPageAssignmentScreen(
                        totalPages: _pageCount,
                        totalChapters: _chapterCount,
                        existingAssignments: _chapterEndPages,
                        onSaved: (List<int> result) {
                          setState(() {
                            _chapterEndPages = result;
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.tune),
                label: const Text("Nastavit rozdělení stránek podle kapitol"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

            if (widget.existingBook == null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _planningEnabled = !_planningEnabled;

                    if (_planningEnabled) {
                      // Automaticky zvolit vhodný režim čtení
                      if (_pagesEnabled && !_chaptersEnabled) {
                        _readingMode = ReadingMode.pages;
                      } else if (_chaptersEnabled && !_pagesEnabled) {
                        _readingMode = ReadingMode.chapters;
                      }
                    }
                  });
                },
                icon: const Icon(Icons.schedule),
                label: Text(_planningEnabled ? "Zrušit plánování čtení" : "Naplánovat čtení"),
              ),

              _buildGoalPlanning(),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.existingBook != null ? 'Uložit změny' : 'Přidat knihu'),
            ),
          ],
        ),
      ),
    );
  }
}
