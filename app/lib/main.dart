import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/onboarding/splash_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/ai_adapter/bff_ai_adapter.dart';
import 'package:calorie_counter_app/services/bff/user_bff_service.dart';
import 'package:calorie_counter_app/services/estimate_quota/estimate_quota_repository.dart';
import 'package:calorie_counter_app/services/estimate_quota/in_memory_estimate_quota_repository.dart';
import 'package:calorie_counter_app/services/estimate_quota/sqlite_estimate_quota_repository.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/services/repository/meal_repository.dart';
import 'package:calorie_counter_app/services/repository/sqlite_meal_repository.dart';
import 'package:calorie_counter_app/services/subscription/app_settings_repository.dart';
import 'package:calorie_counter_app/services/subscription/in_memory_app_settings_repository.dart';
import 'package:calorie_counter_app/services/subscription/sqlite_app_settings_repository.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';
import 'package:calorie_counter_app/features/sync/application/logout_coordinator.dart';
import 'package:calorie_counter_app/features/sync/application/sync_coordinator.dart';
import 'package:calorie_counter_app/features/sync/application/sync_trigger_service.dart';
import 'package:calorie_counter_app/features/sync/domain/nutrition_goal.dart';
import 'package:calorie_counter_app/features/sync/domain/sync_models.dart';
import 'package:calorie_counter_app/features/sync/domain/sync_types.dart';
import 'package:calorie_counter_app/features/sync/infrastructure/bff_sync_gateway.dart';
import 'package:calorie_counter_app/features/sync/infrastructure/sqlite_sync_store.dart';
import 'package:calorie_counter_app/features/sync/presentation/sync_view_model.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/bff/bff_client.dart';
import 'package:calorie_counter_app/services/repository/app_database.dart';

const bool _useMockAi = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('es', null);
  final MealRepository repository;
  final EstimateQuotaRepository estimateQuotaRepository;
  final AppSettingsRepository appSettingsRepository;
  AppDatabase? appDatabase;
  SqliteSyncStore? syncStore;

  if (_supportsSqliteStorage) {
    appDatabase = await AppDatabase.open();
    final cleaner = SqliteLogoutDataCleaner(appDatabase);
    await cleaner.resumeInterruptedCleanup();
    syncStore = SqliteSyncStore(appDatabase);
    repository = await SqliteMealRepository.open();
    estimateQuotaRepository = await SqliteEstimateQuotaRepository.open();
    appSettingsRepository = await SqliteAppSettingsRepository.open();
  } else {
    repository = InMemoryRepository();
    estimateQuotaRepository = InMemoryEstimateQuotaRepository();
    appSettingsRepository = InMemoryAppSettingsRepository();
  }
  final userBffService = UserBffService(localeProvider: _currentLocaleName);
  SyncCoordinator? syncCoordinator;
  SyncTriggerService? syncTriggers;
  HomeViewModel? homeViewModel;
  late SubscriptionSyncSession syncSession;
  final subscriptionService = await SubscriptionService.load(
    appSettingsRepository,
    userBffService: userBffService,
    onPremiumAuthenticated: (settings) async {
      syncSession.update(settings);
      await syncCoordinator?.bootstrap();
    },
    onPremiumStateChanged: (settings) async {
      syncSession.update(settings);
      if (settings.isPremium) await syncCoordinator?.retry();
    },
    onNutritionGoalChanged: syncStore == null
        ? null
        : (goal, settings) async {
            final now = DateTime.now().toUtc();
            await syncStore!.transaction(() async {
              final nutritionGoal = NutritionGoal(
                targetValue: goal,
                effectiveFrom: DateTime(now.year, now.month, now.day),
                modifiedAt: now,
                ownerUserId: settings.userId,
              );
              await syncStore!.upsertGoal(nutritionGoal);
              await syncStore.enqueue(SyncOperation(
                operationId: const Uuid().v4(),
                entityType: SyncEntityType.nutritionGoal,
                entityId: NutritionGoal.canonicalId,
                operation: SyncOperationType.upsert,
                occurredAt: now,
                ownerUserId: settings.userId,
                payload: {
                  'type': 'dailyCalories',
                  'targetValue': nutritionGoal.targetValue,
                  'unit': 'kcalPerDay',
                  'effectiveFrom': nutritionGoal.effectiveFrom
                      .toIso8601String()
                      .split('T')
                      .first,
                },
              ));
            });
            await syncCoordinator?.refreshPendingCount();
            final triggers = syncTriggers;
            if (triggers != null) unawaited(triggers.onMutation());
          },
  );
  syncSession = SubscriptionSyncSession(subscriptionService.settings);
  SyncViewModel? syncViewModel;
  LogoutCoordinator? logoutCoordinator;
  if (syncStore != null && appDatabase != null) {
    final coordinator = SyncCoordinator(
      store: syncStore,
      gateway: BffSyncGateway(BffClient()),
      session: syncSession,
      deviceId: await appDatabase.getOrCreateDeviceId(),
      onDataChanged: () async {
        if (repository is SqliteMealRepository) {
          await repository.reload();
        }
        final goal = await syncStore!.goal(NutritionGoal.canonicalId);
        if (goal != null) {
          await subscriptionService
              .applySyncedDailyCalorieGoal(goal.targetValue);
        }
        homeViewModel?.refreshMeals();
      },
    );
    syncCoordinator = coordinator;
    await coordinator.initialize();
    final triggers = SyncTriggerService(coordinator: coordinator);
    syncTriggers = triggers;
    syncViewModel = SyncViewModel(coordinator, triggers: triggers);
    if (coordinator.pendingCount > 0) {
      unawaited(triggers.onForeground());
    }
    final cleaner = SqliteLogoutDataCleaner(
      appDatabase,
      onDataCleared: () async {
        if (repository is SqliteMealRepository) {
          await repository.reload();
        }
        if (estimateQuotaRepository is SqliteEstimateQuotaRepository) {
          await estimateQuotaRepository.reload();
        }
      },
    );
    logoutCoordinator = LogoutCoordinator(
      flush: coordinator.flush,
      pendingCount: () async {
        await coordinator.refreshPendingCount();
        return coordinator.pendingCount;
      },
      cleaner: cleaner,
      clearSession: subscriptionService.clearLocalSession,
      disconnectIdentityProvider: GoogleAuthService().signOut,
    );
  }
  final configuredHomeViewModel = HomeViewModel(
    repository: repository,
    aiAdapter: _createAiAdapter(subscriptionService),
    estimateQuotaRepository: estimateQuotaRepository,
    subscriptionService: subscriptionService,
    userBffService: userBffService,
    onLocalMutation: syncTriggers?.onMutation,
  );
  homeViewModel = configuredHomeViewModel;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: subscriptionService),
        if (syncViewModel != null)
          ChangeNotifierProvider.value(value: syncViewModel),
        if (logoutCoordinator != null) Provider.value(value: logoutCoordinator),
        ChangeNotifierProvider.value(value: configuredHomeViewModel),
      ],
      child: const CalorieCounterApp(),
    ),
  );
}

AiAdapter _createAiAdapter(SubscriptionService subscriptionService) {
  return _useMockAi
      ? const AiAdapterMock()
      : BffAiAdapter(
          localeProvider: _currentLocaleName,
          authTokenProvider: () => subscriptionService.settings.googleAuthToken,
          premiumActiveProvider: () => subscriptionService.isPremium,
        );
}

String _currentLocaleName() {
  final locale = AppLocalizations.resolve(
    WidgetsBinding.instance.platformDispatcher.locale,
    AppLocalizations.supportedLocales,
  );
  if (locale.languageCode == 'pt') return 'pt_BR';
  if (locale.languageCode == 'es') return 'es';
  return 'en_US';
}

bool get _supportsSqliteStorage {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class CalorieCounterApp extends StatelessWidget {
  const CalorieCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: NutritionTheme.light,
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: AppLocalizations.resolve,
      builder: (context, child) {
        if (!_useMockAi || child == null) {
          return child ?? const SizedBox.shrink();
        }

        return Stack(
          children: [
            child,
            Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      AppLocalizations.of(context).mockAiBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      home: const SplashPage(),
    );
  }
}
