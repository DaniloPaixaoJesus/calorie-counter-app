import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class CalorieTotalCard extends StatelessWidget {
  final int totalCalorias;
  final int? dailyGoal;

  const CalorieTotalCard({
    super.key,
    required this.totalCalorias,
    this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.totalCaloriesSemantic(totalCalorias),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.totalCalories,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$totalCalorias kcal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.consumedToday,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.85),
                  ),
            ),
            if (dailyGoal != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _GoalProgress(
                totalCalorias: totalCalorias,
                dailyGoal: dailyGoal!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final int totalCalorias;
  final int dailyGoal;

  const _GoalProgress({
    required this.totalCalorias,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final progress = dailyGoal <= 0
        ? 0.0
        : (totalCalorias / dailyGoal).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.onPrimary.withValues(alpha: 0.92),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.dailyGoalCalories(dailyGoal),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
