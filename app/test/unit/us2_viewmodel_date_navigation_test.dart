import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';

void main() {
  group('HomeViewModel - Feature 002: Date Navigation', () {
    late HomeViewModel viewModel;
    late InMemoryRepository repository;
    late AiAdapterMock aiAdapter;

    setUp(() {
      repository = InMemoryRepository();
      aiAdapter = AiAdapterMock();
      viewModel = HomeViewModel(repository: repository, aiAdapter: aiAdapter);
    });

    test('T006: dataSelecionada initializes to today', () {
      final hoje = DateTime.now();
      final dataSelecionada = viewModel.dataSelecionada;
      expect(dataSelecionada.year, hoje.year);
      expect(dataSelecionada.month, hoje.month);
      expect(dataSelecionada.day, hoje.day);
      expect(dataSelecionada.hour, 0); // toLocalDate() zeroes out time
      expect(dataSelecionada.minute, 0);
      expect(dataSelecionada.second, 0);
    });

    test('T009: podeVoltar always returns true', () {
      expect(viewModel.podeVoltar, true);
      viewModel.voltarDia();
      expect(viewModel.podeVoltar, true);
      viewModel.voltarDia();
      expect(viewModel.podeVoltar, true);
    });

    test('T010: podeAvancar is false when dataSelecionada == today', () {
      expect(viewModel.eHoje, true);
      expect(viewModel.podeAvancar, false);
    });

    test('T010: podeAvancar is true when dataSelecionada < today', () {
      viewModel.voltarDia();
      expect(viewModel.podeAvancar, true);
    });

    test('T011: eHoje is true when dataSelecionada == today', () {
      expect(viewModel.eHoje, true);
    });

    test('T011: eHoje is false when dataSelecionada != today', () {
      viewModel.voltarDia();
      expect(viewModel.eHoje, false);
    });

    test('T007: mealsDoDia filters by date year/month/day', () {
      // Add meal today
      final hoje = DateTime.now();
      final mealToday = Meal.create(
        descricao: 'Almoço',
        calorias: 500,
        origem: MealOrigem.texto,
        dataSelecionada: hoje,
      );
      repository.add(mealToday);

      // Add meal yesterday
      final yesterday = hoje.subtract(Duration(days: 1));
      final mealYesterday = Meal.create(
        descricao: 'Café',
        calorias: 200,
        origem: MealOrigem.texto,
        dataSelecionada: yesterday,
      );
      repository.add(mealYesterday);

      // Check mealsDoDia filters correctly
      expect(viewModel.mealsDoDia.length, 1);
      expect(viewModel.mealsDoDia[0].descricao, 'Almoço');

      // Navigate to yesterday
      viewModel.voltarDia();
      expect(viewModel.mealsDoDia.length, 1);
      expect(viewModel.mealsDoDia[0].descricao, 'Café');
    });

    test('T008: totalHoje uses mealsDoDia (Feature 002)', () {
      final hoje = DateTime.now();
      final meal1 = Meal.create(
        descricao: 'Almoço',
        calorias: 500,
        origem: MealOrigem.texto,
        dataSelecionada: hoje,
      );
      final meal2 = Meal.create(
        descricao: 'Lanche',
        calorias: 200,
        origem: MealOrigem.texto,
        dataSelecionada: hoje,
      );
      repository.add(meal1);
      repository.add(meal2);

      expect(viewModel.totalHoje, 700);

      // Add meal to yesterday (should not affect today's total)
      final yesterday = hoje.subtract(Duration(days: 1));
      final meal3 = Meal.create(
        descricao: 'Café',
        calorias: 300,
        origem: MealOrigem.texto,
        dataSelecionada: yesterday,
      );
      repository.add(meal3);

      expect(viewModel.totalHoje, 700); // Yesterday's meal not counted
    });
  });
}
