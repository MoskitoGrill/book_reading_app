import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import '../models/book.dart';

enum GoalMode { dailyGoal, targetDate }

class EditReadingPlanScreen extends StatefulWidget {
  final Book book;

  const EditReadingPlanScreen({super.key, required this.book});

  @override
  State<EditReadingPlanScreen> createState() => _EditReadingPlanScreenState();
}

class _EditReadingPlanScreenState extends State<EditReadingPlanScreen> {
  late int? _dailyGoal;
  late DateTime? _targetDate;
  late DateTime _startDate;
  late GoalMode _goalMode;
  late ReadingMode _readingMode;

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.book.dailyGoal ?? 1;
    _targetDate = widget.book.targetDate;
    _startDate = widget.book.startDate ?? DateTime.now();
    _goalMode = _targetDate != null ? GoalMode.targetDate : GoalMode.dailyGoal;
    _readingMode = widget.book.readingMode ?? ReadingMode.chapters;

    // 🛡 Zajištění minimálních hodnot
    if (widget.book.totalChapters == 0 && _readingMode == ReadingMode.chapters) {
      widget.book.totalChapters = 1;
    }
    if (widget.book.totalPages == 0 && _readingMode == ReadingMode.pages) {
      widget.book.totalPages = 1;
    }
    if (widget.book.totalChapters == 0 && widget.book.totalPages > 0) {
      _readingMode = ReadingMode.pages;
    } else if (widget.book.totalPages == 0 && widget.book.totalChapters > 0) {
      _readingMode = ReadingMode.chapters;
    }
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
      initialDate: _startDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null) {
      setState(() => _startDate = selected);
    }
  }

  void _submit() {
    widget.book.dailyGoal = _goalMode == GoalMode.dailyGoal ? _dailyGoal : null;
    widget.book.targetDate = _goalMode == GoalMode.targetDate ? _targetDate : null;
    widget.book.startDate = _startDate; // 🟢 DOPLŇ
    widget.book.readingMode = _readingMode;
    if (widget.book.status != BookStatus.finished) {
      widget.book.status = BookStatus.reading;
    }
    widget.book.save();
    Navigator.of(context).pop(widget.book);
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilTarget = _targetDate?.difference(_startDate).inDays ?? 0;

    final calculatedDailyGoal = () {
      if (_goalMode == GoalMode.targetDate && daysUntilTarget > 0) {
        final total = _readingMode == ReadingMode.chapters ? widget.book.totalChapters : widget.book.totalPages;
        return (total / daysUntilTarget).ceil();
      } else {
        return _dailyGoal ?? 1;
      }
    }();

    return Scaffold(
      appBar: AppBar(title: const Text('Upravit plán čtení')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            const SizedBox(height: 16),
            if (_goalMode == GoalMode.dailyGoal) ...[
              Row(
                children: [
                  if (widget.book.totalChapters > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _readingMode = ReadingMode.chapters),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _readingMode == ReadingMode.chapters ? Colors.green : Colors.grey[300],
                          foregroundColor: _readingMode == ReadingMode.chapters ? Colors.white : Colors.black,
                        ),
                        child: const Text("Kapitoly"),
                      ),
                    ),
                  if (widget.book.totalPages > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _readingMode = ReadingMode.pages),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _readingMode == ReadingMode.pages ? Colors.green : Colors.grey[300],
                          foregroundColor: _readingMode == ReadingMode.pages ? Colors.white : Colors.black,
                        ),
                        child: const Text("Stránky"),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text("Denní cíl (${_readingMode == ReadingMode.chapters ? 'kapitoly' : 'stránky'})"),
              NumberPicker(
                value: _dailyGoal ?? 1,
                minValue: 1,
                maxValue: _readingMode == ReadingMode.chapters
                    ? (widget.book.totalChapters > 0 ? widget.book.totalChapters : 1)
                    : (widget.book.totalPages > 0 ? widget.book.totalPages : 1),
                onChanged: (value) => setState(() => _dailyGoal = value),
              ),
            ]

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
              label: Text("Začít od: ${_startDate.toLocal().toString().split(' ')[0]}"),
            ),
            TextButton(
              onPressed: () => setState(() => _startDate = DateTime.now().add(const Duration(days: 1))),
              child: const Text("Začít od zítřka"),
            ),
            const SizedBox(height: 12),
            Text(
              "Denně číst cca $calculatedDailyGoal ${_readingMode == ReadingMode.chapters ? 'kapitol' : 'stránek'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_goalMode == GoalMode.dailyGoal && _dailyGoal != null && _dailyGoal! > 0)
              Text(
                "Odhadované dokončení: ${_startDate.add(Duration(
                  days: ((_readingMode == ReadingMode.chapters
                      ? widget.book.totalChapters
                      : widget.book.totalPages) ~/ _dailyGoal!).clamp(1, 9999))).toLocal().toString().split(' ')[0]}",
                style: const TextStyle(color: Colors.grey),
              ),


            const Spacer(),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text("Uložit plán"),
            )
          ],
        ),
      ),
    );
  }
}
