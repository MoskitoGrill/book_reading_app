import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/book.dart';

class StreakCalendarScreen extends StatelessWidget {
  const StreakCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final books = Hive.box<Book>('books')
        .values
        .where((b) => b.status == BookStatus.reading)
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<DateTime> days = List.generate(30, (i) => today.subtract(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(title: const Text("Kalendář streaku")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final day = days[index];

            final booksReadToday = books.where((book) =>
              book.readingDates.any((d) =>
                d.year == day.year && d.month == day.month && d.day == day.day)).toList();

            int successCount = 0;
            int goalCount = 0;

            for (final book in booksReadToday) {
              final key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
              final readAmount = book.readingHistory?[key] ?? 0;

              final goal = book.readingMode == ReadingMode.pages
                ? book.calculatedDailyGoalPages
                : book.calculatedDailyGoalChapters;

              goalCount++;
              if (readAmount >= goal) {
                successCount++;
              }
            }

            Color color;
            IconData icon;

            if (booksReadToday.isEmpty) {
              color = Colors.grey.shade300;
              icon = Icons.close;
            } else if (successCount == 0) {
              color = Colors.orange;
              icon = Icons.remove;
            } else if (successCount < goalCount) {
              color = Colors.green;
              icon = Icons.check;
            } else {
              color = Colors.blue;
              icon = Icons.star;
            }

            return Tooltip(
              message: "${day.day}.${day.month}.: $successCount / $goalCount cílů",
              child: CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, size: 16, color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
