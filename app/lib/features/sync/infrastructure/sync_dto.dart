import '../domain/sync_models.dart';
import '../domain/sync_types.dart';

class SyncRequestDto {
  final String deviceId;
  final bool bootstrap;
  final String? cursor;
  final List<SyncOperation> mutations;

  const SyncRequestDto({
    required this.deviceId,
    required this.bootstrap,
    required this.cursor,
    required this.mutations,
  });

  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'bootstrap': bootstrap,
        'cursor': cursor,
        'mutations': mutations.map(_mutationToJson).toList(),
      };

  static Map<String, Object?> _mutationToJson(SyncOperation value) => {
        'operationId': value.operationId,
        'entityType': value.entityType.name,
        'entityId': value.entityId,
        'operation': value.operation.name,
        'modifiedAt': value.occurredAt.toUtc().toIso8601String(),
        if (value.operation == SyncOperationType.upsert)
          'payload': value.payload,
      };
}

class SyncResponseDto {
  final SyncPage page;
  const SyncResponseDto(this.page);

  factory SyncResponseDto.fromJson(Map<String, Object?> json) {
    final results = (json['results'] as List? ?? const [])
        .map((item) => (item as Map).cast<String, Object?>())
        .map((item) => MutationResult(
              operationId: item['operationId'] as String,
              status: item['status'] as String,
              canonicalChange: _change(
                (item['canonicalChange'] as Map).cast<String, Object?>(),
              ),
            ))
        .toList();
    final changes = (json['changes'] as List? ?? const [])
        .map((item) => _change((item as Map).cast<String, Object?>()))
        .toList();
    return SyncResponseDto(SyncPage(
      results: results,
      changes: changes,
      nextCursor: json['nextCursor'] as String,
      hasMore: json['hasMore'] as bool,
      premiumActive: json['premiumActive'] as bool,
    ));
  }

  static RemoteChange _change(Map<String, Object?> json) => RemoteChange(
        sequence: (json['sequence'] as num).toInt(),
        entityType: SyncEntityType.values.byName(json['entityType'] as String),
        entityId: json['entityId'] as String,
        operation: SyncOperationType.values.byName(json['operation'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String).toUtc(),
        operationId: json['operationId'] as String? ??
            'remote-${json['sequence']}-${json['entityId']}',
        payload: json['payload'] == null
            ? null
            : (json['payload'] as Map).cast<String, Object?>(),
      );
}
