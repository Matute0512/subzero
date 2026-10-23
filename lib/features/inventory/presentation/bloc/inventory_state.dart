import 'package:equatable/equatable.dart';

import '../../domain/entities/food_category.dart';
import '../../domain/entities/frozen_item.dart';

/// Clase base para los estados del inventario.
abstract class InventoryState extends Equatable {
  const InventoryState();

  /// Acceso seguro a la capacidad de agregar ítems desde la UI.
  bool get canAddItem => this is InventoryLoaded ? (this as InventoryLoaded).canAddItem : true;

  @override
  List<Object?> get props => [];
}

/// Estado inicial previo a la carga de datos.
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Estado emitido durante transacciones u operaciones asíncronas de lectura/escritura.
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// Estado emitido cuando el inventario ha sido cargado exitosamente.
class InventoryLoaded extends InventoryState {
  final List<FrozenItem> items;
  final List<FrozenItem> filteredItems;
  final UrgencyStatus? urgencyFilter;
  final FoodCategory? categoryFilter;

  /// Indica si el usuario puede agregar alimentos adicionales al congelador.
  ///
  /// Es la ÚNICA fuente de verdad para la UI: evalúa la política de cuota
  /// inyectada [IInventoryQuotaPolicy] frente a los alimentos activos.
  @override
  final bool canAddItem;
  final bool isAscending;

  const InventoryLoaded({
    required this.items,
    required this.filteredItems,
    this.urgencyFilter,
    this.categoryFilter,
    this.canAddItem = true,
    this.isAscending = true,
  });

  /// Retorna la cantidad de alimentos activos (no consumidos).
  int get activeCount => items.where((item) => !item.isConsumed).length;

  /// Retorna la cantidad de alimentos clasificados como críticos.
  int get criticalCount =>
      items.where((item) => !item.isConsumed && item.urgencyStatus == UrgencyStatus.critical).length;

  /// Retorna la cantidad de alimentos clasificados en advertencia.
  int get warningCount =>
      items.where((item) => !item.isConsumed && item.urgencyStatus == UrgencyStatus.warning).length;

  /// Retorna la cantidad de alimentos clasificados como seguros.
  int get safeCount =>
      items.where((item) => !item.isConsumed && item.urgencyStatus == UrgencyStatus.safe).length;

  InventoryLoaded copyWith({
    List<FrozenItem>? items,
    List<FrozenItem>? filteredItems,
    UrgencyStatus? Function()? urgencyFilter,
    FoodCategory? Function()? categoryFilter,
    bool? canAddItem,
    bool? isAscending,
  }) {
    return InventoryLoaded(
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      urgencyFilter: urgencyFilter != null ? urgencyFilter() : this.urgencyFilter,
      categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
      canAddItem: canAddItem ?? this.canAddItem,
      isAscending: isAscending ?? this.isAscending,
    );
  }

  @override
  List<Object?> get props => [
        items,
        filteredItems,
        urgencyFilter,
        categoryFilter,
        canAddItem,
        isAscending,
      ];
}

/// Estado emitido cuando un usuario intenta agregar un alimento superando el límite permitido.
class InventoryLimitReachedState extends InventoryState {
  final int activeCount;
  final int limit;

  const InventoryLimitReachedState({
    required this.activeCount,
    this.limit = 25,
  });

  @override
  List<Object?> get props => [activeCount, limit];
}

/// Estado emitido cuando ocurre un fallo o excepción en la capa de datos.
class InventoryError extends InventoryState {
  final String message;

  const InventoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
