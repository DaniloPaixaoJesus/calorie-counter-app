import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/home_shell_page.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';
import 'package:flutter/material.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  testWidgets('Home smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HomeViewModel(
          repository: InMemoryRepository(),
          aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
        ),
        child: MaterialApp(
          theme: NutritionTheme.light,
          home: const HomeShellPage(),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Adicionar'), findsOneWidget);
  });

  testWidgets('salvar refeicao volta para Home e atualiza lista', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HomeViewModel(
          repository: InMemoryRepository(),
          aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
        ),
        child: MaterialApp(
          theme: NutritionTheme.light,
          home: const HomeShellPage(),
        ),
      ),
    );

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Digitar texto'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.bySemanticsLabel('Descricao da refeicao'),
      'arroz feijão frango',
    );
    await tester.tap(find.text('Estimar com IA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Revisar e confirmar'));
    await tester.tap(find.text('Revisar e confirmar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirmar'));
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar Refeicao'), findsNothing);
    expect(find.text('385 kcal'), findsWidgets);
    expect(find.text('arroz feijão frango'), findsOneWidget);
  });
}
