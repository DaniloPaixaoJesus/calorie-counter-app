import 'package:calorie_counter_app/design_system/app_radius.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:flutter/material.dart';

class MacronutrientsSummaryCard extends StatelessWidget {
  final Macronutrients macronutrients;
  final bool compact;
  final String title;
  final bool showDistributionBar;

  const MacronutrientsSummaryCard({
    super.key,
    required this.macronutrients,
    this.compact = false,
    this.title = 'Macronutrientes estimados',
    this.showDistributionBar = true,
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
            if (showDistributionBar) ...[
              const SizedBox(height: AppSpacing.md),
              _MacroDistributionBar(macronutrients: macronutrients),
            ],
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: double.infinity,
            height: 8,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                for (final macro in macronutrients.values)
                  SizedBox(
                    width: total == 0
                        ? width / macronutrients.values.length
                        : width * (macro.grams / total),
                    child: ColoredBox(
                      color: macro.color.withValues(alpha: 0.95),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MacroColorDot(color: macro.color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                macro.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
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
        _MacroColorDot(color: macro.color),
        const SizedBox(width: AppSpacing.xs),
        Text('${macro.label}: ${macro.grams} g'),
      ],
    );
  }
}

class _MacroColorDot extends StatelessWidget {
  final Color color;

  const _MacroColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
