import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('US3 - Empty state por data', () {
    late HomeViewModel vm;

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(),
      );
    });

    test('mealsDoDia vazio em data sem refeicoes', () {
      expect(vm.mealsDoDia, isEmpty);
    });

    test('mealsDoDia nao-vazio apos adicionar refeicao', () {
      vm.addMeal(
        Meal.create(
          descricao: 'lanche',
          calorias: 150,
          origem: MealOrigem.texto,
          dataSelecionada: vm.dataSelecionada,
        ),
      );

      expect(vm.mealsDoDia, isNotEmpty);
    });

    test('mealsDoDia vazio apos remover ultima refeicao', () {
      final meal = Meal.create(
        descricao: 'jantar',
        calorias: 350,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      vm.addMeal(meal);

      vm.confirmarRemocao(meal.id);

      expect(vm.mealsDoDia, isEmpty);
      expect(vm.totalHoje, 0);
    });
  });
}
