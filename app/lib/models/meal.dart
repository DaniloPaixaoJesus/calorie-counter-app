import 'package:uuid/uuid.dart';
import 'package:calorie_counter_app/design_system/icon_key_registry.dart';

enum MealOrigem { texto, audio }

class Meal {
  final String id;
  final String descricao;
  final int calorias;
  final DateTime timestamp;
  final MealOrigem origem;
  final double? aiConfidence;
  final String? nota;
  final String iconKey;

  const Meal({
    required this.id,
    required this.descricao,
    required this.calorias,
    required this.timestamp,
    required this.origem,
    this.aiConfidence,
    this.nota,
    this.iconKey = IconKeyRegistry.defaultKey,
  });

  factory Meal.create({
    required String descricao,
    required int calorias,
    required MealOrigem origem,
    required DateTime dataSelecionada,
    double? aiConfidence,
    String? nota,
    String? iconKey,
  }) {
    assert(descricao.isNotEmpty, 'descricao não pode ser vazia');
    assert(calorias >= 0, 'calorias deve ser não-negativo');

    // Ajustar timestamp para a data selecionada combinada com hora local atual
    final agora = DateTime.now();
    final timestampAjustado = DateTime(
      dataSelecionada.year,
      dataSelecionada.month,
      dataSelecionada.day,
      agora.hour,
      agora.minute,
      agora.second,
    );

    return Meal(
      id: const Uuid().v4(),
      descricao: descricao,
      calorias: calorias,
      timestamp: timestampAjustado,
      origem: origem,
      aiConfidence: aiConfidence,
      nota: nota,
      iconKey: IconKeyRegistry.normalize(iconKey),
    );
  }

  Meal copyWith({
    String? descricao,
    int? calorias,
    double? aiConfidence,
    String? nota,
    String? iconKey,
  }) {
    return Meal(
      id: id,
      descricao: descricao ?? this.descricao,
      calorias: calorias ?? this.calorias,
      timestamp: timestamp,
      origem: origem,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      nota: nota ?? this.nota,
      iconKey: IconKeyRegistry.normalize(iconKey ?? this.iconKey),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'descricao': descricao,
      'calorias': calorias,
      'timestamp': timestamp.toIso8601String(),
      'origem': origem.name,
      'aiConfidence': aiConfidence,
      'nota': nota,
      'iconKey': iconKey,
    };
  }

  factory Meal.fromMap(Map<String, Object?> map) {
    final origemName = map['origem'] as String? ?? MealOrigem.texto.name;

    return Meal(
      id: map['id'] as String,
      descricao: map['descricao'] as String,
      calorias: (map['calorias'] as num).toInt(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      origem: MealOrigem.values.firstWhere(
        (value) => value.name == origemName,
        orElse: () => MealOrigem.texto,
      ),
      aiConfidence: (map['aiConfidence'] as num?)?.toDouble(),
      nota: map['nota'] as String?,
      iconKey: IconKeyRegistry.normalize(map['iconKey'] as String?),
    );
  }
}
