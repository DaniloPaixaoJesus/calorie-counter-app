import '../../../models/meal.dart';
import 'nutrition_goal.dart';
import 'sync_models.dart';

abstract interface class SyncClock {
  DateTime now();
}

class SystemSyncClock implements SyncClock {
  const SystemSyncClock();
  @override
  DateTime now() => DateTime.now().toUtc();
}

abstract interface class SyncStore {
  Future<T> transaction<T>(Future<T> Function() action);
  Future<List<SyncOperation>> pendingOperations({int limit = 100});
  Future<void> markSending(List<String> operationIds, DateTime attemptedAt);
  Future<void> acknowledge(List<String> operationIds);
  Future<void> fail(List<String> operationIds, String errorCode);
  Future<void> recoverSending();
  Future<SyncCheckpoint?> checkpoint(String ownerUserId);
  Future<void> saveCheckpoint(SyncCheckpoint checkpoint);
  Future<void> applyRemoteChanges(
    List<RemoteChange> changes, {
    required bool remoteWins,
    required String ownerUserId,
  });
  Future<void> associateAnonymousData(String ownerUserId);
  Future<void> enqueue(SyncOperation operation);
  Future<void> upsertMeal(Meal meal);
  Future<void> upsertGoal(NutritionGoal goal);
  Future<NutritionGoal?> goal(String id);
}

abstract interface class SyncGateway {
  Future<SyncPage> synchronize({
    required String userId,
    required String bearerToken,
    required String deviceId,
    required bool bootstrap,
    required String? cursor,
    required List<SyncOperation> mutations,
  });
}

abstract interface class SyncSession {
  String? get userId;
  String? get bearerToken;
  bool get isPremiumActive;
}
