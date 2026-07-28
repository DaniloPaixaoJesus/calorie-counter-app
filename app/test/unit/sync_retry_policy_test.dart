import 'dart:async';

import 'package:calorie_counter_app/features/sync/sync.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session implements SyncSession {
  @override
  String? get bearerToken => 'token';

  @override
  bool get isPremiumActive => true;

  @override
  String? get userId => 'user-1';
}

class _OfflineThenOnlineGateway implements SyncGateway {
  final Completer<void> synchronized = Completer<void>();
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
    if (calls == 1) {
      throw const SyncGatewayException(
        code: 'NETWORK_UNAVAILABLE',
        retryable: true,
      );
    }
    if (!synchronized.isCompleted) synchronized.complete();
    return SyncPage(
      results: [
        for (final operation in mutations)
          MutationResult(
            operationId: operation.operationId,
            status: 'applied',
            canonicalChange: RemoteChange(
              sequence: 1,
              entityType: operation.entityType,
              entityId: operation.entityId,
              operation: operation.operation,
              modifiedAt: operation.occurredAt,
              operationId: operation.operationId,
              payload: operation.payload,
            ),
          ),
      ],
      changes: const [],
      nextCursor: '1',
      hasMore: false,
      premiumActive: true,
    );
  }
}

class _ControlledGateway implements SyncGateway {
  final Completer<void> requestStarted = Completer<void>();
  final Completer<void> release = Completer<void>();
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
    if (!requestStarted.isCompleted) requestStarted.complete();
    await release.future;
    return SyncPage(
      results: const [],
      changes: const [],
      nextCursor: '1',
      hasMore: false,
      premiumActive: true,
    );
  }
}

void main() {
  test('tenta imediatamente e aguarda conexão para esvaziar a outbox',
      () async {
    final store = InMemorySyncStore();
    await store.enqueue(SyncOperation(
      operationId: 'operation-1',
      entityType: SyncEntityType.meal,
      entityId: 'meal-1',
      operation: SyncOperationType.delete,
      occurredAt: DateTime.utc(2026),
    ));
    final gateway = _OfflineThenOnlineGateway();
    final coordinator = SyncCoordinator(
      store: store,
      gateway: gateway,
      session: _Session(),
      deviceId: '00000000-0000-0000-0000-000000000001',
    );
    final triggers = SyncTriggerService(
      coordinator: coordinator,
      initialBackoff: const Duration(milliseconds: 1),
      maximumBackoff: const Duration(milliseconds: 2),
    );

    await triggers.onMutation();

    expect(gateway.calls, 1);
    expect(store.operations, isNotEmpty);

    await gateway.synchronized.future.timeout(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(gateway.calls, 2);
    expect(store.operations, isEmpty);
    triggers.dispose();
  });

  test('flush do logout aguarda sincronização que já está em andamento',
      () async {
    final gateway = _ControlledGateway();
    final coordinator = SyncCoordinator(
      store: InMemorySyncStore(),
      gateway: gateway,
      session: _Session(),
      deviceId: '00000000-0000-0000-0000-000000000001',
    );

    final currentSync = coordinator.synchronize();
    await gateway.requestStarted.future;
    final logoutFlush = coordinator.flush();

    expect(gateway.calls, 1);
    expect(coordinator.isRunning, isTrue);

    gateway.release.complete();

    expect(await currentSync, isTrue);
    expect(await logoutFlush, isTrue);
    expect(coordinator.isRunning, isFalse);
  });
}
