import 'sync_types.dart';

class SyncOperation {
  final String operationId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operation;
  final DateTime occurredAt;
  final String? ownerUserId;
  final SyncOperationStatus status;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? lastErrorCode;
  final Map<String, Object?>? payload;

  const SyncOperation({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.occurredAt,
    this.ownerUserId,
    this.status = SyncOperationStatus.pending,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastErrorCode,
    this.payload,
  }) : assert(attemptCount >= 0);

  SyncOperation copyWith({
    String? ownerUserId,
    SyncOperationStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? lastErrorCode,
  }) =>
      SyncOperation(
        operationId: operationId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        occurredAt: occurredAt.toUtc(),
        ownerUserId: ownerUserId ?? this.ownerUserId,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        lastErrorCode: lastErrorCode ?? this.lastErrorCode,
        payload: payload,
      );
}

class SyncCheckpoint {
  final String ownerUserId;
  final String deviceId;
  final String? cursor;
  final BootstrapState bootstrapState;
  final DateTime? lastSuccessAt;
  final String? lastErrorCode;
  final bool cleanupPending;

  const SyncCheckpoint({
    required this.ownerUserId,
    required this.deviceId,
    this.cursor,
    this.bootstrapState = BootstrapState.notStarted,
    this.lastSuccessAt,
    this.lastErrorCode,
    this.cleanupPending = false,
  });

  SyncCheckpoint copyWith({
    String? cursor,
    BootstrapState? bootstrapState,
    DateTime? lastSuccessAt,
    String? lastErrorCode,
    bool? cleanupPending,
  }) =>
      SyncCheckpoint(
        ownerUserId: ownerUserId,
        deviceId: deviceId,
        cursor: cursor ?? this.cursor,
        bootstrapState: bootstrapState ?? this.bootstrapState,
        lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
        lastErrorCode: lastErrorCode ?? this.lastErrorCode,
        cleanupPending: cleanupPending ?? this.cleanupPending,
      );
}

class RemoteChange {
  final int sequence;
  final SyncEntityType entityType;
  final String entityId;
  final SyncOperationType operation;
  final DateTime modifiedAt;
  final Map<String, Object?>? payload;
  final String operationId;

  const RemoteChange({
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.modifiedAt,
    required this.operationId,
    this.payload,
  }) : assert(sequence >= 1);
}

class MutationResult {
  final String operationId;
  final String status;
  final RemoteChange canonicalChange;

  const MutationResult({
    required this.operationId,
    required this.status,
    required this.canonicalChange,
  });
}

class SyncPage {
  final List<MutationResult> results;
  final List<RemoteChange> changes;
  final String nextCursor;
  final bool hasMore;
  final bool premiumActive;

  const SyncPage({
    required this.results,
    required this.changes,
    required this.nextCursor,
    required this.hasMore,
    required this.premiumActive,
  });
}
