import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'daily_estimate_quota.dart';
import 'estimate_quota_repository.dart';

class SqliteEstimateQuotaRepository implements EstimateQuotaRepository {
  static const _databaseName = 'calorie_counter.db';
  static const _tableEstimateQuota = 'estimate_quota';

  final Database _database;
  final Map<String, int> _usedByDate;

  SqliteEstimateQuotaRepository._(this._database, this._usedByDate);

  static Future<SqliteEstimateQuotaRepository> open() async {
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(databasePath, _databaseName),
      onOpen: _ensureTable,
    );

    await _ensureTable(database);
    final rows = await database.query(_tableEstimateQuota);
    final usedByDate = <String, int>{
      for (final row in rows) row['dateKey'] as String: row['usedCount'] as int,
    };

    return SqliteEstimateQuotaRepository._(database, usedByDate);
  }

  @override
  DailyEstimateQuota getForDate(DateTime date) {
    final key = _dateKey(date);
    return DailyEstimateQuota(
      date: date,
      usedCount: _usedByDate[key] ?? 0,
    );
  }

  @override
  Future<DailyEstimateQuota> increment(DateTime date) async {
    final key = _dateKey(date);
    final nextCount = (_usedByDate[key] ?? 0) + 1;
    _usedByDate[key] = nextCount;

    await _database.insert(
      _tableEstimateQuota,
      {
        'dateKey': key,
        'usedCount': nextCount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return DailyEstimateQuota(date: date, usedCount: nextCount);
  }

  static Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableEstimateQuota (
        dateKey TEXT PRIMARY KEY,
        usedCount INTEGER NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
