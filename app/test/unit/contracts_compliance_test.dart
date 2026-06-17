import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  test('HomeViewModel interface compliance with contracts', () {
    final vm = HomeViewModel(
      repository: InMemoryRepository(),
      aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
    );

    expect(vm.podeVoltar, isA<bool>());
    expect(vm.podeAvancar, isA<bool>());
    expect(vm.eHoje, isA<bool>());
    expect(vm.mealsDoDia, isA<List<Meal>>());
    expect(vm.totalHoje, isA<int>());

    expect(() => vm.voltarDia(), returnsNormally);
    expect(() => vm.avancarDia(), returnsNormally);
    expect(() => vm.voltarParaHoje(), returnsNormally);

    expect(vm.getMealById('nao-existe'), isNull);
    expect(() => vm.confirmarRemocao('nao-existe'), returnsNormally);
    expect(() => vm.cancelarRemocao(), returnsNormally);
  });
}
