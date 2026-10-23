import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';

/// Política de cuota del inventario.
///
/// Decide si el usuario puede registrar un nuevo alimento según su suscripción.
/// El contrato pertenece al dominio de inventario para que las capas superiores
/// no dependan de la feature de monetización: la implementación (un adaptador
/// sobre `IMonetizationRepository`) reside en `features/inventory/data/` y la
/// dependencia queda invertida detrás de esta abstracción.
abstract class IInventoryQuotaPolicy {
  /// Máximo de alimentos activos permitidos en la versión gratuita de SubZero.
  static const int freeTierItemLimit = 25;

  /// Evalúa si se puede agregar un alimento teniendo [currentActiveCount]
  /// alimentos activos en el inventario.
  ///
  /// Devuelve `Left` si no se pudo determinar el estado de suscripción.
  Future<Either<Failure, bool>> canAddItem({required int currentActiveCount});

  /// Decisión a aplicar cuando no se pudo determinar el estado de suscripción.
  ///
  /// Postura conservadora: sin confirmación de Pro se aplica el límite gratuito,
  /// de modo que un fallo transitorio nunca otorga ventajas por error.
  ///
  /// Es estática para que sea una regla del dominio y no una pieza que cada
  /// implementación deba replicar.
  static bool resolveWithoutSubscription({required int currentActiveCount}) =>
      currentActiveCount < freeTierItemLimit;
}
