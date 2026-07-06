import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/home/widgets/macronutrients_summary_card.dart';
import 'package:calorie_counter_app/features/home/widgets/meal_form.dart';
import 'package:calorie_counter_app/features/home/widgets/section_header.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/subscription/subscription_service.dart';
import 'package:calorie_counter_app/utils/meal_icon_mapper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditMealPage extends StatefulWidget {
  final Meal meal;

  const EditMealPage({super.key, required this.meal});

  @override
  State<EditMealPage> createState() => _EditMealPageState();
}

class _EditMealPageState extends State<EditMealPage> {
  late String _descricao;
  late int _calorias;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _descricao = widget.meal.descricao;
    _calorias = widget.meal.calorias;
  }

  Future<void> _salvar(HomeViewModel vm) async {
    final descricao = _descricao.trim();
    if (descricao.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite pelo menos 2 caracteres.')),
      );
      return;
    }

    if (_calorias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as calorias antes de salvar.')),
      );
      return;
    }

    await vm.updateMeal(
      widget.meal.copyWith(
        descricao: descricao,
        calorias: _calorias,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final meal = widget.meal;
    final colorScheme = Theme.of(context).colorScheme;
    final subscriptionService = context.watch<SubscriptionService?>();
    final isPremium = subscriptionService?.isPremium ?? false;
    final iconData = MealIconMapper.toIconData(meal.iconKey);
    final date = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(meal.timestamp);
    final confidence = meal.aiConfidence == null
        ? 'Nao informada'
        : '${(meal.aiConfidence! * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        meal.descricao,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${meal.calorias} kcal',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _infoRow(context, 'Descricao', meal.descricao),
        _infoRow(context, 'Calorias', '${meal.calorias} kcal'),
        if (isPremium) ...[
          MacronutrientsSummaryCard(
            macronutrients: meal.macronutrients ?? Macronutrients.zero,
            compact: true,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _infoRow(context, 'Origem',
            meal.origem == MealOrigem.audio ? 'Audio' : 'Texto'),
        _infoRow(context, 'Data e hora', date),
        _infoRow(context, 'Confianca da IA', confidence),
        _infoRow(
          context,
          'Observacao',
          meal.nota == null || meal.nota!.trim().isEmpty
              ? 'Sem observacao'
              : meal.nota!,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: () => setState(() => _isEditing = true),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context, HomeViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MealForm(
          descricao: _descricao,
          calorias: _calorias,
          onDescricaoChanged: (value) {
            setState(() => _descricao = value);
          },
          onCaloriasChanged: (value) {
            setState(() => _calorias = value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => _salvar(vm),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Salvar alteracoes'),
        ),
        TextButton(
          onPressed: () => setState(() => _isEditing = false),
          child: const Text('Voltar aos detalhes'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar refeicao')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: LayoutBreakpoints.contentMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title:
                      _isEditing ? 'Editar refeicao' : 'Detalhes da refeicao',
                  subtitle: _isEditing
                      ? 'Altere descricao e calorias antes de salvar'
                      : 'Revise as informacoes registradas',
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_isEditing)
                  _buildEditForm(context, vm)
                else
                  _buildDetails(context),
                const SizedBox(height: AppSpacing.md),
                if (!_isEditing)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
