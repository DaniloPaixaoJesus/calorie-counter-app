import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/design_system/premium_crown_icon.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/features/onboarding/paywall_page.dart';
import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'edit_meal_page.dart';
import 'view_model.dart';
import 'widgets/date_navigation_bar.dart';
import 'widgets/date_empty_state.dart';
import 'widgets/meal_removal_dialog.dart';
import 'widgets/calorie_total_card.dart';
import 'widgets/meal_list_item.dart';
import 'widgets/ad_card.dart';
import 'widgets/macronutrients_summary_card.dart';
import 'widgets/premium_upgrade_card.dart';

class HomePage extends StatelessWidget {
  final bool showAds;

  const HomePage({super.key, this.showAds = true});

  Future<void> _showRemovalDialog(
    BuildContext context,
    HomeViewModel vm,
    String mealId,
  ) async {
    final meal = vm.getMealById(mealId);
    await showDialog<void>(
      context: context,
      builder: (context) => MealRemovalDialog(
        meal: meal,
        onConfirm: () async {
          Navigator.of(context).pop();
          await vm.confirmarRemocao(mealId);
        },
        onCancel: () {
          Navigator.of(context).pop();
          vm.cancelarRemocao();
        },
      ),
    );
  }

  Future<void> _openEditMealPage(BuildContext context, Meal meal) async {
    final vm = context.read<HomeViewModel>();
    await Navigator.of(context).push(
      adaptivePageRoute(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: EditMealPage(meal: meal),
        ),
      ),
    );
  }

  Future<void> _openPremium(BuildContext context) async {
    await Navigator.of(context).push(
      adaptivePageRoute(
        context: context,
        builder: (_) => const PaywallPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final subscriptionService = context.watch<SubscriptionService?>();
    final settings = subscriptionService?.settings;
    final isPremium = subscriptionService?.isPremium ?? false;
    final meals = vm.mealsDoDia;
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                const DateNavigationBar(),
                if (isPremium && settings?.userName != null) ...[
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _PremiumHeader(
                      settings: settings!,
                      onLogout: () async {
                        try {
                          await GoogleAuthService().signOut();
                        } catch (_) {}
                        if (!context.mounted) return;
                        await context.read<SubscriptionService>().logout();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: CalorieTotalCard(totalCalorias: vm.totalHoje),
                ),
                if (isPremium) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: MacronutrientsSummaryCard(
                      macronutrients: vm.totalMacronutrientsHoje,
                      title: 'Macros de hoje',
                      showMockNotice: false,
                    ),
                  ),
                ],
                if (showAds) ...[
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: const AdCard(),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (vm.homeErrorMessage != null &&
                    vm.homeErrorMessage!.isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          vm.homeErrorMessage!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    itemCount:
                        (meals.isEmpty ? 1 : meals.length) + (showAds ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      if (meals.isEmpty && i == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: DateEmptyStateWidget(
                            dataSelecionada: vm.dataSelecionada,
                          ),
                        );
                      }
                      final mealIndex = meals.isEmpty ? i - 1 : i;
                      if (mealIndex >= meals.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: PremiumUpgradeCard(
                            onTap: () => _openPremium(context),
                          ),
                        );
                      }
                      final meal = meals[mealIndex];
                      return MealListItem(
                        meal: meal,
                        onTap: () => _openEditMealPage(context, meal),
                        onRemoveTap: () =>
                            _showRemovalDialog(context, vm, meal.id),
                        onLongPress: () =>
                            _showRemovalDialog(context, vm, meal.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final AppSettings settings;
  final Future<void> Function() onLogout;

  const _PremiumHeader({required this.settings, required this.onLogout});

  void _showUserData(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserPhoto(settings: settings, radius: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.userName ?? 'Usuário Premium',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if ((settings.userEmail ?? '').isNotEmpty)
                            Text(
                              settings.userEmail!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const PremiumCrownIcon(),
                  title: const Text('Plano Premium'),
                  subtitle: const Text('Autenticado via Google'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await onLogout();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PremiumCrownIcon(size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Premium',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Tooltip(
          message: 'Dados do usuário',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showUserData(context),
            child: _UserPhoto(settings: settings, radius: 18),
          ),
        ),
      ],
    );
  }
}

class _UserPhoto extends StatelessWidget {
  final AppSettings settings;
  final double radius;

  const _UserPhoto({required this.settings, required this.radius});

  @override
  Widget build(BuildContext context) {
    final photoPath = settings.userPhotoAssetPath;
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    final hasRemotePhoto = hasPhoto && photoPath.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: hasPhoto
          ? (hasRemotePhoto
              ? NetworkImage(photoPath)
              : AssetImage(photoPath) as ImageProvider)
          : null,
      child: hasPhoto
          ? null
          : Icon(Icons.person_rounded, color: colorScheme.primary),
    );
  }
}
