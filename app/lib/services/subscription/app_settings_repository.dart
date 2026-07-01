import 'package:calorie_counter_app/models/app_settings.dart';

abstract class AppSettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
