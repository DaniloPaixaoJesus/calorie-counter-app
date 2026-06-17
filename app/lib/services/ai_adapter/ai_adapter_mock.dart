import 'ai_adapter.dart';
import 'package:calorie_counter_app/design_system/icon_key_registry.dart';

/// Implementação mock do AiAdapter para MVP e testes.
/// Threshold de confiança: < 0.7 → aviso ao usuário.
class AiAdapterMock implements AiAdapter {
  static const _keywords = <String, int>{
    'arroz': 130,
    'feijão': 90,
    'frango': 165,
    'frango grelhado': 165,
    'pão': 80,
    'ovo': 70,
    'salada': 25,
    'maçã': 52,
    'banana': 89,
    'leite': 61,
    'queijo': 113,
    'batata': 77,
    'macarrão': 131,
    'carne': 250,
    'peixe': 140,
    'iogurte': 59,
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

    await Future.delayed(const Duration(milliseconds: 300));

    final lower = descricao.toLowerCase();
    int total = 0;
    final matched = <String>[];

    for (final entry in _keywords.entries) {
      if (lower.contains(entry.key)) {
        total += entry.value;
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
    );
  }
}
