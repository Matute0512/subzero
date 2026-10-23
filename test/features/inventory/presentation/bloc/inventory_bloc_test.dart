import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/failures.dart';
import 'package:subzero/core/notifications/notification_service.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';
import 'package:subzero/features/inventory/domain/repositories/inventory_quota_policy.dart';
import 'package:subzero/features/inventory/domain/usecases/add_frozen_item_usecase.dart';
import 'package:subzero/features/inventory/domain/usecases/delete_frozen_item_usecase.dart';
import 'package:subzero/features/inventory/domain/usecases/get_inventory_items_usecase.dart';
import 'package:subzero/features/inventory/domain/usecases/toggle_consumed_usecase.dart';
import 'package:subzero/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:subzero/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:subzero/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:subzero/features/inventory/domain/usecases/update_frozen_item_usecase.dart';
import 'package:subzero/features/inventory/domain/usecases/sync_inventory_alerts_usecase.dart';

class MockGetInventoryItemsUseCase extends Mock
    implements GetInventoryItemsUseCase {}

class MockAddFrozenItemUseCase extends Mock implements AddFrozenItemUseCase {}

class MockDeleteFrozenItemUseCase extends Mock
    implements DeleteFrozenItemUseCase {}

class MockToggleConsumedUseCase extends Mock
    implements ToggleConsumedUseCase {}

class MockUpdateFrozenItemUseCase extends Mock
    implements UpdateFrozenItemUseCase {}

class MockNotificationService extends Mock implements INotificationService {}

class MockInventoryQuotaPolicy extends Mock implements IInventoryQuotaPolicy {}

class MockSyncInventoryAlertsUseCase extends Mock
    implements SyncInventoryAlertsUseCase {}

void main() {
  late InventoryBloc bloc;
  late MockGetInventoryItemsUseCase mockGetItems;
  late MockAddFrozenItemUseCase mockAddItem;
  late MockDeleteFrozenItemUseCase mockDeleteItem;
  late MockToggleConsumedUseCase mockToggleConsumed;
  late MockUpdateFrozenItemUseCase mockUpdateItem;
  late MockNotificationService mockNotificationService;
  late MockInventoryQuotaPolicy mockQuotaPolicy;
  late MockSyncInventoryAlertsUseCase mockSyncAlerts;

  final testDate = DateTime.now();
  final sampleItem = FrozenItem(
    id: 'test-1',
    name: 'Guiso de lentejas',
    category: FoodCategory.cooked,
    frozenDate: testDate,
    expirationDate: testDate.add(const Duration(days: 90)),
    reminderEnabled: true,
    isConsumed: false,
  );

  setUpAll(() {
    registerFallbackValue(sampleItem);
  });

  setUp(() {
    mockGetItems = MockGetInventoryItemsUseCase();
    mockAddItem = MockAddFrozenItemUseCase();
    mockDeleteItem = MockDeleteFrozenItemUseCase();
    mockToggleConsumed = MockToggleConsumedUseCase();
    mockUpdateItem = MockUpdateFrozenItemUseCase();
    mockNotificationService = MockNotificationService();
    mockQuotaPolicy = MockInventoryQuotaPolicy();
    mockSyncAlerts = MockSyncInventoryAlertsUseCase();

    when(() => mockNotificationService.scheduleItemAlerts(any()))
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelItemAlerts(any()))
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelAllAlerts())
        .thenAnswer((_) async {});

    when(() => mockSyncAlerts()).thenAnswer((_) async => const Right(0));

    when(() => mockQuotaPolicy.canAddItem(
          currentActiveCount: any(named: 'currentActiveCount'),
        )).thenAnswer((_) async => const Right(true));

    bloc = InventoryBloc(
      getInventoryItemsUseCase: mockGetItems,
      addFrozenItemUseCase: mockAddItem,
      deleteFrozenItemUseCase: mockDeleteItem,
      toggleConsumedUseCase: mockToggleConsumed,
      updateFrozenItemUseCase: mockUpdateItem,
      notificationService: mockNotificationService,
      quotaPolicy: mockQuotaPolicy,
      syncInventoryAlertsUseCase: mockSyncAlerts,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('el estado inicial debe ser InventoryInitial', () {
    expect(bloc.state, equals(const InventoryInitial()));
  });

  group('LoadInventoryEvent Tests', () {
    test('debe emitir [InventoryLoading, InventoryLoaded] cuando la carga es exitosa',
        () async {
      when(() => mockGetItems())
          .thenAnswer((_) async => Right([sampleItem]));

      final expectedStates = [
        const InventoryLoading(),
        InventoryLoaded(
          items: [sampleItem],
          filteredItems: [sampleItem],
        ),
      ];

      final expectation = expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const LoadInventoryEvent());
      await expectation;
    });
  });

  group('AddInventoryItemEvent Tests', () {
    test('debe llamar a AddFrozenItemUseCase, programar alertas y recargar la lista cuando está dentro del límite',
        () async {
      when(() => mockAddItem(sampleItem))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetItems())
          .thenAnswer((_) async => Right([sampleItem]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          InventoryLoaded(
            items: [sampleItem],
            filteredItems: [sampleItem],
          ),
        ]),
      );

      bloc.add(AddInventoryItemEvent(sampleItem));
      await expectation;

      verify(() => mockAddItem(sampleItem)).called(1);
      verify(() => mockNotificationService.scheduleItemAlerts(sampleItem)).called(1);
    });

    test('bloquea la inserción y emite InventoryLimitReachedState cuando la cuota no permite agregar', () async {
      final activeList = List.generate(
        25,
        (i) => sampleItem.copyWith(id: 'item-$i', isConsumed: false),
      );
      final newItem = sampleItem.copyWith(id: 'item-26');

      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer((_) async => const Right(false));
      when(() => mockGetItems())
          .thenAnswer((_) async => Right(activeList));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const InventoryLimitReachedState(activeCount: 25),
        ]),
      );

      bloc.add(AddInventoryItemEvent(newItem));
      await expectation;

      verifyNever(() => mockAddItem(newItem));
      verifyNever(() => mockNotificationService.scheduleItemAlerts(newItem));
    });

    test('permite superar el límite de 25 items cuando la política de cuota lo permite', () async {
      final activeList = List.generate(
        25,
        (i) => sampleItem.copyWith(id: 'item-$i', isConsumed: false),
      );
      final newItem = sampleItem.copyWith(id: 'item-26');

      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer((_) async => const Right(true));
      when(() => mockAddItem(newItem))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetItems())
          .thenAnswer((_) async => Right([...activeList, newItem]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          InventoryLoaded(
            items: [...activeList, newItem],
            filteredItems: [...activeList, newItem],
          ),
        ]),
      );

      bloc.add(AddInventoryItemEvent(newItem));
      await expectation;

      verify(() => mockAddItem(newItem)).called(1);
    });

    test('no debe programar alertas si reminderEnabled es false', () async {
      final itemNoReminder = sampleItem.copyWith(reminderEnabled: false);
      when(() => mockAddItem(itemNoReminder))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetItems())
          .thenAnswer((_) async => Right([itemNoReminder]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          InventoryLoaded(
            items: [itemNoReminder],
            filteredItems: [itemNoReminder],
          ),
        ]),
      );

      bloc.add(AddInventoryItemEvent(itemNoReminder));
      await expectation;

      verify(() => mockAddItem(itemNoReminder)).called(1);
      verifyNever(() => mockNotificationService.scheduleItemAlerts(any()));
    });
  });

  group('Política de cuota Tests', () {
    test('expone canAddItem en false en el estado cuando la cuota no permite agregar',
        () async {
      when(() => mockGetItems()).thenAnswer((_) async => Right([sampleItem]));
      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer((_) async => const Right(false));

      bloc.add(const LoadInventoryEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<InventoryState>((state) =>
            state is InventoryLoaded && state.canAddItem == false)),
      );
    });

    test('consulta la política con el número de alimentos activos', () async {
      final activeList = List.generate(
        3,
        (i) => sampleItem.copyWith(id: 'item-$i', isConsumed: false),
      );
      final consumedItem = sampleItem.copyWith(id: 'consumed', isConsumed: true);

      when(() => mockGetItems())
          .thenAnswer((_) async => Right([...activeList, consumedItem]));
      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer((_) async => const Right(true));

      bloc.add(const LoadInventoryEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<InventoryState>(
            (state) => state is InventoryLoaded)),
      );

      verify(() => mockQuotaPolicy.canAddItem(currentActiveCount: 3)).called(1);
    });

    test('aplica el límite gratuito cuando la política no puede determinar la suscripción',
        () async {
      final activeList = List.generate(
        25,
        (i) => sampleItem.copyWith(id: 'item-$i', isConsumed: false),
      );
      final newItem = sampleItem.copyWith(id: 'item-26');

      when(() => mockGetItems()).thenAnswer((_) async => Right(activeList));
      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Sin conexión con Hive.')),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const InventoryLimitReachedState(activeCount: 25),
        ]),
      );

      bloc.add(AddInventoryItemEvent(newItem));
      await expectation;

      verifyNever(() => mockAddItem(newItem));
    });

    test('permite agregar cuando la política falla y el usuario está bajo el límite',
        () async {
      final newItem = sampleItem.copyWith(id: 'item-nuevo');

      when(() => mockGetItems()).thenAnswer((_) async => Right([newItem]));
      when(() => mockAddItem(newItem)).thenAnswer((_) async => const Right(unit));
      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Sin conexión con Hive.')),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          InventoryLoaded(
            items: [newItem],
            filteredItems: [newItem],
          ),
        ]),
      );

      bloc.add(AddInventoryItemEvent(newItem));
      await expectation;

      verify(() => mockAddItem(newItem)).called(1);
    });
    test('reevalúa la cuota tras un RefreshInventoryQuotaEvent sin recargar los alimentos',
        () async {
      var allowed = false;
      when(() => mockGetItems()).thenAnswer((_) async => Right([sampleItem]));
      when(() => mockQuotaPolicy.canAddItem(
            currentActiveCount: any(named: 'currentActiveCount'),
          )).thenAnswer((_) async => Right(allowed));

      bloc.add(const LoadInventoryEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<InventoryState>(
            (state) => state is InventoryLoaded && !state.canAddItem)),
      );

      // El usuario compra Pro: la cuota debe reevaluarse sin recargar la lista.
      allowed = true;
      bloc.add(const RefreshInventoryQuotaEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<InventoryState>(
            (state) => state is InventoryLoaded && state.canAddItem)),
      );
    });
  });

  group('RemoveInventoryItemEvent Tests', () {
    test('debe cancelar alertas y recargar la lista de alimentos', () async {
      when(() => mockDeleteItem('test-1'))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetItems())
          .thenAnswer((_) async => const Right([]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const InventoryLoaded(
            items: [],
            filteredItems: [],
          ),
        ]),
      );

      bloc.add(const RemoveInventoryItemEvent('test-1'));
      await expectation;

      verify(() => mockDeleteItem('test-1')).called(1);
      verify(() => mockNotificationService.cancelItemAlerts('test-1')).called(1);
    });
  });

  group('ToggleConsumedItemEvent Tests', () {
    test('al marcar como consumido, debe cancelar las alertas pendientes', () async {
      final activeItem = sampleItem.copyWith(isConsumed: false);
      when(() => mockToggleConsumed(activeItem))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetItems())
          .thenAnswer((_) async => Right([activeItem.copyWith(isConsumed: true)]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          InventoryLoaded(
            items: [activeItem.copyWith(isConsumed: true)],
            filteredItems: [activeItem.copyWith(isConsumed: true)],
          ),
        ]),
      );

      bloc.add(ToggleConsumedItemEvent(activeItem));
      await expectation;

      verify(() => mockToggleConsumed(activeItem)).called(1);
      verify(() => mockNotificationService.cancelItemAlerts(activeItem.id)).called(1);
    });

    test('al desmarcar como consumido, debe reprogramar alertas si la fecha es vigente', () async {
      final consumedItem = sampleItem.copyWith(
        isConsumed: true,
        expirationDate: DateTime.now().add(const Duration(days: 60)),
      );
      when(() => mockToggleConsumed(consumedItem))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetItems())
          .thenAnswer((_) async => Right([consumedItem.copyWith(isConsumed: false)]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          InventoryLoaded(
            items: [consumedItem.copyWith(isConsumed: false)],
            filteredItems: [consumedItem.copyWith(isConsumed: false)],
          ),
        ]),
      );

      bloc.add(ToggleConsumedItemEvent(consumedItem));
      await expectation;

      verify(() => mockToggleConsumed(consumedItem)).called(1);
      verify(() => mockNotificationService.scheduleItemAlerts(any())).called(1);
    });
  });

  group('FilterInventoryEvent Tests', () {
    test('debe filtrar correctamente los elementos en base a UrgencyStatus',
        () async {
      final safeItem = FrozenItem(
        id: '1',
        name: 'Carne segura',
        category: FoodCategory.redMeat,
        frozenDate: testDate,
        expirationDate: testDate.add(const Duration(days: 100)),
      );
      final criticalItem = FrozenItem(
        id: '2',
        name: 'Pollo crítico',
        category: FoodCategory.poultry,
        frozenDate: testDate,
        expirationDate: testDate.add(const Duration(days: 3)),
      );

      when(() => mockGetItems())
          .thenAnswer((_) async => Right([criticalItem, safeItem]));

      bloc.add(const LoadInventoryEvent());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<InventoryState>((state) =>
            state is InventoryLoaded && state.items.length == 2)),
      );

      // Ahora emitimos el filtro para mostrar solo critical
      bloc.add(const FilterInventoryEvent(urgencyFilter: UrgencyStatus.critical));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<InventoryState>((state) {
          if (state is InventoryLoaded) {
            return state.filteredItems.length == 1 &&
                state.filteredItems.first.id == '2';
          }
          return false;
        })),
      );
    });

    group('UpdateInventoryItemEvent Tests', () {
      test('debe llamar a UpdateFrozenItemUseCase, resincronizar alertas y recargar la lista', () async {
        final updatedItem = sampleItem.copyWith(name: 'Guiso de lentejas actualizado');

        when(() => mockUpdateItem(any())).thenAnswer((_) async => const Right(unit));
        when(() => mockGetItems()).thenAnswer((_) async => Right([updatedItem]));

        bloc.add(UpdateInventoryItemEvent(updatedItem));

        await expectLater(
          bloc.stream,
          emitsThrough(predicate<InventoryState>((state) {
            if (state is InventoryLoaded) {
              return state.items.first.name == 'Guiso de lentejas actualizado';
            }
            return false;
          })),
        );

        verify(() => mockUpdateItem(updatedItem)).called(1);
        verify(() => mockNotificationService.cancelItemAlerts(updatedItem.id)).called(1);
        verify(() => mockNotificationService.scheduleItemAlerts(updatedItem)).called(1);
      });

      test('debe emitir InventoryError cuando falla UpdateFrozenItemUseCase', () async {
        when(() => mockUpdateItem(any())).thenAnswer(
          (_) async => const Left(ValidationFailure(message: 'El nombre del alimento no puede estar vacío.')),
        );

        bloc.add(UpdateInventoryItemEvent(sampleItem));

        await expectLater(
          bloc.stream,
          emitsThrough(predicate<InventoryState>((state) =>
              state is InventoryError && state.message.contains('vacío'))),
        );
      });
    });
  });
}
