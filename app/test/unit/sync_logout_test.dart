import 'package:calorie_counter_app/features/sync/application/logout_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

class _Cleaner implements LogoutDataCleaner {
  final events = <String>[];
  final localRecords = <String>['meal-1'];

  @override
  Future<void> markCleanupPending() async => events.add('mark');

  @override
  Future<void> clearAccountData() async {
    localRecords.clear();
    events.add('data');
  }

  @override
  Future<void> clearCleanupPending() async => events.add('done');
}

void main() {
  test('flush sem pendências encerra sessão e deixa a base local vazia',
      () async {
    final cleaner = _Cleaner();
    final events = cleaner.events;
    final coordinator = LogoutCoordinator(
      flush: () async {
        events.add('flush');
        return true;
      },
      pendingCount: () async => 0,
      cleaner: cleaner,
      clearSession: () async {
        expect(cleaner.localRecords, isEmpty);
        events.add('session');
      },
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
    expect(cleaner.localRecords, ['meal-1']);
  });
}
