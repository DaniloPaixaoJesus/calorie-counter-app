import 'package:flutter/material.dart';

class Macronutrient {
  final String label;
  final int grams;
  final Color color;

  const Macronutrient({
    required this.label,
    required this.grams,
    required this.color,
  });
}

class Macronutrients {
  final Macronutrient protein;
  final Macronutrient carbs;
  final Macronutrient fat;

  const Macronutrients({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Macronutrients.fromGramValues({
    required int proteinGrams,
    required int carbohydrateGrams,
    required int fatGrams,
  }) {
    return Macronutrients(
      protein: Macronutrient(
        label: 'Proteínas',
        grams: proteinGrams < 0 ? 0 : proteinGrams,
        color: _proteinColor,
      ),
      carbs: Macronutrient(
        label: 'Carboidratos',
        grams: carbohydrateGrams < 0 ? 0 : carbohydrateGrams,
        color: _carbsColor,
      ),
      fat: Macronutrient(
        label: 'Gorduras',
        grams: fatGrams < 0 ? 0 : fatGrams,
        color: _fatColor,
      ),
    );
  }

  static const _proteinColor = Color(0xFF2E7D32);
  static const _carbsColor = Color(0xFFB7791F);
  static const _fatColor = Color(0xFFC9A227);

  static const zero = Macronutrients(
    protein: Macronutrient(
      label: 'Proteínas',
      grams: 0,
      color: _proteinColor,
    ),
    carbs: Macronutrient(
      label: 'Carboidratos',
      grams: 0,
      color: _carbsColor,
    ),
    fat: Macronutrient(
      label: 'Gorduras',
      grams: 0,
      color: _fatColor,
    ),
  );

  static const mock = Macronutrients(
    protein: Macronutrient(
      label: 'Proteínas',
      grams: 32,
      color: _proteinColor,
    ),
    carbs: Macronutrient(
      label: 'Carboidratos',
      grams: 48,
      color: _carbsColor,
    ),
    fat: Macronutrient(
      label: 'Gorduras',
      grams: 12,
      color: _fatColor,
    ),
  );

  static const dailyMock = Macronutrients(
    protein: Macronutrient(
      label: 'Proteínas',
      grams: 112,
      color: _proteinColor,
    ),
    carbs: Macronutrient(
      label: 'Carboidratos',
      grams: 152,
      color: _carbsColor,
    ),
    fat: Macronutrient(
      label: 'Gorduras',
      grams: 48,
      color: _fatColor,
    ),
  );

  List<Macronutrient> get values => [protein, carbs, fat];

  int get totalGrams => values.fold(0, (sum, macro) => sum + macro.grams);

  Macronutrients operator +(Macronutrients other) {
    return Macronutrients.fromGramValues(
      proteinGrams: protein.grams + other.protein.grams,
      carbohydrateGrams: carbs.grams + other.carbs.grams,
      fatGrams: fat.grams + other.fat.grams,
    );
  }
}
