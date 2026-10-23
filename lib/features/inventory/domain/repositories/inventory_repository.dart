import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/frozen_item.dart';

/// Contrato abstracto del repositorio de inventario para la capa de dominio.
abstract class IInventoryRepository {
  /// Obtiene todos los ítems almacenados en el inventario local.
  Future<Either<Failure, List<FrozenItem>>> getItems();

  /// Guarda un nuevo ítem en el inventario.
  Future<Either<Failure, Unit>> saveItem(FrozenItem item);

  /// Elimina un ítem por su identificador único.
  Future<Either<Failure, Unit>> deleteItem(String id);

  /// Actualiza un ítem existente en el inventario.
  Future<Either<Failure, Unit>> updateItem(FrozenItem item);
}
