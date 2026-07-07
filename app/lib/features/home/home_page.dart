import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/features/onboarding/paywall_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/models/app_settings.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'package:intl/intl.dart';
import 'edit_meal_page.dart';
import 'profile_insights_page.dart';
import 'view_model.dart';
import 'widgets/date_navigation_bar.dart';
import 'widgets/date_empty_state.dart';
import 'widgets/meal_removal_dialog.dart';
import 'widgets/calorie_total_card.dart';
import 'widgets/meal_list_item.dart';
import 'widgets/ad_card.dart';
import 'widgets/macronutrients_summary_card.dart';

class HomePage extends StatelessWidget {
  final bool showAds;

  const HomePage({super.key, this.showAds = true});

  String _macroTitle(BuildContext context, HomeViewModel vm) {
    final l10n = AppLocalizations.of(context);
    if (vm.eHoje) return l10n.macrosToday;
    final formatted = DateFormat(
      'dd/MM',
      AppLocalizations.localeNameOf(context),
    ).format(vm.dataSelecionada);
    return l10n.macrosOn(formatted);
  }

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

  Future<void> _openProfileInsights(BuildContext context) async {
    await Navigator.of(context).push(
      adaptivePageRoute(
        context: context,
        builder: (_) => const ProfileInsightsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final subscriptionService = context.watch<SubscriptionService?>();
    final settings = subscriptionService?.settings;
    final isPremium = subscriptionService?.isPremium ?? false;
    final l10n = AppLocalizations.of(context);
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
                const SizedBox(height: AppSpacing.md),
                if (isPremium && settings?.userName != null) ...[
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _PremiumHeader(
                      settings: settings!,
                      onProfileTap: () => _openProfileInsights(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _FreeHeader(onTap: () => _openPremium(context)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const DateNavigationBar(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: CalorieTotalCard(
                    totalCalorias: vm.totalHoje,
                    dailyGoal: settings?.dailyCalorieGoal,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: MacronutrientsSummaryCard(
                    macronutrients: vm.totalMacronutrientsHoje,
                    title: _macroTitle(context, vm),
                    showDistributionBar: false,
                  ),
                ),
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
                          l10n.userFacingMessage(vm.homeErrorMessage!),
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
                    itemCount: meals.isEmpty ? 1 : meals.length,
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
                      final meal = meals[i];
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
  final VoidCallback onProfileTap;

  const _PremiumHeader({
    required this.settings,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          color: Color(0xFFF2BE1A),
          size: 20,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Premium',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const Spacer(),
        Tooltip(
          message: AppLocalizations.of(context).profileAndGoals,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onProfileTap,
            child: _UserPhoto(settings: settings, radius: 18),
          ),
        ),
      ],
    );
  }
}

class _FreeHeader extends StatelessWidget {
  final VoidCallback onTap;

  const _FreeHeader({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.eco_rounded,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppLocalizations.of(context).free,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFF2BE1A),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppLocalizations.of(context).becomePremium,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
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
