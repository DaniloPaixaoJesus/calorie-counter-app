import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/onboarding/splash_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/ai_adapter/bff_ai_adapter.dart';
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

const bool _useMockAi = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('pt_BR', null);
  await initializeDateFormatting('es', null);
  final MealRepository repository;
  final EstimateQuotaRepository estimateQuotaRepository;
  final AppSettingsRepository appSettingsRepository;

  if (_supportsSqliteStorage) {
    repository = await SqliteMealRepository.open();
    estimateQuotaRepository = await SqliteEstimateQuotaRepository.open();
    appSettingsRepository = await SqliteAppSettingsRepository.open();
  } else {
    repository = InMemoryRepository();
    estimateQuotaRepository = InMemoryEstimateQuotaRepository();
    appSettingsRepository = InMemoryAppSettingsRepository();
  }
  final subscriptionService = await SubscriptionService.load(
    appSettingsRepository,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: subscriptionService),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            repository: repository,
            aiAdapter: _createAiAdapter(),
            estimateQuotaRepository: estimateQuotaRepository,
            subscriptionService: subscriptionService,
          ),
        ),
      ],
      child: const CalorieCounterApp(),
    ),
  );
}

AiAdapter _createAiAdapter() {
  return _useMockAi ? const AiAdapterMock() : BffAiAdapter();
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
