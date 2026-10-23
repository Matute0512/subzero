import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/frozen_item.dart';
import '../repositories/inventory_repository.dart';

/// Caso de uso para alternar el estado de consumo (consumido vs activo) de un alimento.
class ToggleConsumedUseCase {
  final IInventoryRepository repository;

  const ToggleConsumedUseCase(this.repository);

  Future<Either<Failure, Unit>> call(FrozenItem item) async {
    final updated = item.copyWith(isConsumed: !item.isConsumed);
    return repository.updateItem(updated);
  }
}

