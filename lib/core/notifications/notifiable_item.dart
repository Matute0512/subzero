/// Contrato abstracto para cualquier elemento que admita programación de alertas locales.
///
/// Permite que el subsistema de notificaciones en `core/notifications/` opere
/// de forma totalmente desacoplada de las entidades concretas de features (Clean Architecture).
abstract interface class NotifiableItem {
  /// Identificador único del elemento para cálculo determinista de ID de alarma.
  String get id;

  /// Nombre legible del elemento que aparecerá en el cuerpo de la notificación.
  String get name;

  /// Nombre de la categoría o grupo para enriquecer el mensaje de advertencia.
  String get categoryDisplayName;

  /// Fecha exacta de vencimiento a partir de la cual se calculan los recordatorios.
  DateTime get expirationDate;

  /// Si es true, el elemento ya no requiere alertas pendientes.
  bool get isConsumed;

  /// Si es false, el usuario optó por no recibir recordatorios para este elemento.
  bool get reminderEnabled;
}

