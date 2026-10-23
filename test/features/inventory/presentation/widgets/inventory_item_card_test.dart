import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subzero/core/theme/app_theme.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';
import 'package:subzero/features/inventory/presentation/widgets/inventory_item_card.dart';

void main() {
  group('InventoryItemCard Widget Tests', () {
    final now = DateTime.now();

    final testItem = FrozenItem(
      id: 'card-test-1',
      name: 'Bifes de chorizo',
      category: FoodCategory.redMeat,
      frozenDate: now,
      expirationDate: now.add(const Duration(days: 4)),
      locationNotes: 'Cajón 2',
      quantity: 2.0,
      unit: 'kg',
      isConsumed: false,
    );

    testWidgets('debe renderizar el nombre, ubicación y cantidad correctamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: InventoryItemCard(item: testItem),
          ),
        ),
      );

      expect(find.text('Bifes de chorizo'), findsOneWidget);
      expect(find.textContaining('Cajón 2'), findsOneWidget);
      expect(find.textContaining('2 kg'), findsOneWidget);
    });

    testWidgets('debe disparar onTap cuando el usuario presiona la tarjeta', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: InventoryItemCard(
              item: testItem,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InventoryItemCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('debe mostrar el badge de urgencia correspondiente a estado crítico (<= 7 días)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: InventoryItemCard(item: testItem),
          ),
        ),
      );

      expect(find.textContaining('Vence en'), findsOneWidget);
    });

    testWidgets('debe aplicar estilo atenuado cuando el alimento está consumido', (tester) async {
      final consumedItem = testItem.copyWith(isConsumed: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: InventoryItemCard(item: consumedItem),
          ),
        ),
      );

      expect(find.text('Consumido'), findsOneWidget);
    });
  });
}
