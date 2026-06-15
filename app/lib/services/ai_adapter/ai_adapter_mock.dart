import 'ai_adapter.dart';

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
        nota: 'Não foi possível reconhecer os alimentos. Edite manualmente.',
        confidence: 0.3,
      );
    }

    final confidence = matched.length >= 2 ? 0.9 : 0.75;
    final nota = matched.length == 1
        ? 'Estimativa baseada em porção média de ${matched.first}'
        : 'Estimativa combinada: ${matched.join(', ')}';

    return AiEstimate(
      descricaoInterpretada: descricao,
      calorias: total,
      nota: nota,
      confidence: confidence,
    );
  }
}
