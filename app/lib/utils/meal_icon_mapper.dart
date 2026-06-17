import 'package:calorie_counter_app/design_system/icon_key_registry.dart';
import 'package:flutter/material.dart';

class MealIconMapper {
  MealIconMapper._();

  static String normalize(String? iconKey) {
    return IconKeyRegistry.normalize(iconKey);
  }

  static IconData toIconData(String? iconKey) {
    switch (normalize(iconKey)) {
      case IconKeyRegistry.breakfast:
        return Icons.free_breakfast_rounded;
      case IconKeyRegistry.lunch:
        return Icons.lunch_dining_rounded;
      case IconKeyRegistry.dinner:
        return Icons.dinner_dining_rounded;
      case IconKeyRegistry.snack:
        return Icons.cookie_rounded;
      case IconKeyRegistry.drink:
        return Icons.local_drink_rounded;
      case IconKeyRegistry.dessert:
        return Icons.icecream_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
