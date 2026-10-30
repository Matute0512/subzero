import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/frozen_item.dart';
import '../repositories/inventory_repository.dart';

/// Caso de uso para actualizar los detalles de un alimento existente en el congelador con validaciones de negocio y seguridad.
class UpdateFrozenItemUseCase {
  static const int maxNameLength = 100;
  static const int maxLocationNotesLength = 300;
  static const int maxUnitLength = 30;
  static const double maxQuantity = 999999.0;

  final IInventoryRepository repository;

  const UpdateFrozenItemUseCase(this.repository);

  Future<Either<Failure, Unit>> call(FrozenItem item) async {
    final trimmedName = item.name.trim();
    if (trimmedName.isEmpty) {
      return const Left(
        ValidationFailure(message: 'El nombre del alimento no puede estar vacío.'),
      );
    }

    if (trimmedName.length > maxNameLength) {
      return const Left(
        ValidationFailure(message: 'El nombre del alimento no puede exceder los 100 caracteres.'),
      );
    }

    if (item.quantity <= 0) {
      return const Left(
        ValidationFailure(message: 'La cantidad del alimento debe ser mayor a cero.'),
      );
    }

    if (item.quantity > maxQuantity) {
      return const Left(
        ValidationFailure(message: 'La cantidad del alimento excede el límite permitido.'),
      );
    }

    if (item.locationNotes != null && item.locationNotes!.length > maxLocationNotesLength) {
      return const Left(
        ValidationFailure(message: 'La ubicación o notas no pueden exceder los 300 caracteres.'),
      );
    }

    if (item.unit.trim().length > maxUnitLength) {
      return const Left(
        ValidationFailure(message: 'La unidad no puede exceder los 30 caracteres.'),
      );
    }

    return repository.updateItem(item);
  }
}
