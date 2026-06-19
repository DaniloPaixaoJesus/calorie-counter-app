import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/meal.dart';
import 'meal_repository.dart';

class SqliteMealRepository implements MealRepository {
  static const _databaseName = 'calorie_counter.db';
  static const _databaseVersion = 1;
  static const _tableMeals = 'meals';

  final Database _database;
  final List<Meal> _cache;

  SqliteMealRepository._(this._database, this._cache);

  static Future<SqliteMealRepository> open() async {
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(databasePath, _databaseName),
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableMeals (
            id TEXT PRIMARY KEY,
            descricao TEXT NOT NULL,
            calorias INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            origem TEXT NOT NULL,
            aiConfidence REAL,
            nota TEXT,
            iconKey TEXT NOT NULL
          )
        ''');
      },
    );

    final rows = await database.query(
      _tableMeals,
      orderBy: 'timestamp DESC',
    );
    final meals = rows.map(Meal.fromMap).toList();

    return SqliteMealRepository._(database, meals);
  }

  @override
  Future<void> add(Meal meal) async {
    await _database.insert(
      _tableMeals,
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cache
      ..removeWhere((existing) => existing.id == meal.id)
      ..add(meal)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> update(Meal meal) async {
    await _database.update(
      _tableMeals,
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
    final index = _cache.indexWhere((existing) => existing.id == meal.id);
    if (index == -1) return;
    _cache[index] = meal;
    _cache.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  List<Meal> getAll() => List.unmodifiable(_cache);

  @override
  Future<void> remove(String id) async {
    await _database.delete(
      _tableMeals,
      where: 'id = ?',
      whereArgs: [id],
    );
    _cache.removeWhere((meal) => meal.id == id);
  }

  @override
  int getTotalCaloriesHoje() {
    final hoje = DateTime.now();
    return _cache
        .where(
          (m) =>
              m.timestamp.year == hoje.year &&
              m.timestamp.month == hoje.month &&
              m.timestamp.day == hoje.day,
        )
        .fold(0, (sum, m) => sum + m.calorias);
  }
}
