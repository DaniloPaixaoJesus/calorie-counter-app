import 'dart:async';

import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/subscription/in_memory_app_settings_repository.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login premium não aguarda o bootstrap', () async {
    final bootstrapStarted = Completer<void>();
    final releaseBootstrap = Completer<void>();
    final service = await SubscriptionService.load(
      InMemoryAppSettingsRepository(),
      onPremiumAuthenticated: (_) async {
        bootstrapStarted.complete();
        await releaseBootstrap.future;
      },
    );

    await service.authenticatePremiumWithGoogle(
      const GoogleAuthAccount(email: 'user@example.com'),
    );

    expect(service.isPremium, isTrue);
    await bootstrapStarted.future;
    releaseBootstrap.complete();
  });

  test('meta é persistida localmente antes de notificar sincronização',
      () async {
    final repository = InMemoryAppSettingsRepository();
    final observed = <int>[];
    final service = await SubscriptionService.load(
      repository,
      onNutritionGoalChanged: (goal, settings) async {
        expect((await repository.load()).dailyCalorieGoal, goal);
        observed.add(goal);
      },
    );

    await service.updateDailyCalorieGoal(2300);

    expect(service.settings.dailyCalorieGoal, 2300);
    expect(observed, [2300]);
  });

  test('expiração pausa premium mas preserva sessão e meta', () async {
    final repository = InMemoryAppSettingsRepository();
    final states = <AppSettings>[];
    final service = await SubscriptionService.load(
      repository,
      onPremiumStateChanged: (settings) async => states.add(settings),
    );
    await service.activatePremium(userId: 'u-1');
    await service.updateDailyCalorieGoal(2100);

    await service.refreshPremiumState(false);

    expect(service.settings.userLogged, isTrue);
    expect(service.settings.dailyCalorieGoal, 2100);
    expect(service.isPremium, isFalse);
    expect(states.single.isPremium, isFalse);
  });

  test('limpeza de sessão após logout não recria dados no repositório',
      () async {
    final repository = InMemoryAppSettingsRepository();
    final service = await SubscriptionService.load(repository);
    await service.activatePremium(userId: 'u-1');

    await service.clearLocalSession();

    expect(service.settings, same(AppSettings.empty));
    expect((await repository.load()).userId, 'u-1');
  });
}
