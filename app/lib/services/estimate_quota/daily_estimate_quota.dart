import 'package:calorie_counter_app/utils/datetime_extensions.dart';

class DailyEstimateQuota {
  final DateTime date;
  final int usedCount;

  DailyEstimateQuota({
    required DateTime date,
    required this.usedCount,
  }) : date = date.toLocalDate();
}
