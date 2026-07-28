import 'package:flutter/foundation.dart';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/features/sync/domain/sync_ports.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/bff/user_bff_service.dart';
import 'app_settings_repository.dart';
import 'in_memory_app_settings_repository.dart';

typedef PremiumSessionCallback = Future<void> Function(AppSettings settings);
typedef NutritionGoalCallback = Future<void> Function(
  int goal,
  AppSettings settings,
);

class SubscriptionSyncSession implements SyncSession {
  AppSettings _settings;
  SubscriptionSyncSession(this._settings);
  void update(AppSettings settings) => _settings = settings;
  @override
  String? get userId => _settings.userId;
  @override
  String? get bearerToken => _settings.googleAuthToken;
  @override
  bool get isPremiumActive => _settings.isPremium && _settings.userLogged;
}

class SubscriptionService extends ChangeNotifier {
  static const int freeDailyEstimateLimit = 3;

  final AppSettingsRepository _repository;
  final UserBffService? _userBffService;
  final PremiumSessionCallback? _onPremiumAuthenticated;
  final PremiumSessionCallback? _onPremiumStateChanged;
  final NutritionGoalCallback? _onNutritionGoalChanged;
  AppSettings _settings;

  SubscriptionService._({
    required AppSettingsRepository repository,
    required AppSettings settings,
    UserBffService? userBffService,
    PremiumSessionCallback? onPremiumAuthenticated,
    PremiumSessionCallback? onPremiumStateChanged,
    NutritionGoalCallback? onNutritionGoalChanged,
  })  : _repository = repository,
        _userBffService = userBffService,
        _onPremiumAuthenticated = onPremiumAuthenticated,
        _onPremiumStateChanged = onPremiumStateChanged,
        _onNutritionGoalChanged = onNutritionGoalChanged,
        _settings = settings;

  SubscriptionService.fallback()
      : _repository = InMemoryAppSettingsRepository(),
        _userBffService = null,
        _onPremiumAuthenticated = null,
        _onPremiumStateChanged = null,
        _onNutritionGoalChanged = null,
        _settings = const AppSettings(selectedPlan: AppPlan.free);

  static Future<SubscriptionService> load(
    AppSettingsRepository repository, {
    UserBffService? userBffService,
    PremiumSessionCallback? onPremiumAuthenticated,
    PremiumSessionCallback? onPremiumStateChanged,
    NutritionGoalCallback? onNutritionGoalChanged,
  }) async {
    return SubscriptionService._(
      repository: repository,
      settings: await repository.load(),
      userBffService: userBffService,
      onPremiumAuthenticated: onPremiumAuthenticated,
      onPremiumStateChanged: onPremiumStateChanged,
      onNutritionGoalChanged: onNutritionGoalChanged,
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
        googleAuthToken: null,
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
          googleAuthToken: remoteSettings.googleAuthToken,
          trialStartDate: remoteSettings.trialStartDate,
          birthDate: remoteSettings.birthDate,
          gender: remoteSettings.gender,
          dailyCalorieGoal: remoteSettings.dailyCalorieGoal,
          remainingDailyEstimations: freeDailyEstimateLimit,
          lastResetDate: DateTime.now(),
        ),
      );
      if (_settings.isPremium) {
        Future<void>(() async => _onPremiumAuthenticated?.call(_settings));
      } else {
        await _onPremiumStateChanged?.call(_settings);
      }
      return;
    }

    await activatePremium(
      userName: account.displayName,
      userEmail: account.email,
      userPhotoUrl: account.photoUrl,
    );
    Future<void>(() async => _onPremiumAuthenticated?.call(_settings));
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
    await _onPremiumStateChanged?.call(_settings);
  }

  Future<void> clearLocalSession() async {
    _settings = AppSettings.empty;
    notifyListeners();
    await _onPremiumStateChanged?.call(_settings);
  }

  Future<void> updateDailyCalorieGoal(int goal) async {
    final normalizedGoal = goal.clamp(800, 6000).toInt();
    final updated = _settings.copyWith(dailyCalorieGoal: normalizedGoal);
    await _save(updated);
    await _onNutritionGoalChanged?.call(normalizedGoal, _settings);
  }

  Future<void> applySyncedDailyCalorieGoal(int goal) async {
    await _save(_settings.copyWith(
      dailyCalorieGoal: goal.clamp(800, 6000).toInt(),
    ));
  }

  Future<void> refreshPremiumState(bool active) async {
    await _save(_settings.copyWith(isPremium: active));
    await _onPremiumStateChanged?.call(_settings);
  }

  Future<void> updateUserProfile({
    DateTime? birthDate,
    String? gender,
    int? dailyCalorieGoal,
  }) async {
    final previousGoal = _settings.dailyCalorieGoal;
    var updated = _settings.copyWith(
      birthDate: birthDate,
      gender: gender == null || gender.trim().isEmpty ? null : gender.trim(),
      dailyCalorieGoal: dailyCalorieGoal == null
          ? _settings.dailyCalorieGoal
          : dailyCalorieGoal.clamp(800, 6000).toInt(),
    );
    await _save(updated);
    if (updated.dailyCalorieGoal != previousGoal) {
      await _onNutritionGoalChanged?.call(
        updated.dailyCalorieGoal,
        _settings,
      );
    }
    final userBffService = _userBffService;
    if (userBffService != null && updated.userId != null) {
      try {
        updated = (await userBffService.updateProfile(updated)).copyWith(
          trialStartDate: _settings.trialStartDate,
          googleAuthToken: _settings.googleAuthToken,
        );
        await _save(updated);
      } catch (_) {
        // Perfil e meta já estão persistidos localmente; a meta será retomada
        // pela outbox quando a conectividade voltar.
      }
    }
  }

  Future<void> _save(AppSettings settings) async {
    _settings = settings;
    await _repository.save(settings);
    notifyListeners();
  }
}
