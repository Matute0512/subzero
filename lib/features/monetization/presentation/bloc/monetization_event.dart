import 'package:equatable/equatable.dart';

import '../../domain/entities/purchase_issue.dart';

abstract class MonetizationEvent extends Equatable {
  const MonetizationEvent();

  @override
  List<Object?> get props => [];
}

/// Consulta el estado Pro almacenado localmente en Hive.
class CheckProStatusEvent extends MonetizationEvent {
  const CheckProStatusEvent();
}

/// Consulta detalles y precio del producto Pro en Google Play / App Store.
class LoadProductsEvent extends MonetizationEvent {
  const LoadProductsEvent();
}

/// Inicia el flujo de compra in-app nativo para SubZero Pro.
class PurchaseProEvent extends MonetizationEvent {
  final String? productId;

  const PurchaseProEvent([this.productId]);

  @override
  List<Object?> get props => [productId];
}

/// Restaura compras previas asociadas a la cuenta del usuario en la tienda.
class RestorePurchasesEvent extends MonetizationEvent {
  const RestorePurchasesEvent();
}

/// Evento interno emitido reactivamente cuando el stream de compras detecta un cambio.
class ProStatusUpdatedEvent extends MonetizationEvent {
  final bool isPro;

  const ProStatusUpdatedEvent(this.isPro);

  @override
  List<Object?> get props => [isPro];
}

/// Evento interno emitido cuando el flujo de compra termina sin éxito.
///
/// Cubre la cancelación del usuario, el pago pendiente y el fallo de la
/// tienda. Sin este evento, una compra cancelada no produce ninguna señal y
/// la pantalla aparenta estar congelada.
class MonetizationPurchaseIssueEvent extends MonetizationEvent {
  final PurchaseIssue issue;

  const MonetizationPurchaseIssueEvent(this.issue);

  @override
  List<Object?> get props => [issue];
}



