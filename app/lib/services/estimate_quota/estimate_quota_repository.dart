import 'daily_estimate_quota.dart';

abstract class EstimateQuotaRepository {
  DailyEstimateQuota getForDate(DateTime date);

  Future<DailyEstimateQuota> increment(DateTime date);
}
