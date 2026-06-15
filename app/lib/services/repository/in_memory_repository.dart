import '../../models/meal.dart';

/// Repositório em memória para refeições do dia atual.
class InMemoryRepository {
  final List<Meal> _meals = [];

  /// Adiciona uma refeição à lista.
  void add(Meal meal) => _meals.add(meal);

  /// Retorna todas as refeições registradas.
  List<Meal> getAll() => List.unmodifiable(_meals);

  /// Remove uma refeição pelo id.
  void remove(String id) => _meals.removeWhere((m) => m.id == id);

  /// Retorna total de calorias para refeições do dia de hoje.
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
