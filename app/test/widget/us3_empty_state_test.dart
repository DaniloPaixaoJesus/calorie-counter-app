import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/home_page.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/l10n/app_localizations.dart';
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

    testWidgets('navegar para data sem refeicoes exibe estado vazio', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.text('Nenhuma refeicao registrada'), findsOneWidget);
    });

    testWidgets('estado vazio nao exibe data no texto principal', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      expect(find.textContaining('Nenhuma refeicao em'), findsNothing);
    });

    testWidgets(
        'estado vazio mantem a data e permite navegar para dias anteriores', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      final formatador = DateFormat('d MMM yyyy', 'pt_BR');
      expect(find.text(formatador.format(vm.dataSelecionada)), findsOneWidget);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }

      expect(find.text(formatador.format(vm.dataSelecionada)), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('icone renderizado no estado vazio', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });
  });
}
