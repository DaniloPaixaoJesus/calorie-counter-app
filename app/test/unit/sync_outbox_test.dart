import 'package:calorie_counter_app/features/sync/sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recupera sending e remove somente após ack', () async {
    final store = InMemorySyncStore();
    final operation = SyncOperation(
      operationId: 'op-1',
      entityType: SyncEntityType.meal,
      entityId: 'meal-1',
      operation: SyncOperationType.upsert,
      occurredAt: DateTime.utc(2026),
    );
    await store.enqueue(operation);
    await store.markSending(['op-1'], DateTime.utc(2026, 1, 2));

    expect(store.operations['op-1']!.status, SyncOperationStatus.sending);
    expect(store.operations['op-1']!.attemptCount, 1);

    await store.recoverSending();
    expect(store.operations['op-1']!.status, SyncOperationStatus.pending);

    await store.acknowledge(['op-1']);
    expect(store.operations, isEmpty);
  });

  test('falha mantém operação para nova tentativa', () async {
    final store = InMemorySyncStore();
    await store.enqueue(SyncOperation(
      operationId: 'op-2',
      entityType: SyncEntityType.nutritionGoal,
      entityId: NutritionGoal.canonicalId,
      operation: SyncOperationType.delete,
      occurredAt: DateTime.utc(2026),
    ));

    await store.fail(['op-2'], 'NETWORK_UNAVAILABLE');
    final pending = await store.pendingOperations();
    expect(pending.single.lastErrorCode, 'NETWORK_UNAVAILABLE');
  });
}
