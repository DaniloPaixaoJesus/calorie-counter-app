import 'ai_adapter.dart';
import 'package:calorie_counter_app/design_system/icon_key_registry.dart';
import 'package:calorie_counter_app/models/macronutrients.dart';

/// Implementação mock do AiAdapter para MVP e testes.
/// Threshold de confiança: < 0.7 → aviso ao usuário.
class AiAdapterMock implements AiAdapter {
  static const defaultResponseDelay = Duration(seconds: 5);

  final Duration responseDelay;

  const AiAdapterMock({this.responseDelay = defaultResponseDelay});

  static const _keywords = <String, _FoodMacroEstimate>{
    'arroz': _FoodMacroEstimate(130, 3, 28, 0),
    'feijão': _FoodMacroEstimate(90, 6, 16, 1),
    'frango': _FoodMacroEstimate(165, 31, 0, 4),
    'frango grelhado': _FoodMacroEstimate(165, 31, 0, 4),
    'pão': _FoodMacroEstimate(80, 3, 15, 1),
    'ovo': _FoodMacroEstimate(70, 6, 1, 5),
    'salada': _FoodMacroEstimate(25, 1, 4, 1),
    'maçã': _FoodMacroEstimate(52, 0, 14, 0),
    'banana': _FoodMacroEstimate(89, 1, 23, 0),
    'leite': _FoodMacroEstimate(61, 3, 5, 3),
    'queijo': _FoodMacroEstimate(113, 7, 1, 9),
    'batata': _FoodMacroEstimate(77, 2, 17, 0),
    'macarrão': _FoodMacroEstimate(131, 5, 25, 1),
    'carne': _FoodMacroEstimate(250, 26, 0, 17),
    'peixe': _FoodMacroEstimate(140, 22, 0, 5),
    'iogurte': _FoodMacroEstimate(59, 4, 7, 2),
  };

  String _inferIconKey(String lowerDescription) {
    final hour = DateTime.now().hour;
    if (lowerDescription.contains('café') ||
        lowerDescription.contains('pão') ||
        lowerDescription.contains('ovo') ||
        hour < 11) {
      return IconKeyRegistry.breakfast;
    }
    if (lowerDescription.contains('suco') ||
        lowerDescription.contains('água') ||
        lowerDescription.contains('agua') ||
        lowerDescription.contains('café')) {
      return IconKeyRegistry.drink;
    }
    if (lowerDescription.contains('bolo') ||
        lowerDescription.contains('doce') ||
        lowerDescription.contains('sorvete')) {
      return IconKeyRegistry.dessert;
    }
    if (lowerDescription.contains('lanche') || hour >= 16 && hour < 19) {
      return IconKeyRegistry.snack;
    }
    if (hour >= 19) {
      return IconKeyRegistry.dinner;
    }
    return IconKeyRegistry.lunch;
  }

  @override
  Future<AiEstimate> estimateCalories(String descricao) async {
    if (descricao.trim().length < 2) {
      throw const AiAdapterException('Descrição muito curta');
    }
    if (descricao.length > 1000) {
      throw const AiAdapterException('Descrição muito longa (máx 1.000 chars)');
    }

    await Future.delayed(responseDelay);

    final lower = descricao.toLowerCase();
    int total = 0;
    int proteinGrams = 0;
    int carbohydrateGrams = 0;
    int fatGrams = 0;
    final matched = <String>[];

    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key)) {
        total += entry.value.calories;
        proteinGrams += entry.value.proteinGrams;
        carbohydrateGrams += entry.value.carbohydrateGrams;
        fatGrams += entry.value.fatGrams;
        matched.add(entry.key);
      }
    }

    if (matched.isEmpty) {
      return AiEstimate(
        descricaoInterpretada: descricao,
        calorias: 0,
        observacao:
            'Não foi possível reconhecer os alimentos. Quantidade não informada; assumido valor padrão.',
        confidence: 0.3,
        iconKey: IconKeyRegistry.defaultKey,
      );
    }

    final confidence = matched.length >= 2 ? 0.9 : 0.75;
    final observacao = matched.length == 1
        ? 'Estimativa baseada em porção média de ${matched.first}'
        : 'Estimativa combinada: ${matched.join(', ')}';

    return AiEstimate(
      descricaoInterpretada: descricao,
      calorias: total,
      observacao: observacao,
      confidence: confidence,
      iconKey: _inferIconKey(lower),
      macronutrients: Macronutrients.fromGramValues(
        proteinGrams: proteinGrams,
        carbohydrateGrams: carbohydrateGrams,
        fatGrams: fatGrams,
      ),
    );
  }
}

class _FoodMacroEstimate {
  final int calories;
  final int proteinGrams;
  final int carbohydrateGrams;
  final int fatGrams;

  const _FoodMacroEstimate(
    this.calories,
    this.proteinGrams,
    this.carbohydrateGrams,
    this.fatGrams,
  );
}
