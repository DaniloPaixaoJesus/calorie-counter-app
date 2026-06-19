import 'package:calorie_counter_app/models/meal.dart';
import 'package:calorie_counter_app/design_system/app_spacing.dart';
import 'package:calorie_counter_app/utils/meal_icon_mapper.dart';
import 'package:flutter/material.dart';

class MealListItem extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onRemoveTap;
  final VoidCallback onLongPress;

  const MealListItem({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onRemoveTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = MealIconMapper.toIconData(meal.iconKey);
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '${meal.descricao}, ${meal.calorias} quilocalorias',
      button: true,
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(iconData, color: colorScheme.primary),
        ),
        title: Text(
          meal.descricao,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: meal.nota == null || meal.nota!.isEmpty
            ? null
            : Text(
                meal.nota!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text(
              '${meal.calorias} kcal',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              tooltip: 'Remover refeicao',
              onPressed: onRemoveTap,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
