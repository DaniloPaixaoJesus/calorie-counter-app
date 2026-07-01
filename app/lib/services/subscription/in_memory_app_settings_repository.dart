import 'package:flutter/foundation.dart';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'app_settings_repository.dart';

class InMemoryAppSettingsRepository implements AppSettingsRepository {
  AppSettings _settings = AppSettings.empty;

  @override
  Future<AppSettings> load() => SynchronousFuture(_settings);

  @override
  Future<void> save(AppSettings settings) {
    _settings = settings;
    return SynchronousFuture<void>(null);
  }
}
