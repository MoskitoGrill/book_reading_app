import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/book.dart';

enum BadgeType { future, empty, none, partial, single, all }

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _installDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);

    // první záznam v aplikaci
    final books = Hive.box<Book>('books').values.toList();
    DateTime? earliest;

    // 1) hledej nejdřívější datum v readingDates
    for (final b in books) {
      for (final d in b.readingDates) {
        if (earliest == null || d.isBefore(earliest)) {
          earliest = d;
        }
      }
    }

    // 2) hledej nejdřívější datum v readingHistory
    for (final b in books) {
      final hist = b.readingHistory ?? {};
      for (final k in hist.keys) {
        final parts = k.split('-');
        if (parts.length == 3) {
          final d = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (earliest == null || d.isBefore(earliest)) {
            earliest = d;
          }
        }
      }
    }

    _installDate = earliest ?? now;
  }


  /// všechny dny aktuální mřížky měsíce
  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final daysBefore = first.weekday == 7 ? 0 : first.weekday;
    final start = first.subtract(Duration(days: daysBefore));

    final last = DateTime(month.year, month.month + 1, 0);
    final daysAfter = 7 - (last.weekday == 7 ? 0 : last.weekday);
    final end = last.add(Duration(days: daysAfter));

    return List.generate(
      end.difference(start).inDays + 1,
      (i) => start.add(Duration(days: i)),
    );
  }

  BadgeType _badgeForDay(DateTime day, List<Book> books, DateTime today) {
    if (day.isAfter(today)) return BadgeType.future;   // světle šedá
    if (day.isBefore(_installDate)) return BadgeType.empty; // šedá

    final activeBooks = books.where((b) => b.status == BookStatus.reading).toList();
    if (activeBooks.isEmpty) return BadgeType.empty;

    final key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    int total = activeBooks.length;
    int success = 0;
    int readButNotGoal = 0;

    for (final b in activeBooks) {
      final read = b.readingHistory?[key] ?? 0;
      final goal = b.readingMode == ReadingMode.pages
        ? (b.targetDate != null ? b.adaptiveDailyGoalPages : b.calculatedDailyGoalPages)
        : (b.targetDate != null ? b.adaptiveDailyGoalChapters : b.calculatedDailyGoalChapters);

      if (read >= goal && goal > 0) {
        success++;
      } else if (read > 0) {
        readButNotGoal++;
      }
    }

    if (success == 0 && readButNotGoal == 0) {
      return BadgeType.none; // ⚫ nic nepřečteno
    } else if (success == total) {
      return BadgeType.all; // ⭐ všechny cíle splněny
    } else if (success > 0) {
      return BadgeType.single; // ✅ aspoň jedna kniha splněna
    } else {
      return BadgeType.partial; // 🟠 četl, ale žádný cíl nesplnil
    }
  }

    /// aktuální streak (od dneška zpět dokud jsi každý den splnil alespoň jeden cíl)
    int calculateGlobalStreak(List<Book> books) {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 1000; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final key =
            "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

        final activeBooks = books.where((b) => b.status == BookStatus.reading).toList();
        if (activeBooks.isEmpty) continue;

        final anyGoalMet = activeBooks.any((b) {
          final read = b.readingHistory?[key] ?? 0;
          final goal = b.readingMode == ReadingMode.pages
              ? b.calculatedDailyGoalPages
              : b.calculatedDailyGoalChapters;
          return read >= goal && goal > 0;
        });

        if (anyGoalMet) {
          streak++;
        } else {
          break; // streak se přerušil
        }
      }

      return streak;
    }

    /// nejdelší streak v historii
    int calculateLongestStreak(List<Book> books) {
      final now = DateTime.now();
      int longest = 0;
      int current = 0;

      for (int i = 0; i < 1000; i++) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final key =
            "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

        final activeBooks = books.where((b) => b.status == BookStatus.reading).toList();
        if (activeBooks.isEmpty) continue;

        final anyGoalMet = activeBooks.any((b) {
          final read = b.readingHistory?[key] ?? 0;
          final goal = b.readingMode == ReadingMode.pages
              ? b.calculatedDailyGoalPages
              : b.calculatedDailyGoalChapters;
          return read >= goal && goal > 0;
        });

        if (anyGoalMet) {
          current++;
          if (current > longest) longest = current;
        } else {
          current = 0;
        }
      }

      return longest;
    }

  @override
  Widget build(BuildContext context) {
    final allBooks = Hive.box<Book>('books').values.toList();
    final books = allBooks.where((b) => b.status == BookStatus.reading).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _daysInMonth(_focusedMonth);

    final currentStreak = calculateGlobalStreak(allBooks);
    final longestStreak = calculateLongestStreak(allBooks);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kalendář streaku"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$currentStreak dní',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < 0) {
              final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              if (!next.isAfter(today)) {
                setState(() => _focusedMonth = next);
              }
            } else if (details.primaryVelocity! > 0) {
              setState(() => _focusedMonth =
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1));
            }
          }
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("Po"),
                Text("Út"),
                Text("St"),
                Text("Čt"),
                Text("Pá"),
                Text("So"),
                Text("Ne"),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final type = _badgeForDay(day, books, today);

                  Color color;
                  switch (type) {
                    case BadgeType.future:
                      color = Colors.grey.shade300; // světle šedá
                      break;
                    case BadgeType.empty:
                      color = Colors.grey.shade500; // šedá
                      break;
                    case BadgeType.none:
                      color = Colors.black; // černá
                      break;
                    case BadgeType.partial:
                      color = Colors.orange; // oranžová
                      break;
                    case BadgeType.single:
                      color = Colors.green; // zelená
                      break;
                    case BadgeType.all:
                      color = Colors.yellow.shade700; // žlutá
                      break;
                  }

                  return GestureDetector(
                    onTap: () => _showDayDetail(context, day, books),
                    child: CircleAvatar(
                      backgroundColor: color,
                      child: Text(
                        "${day.day}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Nejdelší streak: $longestStreak dní",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedMonth =
                      DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              "${_monthName(_focusedMonth.month)} ${_focusedMonth.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                final next =
                    DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                if (!next.isAfter(today)) {
                  setState(() => _focusedMonth = next);
                }
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime day, List<Book> books) {
    final key =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    final booksReadToday = books.where((book) {
      final read = book.readingHistory?[key] ?? 0;
      return read > 0;
    }).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${day.day}.${day.month}.${day.year}"),
        content: booksReadToday.isEmpty
            ? const Text("Tento den jsi nečetl.")
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: booksReadToday.map((book) {
                  final read = book.readingHistory?[key] ?? 0;
                  final goal = book.readingMode == ReadingMode.pages
                      ? (book.targetDate != null ? book.adaptiveDailyGoalPages : book.calculatedDailyGoalPages)
                      : (book.targetDate != null ? book.adaptiveDailyGoalChapters : book.calculatedDailyGoalChapters);

                  return ListTile(
                    title: Text(book.title),
                    subtitle: Text("Přečteno: $read / $goal"),
                  );
                }).toList(),
              ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Leden",
      "Únor",
      "Březen",
      "Duben",
      "Květen",
      "Červen",
      "Červenec",
      "Srpen",
      "Září",
      "Říjen",
      "Listopad",
      "Prosinec"
    ];
    return months[month - 1];
  }
}
