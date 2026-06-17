import 'package:flutter/foundation.dart';

import '../../models/meal.dart';
import 'meal_repository.dart';

/// Repositório em memória para refeições do dia atual.
class InMemoryRepository implements MealRepository {
  final List<Meal> _meals = [];

  /// Adiciona uma refeição à lista.
  @override
  Future<void> add(Meal meal) {
    _meals.add(meal);
    return SynchronousFuture<void>(null);
  }

  /// Retorna todas as refeições registradas.
  @override
  List<Meal> getAll() => List.unmodifiable(_meals);

  /// Remove uma refeição pelo id.
  @override
  Future<void> remove(String id) {
    _meals.removeWhere((m) => m.id == id);
    return SynchronousFuture<void>(null);
  }

  /// Retorna total de calorias para refeições do dia de hoje.
  @override
  int getTotalCaloriesHoje() {
    final hoje = DateTime.now();
    return _meals
        .where(
          (m) =>
              m.timestamp.year == hoje.year &&
              m.timestamp.month == hoje.month &&
              m.timestamp.day == hoje.day,
        )
        .fold(0, (sum, m) => sum + m.calorias);
  }
}
