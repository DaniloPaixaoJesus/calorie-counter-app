import 'package:calorie_counter_app/features/sync/sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza instantes e usa operationId no desempate LWW', () {
    final local = DateTime.parse('2026-01-01T09:00:00-03:00');
    final utc = DateTime.parse('2026-01-01T12:00:00Z');

    expect(local.syncUtc, utc);
    expect(
      compareSyncVersions(
        leftModifiedAt: local,
        leftOperationId: 'b',
        rightModifiedAt: utc,
        rightOperationId: 'a',
      ),
      greaterThan(0),
    );
  });

  test('modelos preservam tombstone e identidade estável', () {
    final deletedAt = DateTime.utc(2026, 1, 2);
    final goal = NutritionGoal(
      targetValue: 2000,
      effectiveFrom: DateTime(2026, 1, 1),
      modifiedAt: deletedAt,
      deletedAt: deletedAt,
    );

    expect(goal.id, NutritionGoal.canonicalId);
    expect(goal.isDeleted, isTrue);
    expect(goal.toMap()['deletedAt'], deletedAt.toIso8601String());
  });
}
