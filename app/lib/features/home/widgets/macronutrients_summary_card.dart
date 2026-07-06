import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:flutter/material.dart';

class MacronutrientsSummaryCard extends StatelessWidget {
  final Macronutrients macronutrients;
  final bool compact;
  final String title;

  const MacronutrientsSummaryCard({
    super.key,
    required this.macronutrients,
    this.compact = false,
    this.title = 'Macronutrientes estimados',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (compact)
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final macro in macronutrients.values)
                    _CompactMacroValue(macro: macro),
                ],
              )
            else
              Row(
                children: [
                  for (final macro in macronutrients.values)
                    Expanded(child: _MacroValue(macro: macro)),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            _MacroDistributionBar(macronutrients: macronutrients),
          ],
        ),
      ),
    );
  }
}

class _MacroDistributionBar extends StatelessWidget {
  final Macronutrients macronutrients;

  const _MacroDistributionBar({required this.macronutrients});

  @override
  Widget build(BuildContext context) {
    final total = macronutrients.totalGrams;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (final macro in macronutrients.values)
              Expanded(
                flex: total == 0 ? 1 : macro.grams,
                child: ColoredBox(color: macro.color.withValues(alpha: 0.85)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroValue extends StatelessWidget {
  final Macronutrient macro;

  const _MacroValue({required this.macro});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${macro.grams} g',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          macro.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CompactMacroValue extends StatelessWidget {
  final Macronutrient macro;

  const _CompactMacroValue({required this.macro});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: macro.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text('${macro.label}: ${macro.grams} g'),
      ],
    );
  }
}
