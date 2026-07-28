import 'package:calorie_counter_app/features/sync/sync.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session implements SyncSession {
  @override
  String? bearerToken = 'token';
  @override
  bool isPremiumActive = true;
  @override
  String? userId = 'user-1';
}

class _Gateway implements SyncGateway {
  int calls = 0;
  @override
  Future<SyncPage> synchronize({
    required String userId,
    required String bearerToken,
    required String deviceId,
    required bool bootstrap,
    required String? cursor,
    required List<SyncOperation> mutations,
  }) async {
    calls++;
    return SyncPage(
      results: const [],
      changes: [
        RemoteChange(
          sequence: calls,
          entityType: SyncEntityType.meal,
          entityId: 'shared',
          operation: SyncOperationType.upsert,
          modifiedAt: DateTime.utc(2025),
          operationId: 'remote-$calls',
          payload: const {
            'description': 'Versão remota',
            'calories': 300,
            'mealAt': '2025-01-01T12:00:00Z',
            'origin': 'text',
            'iconKey': 'default',
            'macronutrients': {
              'proteinGrams': 0,
              'carbohydrateGrams': 0,
              'fatGrams': 0,
            },
          },
        ),
      ],
      nextCursor: 'cursor-$calls',
      hasMore: calls == 1,
      premiumActive: true,
    );
  }
}

class _BatchGateway implements SyncGateway {
  final List<int> batchSizes = [];

  @override
  Future<SyncPage> synchronize({
    required String userId,
    required String bearerToken,
    required String deviceId,
    required bool bootstrap,
    required String? cursor,
    required List<SyncOperation> mutations,
  }) async {
    batchSizes.add(mutations.length);
    return SyncPage(
      results: mutations
          .map((operation) => MutationResult(
                operationId: operation.operationId,
                status: 'applied',
                canonicalChange: RemoteChange(
                  sequence: batchSizes.length,
                  entityType: operation.entityType,
                  entityId: operation.entityId,
                  operation: operation.operation,
                  modifiedAt: operation.occurredAt,
                  operationId: operation.operationId,
                  payload: operation.payload,
                ),
              ))
          .toList(),
      changes: const [],
      nextCursor: '${batchSizes.length}',
      hasMore: false,
      premiumActive: true,
    );
  }
}

void main() {
  test('bootstrap é paginado, remote-wins e associa anônimos ao final',
      () async {
    final store = InMemorySyncStore();
    await store.upsertMeal(Meal(
      id: 'shared',
      descricao: 'Local mais nova',
      calorias: 100,
      timestamp: DateTime.utc(2026),
      origem: MealOrigem.texto,
      modifiedAt: DateTime.utc(2026),
    ));
    final gateway = _Gateway();
    final coordinator = SyncCoordinator(
      store: store,
      gateway: gateway,
      session: _Session(),
      deviceId: '00000000-0000-0000-0000-000000000001',
    );

    expect(await coordinator.bootstrap(), isTrue);
    expect(gateway.calls, 2);
    expect(store.meals['shared']!.descricao, 'Versão remota');
    expect(store.meals['shared']!.ownerUserId, 'user-1');
    expect(
        store.checkpoints['user-1']!.bootstrapState, BootstrapState.completed);
  });

  test('envia todas as pendências em lotes de no máximo 100', () async {
    final store = InMemorySyncStore();
    for (var index = 0; index < 205; index++) {
      await store.enqueue(SyncOperation(
        operationId: 'operation-$index',
        entityType: SyncEntityType.meal,
        entityId: 'meal-$index',
        operation: SyncOperationType.delete,
        occurredAt: DateTime.utc(2026),
      ));
    }
    final gateway = _BatchGateway();
    final coordinator = SyncCoordinator(
      store: store,
      gateway: gateway,
      session: _Session(),
      deviceId: '00000000-0000-0000-0000-000000000001',
    );

    expect(await coordinator.bootstrap(), isTrue);
    expect(gateway.batchSizes, [100, 100, 5]);
    expect(store.operations, isEmpty);
  });
}
