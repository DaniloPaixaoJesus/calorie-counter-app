import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulário de refeição: campos de descrição e calorias editáveis.
class MealForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: descricao,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Descrição da refeição',
            hintText: 'Ex: arroz, feijão, frango grelhado e salada',
            border: OutlineInputBorder(),
          ),
          onChanged: onDescricaoChanged,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: calorias == 0 ? '' : calorias.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Calorias (kcal)',
            hintText: 'Edite se necessário',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => onCaloriasChanged(int.tryParse(v) ?? 0),
        ),
      ],
    );
  }
}
