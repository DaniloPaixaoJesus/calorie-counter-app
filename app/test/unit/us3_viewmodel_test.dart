import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter.dart';
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

    test('updateMeal edita refeicao existente sem duplicar', () async {
      final meal = Meal.create(
        descricao: 'arroz e feijão',
        calorias: 220,
        origem: MealOrigem.texto,
        dataSelecionada: vm.dataSelecionada,
      );
      await vm.addMeal(meal);

      await vm.updateMeal(
        meal.copyWith(
          descricao: 'arroz, feijão e ovo',
          calorias: 310,
        ),
      );

      expect(vm.meals.length, 1);
      expect(vm.meals.single.descricao, 'arroz, feijão e ovo');
      expect(vm.totalHoje, 310);
    });

    test('calorias == 0 indicam necessidade de edição manual', () async {
      await vm.requestEstimate('xyzabc');
      expect(vm.estimate?.calorias, 0);
    });

    test('erro HTTP da API exibe código e pode ser fechado', () async {
      final vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: const _FailingAiAdapter(),
      );

      await vm.requestEstimate('arroz e feijão');

      expect(vm.errorMessage, 'HTTP 503 - Serviço indisponível');
      expect(vm.estimateErrorMessage, 'HTTP 503 - Serviço indisponível');
      expect(vm.homeErrorMessage, isNull);

      vm.clearEstimateError();

      expect(vm.errorMessage, isNull);
      expect(vm.estimateErrorMessage, isNull);
    });
  });
}

class _FailingAiAdapter implements AiAdapter {
  const _FailingAiAdapter();

  @override
  Future<AiEstimate> estimateCalories(String descricao) async {
    throw const AiAdapterException(
      'Serviço indisponível',
      statusCode: 503,
    );
  }
}
