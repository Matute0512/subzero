import 'notifiable_item.dart';

export 'local_notification_service.dart';
export 'notifiable_item.dart';

/// Callback invocado cuando el usuario toca la notificacion de un alimento.
///
/// Recibe el `itemId` del alimento, extraido del payload de la notificacion.
typedef NotificationTapHandler = void Function(String itemId);

/// Contrato abstracto para el servicio de notificaciones locales de SubZero.
abstract class INotificationService {
  /// Se asigna desde la UI para reaccionar a la pulsacion de una notificacion.
  ///
  /// Debe asignarse a `null` cuando la pantalla que lo consume se desmonta.
  NotificationTapHandler? onItemNotificationTapped;

  /// Inicializa el plugin de notificaciones locales y la base de datos de zonas horarias.
  Future<void> initialize();

  /// Solicita los permisos necesarios de notificación y alarmas al usuario de forma no bloqueante.
  Future<bool> requestPermissions();

  /// Programa las alertas de vencimiento (7 días previos y 1 día previo a las 09:00 AM)
  /// para el elemento provisto si no está consumido y las fechas están en el futuro.
  Future<void> scheduleItemAlerts(NotifiableItem item);

  /// Cancela todas las alertas pendientes asociadas a un alimento específico.
  Future<void> cancelItemAlerts(String itemId);

  /// Cancela todas las notificaciones activas y programadas en el sistema.
  Future<void> cancelAllAlerts();
}
