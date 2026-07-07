import 'package:flutter/foundation.dart';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/bff/user_bff_service.dart';
import 'app_settings_repository.dart';
import 'in_memory_app_settings_repository.dart';

class SubscriptionService extends ChangeNotifier {
  static const int freeDailyEstimateLimit = 3;

  final AppSettingsRepository _repository;
  final UserBffService? _userBffService;
  AppSettings _settings;

  SubscriptionService._({
    required AppSettingsRepository repository,
    required AppSettings settings,
    UserBffService? userBffService,
  })  : _repository = repository,
        _userBffService = userBffService,
        _settings = settings;

  SubscriptionService.fallback()
      : _repository = InMemoryAppSettingsRepository(),
        _userBffService = null,
        _settings = const AppSettings(selectedPlan: AppPlan.free);

  static Future<SubscriptionService> load(
    AppSettingsRepository repository, {
    UserBffService? userBffService,
  }) async {
    return SubscriptionService._(
      repository: repository,
      settings: await repository.load(),
      userBffService: userBffService,
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
    String? userId,
  }) async {
    final trimmedName = userName?.trim();
    final trimmedEmail = userEmail?.trim();
    final trimmedPhoto = userPhotoUrl?.trim();

    await _save(
      _settings.copyWith(
        selectedPlan: AppPlan.premium,
        isPremium: true,
        userLogged: true,
        userId: userId,
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

  Future<void> authenticatePremiumWithGoogle(GoogleAuthAccount account) async {
    final userBffService = _userBffService;
    if (userBffService != null) {
      final remoteSettings = await userBffService.authenticateGoogle(account);
      await _save(
        _settings.copyWith(
          selectedPlan: AppPlan.premium,
          isPremium: remoteSettings.isPremium,
          userLogged: remoteSettings.userLogged,
          userId: remoteSettings.userId,
          userName: remoteSettings.userName,
          userEmail: remoteSettings.userEmail,
          userPhotoAssetPath: remoteSettings.userPhotoAssetPath,
          birthDate: remoteSettings.birthDate,
          gender: remoteSettings.gender,
          dailyCalorieGoal: remoteSettings.dailyCalorieGoal,
          remainingDailyEstimations: freeDailyEstimateLimit,
          lastResetDate: DateTime.now(),
        ),
      );
      return;
    }

    await activatePremium(
      userName: account.displayName,
      userEmail: account.email,
      userPhotoUrl: account.photoUrl,
    );
  }

  Future<void> logout() async {
    await _save(
      AppSettings(
        selectedPlan: AppPlan.free,
        isPremium: false,
        userLogged: false,
        remainingDailyEstimations: freeDailyEstimateLimit,
        lastResetDate: DateTime.now(),
        dailyCalorieGoal: _settings.dailyCalorieGoal,
      ),
    );
  }

  Future<void> updateDailyCalorieGoal(int goal) async {
    final normalizedGoal = goal.clamp(800, 6000).toInt();
    var updated = _settings.copyWith(dailyCalorieGoal: normalizedGoal);
    final userBffService = _userBffService;
    if (userBffService != null && updated.userId != null) {
      updated = await userBffService.updateProfile(updated);
    }
    await _save(updated);
  }

  Future<void> updateUserProfile({
    DateTime? birthDate,
    String? gender,
    int? dailyCalorieGoal,
  }) async {
    var updated = _settings.copyWith(
      birthDate: birthDate,
      gender: gender == null || gender.trim().isEmpty ? null : gender.trim(),
      dailyCalorieGoal: dailyCalorieGoal == null
          ? _settings.dailyCalorieGoal
          : dailyCalorieGoal.clamp(800, 6000).toInt(),
    );
    final userBffService = _userBffService;
    if (userBffService != null && updated.userId != null) {
      updated = await userBffService.updateProfile(updated);
    }
    await _save(updated);
  }

  Future<void> _save(AppSettings settings) async {
    _settings = settings;
    await _repository.save(settings);
    notifyListeners();
  }
}
