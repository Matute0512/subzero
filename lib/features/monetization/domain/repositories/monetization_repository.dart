import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/errors/failures.dart';
import '../entities/purchase_issue.dart';
import '../entities/subscription_status.dart';

/// Contrato abstracto para el repositorio de monetización y compras in-app.
abstract class IMonetizationRepository {
  /// Obtiene el estado actual de la suscripción (Free vs Pro) desde la persistencia local.
  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus();

  /// Obtiene los detalles y el precio localizado del producto Pro desde la tienda.
  Future<Either<Failure, ProductDetails?>> getProductDetails();

  /// Inicia el flujo de compra para el producto Pro no consumible.
  Future<Either<Failure, Unit>> purchaseProduct([String? productId]);

  /// Restaura compras previas asociadas a la cuenta del usuario.
  Future<Either<Failure, SubscriptionStatus>> restorePurchases();

  /// Stream reactivo para observar cambios en el estado Pro en tiempo real.
  Stream<SubscriptionStatus> get subscriptionStatusStream;

  /// Stream reactivo con los incidentes del flujo de compra.
  ///
  /// Emite cuando el usuario cancela el diálogo de la tienda, cuando el pago
  /// queda pendiente de confirmación o cuando la tienda rechaza la operación.
  /// Sin este stream, una compra cancelada no produce ninguna señal y la UI
  /// queda aparentando estar congelada.
  Stream<PurchaseIssue> get purchaseIssueStream;

  /// Actualiza manualmente el estado Pro persistido localmente.
  Future<Either<Failure, Unit>> setProStatus(bool isPro);

  /// Libera los controladores de streams y suscripciones activas.
  void dispose();
}
