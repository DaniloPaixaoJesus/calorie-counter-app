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

  Future<void> activatePremium({
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
  }) async {
    final trimmedName = userName?.trim();
    final trimmedEmail = userEmail?.trim();
    final trimmedPhoto = userPhotoUrl?.trim();

    await _save(
      _settings.copyWith(
        selectedPlan: AppPlan.premium,
        isPremium: true,
        userLogged: true,
        userName: (trimmedName == null || trimmedName.isEmpty)
            ? 'Usuário Premium'
            : trimmedName,
        userEmail: (trimmedEmail == null || trimmedEmail.isEmpty)
            ? null
            : trimmedEmail,
        userPhotoAssetPath: (trimmedPhoto == null || trimmedPhoto.isEmpty)
            ? null
            : trimmedPhoto,
        remainingDailyEstimations: freeDailyEstimateLimit,
        lastResetDate: DateTime.now(),
      ),
    );
  }

  Future<void> logout() async {
    await _save(
      _settings.copyWith(
        selectedPlan: AppPlan.free,
        isPremium: false,
        userLogged: false,
        userName: null,
        userEmail: null,
        userPhotoAssetPath: null,
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
