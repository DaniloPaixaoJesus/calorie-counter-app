import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/utils/meal_icon_mapper.dart';
import 'package:flutter/material.dart';

class ReviewEstimateResult {
  final String descricao;
  final int calorias;
  final Macronutrients macronutrients;

  const ReviewEstimateResult({
    required this.descricao,
    required this.calorias,
    required this.macronutrients,
  });
}

class ReviewEstimatePage extends StatefulWidget {
  final String descricaoInterpretada;
  final int calorias;
  final double confidence;
  final String? observacao;
  final String iconKey;
  final Macronutrients macronutrients;

  const ReviewEstimatePage({
    super.key,
    required this.descricaoInterpretada,
    required this.calorias,
    required this.confidence,
    required this.observacao,
    required this.iconKey,
    required this.macronutrients,
  });

  @override
  State<ReviewEstimatePage> createState() => _ReviewEstimatePageState();
}

class _ReviewEstimatePageState extends State<ReviewEstimatePage> {
  void _confirmar() {
    Navigator.of(context).pop(
      ReviewEstimateResult(
        descricao: widget.descricaoInterpretada,
        calorias: widget.calorias,
        macronutrients: widget.macronutrients,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconData = MealIconMapper.toIconData(widget.iconKey);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewEstimateTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: LayoutBreakpoints.contentMaxWidth(context),
          ),
          child: ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              Text(
                l10n.reviewMealDetails,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child:
                          Icon(iconData, color: colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.descricaoInterpretada,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${widget.calorias} kcal',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.estimatedMacros,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final macro in widget.macronutrients.values) ...[
                _MacroLine(macro: macro),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (widget.observacao != null &&
                  widget.observacao!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.aiObservation,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.observacao!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.aiConfidence,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${(widget.confidence * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirmar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.confirm),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final Macronutrient macro;

  const _MacroLine({required this.macro});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: macro.color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            _localizedMacroLabel(l10n, macro),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Text(
          '${macro.grams} g',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

String _localizedMacroLabel(AppLocalizations l10n, Macronutrient macro) {
  switch (macro.label) {
    case 'Proteínas':
      return l10n.proteins;
    case 'Carboidratos':
      return l10n.carbs;
    case 'Gorduras':
      return l10n.fats;
  }
  return macro.label;
}
