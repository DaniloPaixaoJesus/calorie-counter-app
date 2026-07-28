import 'package:calorie_counter_app/features/home/home_page.dart';
import 'package:calorie_counter_app/features/home/profile_insights_page.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/services/subscription/in_memory_app_settings_repository.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('nome do usuário Premium abre a tela de perfil', (tester) async {
    final subscription = await SubscriptionService.load(
      InMemoryAppSettingsRepository(),
    );
    final homeViewModel = HomeViewModel(
      repository: InMemoryRepository(),
      aiAdapter: const AiAdapterMock(responseDelay: Duration.zero),
      subscriptionService: subscription,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: subscription),
          ChangeNotifierProvider.value(value: homeViewModel),
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
          home: const HomePage(showAds: false),
        ),
      ),
    );

    final homeHeader = find.byKey(const ValueKey('home-top-header'));
    expect(homeHeader, findsOneWidget);
    expect(tester.getTopLeft(homeHeader).dy, AppSpacing.xs);

    await subscription.activatePremium(
      userName: 'Ana Premium',
      userEmail: 'ana@example.com',
      userId: 'ana-id',
    );
    await tester.pumpAndSettle();

    expect(homeHeader, findsOneWidget);
    expect(tester.getTopLeft(homeHeader).dy, AppSpacing.xs);

    await tester.tap(find.textContaining('Ana Premium'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileInsightsPage), findsOneWidget);
  });
}
