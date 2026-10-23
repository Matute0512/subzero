/// Incidente ocurrido durante un proceso de compra.
///
/// Modela en el dominio los desenlaces no felices de una compra: el usuario
/// canceló, el pago quedó pendiente de confirmación o la tienda falló.
///
/// La traducción desde los estados de la plataforma (`PurchaseStatus`) ocurre
/// en la capa de datos; el dominio solo conoce estos tres casos.
sealed class PurchaseIssue {
  const PurchaseIssue();

  /// Mensaje listo para mostrar al usuario.
  String get message;

  /// `true` si el incidente representa un fallo real, no una acción del usuario.
  ///
  /// Permite que la UI distinga "cancelaste" (informativo) de "falló"
  /// (error), sin que la capa de presentación tenga que conocer códigos de
  /// la tienda.
  bool get isError => true;
}

/// El usuario cerró el diálogo de la tienda sin comprar.
///
/// No es un error: es una decisión del usuario. La UI debe confirmarlo de
/// forma informativa para que la pantalla no parezca congelada.
class PurchaseCanceled extends PurchaseIssue {
  const PurchaseCanceled();

  @override
  String get message =>
      'Cancelaste la compra. Podés intentarlo de nuevo cuando quieras.';

  @override
  bool get isError => false;
}

/// El pago quedó pendiente de confirmación (pago diferido, pago en efectivo).
///
/// Play reintentará la confirmación automáticamente; la app solo debe
/// informarlo para que el usuario no piense que la compra se perdió.
class PurchasePending extends PurchaseIssue {
  const PurchasePending();

  @override
  String get message =>
      'El pago quedó pendiente de confirmación. Se completará automáticamente.';

  @override
  bool get isError => false;
}

/// La tienda rechazó la operación.
///
/// Puede deberse a falta de conexión, a que la tienda no esté disponible o
/// a un error interno de Google Play.
class PurchaseFailed extends PurchaseIssue {
  /// Código de error reportado por la tienda.
  final String code;

  /// Detalle legible del error.
  final String detail;

  const PurchaseFailed({required this.code, required this.detail});

  @override
  String get message => 'No se pudo completar la compra: $detail';
}
