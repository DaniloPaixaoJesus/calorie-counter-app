import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/home/widgets/meal_form.dart';
import 'package:calorie_counter_app/features/home/widgets/section_header.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:flutter/material.dart';
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
                const SectionHeader(
                  title: 'Ajuste sua refeicao',
                  subtitle: 'Edite descricao e calorias antes de salvar',
                ),
                const SizedBox(height: AppSpacing.xl),
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
