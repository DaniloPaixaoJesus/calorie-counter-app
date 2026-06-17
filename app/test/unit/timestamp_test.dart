import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('Edge case - timestamp preservation', () {
    late HomeViewModel vm;

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
      );
    });

    test('refeicao criada em data nao-hoje fica vinculada ao dia correto', () {
      final dia14 = vm.dataSelecionada.subtract(const Duration(days: 1));

      vm.dataSelecionada = dia14;
      final meal = Meal.create(
        descricao: 'teste 14',
        calorias: 180,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      vm.addMeal(meal);

      expect(vm.mealsDoDia.length, 1);

      vm.voltarParaHoje();
      expect(vm.mealsDoDia, isEmpty);

      vm.dataSelecionada = dia14;
      expect(vm.mealsDoDia.length, 1);
      expect(vm.mealsDoDia.first.descricao, 'teste 14');
    });
  });
}
