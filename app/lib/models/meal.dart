import 'package:uuid/uuid.dart';

enum MealOrigem { texto, audio }

class Meal {
  final String id;
  final String descricao;
  final int calorias;
  final DateTime timestamp;
  final MealOrigem origem;
  final double? aiConfidence;
  final String? nota;

  const Meal({
    required this.id,
    required this.descricao,
    required this.calorias,
    required this.timestamp,
    required this.origem,
    this.aiConfidence,
    this.nota,
  });

  factory Meal.create({
    required String descricao,
    required int calorias,
    required MealOrigem origem,
    double? aiConfidence,
    String? nota,
  }) {
    assert(descricao.isNotEmpty, 'descricao não pode ser vazia');
    assert(calorias >= 0, 'calorias deve ser não-negativo');
    return Meal(
      id: const Uuid().v4(),
      descricao: descricao,
      calorias: calorias,
      timestamp: DateTime.now(),
      origem: origem,
      aiConfidence: aiConfidence,
      nota: nota,
    );
  }

  Meal copyWith({
    String? descricao,
    int? calorias,
    double? aiConfidence,
    String? nota,
  }) {
    return Meal(
      id: id,
      descricao: descricao ?? this.descricao,
      calorias: calorias ?? this.calorias,
      timestamp: timestamp,
      origem: origem,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      nota: nota ?? this.nota,
    );
  }
}
