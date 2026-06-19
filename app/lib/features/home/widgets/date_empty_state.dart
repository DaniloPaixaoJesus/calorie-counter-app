import 'package:flutter/material.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';

class DateEmptyStateWidget extends StatelessWidget {
  final DateTime dataSelecionada;

  const DateEmptyStateWidget({
    super.key,
    required this.dataSelecionada,
  });

  @override
  Widget build(BuildContext context) {
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
          'Nenhuma refeicao registrada',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Toque em Adicionar para registrar sua primeira refeicao do dia.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
