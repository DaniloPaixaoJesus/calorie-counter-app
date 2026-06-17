import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('US3 — ViewModel: revisão e confiança', () {
    late HomeViewModel vm;

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
      );
    });

    test('lowConfidence é true quando confidence < 0.7', () async {
      // "xyzabc" não é reconhecido → confidence 0.3
      await vm.requestEstimate('xyzabc');
      expect(vm.estimate, isNotNull);
      expect(vm.lowConfidence, isTrue);
    });

    test('lowConfidence é false quando confidence >= 0.7', () async {
      // alimentos reconhecidos → confidence alta
      await vm.requestEstimate('arroz feijão frango');
      expect(vm.estimate, isNotNull);
      expect(vm.lowConfidence, isFalse);
    });

    test('addMeal atualiza lista e total', () {
      final meal = Meal.create(
        descricao: 'arroz e feijão',
        calorias: 220,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      vm.addMeal(meal);
      expect(vm.meals.length, 1);
      expect(vm.totalHoje, 220);
    });

    test('calorias == 0 indicam necessidade de edição manual', () async {
      await vm.requestEstimate('xyzabc');
      expect(vm.estimate?.calorias, 0);
    });
  });
}
