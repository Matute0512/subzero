import 'package:flutter_test/flutter_test.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';

void main() {
  group('Smoke & Sanity Tests', () {
    test('instanciación y validación de frozen item básico', () {
      final now = DateTime.now();
      final item = FrozenItem(
        id: 'sanity-1',
        name: 'Pescado blanco',
        category: FoodCategory.fish,
        frozenDate: now,
        expirationDate: now.add(const Duration(days: 120)),
      );

      expect(item.id, equals('sanity-1'));
      expect(item.category.displayName, equals('Pescados y Mariscos'));
      expect(item.urgencyStatus, equals(UrgencyStatus.safe));
    });
  });
}
