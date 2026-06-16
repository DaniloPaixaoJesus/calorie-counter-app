import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/home_page.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/home/widgets/date_navigation_bar.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';

void main() {
  group('HomePage - Feature 002: Date Navigation Widget Tests', () {
    late HomeViewModel viewModel;
    late InMemoryRepository repository;
    late AiAdapterMock aiAdapter;

    setUpAll(() async {
      await initializeDateFormatting('pt_BR', null);
    });

    setUp(() {
      repository = InMemoryRepository();
      aiAdapter = AiAdapterMock();
      viewModel = HomeViewModel(repository: repository, aiAdapter: aiAdapter);
    });

    Widget createHomePageWidget() {
      return MaterialApp(
        theme: NutritionTheme.light,
        home: ChangeNotifierProvider.value(
          value: viewModel,
          child: const HomePage(),
        ),
      );
    }

    testWidgets('T020: Anterior button navigates to previous day correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomePageWidget());

      // Find and tap "Anterior" button
      final anteriorBtn = find.byIcon(Icons.arrow_back);
      expect(anteriorBtn, findsOneWidget);

      // Get the initial date
      final initialDate = viewModel.dataSelecionada;

      await tester.tap(anteriorBtn);
      await tester.pumpAndSettle();

      // Verify date changed by one day
      expect(
        viewModel.dataSelecionada,
        initialDate.subtract(const Duration(days: 1)),
      );
      expect(viewModel.podeVoltar, true);
    });

    testWidgets('T020: Próximo button enabled only when date < today',
        (WidgetTester tester) async {
      // Go back 2 days
      viewModel.voltarDia();
      viewModel.voltarDia();

      await tester.pumpWidget(createHomePageWidget());

      // "Próximo" button should be enabled
      final proximoBtn = find.byIcon(Icons.arrow_forward);
      expect(proximoBtn, findsOneWidget);
      expect(viewModel.podeAvancar, true);

      // Navigate forward to today
      await tester.tap(proximoBtn);
      await tester.pumpAndSettle();
      await tester.tap(proximoBtn);
      await tester.pumpAndSettle();

      // Now at today, "Próximo" button should be disabled
      expect(viewModel.eHoje, true);
      expect(viewModel.podeAvancar, false);
    });

    testWidgets('T020: Hoje button returns to today',
        (WidgetTester tester) async {
      // Go back 5 days
      for (int i = 0; i < 5; i++) {
        viewModel.voltarDia();
      }

      await tester.pumpWidget(createHomePageWidget());

      // "Hoje" button should be enabled (not eHoje)
      expect(viewModel.eHoje, false);
      final hojeBtn = find.byIcon(Icons.home);
      expect(hojeBtn, findsOneWidget);

      await tester.tap(hojeBtn);
      await tester.pumpAndSettle();

      // Verify back at today
      expect(viewModel.eHoje, true);
    });

    testWidgets('T020: DateNavigationBar renders all buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NutritionTheme.light,
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: Scaffold(
              body: const DateNavigationBar(),
            ),
          ),
        ),
      );

      // Check all three buttons are present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget); // Anterior
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget); // Próximo
      expect(find.byIcon(Icons.home), findsOneWidget); // Hoje

      // Verify button labels
      expect(find.text('Anterior'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
    });
  });
}
