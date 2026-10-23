import 'package:flutter/material.dart';

import '../../domain/entities/food_category.dart';

/// Helper para asociar iconos de Material Design a las categorías de alimentos.
extension FoodCategoryIcon on FoodCategory {
  IconData get icon {
    switch (this) {
      case FoodCategory.redMeat:
        return Icons.restaurant;
      case FoodCategory.poultry:
        return Icons.egg_outlined;
      case FoodCategory.fish:
        return Icons.set_meal;
      case FoodCategory.cooked:
        return Icons.dinner_dining;
      case FoodCategory.vegetables:
        return Icons.eco;
      case FoodCategory.bakery:
        return Icons.bakery_dining;
      case FoodCategory.other:
        return Icons.inventory_2_outlined;
    }
  }
}

