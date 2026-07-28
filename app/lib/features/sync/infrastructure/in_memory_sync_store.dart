import '../../../models/meal.dart';
import '../domain/nutrition_goal.dart';
import '../domain/sync_models.dart';
import '../domain/sync_ports.dart';
import '../domain/sync_types.dart';

class InMemorySyncStore implements SyncStore {
  final Map<String, Meal> meals = {};
  final Map<String, NutritionGoal> goals = {};
  final Map<String, SyncOperation> operations = {};
  final Map<String, SyncCheckpoint> checkpoints = {};

  @override
  Future<T> transaction<T>(Future<T> Function() action) => action();

  @override
  Future<void> enqueue(SyncOperation operation) async {
    operations[operation.operationId] = operation;
  }

  @override
  Future<List<SyncOperation>> pendingOperations({int limit = 100}) async =>
      operations.values
          .where((item) =>
              item.status == SyncOperationStatus.pending ||
              item.status == SyncOperationStatus.failed)
          .take(limit)
          .toList();

  @override
  Future<void> markSending(List<String> ids, DateTime attemptedAt) async {
    for (final id in ids) {
      final item = operations[id];
      if (item != null) {
        operations[id] = item.copyWith(
          status: SyncOperationStatus.sending,
          attemptCount: item.attemptCount + 1,
          lastAttemptAt: attemptedAt.toUtc(),
        );
      }
    }
  }

  @override
  Future<void> acknowledge(List<String> ids) async {
    for (final id in ids) {
      operations.remove(id);
    }
  }

  @override
  Future<void> fail(List<String> ids, String errorCode) async {
    for (final id in ids) {
      final item = operations[id];
      if (item != null) {
        operations[id] = item.copyWith(
            status: SyncOperationStatus.failed, lastErrorCode: errorCode);
      }
    }
  }

  @override
  Future<void> recoverSending() async {
    for (final entry in operations.entries.toList()) {
      if (entry.value.status == SyncOperationStatus.sending) {
        operations[entry.key] =
            entry.value.copyWith(status: SyncOperationStatus.pending);
      }
    }
  }

  @override
  Future<SyncCheckpoint?> checkpoint(String ownerUserId) async =>
      checkpoints[ownerUserId];

  @override
  Future<void> saveCheckpoint(SyncCheckpoint checkpoint) async {
    checkpoints[checkpoint.ownerUserId] = checkpoint;
  }

  @override
  Future<void> upsertMeal(Meal meal) async => meals[meal.id] = meal;

  @override
  Future<void> upsertGoal(NutritionGoal goal) async => goals[goal.id] = goal;

  @override
  Future<NutritionGoal?> goal(String id) async {
    final value = goals[id];
    return value == null || value.isDeleted ? null : value;
  }

  @override
  Future<void> associateAnonymousData(String ownerUserId) async {
    meals.updateAll((_, meal) => meal.ownerUserId == null
        ? meal.copyWith(
            ownerUserId: ownerUserId,
            modifiedAt: meal.modifiedAt,
          )
        : meal);
    goals.updateAll((_, goal) => goal.ownerUserId == null
        ? goal.copyWith(ownerUserId: ownerUserId)
        : goal);
    operations.updateAll((_, operation) => operation.ownerUserId == null
        ? operation.copyWith(ownerUserId: ownerUserId)
        : operation);
  }

  @override
  Future<void> applyRemoteChanges(
    List<RemoteChange> changes, {
    required bool remoteWins,
    required String ownerUserId,
  }) async {
    for (final change in changes) {
      if (change.entityType == SyncEntityType.meal) {
        final local = meals[change.entityId];
        if (!remoteWins &&
            local != null &&
            local.modifiedAt.toUtc().isAfter(change.modifiedAt.toUtc())) {
          continue;
        }
        meals[change.entityId] = _mealFromChange(change, ownerUserId);
      } else {
        final local = goals[change.entityId];
        if (!remoteWins &&
            local != null &&
            local.modifiedAt.toUtc().isAfter(change.modifiedAt.toUtc())) {
          continue;
        }
        goals[change.entityId] = _goalFromChange(change, ownerUserId);
      }
    }
  }
}

Meal _mealFromChange(RemoteChange change, String? ownerUserId) {
  final payload = change.payload ?? const <String, Object?>{};
  final existingTimestamp = payload['mealAt'] as String?;
  return Meal.fromMap({
    'id': change.entityId,
    'descricao': payload['description'] as String? ?? 'Refeição removida',
    'descricaoOriginal': payload['originalDescription'],
    'calorias': payload['calories'] as num? ?? 0,
    'timestamp':
        existingTimestamp ?? change.modifiedAt.toUtc().toIso8601String(),
    'origem': payload['origin'] == 'audio' ? 'audio' : 'texto',
    'aiConfidence': payload['aiConfidence'],
    'nota': payload['note'],
    'iconKey': payload['iconKey'] as String? ?? 'default',
    'proteinGrams':
        (payload['macronutrients'] as Map?)?['proteinGrams'] as num?,
    'carbohydrateGrams':
        (payload['macronutrients'] as Map?)?['carbohydrateGrams'] as num?,
    'fatGrams': (payload['macronutrients'] as Map?)?['fatGrams'] as num?,
    'modifiedAt': change.modifiedAt.toUtc().toIso8601String(),
    'deletedAt': change.operation == SyncOperationType.delete
        ? change.modifiedAt.toUtc().toIso8601String()
        : null,
    'ownerUserId': ownerUserId,
  });
}

NutritionGoal _goalFromChange(RemoteChange change, String? ownerUserId) {
  final payload = change.payload ?? const <String, Object?>{};
  return NutritionGoal(
    targetValue: (payload['targetValue'] as num?)?.toInt() ?? 2000,
    effectiveFrom:
        DateTime.parse(payload['effectiveFrom'] as String? ?? '1970-01-01'),
    effectiveUntil: payload['effectiveUntil'] == null
        ? null
        : DateTime.parse(payload['effectiveUntil'] as String),
    modifiedAt: change.modifiedAt.toUtc(),
    deletedAt: change.operation == SyncOperationType.delete
        ? change.modifiedAt.toUtc()
        : null,
    ownerUserId: ownerUserId,
  );
}
