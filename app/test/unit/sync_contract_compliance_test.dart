import 'package:calorie_counter_app/features/sync/sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializa request e interpreta exemplo compatível com OpenAPI', () {
    final request = SyncRequestDto(
      deviceId: '00000000-0000-0000-0000-000000000001',
      bootstrap: true,
      cursor: null,
      mutations: [
        SyncOperation(
          operationId: '00000000-0000-0000-0000-000000000002',
          entityType: SyncEntityType.meal,
          entityId: 'meal-1',
          operation: SyncOperationType.delete,
          occurredAt: DateTime.utc(2026),
        ),
      ],
    ).toJson();
    expect(request['bootstrap'], true);
    expect((request['mutations'] as List).single, isNot(contains('payload')));

    final response = SyncResponseDto.fromJson({
      'results': <Object?>[],
      'changes': [
        {
          'sequence': 1,
          'entityType': 'meal',
          'entityId': 'meal-1',
          'operation': 'delete',
          'modifiedAt': '2026-01-01T00:00:00Z',
        }
      ],
      'nextCursor': '1',
      'hasMore': false,
      'premiumActive': true,
    }).page;
    expect(response.changes.single.operation, SyncOperationType.delete);
    expect(response.premiumActive, isTrue);
  });
}
