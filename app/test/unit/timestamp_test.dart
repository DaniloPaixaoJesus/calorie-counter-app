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

    test('data atual acompanha a virada do dia enquanto o app permanece aberto',
        () {
      var now = DateTime(2026, 7, 26, 23, 59);
      final rolloverViewModel = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
        now: () => now,
      );

      expect(rolloverViewModel.dataSelecionada, DateTime(2026, 7, 26));

      now = DateTime(2026, 7, 27, 0, 1);
      rolloverViewModel.refreshCurrentDate();

      expect(rolloverViewModel.dataSelecionada, DateTime(2026, 7, 27));
    });

    test('instante recebido com offset é reconstruído na hora local', () {
      final source = DateTime.parse('2026-07-27T23:30:00-03:00');
      final meal = Meal.fromMap({
        'id': 'remote-meal',
        'descricao': 'Refeição remota',
        'calorias': 300,
        'timestamp': '2026-07-27T23:30:00-03:00',
        'origem': 'texto',
        'iconKey': 'meal',
        'modifiedAt': '2026-07-28T02:31:00Z',
      });

      expect(meal.timestamp, source.toLocal());
      expect(meal.timestamp.isUtc, isFalse);
    });
  });
}
