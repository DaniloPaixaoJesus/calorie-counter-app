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
  final String? nota;
  final double confidence;

  const AiEstimate({
    required this.descricaoInterpretada,
    required this.calorias,
    this.nota,
    required this.confidence,
  });
}

class AiAdapterException implements Exception {
  final String message;
  const AiAdapterException(this.message);

  @override
  String toString() => 'AiAdapterException: $message';
}
