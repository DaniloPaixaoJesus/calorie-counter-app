import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';

class DateEmptyStateWidget extends StatelessWidget {
  final DateTime dataSelecionada;

  const DateEmptyStateWidget({
    super.key,
    required this.dataSelecionada,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.restaurant_menu,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.noMealsRegistered,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.emptyMealsHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
