import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/onboarding/plan_selection_page.dart';
import 'package:calorie_counter_app/features/onboarding/splash_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/bff/user_bff_service.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/services/subscription/in_memory_app_settings_repository.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _GoogleAuthFake extends GoogleAuthService {
  bool signedOut = false;

  @override
  Future<GoogleAuthAccount> signIn() async =>
      const GoogleAuthAccount(email: 'restore@example.com');

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _RestoreBffFake extends UserBffService {
  final AppSettings? result;

  _RestoreBffFake(this.result) : super(localeProvider: () => 'pt_BR');

  @override
  Future<AppSettings?> restoreGooglePurchase(GoogleAuthAccount account) async =>
      result;
}

Widget _app(
  SubscriptionService service,
  GoogleAuthService googleAuthService, {
  Widget? home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: service),
      ChangeNotifierProvider(
        create: (_) => HomeViewModel(
          repository: InMemoryRepository(),
          aiAdapter: const AiAdapterMock(responseDelay: Duration.zero),
          subscriptionService: service,
        ),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: NutritionTheme.light,
      home: home ??
          PlanSelectionPage(
            restoreGoogleAuthService: googleAuthService,
          ),
    ),
  );
}

void main() {
  testWidgets('sem plano ativo avisa e retorna para seleção de plano',
      (tester) async {
    final google = _GoogleAuthFake();
    final service = await SubscriptionService.load(
      InMemoryAppSettingsRepository(),
      userBffService: _RestoreBffFake(null),
    );
    await tester.pumpWidget(_app(service, google));

    await tester.ensureVisible(find.text('Recuperar compra'));
    await tester.tap(find.text('Recuperar compra'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha seu plano'), findsOneWidget);
    expect(
      find.text(
        'O e-mail restore@example.com não possui uma conta Premium ativa.',
      ),
      findsOneWidget,
    );
    expect(google.signedOut, isTrue);
    expect(service.isPremium, isFalse);
  });

  testWidgets('seleção exibida após o Splash oferece recuperação de compra',
      (tester) async {
    final google = _GoogleAuthFake();
    final service = await SubscriptionService.load(
      InMemoryAppSettingsRepository(),
      userBffService: _RestoreBffFake(null),
    );
    await tester.pumpWidget(
      _app(service, google, home: const SplashPage()),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Escolha seu plano'), findsOneWidget);
    expect(find.text('Recuperar compra'), findsOneWidget);
  });

  testWidgets('plano ativo autentica e abre o app', (tester) async {
    final google = _GoogleAuthFake();
    final service = await SubscriptionService.load(
      InMemoryAppSettingsRepository(),
      userBffService: _RestoreBffFake(const AppSettings(
        selectedPlan: AppPlan.premium,
        isPremium: true,
        userLogged: true,
        userId: 'restored-user',
        userEmail: 'restore@example.com',
        googleAuthToken: 'token',
      )),
    );
    await tester.pumpWidget(_app(service, google));

    final premiumPlan = find.ancestor(
      of: find.text('Premium'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(premiumPlan);
    await tester.tap(premiumPlan);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Recuperar compra'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Recuperar compra'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(service.isPremium, isTrue);
    expect(service.settings.userId, 'restored-user');
  });
}
