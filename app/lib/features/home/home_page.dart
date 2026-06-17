import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calorie_counter_app/design_system/layout_breakpoints.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'view_model.dart';
import 'widgets/date_navigation_bar.dart';
import 'widgets/date_empty_state.dart';
import 'widgets/meal_removal_dialog.dart';
import 'widgets/calorie_total_card.dart';
import 'widgets/meal_list_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _showRemovalDialog(
    BuildContext context,
    HomeViewModel vm,
    String mealId,
  ) async {
    final meal = vm.getMealById(mealId);
    await showDialog<void>(
      context: context,
      builder: (context) => MealRemovalDialog(
        meal: meal,
        onConfirm: () async {
          Navigator.of(context).pop();
          await vm.confirmarRemocao(mealId);
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
    final meals = vm.mealsDoDia;
    final horizontalPadding =
        LayoutBreakpoints.isSmall(context) ? AppSpacing.md : AppSpacing.lg;
    final datePrefix = vm.eHoje ? 'Hoje,' : 'Data,';

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LayoutBreakpoints.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        datePrefix,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          MaterialLocalizations.of(context).formatMediumDate(
                            vm.dataSelecionada,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const DateNavigationBar(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: CalorieTotalCard(totalCalorias: vm.totalHoje),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Refeicoes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty)
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: meals.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Center(
                            child: DateEmptyStateWidget(
                              dataSelecionada: vm.dataSelecionada,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          itemCount: meals.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final meal = meals[i];
                            return MealListItem(
                              meal: meal,
                              onRemoveTap: () =>
                                  _showRemovalDialog(context, vm, meal.id),
                              onLongPress: () =>
                                  _showRemovalDialog(context, vm, meal.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
