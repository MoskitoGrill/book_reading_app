import 'package:flutter/material.dart';

class ChapterPageAssignmentScreen extends StatefulWidget {
  final int totalChapters;
  final int totalPages;
  final List<int>? existingAssignments;
  final void Function(List<int> chapterEndPages, List<String> chapterNames) onSaved;

  const ChapterPageAssignmentScreen({
    super.key,
    required this.totalChapters,
    required this.totalPages,
    required this.onSaved,
    this.existingAssignments,
  });

  @override
  State<ChapterPageAssignmentScreen> createState() => _ChapterPageAssignmentScreenState();
}

class _ChapterPageAssignmentScreenState extends State<ChapterPageAssignmentScreen> {
  int? _expandedChapter;
  late List<int> _chapterEndPages;
  late List<TextEditingController> _chapterNameControllers;

  @override
  void initState() {
    super.initState();

    // inicializace koncových stránek kapitol
    _chapterEndPages = List.generate(widget.totalChapters, (i) {
      return widget.existingAssignments != null && i < widget.existingAssignments!.length
          ? widget.existingAssignments![i]
          : ((i + 1) * (widget.totalPages / widget.totalChapters)).ceil();
    });

    // inicializace kontrolerů pro názvy kapitol
    _chapterNameControllers = List.generate(widget.totalChapters, (i) {
      return TextEditingController(text: "Kapitola ${i + 1}");
    });
  }

  @override
  void dispose() {
    for (var controller in _chapterNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rozdělení stránek podle kapitol")),
      body: ListView.builder(
        itemCount: widget.totalChapters,
        itemBuilder: (context, index) {
          final isExpanded = _expandedChapter == index;
          final minPage = index == 0 ? 1 : _chapterEndPages[index - 1] + 1;
          final maxPage = widget.totalPages - (widget.totalChapters - index - 1);

          final canExpand = maxPage > minPage;

          return Column(
            children: [
              ListTile(
                title: Row(
                  children: [
                    Text("Kapitola ${index + 1}: "),
                    Expanded(
                      child: TextField(
                        controller: _chapterNameControllers[index],
                        decoration: const InputDecoration(
                          hintText: "Název kapitoly",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.words, // automaticky velké písmeno
                      ),
                    ),
                  ],
                ),
                subtitle: Text("Končí na straně: ${_chapterEndPages[index]}"),
                trailing: canExpand
                    ? Icon(isExpanded ? Icons.expand_less : Icons.expand_more)
                    : const Icon(Icons.lock_outline, color: Colors.grey),
                onTap: canExpand
                    ? () => setState(() {
                        _expandedChapter = isExpanded ? null : index;
                      })
                    : null,
              ),

              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Slider(
                    value: _chapterEndPages[index].toDouble(),
                    min: minPage.toDouble(),
                    max: maxPage.toDouble(),
                    divisions: maxPage > minPage ? (maxPage - minPage) : null,
                    label: _chapterEndPages[index].toString(),
                    onChanged: (value) {
                      setState(() {
                        _chapterEndPages[index] = value.round();
                        for (int i = index + 1; i < widget.totalChapters; i++) {
                          if (_chapterEndPages[i] <= _chapterEndPages[i - 1]) {
                            _chapterEndPages[i] = _chapterEndPages[i - 1] + 1;
                          }
                        }
                      });
                    },
                  ),
                ),
            ],
          );
        }

      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text("Uložit"),
          onPressed: () {
            if (_chapterEndPages.last > widget.totalPages) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Překročili jste celkový počet stránek!")),
              );
              return;
            }
            widget.onSaved(
              _chapterEndPages,
              _chapterNameControllers.map((c) => c.text.trim()).toList(),
            );

            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48), // výška jako u jiných tlačítek
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

    );
  }
}
