import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/frozen_item.dart';
import '../repositories/inventory_repository.dart';

/// Caso de uso para actualizar los detalles de un alimento existente en el congelador.
class UpdateFrozenItemUseCase {
  final IInventoryRepository repository;

  const UpdateFrozenItemUseCase(this.repository);

  Future<Either<Failure, Unit>> call(FrozenItem item) async {
    if (item.name.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'El nombre del alimento no puede estar vacío.'),
      );
    }

    if (item.quantity <= 0) {
      return const Left(
        ValidationFailure(message: 'La cantidad del alimento debe ser mayor a cero.'),
      );
    }

    return repository.updateItem(item);
  }
}

