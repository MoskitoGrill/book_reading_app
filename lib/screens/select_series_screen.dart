import 'package:flutter/material.dart';

class SelectSeriesScreen extends StatefulWidget {
  final List<String> existingSeries;
  final String? currentSeries;
  final void Function(String? seriesName, int? indexInSeries) onSelected;

  const SelectSeriesScreen({
    super.key,
    required this.existingSeries,
    this.currentSeries,
    required this.onSelected,
  });

  @override
  State<SelectSeriesScreen> createState() => _SelectSeriesScreenState();
}

class _SelectSeriesScreenState extends State<SelectSeriesScreen> {
  String? _selectedSeries;
  int _selectedIndex = 1;
  final TextEditingController _newSeriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.currentSeries;
  }

  @override
  void dispose() {
    _newSeriesController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    if (_selectedSeries != null) {
      widget.onSelected(_selectedSeries, _selectedIndex);
      Navigator.pop(context);
    }
  }

  void _createNewSeries() {
    final newName = _newSeriesController.text.trim();
    if (newName.isNotEmpty) {
      setState(() {
        _selectedSeries = newName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vyber sérii")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Vyber existující sérii:"),
            ...widget.existingSeries.map((series) {
              return RadioListTile<String>(
                title: Text(series),
                value: series,
                groupValue: _selectedSeries,
                onChanged: (value) {
                  setState(() => _selectedSeries = value);
                },
              );
            }),
            const Divider(height: 32),
            const Text("Nebo přidej novou sérii:"),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSeriesController,
                    decoration: const InputDecoration(
                      labelText: "Nový název série",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createNewSeries,
                  child: const Text("Přidat"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_selectedSeries != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pořadí knihy v sérii:"),
                  Slider(
                    value: _selectedIndex.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: "$_selectedIndex",
                    onChanged: (value) {
                      setState(() => _selectedIndex = value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.check),
                    label: const Text("Potvrdit"),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
