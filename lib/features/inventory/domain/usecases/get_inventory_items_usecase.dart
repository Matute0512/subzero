import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/frozen_item.dart';
import '../repositories/inventory_repository.dart';

/// Caso de uso para obtener todos los alimentos del congelador,
/// ordenados de forma ascendente por urgencia de consumo (menor `daysRemaining` primero).
class GetInventoryItemsUseCase {
  final IInventoryRepository repository;

  const GetInventoryItemsUseCase(this.repository);

  Future<Either<Failure, List<FrozenItem>>> call() async {
    final result = await repository.getItems();
    return result.map((items) {
      // Filtrar no consumidos y ordenar por días restantes ascendente
      final activeItems = items.where((item) => !item.isConsumed).toList();
      activeItems.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
      return activeItems;
    });
  }
}

