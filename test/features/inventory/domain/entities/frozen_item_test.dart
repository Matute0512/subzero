import 'package:flutter_test/flutter_test.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';

void main() {
  group('FoodCategory Enum Tests', () {
    test('cada categoría debe tener un defaultShelfLifeDays y displayName válido', () {
      for (final category in FoodCategory.values) {
        expect(category.defaultShelfLifeDays, greaterThan(0));
        expect(category.displayName, isNotEmpty);
      }

      expect(FoodCategory.redMeat.defaultShelfLifeDays, equals(300));
      expect(FoodCategory.poultry.defaultShelfLifeDays, equals(240));
      expect(FoodCategory.fish.defaultShelfLifeDays, equals(120));
      expect(FoodCategory.cooked.defaultShelfLifeDays, equals(90));
      expect(FoodCategory.vegetables.defaultShelfLifeDays, equals(330));
      expect(FoodCategory.bakery.defaultShelfLifeDays, equals(90));
      expect(FoodCategory.other.defaultShelfLifeDays, equals(30));
    });

    test('calculateDefaultExpiration debe sumar defaultShelfLifeDays a la fecha base', () {
      final now = DateTime(2026, 1, 1);
      final expiration = FoodCategory.cooked.calculateDefaultExpiration(now);
      expect(expiration, equals(now.add(const Duration(days: 90))));
    });
  });

  group('FrozenItem Entity Tests', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('debe clasificar como critical cuando daysRemaining <= 7', () {
      final item3Days = FrozenItem(
        id: '1',
        name: 'Carne picada',
        category: FoodCategory.redMeat,
        frozenDate: today.subtract(const Duration(days: 60)),
        expirationDate: today.add(const Duration(days: 3)),
      );

      final item7Days = FrozenItem(
        id: '2',
        name: 'Pollo desmenuzado',
        category: FoodCategory.poultry,
        frozenDate: today.subtract(const Duration(days: 60)),
        expirationDate: today.add(const Duration(days: 7)),
      );

      final itemExpired = FrozenItem(
        id: '3',
        name: 'Salsa bolognesa',
        category: FoodCategory.cooked,
        frozenDate: today.subtract(const Duration(days: 100)),
        expirationDate: today.subtract(const Duration(days: 2)),
      );

      expect(item3Days.daysRemaining, equals(3));
      expect(item3Days.urgencyStatus, equals(UrgencyStatus.critical));
      expect(item3Days.isExpired, isFalse);

      expect(item7Days.daysRemaining, equals(7));
      expect(item7Days.urgencyStatus, equals(UrgencyStatus.critical));

      expect(itemExpired.daysRemaining, equals(-2));
      expect(itemExpired.urgencyStatus, equals(UrgencyStatus.critical));
      expect(itemExpired.isExpired, isTrue);
    });

    test('debe clasificar como warning cuando daysRemaining está entre 8 y 30 días', () {
      final item15Days = FrozenItem(
        id: '4',
        name: 'Filete de merluza',
        category: FoodCategory.fish,
        frozenDate: today.subtract(const Duration(days: 45)),
        expirationDate: today.add(const Duration(days: 15)),
      );

      final item30Days = FrozenItem(
        id: '5',
        name: 'Medialunas',
        category: FoodCategory.bakery,
        frozenDate: today.subtract(const Duration(days: 30)),
        expirationDate: today.add(const Duration(days: 30)),
      );

      expect(item15Days.daysRemaining, equals(15));
      expect(item15Days.urgencyStatus, equals(UrgencyStatus.warning));

      expect(item30Days.daysRemaining, equals(30));
      expect(item30Days.urgencyStatus, equals(UrgencyStatus.warning));
    });

    test('debe clasificar como safe cuando daysRemaining > 30 días', () {
      final itemSafe = FrozenItem(
        id: '6',
        name: 'Espinacas congeladas',
        category: FoodCategory.vegetables,
        frozenDate: today,
        expirationDate: today.add(const Duration(days: 180)),
      );

      expect(itemSafe.daysRemaining, equals(180));
      expect(itemSafe.urgencyStatus, equals(UrgencyStatus.safe));
    });

    test('copyWith debe mantener inmutabilidad y actualizar campos', () {
      final original = FrozenItem(
        id: '1',
        name: 'Pizza casera',
        category: FoodCategory.bakery,
        frozenDate: today,
        expirationDate: today.add(const Duration(days: 60)),
      );

      final updated = original.copyWith(name: 'Pizza de jamón', isConsumed: true);

      expect(updated.id, equals(original.id));
      expect(updated.name, equals('Pizza de jamón'));
      expect(updated.isConsumed, isTrue);
      expect(original.isConsumed, isFalse);
    });

    test('hasActiveAlerts debe ser true solo si reminderEnabled, !isConsumed y !isExpired', () {
      final active = FrozenItem(
        id: '1',
        name: 'Guiso',
        category: FoodCategory.cooked,
        frozenDate: today,
        expirationDate: today.add(const Duration(days: 10)),
        reminderEnabled: true,
        isConsumed: false,
      );

      expect(active.hasActiveAlerts, isTrue);
      expect(active.copyWith(reminderEnabled: false).hasActiveAlerts, isFalse);
      expect(active.copyWith(isConsumed: true).hasActiveAlerts, isFalse);
      expect(
        active.copyWith(expirationDate: today.subtract(const Duration(days: 1))).hasActiveAlerts,
        isFalse,
      );
    });
  });
}

