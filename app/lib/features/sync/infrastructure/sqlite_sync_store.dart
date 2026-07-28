import 'package:sqflite/sqflite.dart';
import 'dart:convert';

import '../../../models/meal.dart';
import '../../../services/repository/app_database.dart';
import '../domain/nutrition_goal.dart';
import '../domain/sync_models.dart';
import '../domain/sync_ports.dart';
import '../domain/sync_types.dart';

class SqliteSyncStore implements SyncStore {
  final AppDatabase appDatabase;
  DatabaseExecutor? _executor;

  SqliteSyncStore(this.appDatabase);
  DatabaseExecutor get _db => _executor ?? appDatabase.database;

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      appDatabase.database.transaction((txn) async {
        final previous = _executor;
        _executor = txn;
        try {
          return await action();
        } finally {
          _executor = previous;
        }
      });

  @override
  Future<void> upsertMeal(Meal meal) => _db.insert(
        'meals',
        meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> upsertGoal(NutritionGoal goal) => _db.insert(
        'nutrition_goals',
        goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<NutritionGoal?> goal(String id) async {
    final rows = await _db.query(
      'nutrition_goals',
      where: 'id = ? AND deletedAt IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : NutritionGoal.fromMap(rows.single);
  }

  @override
  Future<void> enqueue(SyncOperation operation) => _db.insert(
        'sync_outbox',
        _operationToMap(operation),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<List<SyncOperation>> pendingOperations({int limit = 100}) async {
    final rows = await _db.query(
      'sync_outbox',
      where: 'status IN (?, ?)',
      whereArgs: [
        SyncOperationStatus.pending.name,
        SyncOperationStatus.failed.name
      ],
      orderBy: 'occurredAt ASC, operationId ASC',
      limit: limit,
    );
    return rows.map(_operationFromMap).toList();
  }

  @override
  Future<void> markSending(List<String> ids, DateTime attemptedAt) async {
    for (final id in ids) {
      await _db.rawUpdate(
        'UPDATE sync_outbox SET status = ?, attemptCount = attemptCount + 1, '
        'lastAttemptAt = ?, lastErrorCode = NULL WHERE operationId = ?',
        [
          SyncOperationStatus.sending.name,
          attemptedAt.toUtc().toIso8601String(),
          id
        ],
      );
    }
  }

  @override
  Future<void> acknowledge(List<String> ids) async {
    for (final id in ids) {
      await _db.delete(
        'sync_outbox',
        where: 'operationId = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> fail(List<String> ids, String errorCode) async {
    for (final id in ids) {
      await _db.update(
        'sync_outbox',
        {'status': SyncOperationStatus.failed.name, 'lastErrorCode': errorCode},
        where: 'operationId = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> recoverSending() => _db.update(
        'sync_outbox',
        {'status': SyncOperationStatus.pending.name},
        where: 'status = ?',
        whereArgs: [SyncOperationStatus.sending.name],
      );

  @override
  Future<SyncCheckpoint?> checkpoint(String ownerUserId) async {
    final rows = await _db.query('sync_checkpoints',
        where: 'ownerUserId = ?', whereArgs: [ownerUserId], limit: 1);
    return rows.isEmpty ? null : _checkpointFromMap(rows.single);
  }

  @override
  Future<void> saveCheckpoint(SyncCheckpoint value) => _db.insert(
        'sync_checkpoints',
        _checkpointToMap(value),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> associateAnonymousData(String ownerUserId) async {
    await _db.update('meals', {'ownerUserId': ownerUserId},
        where: 'ownerUserId IS NULL');
    await _db.update('nutrition_goals', {'ownerUserId': ownerUserId},
        where: 'ownerUserId IS NULL');
    await _db.update('sync_outbox', {'ownerUserId': ownerUserId},
        where: 'ownerUserId IS NULL');
  }

  @override
  Future<void> applyRemoteChanges(
    List<RemoteChange> changes, {
    required bool remoteWins,
    required String ownerUserId,
  }) async {
    for (final change in changes) {
      if (change.entityType == SyncEntityType.meal) {
        final rows = await _db.query('meals',
            where: 'id = ?', whereArgs: [change.entityId], limit: 1);
        if (!remoteWins &&
            rows.isNotEmpty &&
            DateTime.parse(rows.single['modifiedAt'] as String)
                .toUtc()
                .isAfter(change.modifiedAt.toUtc())) {
          continue;
        }
        await upsertMeal(_mealFromChange(change, ownerUserId));
      } else {
        final rows = await _db.query('nutrition_goals',
            where: 'id = ?', whereArgs: [change.entityId], limit: 1);
        if (!remoteWins &&
            rows.isNotEmpty &&
            DateTime.parse(rows.single['modifiedAt'] as String)
                .toUtc()
                .isAfter(change.modifiedAt.toUtc())) {
          continue;
        }
        await upsertGoal(_goalFromChange(change, ownerUserId));
      }
    }
  }

  static Map<String, Object?> _operationToMap(SyncOperation value) => {
        'operationId': value.operationId,
        'entityType': value.entityType.name,
        'entityId': value.entityId,
        'operation': value.operation.name,
        'occurredAt': value.occurredAt.toUtc().toIso8601String(),
        'ownerUserId': value.ownerUserId,
        'status': value.status.name,
        'attemptCount': value.attemptCount,
        'lastAttemptAt': value.lastAttemptAt?.toUtc().toIso8601String(),
        'lastErrorCode': value.lastErrorCode,
        'payload': value.payload == null ? null : jsonEncode(value.payload),
      };

  static SyncOperation _operationFromMap(Map<String, Object?> map) =>
      SyncOperation(
        operationId: map['operationId'] as String,
        entityType: SyncEntityType.values.byName(map['entityType'] as String),
        entityId: map['entityId'] as String,
        operation: SyncOperationType.values.byName(map['operation'] as String),
        occurredAt: DateTime.parse(map['occurredAt'] as String).toUtc(),
        ownerUserId: map['ownerUserId'] as String?,
        status: SyncOperationStatus.values.byName(map['status'] as String),
        attemptCount: (map['attemptCount'] as num).toInt(),
        lastAttemptAt: map['lastAttemptAt'] == null
            ? null
            : DateTime.parse(map['lastAttemptAt'] as String).toUtc(),
        lastErrorCode: map['lastErrorCode'] as String?,
        payload: map['payload'] == null
            ? null
            : (jsonDecode(map['payload'] as String) as Map)
                .cast<String, Object?>(),
      );

  static Map<String, Object?> _checkpointToMap(SyncCheckpoint value) => {
        'ownerUserId': value.ownerUserId,
        'deviceId': value.deviceId,
        'cursor': value.cursor,
        'bootstrapState': value.bootstrapState.name,
        'lastSuccessAt': value.lastSuccessAt?.toUtc().toIso8601String(),
        'lastErrorCode': value.lastErrorCode,
        'cleanupPending': value.cleanupPending ? 1 : 0,
      };

  static SyncCheckpoint _checkpointFromMap(Map<String, Object?> map) =>
      SyncCheckpoint(
        ownerUserId: map['ownerUserId'] as String,
        deviceId: map['deviceId'] as String,
        cursor: map['cursor'] as String?,
        bootstrapState:
            BootstrapState.values.byName(map['bootstrapState'] as String),
        lastSuccessAt: map['lastSuccessAt'] == null
            ? null
            : DateTime.parse(map['lastSuccessAt'] as String).toUtc(),
        lastErrorCode: map['lastErrorCode'] as String?,
        cleanupPending: (map['cleanupPending'] as num).toInt() == 1,
      );
}

Meal _mealFromChange(RemoteChange change, String ownerUserId) {
  final p = change.payload ?? const <String, Object?>{};
  final macros = p['macronutrients'] as Map?;
  return Meal.fromMap({
    'id': change.entityId,
    'descricao': p['description'] as String? ?? 'Refeição removida',
    'descricaoOriginal': p['originalDescription'],
    'calorias': p['calories'] as num? ?? 0,
    'timestamp': p['mealAt'] as String? ?? change.modifiedAt.toIso8601String(),
    'origem': p['origin'] == 'audio' ? 'audio' : 'texto',
    'aiConfidence': p['aiConfidence'],
    'nota': p['note'],
    'iconKey': p['iconKey'] as String? ?? 'default',
    'proteinGrams': macros?['proteinGrams'],
    'carbohydrateGrams': macros?['carbohydrateGrams'],
    'fatGrams': macros?['fatGrams'],
    'modifiedAt': change.modifiedAt.toUtc().toIso8601String(),
    'deletedAt': change.operation == SyncOperationType.delete
        ? change.modifiedAt.toUtc().toIso8601String()
        : null,
    'ownerUserId': ownerUserId,
  });
}

NutritionGoal _goalFromChange(RemoteChange change, String ownerUserId) {
  final p = change.payload ?? const <String, Object?>{};
  return NutritionGoal(
    targetValue: (p['targetValue'] as num?)?.toInt() ?? 2000,
    effectiveFrom:
        DateTime.parse(p['effectiveFrom'] as String? ?? '1970-01-01'),
    effectiveUntil: p['effectiveUntil'] == null
        ? null
        : DateTime.parse(p['effectiveUntil'] as String),
    modifiedAt: change.modifiedAt.toUtc(),
    deletedAt: change.operation == SyncOperationType.delete
        ? change.modifiedAt.toUtc()
        : null,
    ownerUserId: ownerUserId,
  );
}
