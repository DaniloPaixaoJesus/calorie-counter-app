import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/home_page.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';

void main() {
  group('US3 - Widget empty state', () {
    late HomeViewModel vm;

    setUpAll(() async {
      await initializeDateFormatting('pt_BR', null);
    });

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
      );
    });

    Widget buildApp() {
      return MaterialApp(
        theme: NutritionTheme.light,
        home: ChangeNotifierProvider.value(
          value: vm,
          child: const HomePage(),
        ),
      );
    }

    testWidgets('navegar para data sem refeicoes exibe estado vazio', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.textContaining('Nenhuma refeicao em'), findsOneWidget);
    });

    testWidgets('mensagem contem data correta', (tester) async {
      await tester.pumpWidget(buildApp());

      final expectedDate =
          DateFormat('d de MMMM', 'pt_BR').format(vm.dataSelecionada);
      expect(find.text('Nenhuma refeicao em $expectedDate'), findsOneWidget);
    });

    testWidgets('icone renderizado no estado vazio', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });
  });
}
