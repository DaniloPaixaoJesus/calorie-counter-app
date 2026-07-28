import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class AppDatabase {
  static const name = 'calorie_counter.db';
  static const version = 4;
  final Database database;

  const AppDatabase(this.database);

  static Future<AppDatabase> open() async {
    final root = await getDatabasesPath();
    final database = await openDatabase(
      p.join(root, name),
      version: version,
      onCreate: (db, _) => _create(db),
      onUpgrade: _upgrade,
      onOpen: (db) => _ensureSyncSchema(db),
    );
    return AppDatabase(database);
  }

  static Future<void> _create(Database db) async {
    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY, descricao TEXT NOT NULL,
        descricaoOriginal TEXT, calorias INTEGER NOT NULL,
        timestamp TEXT NOT NULL, origem TEXT NOT NULL,
        aiConfidence REAL, nota TEXT, iconKey TEXT NOT NULL,
        proteinGrams INTEGER, carbohydrateGrams INTEGER, fatGrams INTEGER,
        modifiedAt TEXT NOT NULL, deletedAt TEXT, ownerUserId TEXT
      )
    ''');
    await _ensureSyncSchema(db);
  }

  static Future<void> _upgrade(
      Database db, int oldVersion, int newVersion) async {
    final mealTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'meals'",
    );
    if (mealTable.isEmpty) {
      await _create(db);
      return;
    }
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE meals ADD COLUMN proteinGrams INTEGER');
      await db
          .execute('ALTER TABLE meals ADD COLUMN carbohydrateGrams INTEGER');
      await db.execute('ALTER TABLE meals ADD COLUMN fatGrams INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE meals ADD COLUMN descricaoOriginal TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE meals ADD COLUMN modifiedAt TEXT');
      await db.execute('ALTER TABLE meals ADD COLUMN deletedAt TEXT');
      await db.execute('ALTER TABLE meals ADD COLUMN ownerUserId TEXT');
      await db.execute(
          "UPDATE meals SET modifiedAt = timestamp WHERE modifiedAt IS NULL");
    }
    await _ensureSyncSchema(db);
  }

  static Future<void> _ensureSyncSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS installation_metadata (
        id TEXT PRIMARY KEY, deviceId TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_goals (
        id TEXT PRIMARY KEY, targetValue INTEGER NOT NULL,
        effectiveFrom TEXT NOT NULL, effectiveUntil TEXT,
        modifiedAt TEXT NOT NULL, deletedAt TEXT, ownerUserId TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        operationId TEXT PRIMARY KEY, entityType TEXT NOT NULL,
        entityId TEXT NOT NULL, operation TEXT NOT NULL,
        occurredAt TEXT NOT NULL, ownerUserId TEXT,
        status TEXT NOT NULL, attemptCount INTEGER NOT NULL DEFAULT 0,
        lastAttemptAt TEXT, lastErrorCode TEXT, payload TEXT
      )
    ''');
    final outboxColumns = await db.rawQuery('PRAGMA table_info(sync_outbox)');
    if (!outboxColumns.any((column) => column['name'] == 'payload')) {
      await db.execute('ALTER TABLE sync_outbox ADD COLUMN payload TEXT');
    }
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_outbox_pending
      ON sync_outbox(status, occurredAt)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_checkpoints (
        ownerUserId TEXT PRIMARY KEY, deviceId TEXT NOT NULL,
        cursor TEXT, bootstrapState TEXT NOT NULL,
        lastSuccessAt TEXT, lastErrorCode TEXT,
        cleanupPending INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<String> getOrCreateDeviceId() async {
    final rows = await database.query(
      'installation_metadata',
      where: 'id = ?',
      whereArgs: ['current'],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.single['deviceId'] as String;
    final deviceId = const Uuid().v4();
    await database.insert('installation_metadata', {
      'id': 'current',
      'deviceId': deviceId,
    });
    return deviceId;
  }
}
