import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/frozen_item.dart';
import '../repositories/inventory_repository.dart';

/// Caso de uso para agregar un nuevo alimento al congelador con validaciones de negocio.
class AddFrozenItemUseCase {
  final IInventoryRepository repository;

  const AddFrozenItemUseCase(this.repository);

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

    return repository.saveItem(item);
  }
}

