import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('Edge cases - remocao', () {
    late HomeViewModel vm;

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(),
      );
    });

    test('confirmarRemocao multiplas vezes remove apenas uma vez e nao quebra',
        () {
      final meal = Meal.create(
        descricao: 'refeicao',
        calorias: 180,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      vm.addMeal(meal);

      expect(vm.mealsDoDia.length, 1);

      vm.confirmarRemocao(meal.id);
      vm.confirmarRemocao(meal.id);
      vm.confirmarRemocao(meal.id);

      expect(vm.mealsDoDia, isEmpty);
      expect(vm.totalHoje, 0);
      expect(vm.errorMessage, 'Refeição não encontrada');
    });
  });
}
