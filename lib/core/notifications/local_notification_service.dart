import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


import '../utils/logger.dart';
import 'notification_service.dart';

/// Implementación concreta de [INotificationService] con flutter_local_notifications y timezone.
class LocalNotificationService implements INotificationService {
  static const String _tag = 'LocalNotificationService';
  static const String channelId = 'subzero_expiration_channel';
  static const String channelName = 'Alertas de Vencimiento SubZero';
  static const String channelDescription =
      'Alertas y recordatorios de caducidad para alimentos en el congelador.';

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;
  bool _isInitialized;

  /// `true` si el sistema permite programar alarmas exactas.
  ///
  /// El usuario puede revocar el permiso en Ajustes -> Alarms & reminders.
  /// Cuando no esta concedido, las alertas se programan en modo inexacto en
  /// lugar de fallar (P2-5).
  bool _canScheduleExact = false;

  @override
  NotificationTapHandler? onItemNotificationTapped;

  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
    bool isInitialized = false,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _clock = clock ?? DateTime.now,
        _isInitialized = isInitialized;

  /// Hash determinista de 32 bits (FNV-1a) e independiente del runtime.
  ///
  /// `String.hashCode` de Dart no garantiza unicidad ni estabilidad entre
  /// ejecuciones, por lo que dos alimentos distintos podian recibir el mismo
  /// ID de notificacion y pisarse entre si (P2-4).
  static int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Genera un ID entero seguro y determinista para la alerta de advertencia (7 días).
  ///
  /// Rango par: [0, 999.999.998]. El urgente usa los impares, de modo que un
  /// aviso nunca pisa al otro del mismo alimento.
  static int getWarningNotificationId(String itemId) =>
      (_stableHash(itemId) % 500000000) * 2;

  /// Genera un ID entero seguro y determinista para la alerta urgente (1 día).
  ///
  /// Rango impar: [1, 999.999.999].
  static int getUrgentNotificationId(String itemId) =>
      getWarningNotificationId(itemId) + 1;

  /// Calcula la fecha de disparo para la advertencia previa: 7 días antes a las 09:00 AM.
  static DateTime calculateWarningAlertDate(DateTime expirationDate) {
    final targetDay = expirationDate.subtract(const Duration(days: 7));
    return DateTime(targetDay.year, targetDay.month, targetDay.day, 9, 0, 0);
  }

  /// Calcula la fecha de disparo para la alerta urgente: 1 día antes a las 09:00 AM.
  static DateTime calculateUrgentAlertDate(DateTime expirationDate) {
    final targetDay = expirationDate.subtract(const Duration(days: 1));
    return DateTime(targetDay.year, targetDay.month, targetDay.day, 9, 0, 0);
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      // CRÍTICO: el paquete `timezone` no conoce la zona horaria del
      // dispositivo. Sin `setLocalLocation`, `tz.local` queda en UTC y las
      // alertas se disparan a la hora equivocada (09:00 local -> 06:00 en
      // Argentina, 07:00 en España, 03:30 en India).
      await _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Crear canal de notificación de alta importancia en Android
      final androidNotificationPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidNotificationPlugin != null) {
        const androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
        );
        await androidNotificationPlugin.createNotificationChannel(androidChannel);

        // Estado del permiso de alarma exacta (P2-5).
        _canScheduleExact =
            await androidNotificationPlugin.canScheduleExactNotifications() ??
                false;
      }

      _isInitialized = true;
      AppLogger.info('LocalNotificationService inicializado correctamente.', tag: _tag);
    } catch (e, stack) {
      AppLogger.error(
        'Fallo al inicializar LocalNotificationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Configura `tz.local` con la zona horaria real del dispositivo.
  ///
  /// Si la zona no puede determinarse (plataforma sin soporte, error del
  /// plugin o identificador desconocido) se registra el fallo y se continúa:
  /// el disparo de las alertas usa el offset del dispositivo (ver
  /// [_toScheduledInstant]) y no depende de `tz.local`.
  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      AppLogger.info(
        'Zona horaria local configurada: ${timezoneInfo.identifier}',
        tag: _tag,
      );
    } on tz.LocationNotFoundException {
      AppLogger.warning(
        'La zona horaria reportada por el dispositivo no es reconocida por el '
        'paquete timezone. Las alertas usarán el offset local del sistema.',
        tag: _tag,
      );
    } catch (e, stack) {
      AppLogger.warning(
        'No se pudo determinar la zona horaria del dispositivo. '
        'Las alertas usarán el offset local del sistema.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Convierte una hora de pared local al instante absoluto que debe disparar
  /// la alarma.
  ///
  /// Se usa el offset del dispositivo para esa fecha concreta (incluye DST) en
  /// lugar de `tz.local`, de modo que la alarma sea correcta incluso si la
  /// zona horaria no se pudo configurar.
  tz.TZDateTime _toScheduledInstant(DateTime localWallClock) {
    final offset = localWallClock.timeZoneOffset;
    return tz.TZDateTime(
      tz.UTC,
      localWallClock.year,
      localWallClock.month,
      localWallClock.day,
      localWallClock.hour,
      localWallClock.minute,
      localWallClock.second,
    ).subtract(offset);
  }

  /// Traduce la pulsacion de una notificacion al `itemId` del alimento.
  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) {
      AppLogger.info('Notificacion seleccionada sin payload.', tag: _tag);
      return;
    }

    AppLogger.info('Notificacion seleccionada. Payload: $payload', tag: _tag);

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic> && decoded['itemId'] is String) {
        onItemNotificationTapped?.call(decoded['itemId'] as String);
      } else {
        AppLogger.warning(
          'El payload de la notificacion no contiene un itemId valido.',
          tag: _tag,
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Payload de notificacion invalido',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      bool granted = false;

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notifGranted = await androidImpl.requestNotificationsPermission();
        granted = notifGranted ?? false;

        // Se solicita el permiso de alarma exacta y se verifica el resultado:
        // el usuario puede denegarlo, y en ese caso las alertas se programan
        // en modo inexacto (P2-5).
        final exactGranted = await androidImpl.requestExactAlarmsPermission();
        _canScheduleExact = exactGranted ?? false;
        if (!_canScheduleExact) {
          AppLogger.info(
            'Sin permiso de alarma exacta: las alertas se programaran de forma '
            'aproximada. Revisar Ajustes > Alarms & reminders para activarlo.',
            tag: _tag,
          );
        }
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final iosGranted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = iosGranted ?? false;
      }

      AppLogger.info('Permisos de notificación solicitados. Concedidos: $granted', tag: _tag);
      return granted;
    } catch (e, stack) {
      AppLogger.error(
        'Error al solicitar permisos de notificación',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  @override
  Future<void> scheduleItemAlerts(NotifiableItem item) async {
    if (!_isInitialized) await initialize();

    // No programar alertas si ya fue consumido o tiene recordatorios desactivados
    if (item.isConsumed || !item.reminderEnabled) {
      AppLogger.info(
        'Omitiendo programación para ítem ${item.id} (consumido o desactivado)',
        tag: _tag,
      );
      return;
    }

    final now = _clock();

    // 1. Alerta de Advertencia (7 días antes a las 09:00 AM)
    final warningDate = calculateWarningAlertDate(item.expirationDate);
    if (warningDate.isAfter(now)) {
      final warningId = getWarningNotificationId(item.id);
      await _scheduleZonedNotification(
        id: warningId,
        title: '¡Alerta de Vencimiento! (7 días)',
        body: '"${item.name}" vencerá en 7 días (${item.categoryDisplayName}). ¡Planea consumirlo pronto!',
        scheduledDate: warningDate,
        payload: jsonEncode({'itemId': item.id, 'alertType': 'warning'}),
      );
      AppLogger.info(
        'Alerta de advertencia programada para "${item.name}" en $warningDate [ID: $warningId]',
        tag: _tag,
      );
    }

    // 2. Alerta Urgente (1 día antes a las 09:00 AM)
    final urgentDate = calculateUrgentAlertDate(item.expirationDate);
    if (urgentDate.isAfter(now)) {
      final urgentId = getUrgentNotificationId(item.id);
      await _scheduleZonedNotification(
        id: urgentId,
        title: '¡Urgente! Vence mañana',
        body: '"${item.name}" vence mañana. Recuerda consumirlo o prepararlo.',
        scheduledDate: urgentDate,
        payload: jsonEncode({'itemId': item.id, 'alertType': 'urgent'}),
      );
      AppLogger.info(
        'Alerta urgente programada para "${item.name}" en $urgentDate [ID: $urgentId]',
        tag: _tag,
      );
    }
  }

  @override
  Future<void> cancelItemAlerts(String itemId) async {
    try {
      final warningId = getWarningNotificationId(itemId);
      final urgentId = getUrgentNotificationId(itemId);

      await _plugin.cancel(warningId);
      await _plugin.cancel(urgentId);

      AppLogger.info(
        'Alertas canceladas para ítem [$itemId] (IDs: $warningId, $urgentId)',
        tag: _tag,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Error al cancelar alertas para ítem [$itemId]',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> cancelAllAlerts() async {
    try {
      await _plugin.cancelAll();
      AppLogger.info('Todas las alertas del sistema han sido canceladas.', tag: _tag);
    } catch (e, stack) {
      AppLogger.error(
        'Error al cancelar todas las alertas',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final scheduledTz = _toScheduledInstant(scheduledDate);

    // Si el permiso de alarma exacta no esta concedido, se usa el modo
    // inexacto desde el principio en lugar de provocar una excepcion (P2-5).
    final scheduleMode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTz,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e, stack) {
      // En Android 12+ el permiso de alarma exacta puede ser revocado por el
      // usuario. Sin este fallback la alerta se pierde en silencio (P1-8):
      // una alarma inexacta llega cerca de la hora, que es mejor que no
      // recibir ningún aviso de vencimiento.
      AppLogger.warning(
        'No se pudo programar la alarma exacta; se reintenta en modo inexacto.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTz,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        AppLogger.info(
          'Alerta reprogramada en modo inexacto (ID: $id).',
          tag: _tag,
        );
      } catch (fallbackError, fallbackStack) {
        AppLogger.error(
          'No se pudo programar la alerta $id ni en modo inexacto.',
          tag: _tag,
          error: fallbackError,
          stackTrace: fallbackStack,
        );
      }
    }
  }
}

