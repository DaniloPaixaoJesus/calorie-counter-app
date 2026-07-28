import 'dart:async';

import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('salva a refeição localmente antes de disparar sincronização', () async {
    final repository = InMemoryRepository();
    final syncTriggered = Completer<void>();
    final meal = Meal(
      id: 'meal-1',
      descricao: 'Almoço',
      calorias: 500,
      timestamp: DateTime.utc(2026, 7, 27, 12),
      origem: MealOrigem.texto,
    );
    final viewModel = HomeViewModel(
      repository: repository,
      aiAdapter: const AiAdapterMock(),
      onLocalMutation: () async {
        expect(repository.getAll(), contains(meal));
        syncTriggered.complete();
      },
    );

    await viewModel.addMeal(meal);
    await syncTriggered.future;

    expect(repository.getAll(), contains(meal));
    viewModel.dispose();
  });
}
