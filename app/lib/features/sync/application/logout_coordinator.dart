import 'package:sqflite/sqflite.dart';

import '../../../services/repository/app_database.dart';

enum LogoutResult { completed, confirmationRequired, cancelled }

abstract interface class LogoutDataCleaner {
  Future<void> markCleanupPending();
  Future<void> clearAccountData();
  Future<void> clearCleanupPending();
}

class SqliteLogoutDataCleaner implements LogoutDataCleaner {
  final AppDatabase appDatabase;
  const SqliteLogoutDataCleaner(this.appDatabase);

  @override
  Future<void> markCleanupPending() => appDatabase.database.execute(
        'UPDATE sync_checkpoints SET cleanupPending = 1',
      );

  @override
  Future<void> clearAccountData() =>
      appDatabase.database.transaction((txn) async {
        for (final table in [
          'meals',
          'nutrition_goals',
          'sync_outbox',
          'app_settings',
        ]) {
          await txn.delete(table);
        }
      });

  @override
  Future<void> clearCleanupPending() =>
      appDatabase.database.delete('sync_checkpoints');

  Future<void> resumeInterruptedCleanup() async {
    final pending = Sqflite.firstIntValue(await appDatabase.database.rawQuery(
          'SELECT COUNT(*) FROM sync_checkpoints WHERE cleanupPending = 1',
        )) ??
        0;
    if (pending == 0) return;
    await clearAccountData();
    await clearCleanupPending();
  }
}

class LogoutCoordinator {
  final Future<bool> Function() flush;
  final Future<int> Function() pendingCount;
  final LogoutDataCleaner cleaner;
  final Future<void> Function() clearSession;
  final Future<void> Function() disconnectIdentityProvider;

  const LogoutCoordinator({
    required this.flush,
    required this.pendingCount,
    required this.cleaner,
    required this.clearSession,
    required this.disconnectIdentityProvider,
  });

  Future<LogoutResult> prepare() async {
    await flush();
    if (await pendingCount() == 0) {
      return complete();
    }
    return LogoutResult.confirmationRequired;
  }

  Future<LogoutResult> cancel() async => LogoutResult.cancelled;

  Future<LogoutResult> complete() async {
    await cleaner.markCleanupPending();
    await cleaner.clearAccountData();
    await clearSession();
    await cleaner.clearCleanupPending();
    await disconnectIdentityProvider();
    return LogoutResult.completed;
  }
}
