enum SyncEntityType { meal, nutritionGoal }

enum SyncOperationType { upsert, delete }

enum SyncOperationStatus { pending, sending, acknowledged, failed }

enum SyncStatus {
  idle,
  pending,
  syncing,
  updated,
  pausedPremium,
  authenticationRequired,
  recoverableError,
}

enum BootstrapState { notStarted, running, completed }

extension SyncDateTime on DateTime {
  DateTime get syncUtc => isUtc ? this : toUtc();
}

int compareSyncVersions({
  required DateTime leftModifiedAt,
  required String leftOperationId,
  required DateTime rightModifiedAt,
  required String rightOperationId,
}) {
  final timeComparison =
      leftModifiedAt.syncUtc.compareTo(rightModifiedAt.syncUtc);
  if (timeComparison != 0) return timeComparison;
  return leftOperationId.compareTo(rightOperationId);
}
