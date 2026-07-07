import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/home_page.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/services/ai_adapter/ai_adapter_mock.dart';
import 'package:calorie_counter_app/services/repository/in_memory_repository.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';

void main() {
  group('US2 - Widget remocao', () {
    late HomeViewModel vm;

    setUpAll(() async {
      await initializeDateFormatting('pt_BR', null);
    });

    setUp(() {
      vm = HomeViewModel(
        repository: InMemoryRepository(),
        aiAdapter: AiAdapterMock(responseDelay: Duration.zero),
      );

      vm.addMeal(
        Meal.create(
          descricao: 'prato teste',
          calorias: 200,
          origem: MealOrigem.texto,
          dataSelecionada: vm.dataSelecionada,
        ),
      );
    });

    Widget buildApp() {
      return MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: NutritionTheme.light,
        home: ChangeNotifierProvider.value(
          value: vm,
          child: const HomePage(),
        ),
      );
    }

    testWidgets('long-press exibe dialog', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.longPress(find.text('prato teste'));
      await tester.pumpAndSettle();

      expect(find.text('Remover refeicao?'), findsOneWidget);
      expect(find.text('Remover'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('tap no registro abre edicao e salva alteracoes', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('prato teste'));
      await tester.pumpAndSettle();

      expect(find.text('Editar refeicao'), findsOneWidget);
      expect(find.text('Detalhes da refeicao'), findsOneWidget);
      expect(find.text('Observacao'), findsOneWidget);

      await tester.ensureVisible(find.text('Editar'));
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.bySemanticsLabel('Descricao da refeicao'),
        'prato editado',
      );
      await tester.enterText(find.bySemanticsLabel('Calorias (kcal)'), '320');
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(find.text('Editar refeicao'), findsNothing);
      expect(find.text('prato editado'), findsOneWidget);
      expect(find.text('320 kcal'), findsWidgets);
      expect(vm.mealsDoDia.single.descricao, 'prato editado');
      expect(vm.totalHoje, 320);
    });

    testWidgets('cancelar fecha dialog sem remover', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.longPress(find.text('prato teste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('prato teste'), findsOneWidget);
      expect(vm.mealsDoDia.length, 1);
    });

    testWidgets('confirmar remove item e atualiza lista', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.longPress(find.text('prato teste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(find.text('prato teste'), findsNothing);
      expect(vm.mealsDoDia, isEmpty);
      expect(vm.totalHoje, 0);
    });
  });
}
