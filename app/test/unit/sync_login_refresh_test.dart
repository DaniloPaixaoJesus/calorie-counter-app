import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/sync/sync.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session implements SyncSession {
  @override
  String? get bearerToken => 'token';

  @override
  bool get isPremiumActive => true;

  @override
  String? get userId => 'user-1';
}

class _RemoteMealGateway implements SyncGateway {
  @override
  Future<SyncPage> synchronize({
    required String userId,
    required String bearerToken,
    required String deviceId,
    required bool bootstrap,
    required String? cursor,
    required List<SyncOperation> mutations,
  }) async {
    return SyncPage(
      results: const [],
      changes: [
        RemoteChange(
          sequence: 1,
          entityType: SyncEntityType.meal,
          entityId: 'remote-meal',
          operation: SyncOperationType.upsert,
          modifiedAt: DateTime.utc(2026, 7, 27, 12),
          operationId: 'remote-operation',
          payload: const {
            'description': 'Refeição remota',
            'calories': 350,
            'mealAt': '2026-07-27T12:00:00Z',
            'origin': 'text',
            'iconKey': 'meal',
            'macronutrients': {
              'proteinGrams': 10,
              'carbohydrateGrams': 40,
              'fatGrams': 12,
            },
          },
        ),
      ],
      nextCursor: '1',
      hasMore: false,
      premiumActive: true,
    );
  }
}

void main() {
  test('bootstrap notifica a Home após aplicar refeições remotas', () async {
    final viewModel = HomeViewModel(
      repository: InMemoryRepository(),
      aiAdapter: const AiAdapterMock(),
    );
    var notifications = 0;
    viewModel.addListener(() => notifications++);
    final coordinator = SyncCoordinator(
      store: InMemorySyncStore(),
      gateway: _RemoteMealGateway(),
      session: _Session(),
      deviceId: '00000000-0000-0000-0000-000000000001',
      onDataChanged: () async => viewModel.refreshMeals(),
    );

    expect(await coordinator.bootstrap(), isTrue);
    expect(notifications, greaterThan(0));
  });
}
