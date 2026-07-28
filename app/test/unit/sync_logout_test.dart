import 'package:calorie_counter_app/features/sync/application/logout_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cleaner implements LogoutDataCleaner {
  final events = <String>[];
  @override
  Future<void> markCleanupPending() async => events.add('mark');
  @override
  Future<void> clearAccountData() async => events.add('data');
  @override
  Future<void> clearCleanupPending() async => events.add('done');
}

void main() {
  test('flush sem pendências limpa dados antes de desconectar', () async {
    final cleaner = _Cleaner();
    final events = cleaner.events;
    final coordinator = LogoutCoordinator(
      flush: () async {
        events.add('flush');
        return true;
      },
      pendingCount: () async => 0,
      cleaner: cleaner,
      clearSession: () async => events.add('session'),
      disconnectIdentityProvider: () async => events.add('google'),
    );

    expect(await coordinator.prepare(), LogoutResult.completed);
    expect(events, ['flush', 'mark', 'data', 'session', 'done', 'google']);
  });

  test('pendências exigem confirmação e cancelamento preserva dados', () async {
    final cleaner = _Cleaner();
    final coordinator = LogoutCoordinator(
      flush: () async => false,
      pendingCount: () async => 3,
      cleaner: cleaner,
      clearSession: () async {},
      disconnectIdentityProvider: () async {},
    );

    expect(await coordinator.prepare(), LogoutResult.confirmationRequired);
    expect(await coordinator.cancel(), LogoutResult.cancelled);
    expect(cleaner.events, isEmpty);
  });
}
