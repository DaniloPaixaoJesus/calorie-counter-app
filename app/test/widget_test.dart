import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/home_page.dart';
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
          aiAdapter: AiAdapterMock(),
        ),
        child: MaterialApp(theme: NutritionTheme.light, home: const HomePage()),
      ),
    );

    expect(find.text('Calorie Counter'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
