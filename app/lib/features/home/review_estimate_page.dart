import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/utils/meal_icon_mapper.dart';
import 'package:calorie_counter_app/features/home/widgets/macronutrients_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
  late final TextEditingController _descricaoController;
  late final TextEditingController _caloriasController;

  @override
  void initState() {
    super.initState();
    _descricaoController =
        TextEditingController(text: widget.descricaoInterpretada);
    _caloriasController =
        TextEditingController(text: widget.calorias.toString());
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _caloriasController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final calorias = int.tryParse(_caloriasController.text.trim()) ?? 0;
    Navigator.of(context).pop(
      ReviewEstimateResult(
        descricao: _descricaoController.text.trim(),
        calorias: calorias,
        macronutrients: widget.macronutrients,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconData = MealIconMapper.toIconData(widget.iconKey);
    final colorScheme = Theme.of(context).colorScheme;
    final subscriptionService = context.watch<SubscriptionService?>();
    final isPremium = subscriptionService?.isPremium ?? false;
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar estimativa')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: LayoutBreakpoints.contentMaxWidth(context),
          ),
          child: ListView(
            padding: EdgeInsets.all(horizontalPadding),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(iconData, color: colorScheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimativa da IA',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Confianca: ${(widget.confidence * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Descricao interpretada',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descricaoController,
                maxLines: 2,
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Estimativa de calorias',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${widget.calorias} kcal',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (isPremium) ...[
                const SizedBox(height: AppSpacing.lg),
                MacronutrientsSummaryCard(
                  macronutrients: widget.macronutrients,
                ),
              ],
              if (widget.observacao != null &&
                  widget.observacao!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Observacao da IA',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.observacao!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _caloriasController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Calorias (kcal)'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: FilledButton(
                      onPressed: _confirmar,
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
