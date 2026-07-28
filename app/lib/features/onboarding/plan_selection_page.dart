import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_elevation.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/design_system/premium_crown_icon.dart';
import 'package:calorie_counter_app/features/home/home_shell_page.dart';
import 'package:calorie_counter_app/features/onboarding/paywall_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/services/auth/google_auth_service.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlanSelectionPage extends StatelessWidget {
  final GoogleAuthService? restoreGoogleAuthService;

  const PlanSelectionPage({
    super.key,
    this.restoreGoogleAuthService,
  });

  Future<void> _continueFree(BuildContext context) async {
    await context.read<SubscriptionService>().selectFreePlan();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShellPage()),
    );
  }

  Future<void> _openPaywall(
    BuildContext context, {
    required bool restorePurchaseOnOpen,
  }) async {
    final result = await Navigator.of(context).push<PaywallResult>(
      MaterialPageRoute(
        builder: (_) => PaywallPage(
          restoreGoogleAuthService: restoreGoogleAuthService,
          restorePurchaseOnOpen: restorePurchaseOnOpen,
          returnToPlanSelectionOnNotFound: true,
        ),
      ),
    );
    if (!context.mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)
              .noActivePremiumPlanForEmail(result.email),
        ),
      ),
    );
  }

  Future<void> _openPremium(BuildContext context) =>
      _openPaywall(context, restorePurchaseOnOpen: false);

  Future<void> _restorePurchase(BuildContext context) =>
      _openPaywall(context, restorePurchaseOnOpen: true);

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          TextButton(
            onPressed: () => _continueFree(context),
            child: Text(l10n.notNow),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: const ValueKey('plan-selection-hero'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.chooseYourPlan,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.startForFree,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onPrimaryContainer
                                          .withValues(alpha: 0.78),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _PlanCard(
                    key: const ValueKey('free-plan-card'),
                    icon: Icons.eco_rounded,
                    title: l10n.free,
                    badge: l10n.freeBadge,
                    bullets: l10n.freePlanBullets,
                    color: Theme.of(context).colorScheme.primary,
                    background: Theme.of(context).colorScheme.primaryContainer,
                    highlighted: false,
                    onTap: () => _continueFree(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PlanCard(
                    key: const ValueKey('premium-plan-card'),
                    icon: Icons.workspace_premium_rounded,
                    customIcon: const PremiumCrownIcon(size: 22),
                    title: l10n.premium,
                    badge: l10n.mostRecommended,
                    bullets: l10n.premiumPlanBullets,
                    color: const Color(0xFFB56A00),
                    background: const Color(0xFFFFF3D8),
                    highlighted: true,
                    onTap: () => _openPremium(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    key: const ValueKey('restore-purchase-action'),
                    onPressed: () => _restorePurchase(context),
                    icon: const Icon(Icons.restore_rounded),
                    label: Text(l10n.restorePurchase),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => _continueFree(context),
                    icon: const Icon(Icons.eco_outlined),
                    label: Text(l10n.continueWithFree),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final IconData icon;
  final Widget? customIcon;
  final String title;
  final String? badge;
  final List<String> bullets;
  final Color color;
  final Color background;
  final bool highlighted;
  final VoidCallback onTap;

  const _PlanCard({
    super.key,
    required this.icon,
    required this.title,
    required this.bullets,
    required this.color,
    required this.background,
    required this.highlighted,
    required this.onTap,
    this.customIcon,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      side: BorderSide(
        color: color.withValues(alpha: highlighted ? 0.65 : 0.28),
        width: highlighted ? 1.5 : 1,
      ),
    );

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).pick(
        en: '$title plan',
        pt: 'Plano $title',
        es: 'Plan $title',
      ),
      child: Material(
        color: Colors.transparent,
        elevation: highlighted ? AppElevation.level2 : AppElevation.level1,
        shadowColor: color.withValues(alpha: 0.22),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: highlighted ? null : colorScheme.surface,
              gradient: highlighted
                  ? LinearGradient(
                      colors: [
                        colorScheme.surface,
                        background.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: customIcon ?? Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          color: highlighted ? color : colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          badge!,
                          style: textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final bullet in bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            bullet,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 20,
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
