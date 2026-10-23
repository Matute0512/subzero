import 'package:equatable/equatable.dart';

import '../../domain/entities/food_category.dart';
import '../../domain/entities/frozen_item.dart';

/// Eventos base inmutables para [InventoryBloc].
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

/// Carga inicial o recarga completa de alimentos.
class LoadInventoryEvent extends InventoryEvent {
  const LoadInventoryEvent();
}

/// Alta de un alimento en el congelador.
class AddInventoryItemEvent extends InventoryEvent {
  final FrozenItem item;

  const AddInventoryItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

/// Baja o eliminación de un alimento.
class RemoveInventoryItemEvent extends InventoryEvent {
  final String id;

  const RemoveInventoryItemEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Filtrado por nivel de urgencia o categoría de alimento.
class FilterInventoryEvent extends InventoryEvent {
  final UrgencyStatus? urgencyFilter;
  final FoodCategory? categoryFilter;

  const FilterInventoryEvent({
    this.urgencyFilter,
    this.categoryFilter,
  });

  @override
  List<Object?> get props => [urgencyFilter, categoryFilter];
}

/// Alternar estado consumido de un alimento.
class ToggleConsumedItemEvent extends InventoryEvent {
  final FrozenItem item;

  const ToggleConsumedItemEvent(this.item);

  @override
  List<Object?> get props => [item];
}

/// Actualización de los datos de un alimento existente.
class UpdateInventoryItemEvent extends InventoryEvent {
  final FrozenItem updatedItem;

  const UpdateInventoryItemEvent(this.updatedItem);

  @override
  List<Object?> get props => [updatedItem];
}

/// Reevalúa la cuota de inventario sin recargar la lista de alimentos.
///
/// Se dispara cuando cambia el estado de suscripción, para que el bloqueo de
/// la versión gratuita se actualice sin esperar a una recarga completa.
class RefreshInventoryQuotaEvent extends InventoryEvent {
  const RefreshInventoryQuotaEvent();
}


