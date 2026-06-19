import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/features/home/view_model.dart';
import 'package:calorie_counter_app/features/home/home_shell_page.dart';
import 'package:calorie_counter_app/services/ai_adapter/bff_ai_adapter.dart';
import 'package:calorie_counter_app/services/repository/sqlite_meal_repository.dart';
import 'package:calorie_counter_app/themes/nutrition_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final repository = await SqliteMealRepository.open();

  runApp(
    ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        repository: repository,
        aiAdapter: BffAiAdapter(),
      ),
      child: const CalorieCounterApp(),
    ),
  );
}

class CalorieCounterApp extends StatelessWidget {
  const CalorieCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrity',
      theme: NutritionTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomeShellPage(),
    );
  }
}
