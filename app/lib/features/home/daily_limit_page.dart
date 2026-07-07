import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/onboarding/paywall_page.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/utils/adaptive_page_route.dart';
import 'package:flutter/material.dart';

class DailyLimitPage extends StatelessWidget {
  const DailyLimitPage({super.key});

  void _openPlans(BuildContext context) {
    Navigator.of(context).push(
      adaptivePageRoute(
        context: context,
        builder: (_) => const PaywallPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.addMeal),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.notifications_rounded,
                    size: 76,
                    color: Color(0xFFF2BE1A),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.dailyLimitTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.dailyLimitUsed,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      l10n.dailyLimitUpgrade,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: () => _openPlans(context),
                    child: Text(l10n.viewPlans),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.gotIt),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
