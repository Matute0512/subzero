/// Enum exhaustivo de categorías de alimentos para congelador y despensa.
///
/// La capa de dominio permanece pura sin dependencias de Flutter ni SDKs externos.
enum FoodCategory {
  redMeat,
  poultry,
  fish,
  cooked,
  vegetables,
  bakery,
  other;

  /// Cantidad de días recomendada por defecto para cada categoría en el congelador.
  int get defaultShelfLifeDays {
    switch (this) {
      case FoodCategory.redMeat:
        return 300; // 8 - 12 meses
      case FoodCategory.poultry:
        return 240; // 6 - 9 meses
      case FoodCategory.fish:
        return 120; // 3 - 4 meses
      case FoodCategory.cooked:
        return 90; // 2 - 3 meses
      case FoodCategory.vegetables:
        return 330; // 10 - 12 meses
      case FoodCategory.bakery:
        return 90; // 2 - 3 meses
      case FoodCategory.other:
        return 30; // 1 mes
    }
  }

  /// Nombre descriptivo y legible en español.
  String get displayName {
    switch (this) {
      case FoodCategory.redMeat:
        return 'Carnes Rojas';
      case FoodCategory.poultry:
        return 'Aves y Pollo';
      case FoodCategory.fish:
        return 'Pescados y Mariscos';
      case FoodCategory.cooked:
        return 'Comida Cocida / Tupper';
      case FoodCategory.vegetables:
        return 'Verduras y Frutas';
      case FoodCategory.bakery:
        return 'Panadería y Masas';
      case FoodCategory.other:
        return 'Otros';
    }
  }

  /// Calcula la fecha sugerida de caducidad a partir de una fecha de congelación.
  DateTime calculateDefaultExpiration(DateTime frozenDate) {
    return frozenDate.add(Duration(days: defaultShelfLifeDays));
  }
}
