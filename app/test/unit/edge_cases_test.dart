import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('Edge cases - navegacao rapida', () {
    late HomeViewModel vm;

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
      );
    });

    test('navegacao rapida nao mistura refeicoes de datas', () {
      final hoje = vm.dataSelecionada;
      final menos2 = hoje.subtract(const Duration(days: 2));
      final menos5 = hoje.subtract(const Duration(days: 5));

      vm.addMeal(
        Meal.create(
          descricao: 'hoje',
          calorias: 100,
          origem: MealOrigem.texto,
          dataSelecionada: hoje,
        ),
      );
      vm.addMeal(
        Meal.create(
          descricao: 'menos2',
          calorias: 200,
          origem: MealOrigem.texto,
          dataSelecionada: menos2,
        ),
      );
      vm.addMeal(
        Meal.create(
          descricao: 'menos5',
          calorias: 300,
          origem: MealOrigem.texto,
          dataSelecionada: menos5,
        ),
      );

      vm.dataSelecionada = hoje;
      expect(vm.mealsDoDia.single.descricao, 'hoje');

      vm.dataSelecionada = menos2;
      expect(vm.mealsDoDia.single.descricao, 'menos2');

      vm.dataSelecionada = menos5;
      expect(vm.mealsDoDia.single.descricao, 'menos5');

      vm.dataSelecionada = menos2.add(const Duration(days: 2));
      expect(vm.mealsDoDia.single.descricao, 'hoje');
    });
  });
}
