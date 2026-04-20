

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import '../models/diary_entry_isar.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Isar? _isar;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Isar> get database async {
    if (_isar != null) return _isar!;
    _isar = await _initDB();
    return _isar!;
  }

  Future<Isar> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();

    return await Isar.open(
      [DiaryEntrySchema],
      directory: dir.path,
      name: 'mydiary_database',
    );
  }

  

  /// Create a new diary entry
  Future<int> createEntry(DiaryEntry entry) async {
    final isar = await database;
    return await isar.writeTxn(() async {
      final prefs = await SharedPreferences.getInstance();
      entry.userId = prefs.getInt('user_id') ?? 0;
      return await isar.diaryEntrys.put(entry);
    });
  }

  /// Get all diary entries (sorted by date descending)
  Future<List<DiaryEntry>> getAllEntries() async {
    final isar = await database;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    return await isar.diaryEntrys.filter().userIdEqualTo(userId).sortByDateDesc().findAll();
  }

  /// Get entries by specific date
  Future<List<DiaryEntry>> getEntriesByDate(DateTime date) async {
    final isar = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await isar.diaryEntrys
        .where()
        .dateBetween(startOfDay, endOfDay)
        .findAll();
  }

  /// Get all favorite entries
  Future<List<DiaryEntry>> getFavoriteEntries() async {
    final isar = await database;
    return await isar.diaryEntrys
        .filter().isFavoriteEqualTo(true).sortByDateDesc()
        .findAll();
  }

  /// Search entries by title or content text
  Future<List<DiaryEntry>> searchEntries(String query) async {
    final isar = await database;
    return await isar.diaryEntrys
        .filter()
        .titleContains(query, caseSensitive: false)
        .or()
        .contentContains(query, caseSensitive: false)
        .sortByDateDesc()
        .findAll();
  }

  /// Get entries by tag
  Future<List<DiaryEntry>> getEntriesByTag(String tag) async {
    final isar = await database;
    return await isar.diaryEntrys
        .filter()
        .tagsElementContains(tag)
        .sortByDateDesc()
        .findAll();
  }

  /// Update an existing entry
  Future<void> updateEntry(DiaryEntry entry) async {
    final isar = await database;
    entry.updateTimestamp();
    await isar.writeTxn(() async {
      await isar.diaryEntrys.put(entry);
    });
  }

  /// Delete an entry by ID
  Future<bool> deleteEntry(int id) async {
    final isar = await database;
    return await isar.writeTxn(() async {
      return await isar.diaryEntrys.delete(id);
    });
  }

  /// Get a single entry by ID
  Future<DiaryEntry?> getEntryById(int id) async {
    final isar = await database;
    return await isar.diaryEntrys.get(id);
  }

  /// Toggle favorite status of an entry
  Future<void> toggleFavorite(int id) async {
    final isar = await database;
    final entry = await isar.diaryEntrys.get(id);
    if (entry != null) {
      entry.isFavorite = !entry.isFavorite;
      entry.updateTimestamp();
      await isar.writeTxn(() async {
        await isar.diaryEntrys.put(entry);
      });
    }
  }

  /// Get diary statistics (total, favorites, consecutive days)
  Future<Map<String, int>> getStatistics() async {
    final isar = await database;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id") ?? 0;
    final totalEntries = await isar.diaryEntrys.filter().userIdEqualTo(userId).count();
    final favoriteEntries =
        await isar.diaryEntrys.filter().isFavoriteEqualTo(true).count();

    // Calculate consecutive days (last days with entries)
    final now = DateTime.now();
    int consecutiveDays = 0;

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final entriesForDay = await getEntriesByDate(date);
      if (entriesForDay.isNotEmpty) {
        consecutiveDays++;
      } else if (i > 0) {
        break; // Break streak if no entry on a day
      }
    }

    return {
      'total': totalEntries,
      'favorites': favoriteEntries,
      'consecutive_days': consecutiveDays,
    };
  }

  /// Get all unique tags from all entries
  Future<List<String>> getAllTags() async {
    final isar = await database;
    final entries = await isar.diaryEntrys.where().findAll();
    final allTags = <String>{};

    for (final entry in entries) {
      allTags.addAll(entry.tags);
    }

    return allTags.toList()..sort();
  }

  /// Close the database connection
  Future<void> closeDatabase() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
    }
  }
}

