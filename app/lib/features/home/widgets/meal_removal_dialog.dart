import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/models/meal.dart';

class MealRemovalDialog extends StatelessWidget {
  final Meal? meal;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const MealRemovalDialog({
    super.key,
    this.meal,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded),
      title: Text(l10n.removeMealQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cannotBeUndone),
          if (meal != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              meal!.descricao,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${meal!.calorias} kcal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: onConfirm,
          child: Text(l10n.remove),
        ),
      ],
    );
  }
}
