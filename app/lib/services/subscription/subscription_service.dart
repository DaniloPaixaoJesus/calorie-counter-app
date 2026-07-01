import 'package:flutter/foundation.dart';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'app_settings_repository.dart';
import 'in_memory_app_settings_repository.dart';

class SubscriptionService extends ChangeNotifier {
  static const int freeDailyEstimateLimit = 3;

  final AppSettingsRepository _repository;
  AppSettings _settings;

  SubscriptionService._({
    required AppSettingsRepository repository,
    required AppSettings settings,
  })  : _repository = repository,
        _settings = settings;

  SubscriptionService.fallback()
      : _repository = InMemoryAppSettingsRepository(),
        _settings = const AppSettings(selectedPlan: AppPlan.free);

  static Future<SubscriptionService> load(
    AppSettingsRepository repository,
  ) async {
    return SubscriptionService._(
      repository: repository,
      settings: await repository.load(),
    );
  }

  AppSettings get settings => _settings;

  bool get hasSelectedPlan => _settings.hasSelectedPlan;

  bool get isPremium => _settings.isPremium && _settings.userLogged;

  bool get shouldShowAds => !isPremium;

  bool get hasUnlimitedEstimates => isPremium;

  Future<void> selectFreePlan() async {
    await _save(
      _settings.copyWith(
        selectedPlan: AppPlan.free,
        isPremium: false,
        userLogged: false,
        remainingDailyEstimations: freeDailyEstimateLimit,
        lastResetDate: DateTime.now(),
      ),
    );
  }

  Future<void> activatePremium() async {
    await _save(
      _settings.copyWith(
        selectedPlan: AppPlan.premium,
        isPremium: true,
        userLogged: true,
        userName: 'Marina Silva',
        userEmail: 'marina.silva@nutrity.app',
        userPhotoAssetPath: 'assets/branding/nutrity_icon.png',
        remainingDailyEstimations: freeDailyEstimateLimit,
        lastResetDate: DateTime.now(),
      ),
    );
  }

  Future<void> _save(AppSettings settings) async {
    _settings = settings;
    await _repository.save(settings);
    notifyListeners();
  }
}
