import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_model.dart';
import 'add_meal_page.dart';
import 'widgets/date_navigation_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final meals = vm.mealsDoDia; // Feature 002: Filter by selected date

    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Counter')),
      body: Column(
        children: [
          // Feature 002: Date Navigation Bar (T016-T018)
          const DateNavigationBar(),
          // T019: Total label for selected date
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Total', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${vm.totalHoje} kcal',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // FR-002: lista ou estado vazio
          Expanded(
            child: meals.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Nenhuma refeição registrada.\nToque em + para adicionar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: meals.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (ctx, i) {
                      final meal = meals[i];
                      // truncar visualmente descrições longas na lista
                      final label = meal.descricao.length > 60
                          ? '${meal.descricao.substring(0, 60)}…'
                          : meal.descricao;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          meal.origem.name == 'audio'
                              ? Icons.mic
                              : Icons.text_fields,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(label),
                        subtitle: meal.nota != null
                            ? Text(
                                meal.nota!,
                                style: const TextStyle(fontSize: 11),
                              )
                            : null,
                        trailing: Text(
                          '${meal.calorias} kcal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onLongPress: () => vm.removeMeal(meal.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      // FR-003/FR-004: botão de navegação para adicionar
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddMealPage())),
        tooltip: 'Adicionar refeição',
        child: const Icon(Icons.add),
      ),
    );
  }
}
