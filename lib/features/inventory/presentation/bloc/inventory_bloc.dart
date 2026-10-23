import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/frozen_item.dart';
import '../../domain/repositories/inventory_quota_policy.dart';
import '../../domain/usecases/add_frozen_item_usecase.dart';
import '../../domain/usecases/delete_frozen_item_usecase.dart';
import '../../domain/usecases/get_inventory_items_usecase.dart';
import '../../domain/usecases/sync_inventory_alerts_usecase.dart';
import '../../domain/usecases/toggle_consumed_usecase.dart';
import '../../domain/usecases/update_frozen_item_usecase.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

/// BLoC que gestiona el estado y eventos del inventario de SubZero.
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetInventoryItemsUseCase getInventoryItemsUseCase;
  final AddFrozenItemUseCase addFrozenItemUseCase;
  final DeleteFrozenItemUseCase deleteFrozenItemUseCase;
  final ToggleConsumedUseCase toggleConsumedUseCase;
  final UpdateFrozenItemUseCase updateFrozenItemUseCase;
  final INotificationService notificationService;

  /// Reprograma las alertas de vencimiento cuando el inventario se carga.
  ///
  /// El sistema puede perder las alarmas (reinicio, cambio de zona horaria,
  /// hibernación de apps): sin esto el usuario pierde sus avisos (P1-9).
  final SyncInventoryAlertsUseCase syncInventoryAlertsUseCase;

  /// Política de cuota del dominio de inventario.
  ///
  /// Encapsula la decisión de si el usuario puede registrar nuevos alimentos
  /// según su suscripción, de modo que este BLoC no dependa de la feature de
  /// monetización.
  final IInventoryQuotaPolicy quotaPolicy;

  InventoryBloc({
    required this.getInventoryItemsUseCase,
    required this.addFrozenItemUseCase,
    required this.deleteFrozenItemUseCase,
    required this.toggleConsumedUseCase,
    required this.updateFrozenItemUseCase,
    required this.notificationService,
    required this.quotaPolicy,
    required this.syncInventoryAlertsUseCase,
  }) : super(const InventoryInitial()) {
    on<LoadInventoryEvent>(_onLoadInventory);
    on<AddInventoryItemEvent>(_onAddItem);
    on<RemoveInventoryItemEvent>(_onRemoveItem);
    on<FilterInventoryEvent>(_onFilterInventory);
    on<ToggleConsumedItemEvent>(_onToggleConsumed);
    on<UpdateInventoryItemEvent>(_onUpdateItem);
    on<RefreshInventoryQuotaEvent>(_onRefreshQuota);
  }

  Future<void> _onLoadInventory(
    LoadInventoryEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final currentUrgencyFilter = state is InventoryLoaded
        ? (state as InventoryLoaded).urgencyFilter
        : null;
    final currentCategoryFilter = state is InventoryLoaded
        ? (state as InventoryLoaded).categoryFilter
        : null;

    emit(const InventoryLoading());

    final result = await getInventoryItemsUseCase();
    final items = result.getOrElse((_) => const <FrozenItem>[]);
    final filtered = _applyFilters(
      items,
      currentUrgencyFilter,
      currentCategoryFilter,
    );
    final canAddItem =
        await _evaluateCanAddItem(activeCount: _countActive(items));

    result.fold(
      (failure) => emit(InventoryError(message: failure.message)),
      (_) => emit(InventoryLoaded(
        items: items,
        filteredItems: filtered,
        urgencyFilter: currentUrgencyFilter,
        categoryFilter: currentCategoryFilter,
        canAddItem: canAddItem,
      )),
    );

    // Reprograma las alertas de vencimiento. Se hace despues de emitir el
    // estado para no retrasar la carga de la lista: el sistema puede haber
    // perdido las alarmas (reinicio, cambio de zona horaria, app hibernada).
    await syncInventoryAlertsUseCase();
  }

  Future<void> _onAddItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    // La cuota se resuelve a través de la política de dominio, no consultando
    // directamente el estado de suscripción de la feature de monetización.
    final itemsResult = await getInventoryItemsUseCase();
    final currentItems = itemsResult.getOrElse((_) => const <FrozenItem>[]);
    final activeCount = _countActive(currentItems);

    final canAddItem = await _evaluateCanAddItem(activeCount: activeCount);

    if (!canAddItem) {
      AppLogger.warning(
        'Límite de alimentos gratuitos alcanzado ($activeCount / ${IInventoryQuotaPolicy.freeTierItemLimit}). Bloqueando inserción.',
        tag: 'InventoryBloc',
      );
      emit(InventoryLimitReachedState(
        activeCount: activeCount,
        limit: IInventoryQuotaPolicy.freeTierItemLimit,
      ));
      return;
    }

    final result = await addFrozenItemUseCase(event.item);
    await result.fold(
      (failure) async => emit(InventoryError(message: failure.message)),
      (_) async {
        if (!event.item.isConsumed && event.item.reminderEnabled) {
          try {
            await notificationService.scheduleItemAlerts(event.item);
          } catch (e, stack) {
            AppLogger.error(
              'Error al programar alertas para ${event.item.id}',
              error: e,
              stackTrace: stack,
            );
          }
        }
        await _reloadItems(emit);
      },
    );
  }

  Future<void> _onRemoveItem(
    RemoveInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final result = await deleteFrozenItemUseCase(event.id);
    await result.fold(
      (failure) async => emit(InventoryError(message: failure.message)),
      (_) async {
        try {
          await notificationService.cancelItemAlerts(event.id);
        } catch (e, stack) {
          AppLogger.error(
            'Error al cancelar alertas para ${event.id}',
            error: e,
            stackTrace: stack,
          );
        }
        await _reloadItems(emit);
      },
    );
  }

  void _onFilterInventory(
    FilterInventoryEvent event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final current = state as InventoryLoaded;
      final filtered = _applyFilters(
        current.items,
        event.urgencyFilter,
        event.categoryFilter,
      );
      emit(current.copyWith(
        filteredItems: filtered,
        urgencyFilter: () => event.urgencyFilter,
        categoryFilter: () => event.categoryFilter,
      ));
    }
  }

  Future<void> _onToggleConsumed(
    ToggleConsumedItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final updatedItem = event.item.copyWith(isConsumed: !event.item.isConsumed);
    final result = await toggleConsumedUseCase(event.item);
    await result.fold(
      (failure) async => emit(InventoryError(message: failure.message)),
      (_) async {
        try {
          if (updatedItem.isConsumed) {
            await notificationService.cancelItemAlerts(updatedItem.id);
          } else if (updatedItem.reminderEnabled && !updatedItem.isExpired) {
            await notificationService.scheduleItemAlerts(updatedItem);
          }
        } catch (e, stack) {
          AppLogger.error(
            'Error al gestionar alertas en toggle consumed para ${event.item.id}',
            error: e,
            stackTrace: stack,
          );
        }
        await _reloadItems(emit);
      },
    );
  }

  Future<void> _onUpdateItem(
    UpdateInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final result = await updateFrozenItemUseCase(event.updatedItem);
    await result.fold(
      (failure) async => emit(InventoryError(message: failure.message)),
      (_) async {
        try {
          await notificationService.cancelItemAlerts(event.updatedItem.id);
          if (!event.updatedItem.isConsumed &&
              event.updatedItem.reminderEnabled &&
              !event.updatedItem.isExpired) {
            await notificationService.scheduleItemAlerts(event.updatedItem);
          }
        } catch (e, stack) {
          AppLogger.error(
            'Error al reprogramar alertas en actualización para ${event.updatedItem.id}',
            error: e,
            stackTrace: stack,
          );
        }
        await _reloadItems(emit);
      },
    );
  }

  Future<void> _reloadItems(Emitter<InventoryState> emit) async {
    final currentUrgency = state is InventoryLoaded
        ? (state as InventoryLoaded).urgencyFilter
        : null;
    final currentCategory = state is InventoryLoaded
        ? (state as InventoryLoaded).categoryFilter
        : null;

    final result = await getInventoryItemsUseCase();
    final items = result.getOrElse((_) => const <FrozenItem>[]);
    final filtered = _applyFilters(items, currentUrgency, currentCategory);
    final canAddItem =
        await _evaluateCanAddItem(activeCount: _countActive(items));

    result.fold(
      (failure) => emit(InventoryError(message: failure.message)),
      (_) => emit(InventoryLoaded(
        items: items,
        filteredItems: filtered,
        urgencyFilter: currentUrgency,
        categoryFilter: currentCategory,
        canAddItem: canAddItem,
      )),
    );
  }

  /// Cuenta los alimentos activos (no consumidos) de una lista.
  int _countActive(List<FrozenItem> items) =>
      items.where((i) => !i.isConsumed).length;

  /// Reevalúa la cuota sobre el estado actual sin recargar los alimentos.
  ///
  /// Permite que un cambio de suscripción (compra o restauración de Pro) se
  /// refleje de inmediato en la interfaz.
  Future<void> _onRefreshQuota(
    RefreshInventoryQuotaEvent event,
    Emitter<InventoryState> emit,
  ) async {
    final current = state;
    if (current is! InventoryLoaded) return;

    final canAddItem =
        await _evaluateCanAddItem(activeCount: current.activeCount);
    if (canAddItem == current.canAddItem) return;

    emit(current.copyWith(canAddItem: canAddItem));
  }

  /// Evalúa la cuota vigente y devuelve si se puede registrar un nuevo alimento.
  ///
  /// Ante cualquier fallo se aplica el límite gratuito (postura conservadora
  /// definida por la propia política de dominio).
  Future<bool> _evaluateCanAddItem({required int activeCount}) async {
    try {
      final result = await quotaPolicy.canAddItem(currentActiveCount: activeCount);

      return result.fold(
        (failure) {
          AppLogger.warning(
            'No se pudo determinar el estado de suscripción; se aplica el límite gratuito.',
            tag: 'InventoryBloc',
            error: failure,
          );
          return IInventoryQuotaPolicy.resolveWithoutSubscription(
            currentActiveCount: activeCount,
          );
        },
        (allowed) => allowed,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Error inesperado evaluando la cuota de inventario.',
        tag: 'InventoryBloc',
        error: e,
        stackTrace: stack,
      );
      return IInventoryQuotaPolicy.resolveWithoutSubscription(
        currentActiveCount: activeCount,
      );
    }
  }

  List<FrozenItem> _applyFilters(
    List<FrozenItem> items,
    UrgencyStatus? urgencyFilter,
    FoodCategory? categoryFilter,
  ) {
    return items.where((item) {
      if (urgencyFilter != null && item.urgencyStatus != urgencyFilter) {
        return false;
      }
      if (categoryFilter != null && item.category != categoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }
}
