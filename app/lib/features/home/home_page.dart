import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_model.dart';
import 'add_meal_page.dart';
import 'widgets/date_navigation_bar.dart';
import 'widgets/date_empty_state.dart';
import 'widgets/meal_removal_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _showRemovalDialog(
    BuildContext context,
    HomeViewModel vm,
    String mealId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => MealRemovalDialog(
        onConfirm: () {
          Navigator.of(context).pop();
          vm.confirmarRemocao(mealId);
        },
        onCancel: () {
          Navigator.of(context).pop();
          vm.cancelarRemocao();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final meals = vm.mealsDoDia; // Feature 002: Filter by selected date

    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Counter')),
      body: Column(
        children: [
          if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(12),
              child: Text(
                vm.errorMessage!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
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
                ? Center(
                    child: DateEmptyStateWidget(
                      dataSelecionada: vm.dataSelecionada,
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${meal.calorias} kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover refeição',
                              onPressed: () =>
                                  _showRemovalDialog(context, vm, meal.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        onLongPress: () =>
                            _showRemovalDialog(context, vm, meal.id),
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
