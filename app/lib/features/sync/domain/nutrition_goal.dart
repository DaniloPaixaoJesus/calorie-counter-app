class NutritionGoal {
  static const canonicalId = 'daily-calorie';

  final String id;
  final int targetValue;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final DateTime modifiedAt;
  final DateTime? deletedAt;
  final String? ownerUserId;

  NutritionGoal({
    this.id = canonicalId,
    required this.targetValue,
    required this.effectiveFrom,
    required this.modifiedAt,
    this.effectiveUntil,
    this.deletedAt,
    this.ownerUserId,
  })  : assert(targetValue >= 800 && targetValue <= 6000),
        assert(
            effectiveUntil == null || !effectiveUntil.isBefore(effectiveFrom));

  bool get isDeleted => deletedAt != null;

  NutritionGoal copyWith({
    int? targetValue,
    DateTime? effectiveFrom,
    DateTime? effectiveUntil,
    DateTime? modifiedAt,
    DateTime? deletedAt,
    String? ownerUserId,
  }) =>
      NutritionGoal(
        id: id,
        targetValue: targetValue ?? this.targetValue,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        effectiveUntil: effectiveUntil ?? this.effectiveUntil,
        modifiedAt: (modifiedAt ?? this.modifiedAt).toUtc(),
        deletedAt: deletedAt?.toUtc() ?? this.deletedAt,
        ownerUserId: ownerUserId ?? this.ownerUserId,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'targetValue': targetValue,
        'effectiveFrom': _date(effectiveFrom),
        'effectiveUntil':
            effectiveUntil == null ? null : _date(effectiveUntil!),
        'modifiedAt': modifiedAt.toUtc().toIso8601String(),
        'deletedAt': deletedAt?.toUtc().toIso8601String(),
        'ownerUserId': ownerUserId,
      };

  factory NutritionGoal.fromMap(Map<String, Object?> map) => NutritionGoal(
        id: map['id'] as String? ?? canonicalId,
        targetValue: (map['targetValue'] as num).toInt(),
        effectiveFrom: DateTime.parse(map['effectiveFrom'] as String),
        effectiveUntil: map['effectiveUntil'] == null
            ? null
            : DateTime.parse(map['effectiveUntil'] as String),
        modifiedAt: DateTime.parse(map['modifiedAt'] as String).toUtc(),
        deletedAt: map['deletedAt'] == null
            ? null
            : DateTime.parse(map['deletedAt'] as String).toUtc(),
        ownerUserId: map['ownerUserId'] as String?,
      );

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
