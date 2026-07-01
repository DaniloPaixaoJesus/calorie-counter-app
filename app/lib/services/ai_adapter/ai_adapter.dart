// Contrato: specs/001-home-adicionar-refeicao-ia/contracts/ai_adapter.md
import 'package:calorie_counter_app/models/macronutrients.dart';

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
  final Macronutrients macronutrients;

  const AiEstimate({
    required this.descricaoInterpretada,
    required this.calorias,
    this.observacao,
    required this.confidence,
    required this.iconKey,
    this.macronutrients = Macronutrients.zero,
  });

  // Compatibilidade com código legado que ainda usa `nota`.
  String? get nota => observacao;
}

class AiAdapterException implements Exception {
  final String message;
  final int? statusCode;

  const AiAdapterException(this.message, {this.statusCode});

  @override
  String toString() => 'AiAdapterException: $message';
}
