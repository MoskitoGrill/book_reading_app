// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 1;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      title: fields[0] as String,
      author: fields[1] as String,
      description: fields[2] as String,
      totalChapters: fields[3] as int,
      totalPages: fields[4] as int,
      currentChapter: fields[5] as int,
      targetDate: fields[6] as DateTime?,
      dailyGoal: fields[7] as int?,
      status: fields[8] as BookStatus,
      genre: fields[9] as String,
      coverImagePath: fields[10] as String?,
      startDate: fields[11] as DateTime?,
      chapterEndPages: (fields[12] as List?)?.cast<int>(),
      chapterNames: (fields[13] as List?)?.cast<String>(),
      startPage: fields[14] as int?,
      readingMode: fields[15] as ReadingMode?,
      wasRead: fields[16] as bool,
      seriesName: fields[17] as String?,
      seriesIndex: fields[18] as int?,
      readingDates: (fields[20] as List?)?.cast<DateTime>(),
      readingHistory: (fields[21] as Map?)?.cast<String, int>(),
    )..finishedAt = fields[19] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.author)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.totalChapters)
      ..writeByte(4)
      ..write(obj.totalPages)
      ..writeByte(5)
      ..write(obj.currentChapter)
      ..writeByte(6)
      ..write(obj.targetDate)
      ..writeByte(7)
      ..write(obj.dailyGoal)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.genre)
      ..writeByte(10)
      ..write(obj.coverImagePath)
      ..writeByte(11)
      ..write(obj.startDate)
      ..writeByte(12)
      ..write(obj.chapterEndPages)
      ..writeByte(13)
      ..write(obj.chapterNames)
      ..writeByte(14)
      ..write(obj.startPage)
      ..writeByte(15)
      ..write(obj.readingMode)
      ..writeByte(16)
      ..write(obj.wasRead)
      ..writeByte(17)
      ..write(obj.seriesName)
      ..writeByte(18)
      ..write(obj.seriesIndex)
      ..writeByte(19)
      ..write(obj.finishedAt)
      ..writeByte(20)
      ..write(obj.readingDates)
      ..writeByte(21)
      ..write(obj.readingHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookStatusAdapter extends TypeAdapter<BookStatus> {
  @override
  final int typeId = 0;

  @override
  BookStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookStatus.planned;
      case 1:
        return BookStatus.reading;
      case 2:
        return BookStatus.finished;
      case 3:
        return BookStatus.wish;
      default:
        return BookStatus.planned;
    }
  }

  @override
  void write(BinaryWriter writer, BookStatus obj) {
    switch (obj) {
      case BookStatus.planned:
        writer.writeByte(0);
        break;
      case BookStatus.reading:
        writer.writeByte(1);
        break;
      case BookStatus.finished:
        writer.writeByte(2);
        break;
      case BookStatus.wish:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingModeAdapter extends TypeAdapter<ReadingMode> {
  @override
  final int typeId = 2;

  @override
  ReadingMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReadingMode.chapters;
      case 1:
        return ReadingMode.pages;
      default:
        return ReadingMode.chapters;
    }
  }

  @override
  void write(BinaryWriter writer, ReadingMode obj) {
    switch (obj) {
      case ReadingMode.chapters:
        writer.writeByte(0);
        break;
      case ReadingMode.pages:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
