import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('US2 - Remocao de refeicao', () {
    late HomeViewModel vm;

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(),
      );
    });

    test('remove refeicao da data selecionada com sucesso', () {
      final meal = Meal.create(
        descricao: 'almoco',
        calorias: 300,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      vm.addMeal(meal);

      vm.confirmarRemocao(meal.id);

      expect(vm.mealsDoDia, isEmpty);
      expect(vm.totalHoje, 0);
      expect(vm.errorMessage, isNull);
    });

    test('rejeita remocao de refeicao de outro dia', () {
      final outraData = vm.dataSelecionada.subtract(const Duration(days: 1));
      final meal = Meal.create(
        descricao: 'jantar',
        calorias: 450,
        origem: MealOrigem.texto,
        dataSelecionada: outraData,
      );
      vm.addMeal(meal);

      vm.confirmarRemocao(meal.id);

      expect(vm.meals.length, 1);
      expect(vm.errorMessage, 'Refeição não pertence à data selecionada');
    });

    test('rejeita remocao de refeicao inexistente', () {
      vm.confirmarRemocao('id-inexistente');

      expect(vm.errorMessage, 'Refeição não encontrada');
    });

    test('totalHoje atualizado apos remocao', () {
      final meal1 = Meal.create(
        descricao: 'cafe',
        calorias: 100,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      final meal2 = Meal.create(
        descricao: 'almoco',
        calorias: 250,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      vm.addMeal(meal1);
      vm.addMeal(meal2);

      expect(vm.totalHoje, 350);
      vm.confirmarRemocao(meal1.id);

      expect(vm.totalHoje, 250);
    });
  });
}
