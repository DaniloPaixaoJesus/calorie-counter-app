import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'app_settings_repository.dart';

class SqliteAppSettingsRepository implements AppSettingsRepository {
  static const _databaseName = 'calorie_counter.db';
  static const _tableAppSettings = 'app_settings';
  static const _settingsId = 'current';

  final Database _database;

  SqliteAppSettingsRepository._(this._database);

  static Future<SqliteAppSettingsRepository> open() async {
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(databasePath, _databaseName),
      onOpen: _ensureTable,
    );

    await _ensureTable(database);
    return SqliteAppSettingsRepository._(database);
  }

  @override
  Future<AppSettings> load() async {
    final rows = await _database.query(
      _tableAppSettings,
      where: 'id = ?',
      whereArgs: [_settingsId],
      limit: 1,
    );
    if (rows.isEmpty) return AppSettings.empty;
    return AppSettings.fromMap(rows.single);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _database.insert(
      _tableAppSettings,
      {
        'id': _settingsId,
        ...settings.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableAppSettings (
        id TEXT PRIMARY KEY,
        selectedPlan TEXT,
        trialStartDate TEXT,
        trialEndDate TEXT,
        isPremium INTEGER NOT NULL,
        remainingDailyEstimations INTEGER NOT NULL,
        lastResetDate TEXT,
        userLogged INTEGER NOT NULL,
        userName TEXT,
        userEmail TEXT,
        userPhotoAssetPath TEXT,
        updatedAt TEXT NOT NULL
      )
    ''');
    await _ensureColumn(db, 'userName', 'TEXT');
    await _ensureColumn(db, 'userEmail', 'TEXT');
    await _ensureColumn(db, 'userPhotoAssetPath', 'TEXT');
  }

  static Future<void> _ensureColumn(
    Database db,
    String columnName,
    String columnType,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($_tableAppSettings)');
    final hasColumn = columns.any((column) => column['name'] == columnName);
    if (!hasColumn) {
      await db.execute(
        'ALTER TABLE $_tableAppSettings ADD COLUMN $columnName $columnType',
      );
    }
  }
}
