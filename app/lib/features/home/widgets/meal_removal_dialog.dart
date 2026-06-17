import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
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
    return AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded),
      title: const Text('Remover refeicao?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Esta acao nao pode ser desfeita.'),
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
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: onConfirm,
          child: const Text('Remover'),
        ),
      ],
    );
  }
}
