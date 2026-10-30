import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/failures.dart';
import 'package:subzero/core/notifications/notification_service.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';
import 'package:subzero/features/inventory/domain/usecases/get_inventory_items_usecase.dart';
import 'package:subzero/features/inventory/domain/usecases/sync_inventory_alerts_usecase.dart';

class MockGetInventoryItemsUseCase extends Mock
    implements GetInventoryItemsUseCase {}

class MockNotificationService extends Mock implements INotificationService {}

void main() {
  late MockGetInventoryItemsUseCase mockGetItems;
  late MockNotificationService mockNotificationService;
  late SyncInventoryAlertsUseCase useCase;

  final now = DateTime.now();

  FrozenItem item({
    required String id,
    bool isConsumed = false,
    bool reminderEnabled = true,
  }) {
    return FrozenItem(
      id: id,
      name: 'Alimento $id',
      category: FoodCategory.cooked,
      frozenDate: now,
      expirationDate: now.add(const Duration(days: 90)),
      isConsumed: isConsumed,
      reminderEnabled: reminderEnabled,
    );
  }

  setUpAll(() {
    // mocktail necesita un valor de referencia para FrozenItem.
    registerFallbackValue(
      FrozenItem(
        id: 'fallback',
        name: 'Alimento',
        category: FoodCategory.cooked,
        frozenDate: DateTime(2024),
        expirationDate: DateTime(2024).add(const Duration(days: 30)),
      ),
    );
  });

  setUp(() {
    mockGetItems = MockGetInventoryItemsUseCase();
    mockNotificationService = MockNotificationService();

    when(() => mockNotificationService.cancelAllAlerts())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.scheduleItemAlerts(any()))
        .thenAnswer((_) async {});

    useCase = SyncInventoryAlertsUseCase(
      getInventoryItemsUseCase: mockGetItems,
      notificationService: mockNotificationService,
    );
  });

  group('SyncInventoryAlertsUseCase (P1-9)', () {
    test('reprograma las alertas de todos los alimentos activos', () async {
      final a = item(id: 'a');
      final b = item(id: 'b');
      when(() => mockGetItems()).thenAnswer((_) async => Right([a, b]));

      final result = await useCase();

      result.fold(
        (failure) => fail('Se esperaba Right, se obtuvo $failure'),
        (scheduled) => expect(scheduled, 2),
      );

      verify(() => mockNotificationService.scheduleItemAlerts(a)).called(1);
      verify(() => mockNotificationService.scheduleItemAlerts(b)).called(1);
    });

    test('reutiliza preloadedItems sin llamar a getInventoryItemsUseCase', () async {
      final a = item(id: 'a');
      final result = await useCase([a]);

      result.fold(
        (failure) => fail('Se esperaba Right, se obtuvo $failure'),
        (scheduled) => expect(scheduled, 1),
      );

      verifyNever(() => mockGetItems());
      verify(() => mockNotificationService.scheduleItemAlerts(a)).called(1);
    });

    test('no reprograma alertas para alimentos consumidos ni desactivados',
        () async {
      final active = item(id: 'activo');
      final consumed = item(id: 'consumido', isConsumed: true);
      final noReminder = item(id: 'sin-recordatorio', reminderEnabled: false);

      when(() => mockGetItems())
          .thenAnswer((_) async => Right([active, consumed, noReminder]));

      final result = await useCase();

      result.fold(
        (failure) => fail('Se esperaba Right, se obtuvo $failure'),
        (scheduled) => expect(scheduled, 1),
      );

      verify(() => mockNotificationService.scheduleItemAlerts(active)).called(1);
      verifyNever(() =>
          mockNotificationService.scheduleItemAlerts(consumed));
      verifyNever(() =>
          mockNotificationService.scheduleItemAlerts(noReminder));
    });

    test('P2-2: cancela primero las alertas previas para limpiar las huerfanas',
        () async {
      when(() => mockGetItems()).thenAnswer((_) async => Right([item(id: 'a')]));

      await useCase();

      // Cancelar antes de reprogramar deja el sistema sin alarmas de
      // alimentos que ya no existen.
      verify(() => mockNotificationService.cancelAllAlerts()).called(1);
    });

    test('un alimento que falla no aborta la resincronizacion del resto',
        () async {
      final failing = item(id: 'falla');
      final ok = item(id: 'ok');

      when(() => mockGetItems()).thenAnswer((_) async => Right([failing, ok]));
      when(() => mockNotificationService.scheduleItemAlerts(failing))
          .thenThrow(Exception('Fallo al programar'));
      when(() => mockNotificationService.scheduleItemAlerts(ok))
          .thenAnswer((_) async {});

      final result = await useCase();

      result.fold(
        (failure) => fail('Se esperaba Right, se obtuvo $failure'),
        (scheduled) => expect(scheduled, 1),
      );

      verify(() => mockNotificationService.scheduleItemAlerts(ok)).called(1);
    });

    test('propaga el fallo si no se puede leer el inventario', () async {
      when(() => mockGetItems())
          .thenAnswer((_) async => const Left(CacheFailure(message: 'Hive')));

      final result = await useCase();

      expect(result, isA<Left<Failure, int>>());
      verifyNever(() => mockNotificationService.scheduleItemAlerts(any()));
    });
  });
}
