import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/inventory_repository.dart';

/// Caso de uso para eliminar un ítem del inventario por su ID.
class DeleteFrozenItemUseCase {
  final IInventoryRepository repository;

  const DeleteFrozenItemUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'El identificador del alimento no es válido.'),
      );
    }

    return repository.deleteItem(id);
  }
}

