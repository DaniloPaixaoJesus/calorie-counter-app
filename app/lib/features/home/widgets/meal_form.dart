import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';

/// Formulário de refeição: campos de descrição e calorias editáveis.
class MealForm extends StatefulWidget {
  final String descricao;
  final int calorias;
  final ValueChanged<String> onDescricaoChanged;
  final ValueChanged<int> onCaloriasChanged;

  const MealForm({
    super.key,
    required this.descricao,
    required this.calorias,
    required this.onDescricaoChanged,
    required this.onCaloriasChanged,
  });

  @override
  State<MealForm> createState() => _MealFormState();
}

class _MealFormState extends State<MealForm> {
  late final TextEditingController _descricaoController;
  late final TextEditingController _caloriasController;

  @override
  void initState() {
    super.initState();
    _descricaoController = TextEditingController(text: widget.descricao);
    _caloriasController = TextEditingController(
      text: widget.calorias == 0 ? '' : widget.calorias.toString(),
    );
  }

  @override
  void didUpdateWidget(MealForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sincroniza a descrição quando atualizada externamente (ex: áudio/transcrição)
    if (widget.descricao != _descricaoController.text) {
      _descricaoController.value = TextEditingValue(
        text: widget.descricao,
        selection: TextSelection.collapsed(offset: widget.descricao.length),
      );
    }

    // Sincroniza calorias quando atualizadas externamente (ex: estimativa da IA)
    final caloriasText = widget.calorias == 0 ? '' : widget.calorias.toString();
    if (caloriasText != _caloriasController.text) {
      _caloriasController.value = TextEditingValue(
        text: caloriasText,
        selection: TextSelection.collapsed(offset: caloriasText.length),
      );
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _caloriasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _descricaoController,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: l10n.mealDescriptionLabel,
            hintText: l10n.mealDescriptionHint,
          ),
          onChanged: widget.onDescricaoChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _caloriasController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.caloriesLabel,
            hintText: l10n.editIfNeeded,
          ),
          onChanged: (v) => widget.onCaloriasChanged(int.tryParse(v) ?? 0),
        ),
      ],
    );
  }
}
