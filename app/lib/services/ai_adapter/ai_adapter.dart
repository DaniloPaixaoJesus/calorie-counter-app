// Contrato: specs/001-home-adicionar-refeicao-ia/contracts/ai_adapter.md

abstract class AiAdapter {
  /// Estima as calorias de uma refeição descrita em texto livre.
  ///
  /// Lança [AiAdapterException] em caso de falha irrecuperável.
  Future<AiEstimate> estimateCalories(String descricao);
}

class AiEstimate {
  final String descricaoInterpretada;
  final int calorias;
  final String? observacao;
  final double confidence;
  final String iconKey;

  const AiEstimate({
    required this.descricaoInterpretada,
    required this.calorias,
    this.observacao,
    required this.confidence,
    required this.iconKey,
  });

  // Compatibilidade com código legado que ainda usa `nota`.
  String? get nota => observacao;
}

class AiAdapterException implements Exception {
  final String message;
  const AiAdapterException(this.message);

  @override
  String toString() => 'AiAdapterException: $message';
}
