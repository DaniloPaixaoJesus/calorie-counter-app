import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../features/sync/domain/sync_types.dart';
import '../../models/meal.dart';
import 'app_database.dart';
import 'meal_repository.dart';

class SqliteMealRepository implements MealRepository {
  static const _tableMeals = 'meals';

  final Database _database;
  final List<Meal> _cache;

  SqliteMealRepository._(this._database, this._cache);

  static Future<SqliteMealRepository> open() async {
    final appDatabase = await AppDatabase.open();
    final database = appDatabase.database;

    final rows = await database.query(
      _tableMeals,
      where: 'deletedAt IS NULL',
      orderBy: 'timestamp DESC',
    );
    final meals = rows.map(Meal.fromMap).toList();

    return SqliteMealRepository._(database, meals);
  }

  Future<void> reload() async {
    final rows = await _database.query(
      _tableMeals,
      where: 'deletedAt IS NULL',
      orderBy: 'timestamp DESC',
    );
    _cache
      ..clear()
      ..addAll(rows.map(Meal.fromMap));
  }

  @override
  Future<void> add(Meal meal) async {
    final persisted = meal.copyWith(modifiedAt: DateTime.now().toUtc());
    await _writeWithOutbox(persisted, SyncOperationType.upsert);
    _cache
      ..removeWhere((existing) => existing.id == meal.id)
      ..add(persisted)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> update(Meal meal) async {
    final persisted = meal.copyWith(modifiedAt: DateTime.now().toUtc());
    await _writeWithOutbox(persisted, SyncOperationType.upsert);
    final index = _cache.indexWhere((existing) => existing.id == meal.id);
    if (index == -1) return;
    _cache[index] = persisted;
    _cache.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  List<Meal> getAll() => List.unmodifiable(_cache);

  @override
  Future<void> remove(String id) async {
    final index = _cache.indexWhere((meal) => meal.id == id);
    if (index == -1) return;
    final now = DateTime.now().toUtc();
    final tombstone = _cache[index].copyWith(
      modifiedAt: now,
      deletedAt: now,
    );
    await _writeWithOutbox(tombstone, SyncOperationType.delete);
    _cache.removeWhere((meal) => meal.id == id);
  }

  Future<void> _writeWithOutbox(Meal meal, SyncOperationType operation) async {
    final operationId = const Uuid().v4();
    await _database.transaction((txn) async {
      await txn.insert(
        _tableMeals,
        meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert('sync_outbox', {
        'operationId': operationId,
        'entityType': SyncEntityType.meal.name,
        'entityId': meal.id,
        'operation': operation.name,
        'occurredAt': meal.modifiedAt.toUtc().toIso8601String(),
        'ownerUserId': meal.ownerUserId,
        'status': 'pending',
        'attemptCount': 0,
        'payload':
            operation == SyncOperationType.upsert ? _mealPayload(meal) : null,
      });
    });
  }

  static String _mealPayload(Meal meal) {
    return jsonEncode({
      'description': meal.descricao,
      'originalDescription': meal.descricaoOriginal,
      'calories': meal.calorias,
      'mealAt': meal.timestamp.toUtc().toIso8601String(),
      'origin': meal.origem == MealOrigem.audio ? 'audio' : 'text',
      'aiConfidence': meal.aiConfidence,
      'note': meal.nota,
      'iconKey': meal.iconKey,
      'macronutrients': {
        'proteinGrams': meal.macronutrients?.protein.grams ?? 0,
        'carbohydrateGrams': meal.macronutrients?.carbs.grams ?? 0,
        'fatGrams': meal.macronutrients?.fat.grams ?? 0,
      },
    });
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
