import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/home/home_page.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';

Widget buildApp() {
  return ChangeNotifierProvider(
    create: (_) => HomeViewModel(
      repository: InMemoryRepository(),
      aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
    ),
    child: MaterialApp(theme: NutritionTheme.light, home: const HomePage()),
  );
}

void main() {
  group('US1 — Registrar refeição por texto', () {
    setUpAll(() async {
      await initializeDateFormatting('pt_BR', null);
    });

    testWidgets('Home exibe estado vazio quando não há refeições', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('0 kcal'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets(
      'Total diário é atualizado ao adicionar refeição via ViewModel',
      (tester) async {
        await tester.pumpWidget(buildApp());

        final vm = tester.element(find.byType(HomePage)).read<HomeViewModel>();

        final meal = Meal.create(
          descricao: 'arroz e feijao',
          calorias: 220,
          origem: MealOrigem.texto,
          dataSelecionada: vm.dataSelecionada,
        );

        vm.addMeal(meal);
        await tester.pumpAndSettle();

        expect(find.text('220 kcal'), findsWidgets);
        expect(vm.totalHoje, 220);
      },
    );
  });
}
