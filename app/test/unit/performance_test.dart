import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  test('transicao entre datas em volume MVP fica abaixo de 500ms', () {
    final vm = HomeViewModel(
      repository: InMemoryRepository(),
      aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
    );

    for (int i = 0; i < 100; i++) {
      vm.addMeal(
        Meal.create(
          descricao: 'meal-$i',
          calorias: i,
          origem: MealOrigem.texto,
          dataSelecionada: vm.dataSelecionada.subtract(Duration(days: i % 10)),
        ),
      );
    }

    final sw = Stopwatch()..start();
    vm.voltarDia();
    vm.avancarDia();
    sw.stop();

    expect(sw.elapsedMilliseconds < 500, isTrue);
  });
}
