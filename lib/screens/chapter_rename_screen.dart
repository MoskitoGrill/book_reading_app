import 'package:flutter/material.dart';

class ChapterRenameScreen extends StatefulWidget {
  final int totalChapters;
  final List<String>? existingNames;
  final void Function(List<String>) onSaved;

  const ChapterRenameScreen({
    super.key,
    required this.totalChapters,
    required this.onSaved,
    this.existingNames,
  });

  @override
  State<ChapterRenameScreen> createState() => _ChapterRenameScreenState();
}

class _ChapterRenameScreenState extends State<ChapterRenameScreen> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.totalChapters, (index) {
      final existing = widget.existingNames;
      final name = (existing != null && index < existing.length && existing[index].trim().isNotEmpty)
          ? existing[index]
          : "";
      return TextEditingController(text: name);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final names = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final text = entry.value.text.trim();
      return text.isEmpty ? "Kapitola ${index + 1}" : text;
    }).toList();

    widget.onSaved(names);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Přejmenovat kapitoly")),
      body: ListView.builder(
        itemCount: widget.totalChapters,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${index + 1}. kapitola"),
            subtitle: TextField(
              controller: _controllers[index],
              decoration: const InputDecoration(
                hintText: "Název kapitoly",
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text("Uložit"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
