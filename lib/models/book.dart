import 'package:hive/hive.dart';
part 'book.g.dart';

@HiveType(typeId: 1)
class Book extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String author;

  @HiveField(2)
  String description;

  @HiveField(3)
  int totalChapters;

  @HiveField(4)
  int totalPages;

  @HiveField(5)
  int currentChapter;

  @HiveField(6)
  DateTime? targetDate;

  @HiveField(7)
  int? dailyGoal;

  @HiveField(8)
  BookStatus status;

  @HiveField(9)
  String genre;

  @HiveField(10)
  String? coverImagePath;

  @HiveField(11)
  DateTime? startDate;

  @HiveField(12)
  List<int>? chapterEndPages;

  @HiveField(13)
  List<String>? chapterNames;

  @HiveField(14)
  int? startPage;

  @HiveField(15)
  ReadingMode? readingMode;

  @HiveField(16)
  bool wasRead; 

  @HiveField(17)
  String? seriesName;

  @HiveField(18)
  int? seriesIndex;    

  @HiveField(19)
  DateTime? finishedAt;

  @HiveField(20)
  List<DateTime> readingDates;

  @HiveField(21)
  Map<String, int>? readingHistory;

  @HiveField(22)
  int lastPage;

  Book({
    required this.title,
    required this.author,
    required this.description,
    required this.totalChapters,
    required this.totalPages,
    this.currentChapter = 0,
    this.targetDate,
    this.dailyGoal,
    required this.status,
    this.genre = '',
    this.coverImagePath,
    DateTime? startDate,
    this.chapterEndPages,
    this.chapterNames,
    int? startPage,
    this.readingMode,
    this.wasRead = false,
    this.seriesName,
    this.seriesIndex,
    List<DateTime>? readingDates,
    this.readingHistory,
    this.lastPage = 0,
  })  : startPage = startPage ?? 1,
        startDate = startDate,
        readingDates = readingDates ?? [];

  int get effectivePageCount {
    return totalPages - (startPage ?? 1) + 1;
  }

  int get calculatedDailyGoalChapters {
    if (targetDate != null) {
      final days = targetDate!.difference(DateTime.now()).inDays;
      return days > 0 ? (totalChapters - currentChapter) ~/ days : totalChapters;
    } else if (dailyGoal != null) {
      return dailyGoal!;
    } else {
      return 1;
    }
  }

  int get calculatedDailyGoalPages {
    if (readingMode == ReadingMode.pages) {
      if (targetDate != null && startDate != null) {
        final days = targetDate!.difference(startDate!).inDays;
        if (days > 0) {
          return (effectivePageCount / days).ceil();
        }
      }
      return dailyGoal ?? 1;
    }

    if (totalChapters == 0) return dailyGoal ?? 1;
    return (totalPages / totalChapters * calculatedDailyGoalChapters).ceil();
  }

  int get currentStreak {
    if (readingDates.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 1000; i++) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final wasRead = readingDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);

      if (wasRead) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int get maxChapterByPage {
    if (chapterEndPages != null && startPage != null) {
      return chapterEndPages!.indexWhere((end) => end >= currentPage);
    }

    if (totalChapters > 0 && totalPages > 0 && startPage != null) {
      final pagesPerChapter = (effectivePageCount / totalChapters).ceil();
      return ((currentPage - startPage!) / pagesPerChapter).floor();
    }

    return currentChapter;
  }

  int get progressPercent {
    if (totalChapters == 0) return 0;
    return ((currentChapter / totalChapters) * 100).clamp(0, 100).round();
  }

  DateTime? get estimatedEndDate {
    if (dailyGoal == null || dailyGoal == 0) return null;

    if (readingMode == ReadingMode.pages) {
      final current = currentPage;
      final remaining = (totalPages - current).clamp(0, effectivePageCount);
      if (remaining <= 0) return null;

      return DateTime.now().add(
        Duration(days: (remaining / dailyGoal!).ceil()),
      );
    } else if (readingMode == ReadingMode.chapters) {
      final remaining = (totalChapters - currentChapter).clamp(0, totalChapters);
      if (remaining <= 0) return null;

      return DateTime.now().add(
        Duration(days: (remaining / dailyGoal!).ceil()),
      );
    }

    return null;
  }

  int get currentPage {
    return lastPage > 0 ? lastPage : (startPage?? 1);
  }

  int get safeStartPage => startPage ?? 1;
}

// ✅ Enumy musí být mimo třídu Book

@HiveType(typeId: 0)
enum BookStatus {
  @HiveField(0)
  planned,

  @HiveField(1)
  reading,

  @HiveField(2)
  finished,

  @HiveField(3)
  wish,
}

@HiveType(typeId: 2)
enum ReadingMode {
  @HiveField(0)
  chapters,

  @HiveField(1)
  pages,
}
