import '../../models/meal.dart';

abstract class MealRepository {
  Future<void> add(Meal meal);

  Future<void> update(Meal meal);

  List<Meal> getAll();

  Future<void> remove(String id);

  int getTotalCaloriesHoje();
}
