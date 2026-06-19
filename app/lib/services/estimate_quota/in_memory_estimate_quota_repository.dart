import 'package:flutter/foundation.dart';

import 'daily_estimate_quota.dart';
import 'estimate_quota_repository.dart';

class InMemoryEstimateQuotaRepository implements EstimateQuotaRepository {
  final Map<String, int> _usedByDate = {};

  @override
  DailyEstimateQuota getForDate(DateTime date) {
    final key = _dateKey(date);
    return DailyEstimateQuota(
      date: date,
      usedCount: _usedByDate[key] ?? 0,
    );
  }

  @override
  Future<DailyEstimateQuota> increment(DateTime date) {
    final key = _dateKey(date);
    final nextCount = (_usedByDate[key] ?? 0) + 1;
    _usedByDate[key] = nextCount;

    return SynchronousFuture(
      DailyEstimateQuota(date: date, usedCount: nextCount),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
