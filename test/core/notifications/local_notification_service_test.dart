import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:subzero/core/notifications/local_notification_service.dart';
import 'package:subzero/features/inventory/domain/entities/food_category.dart';
import 'package:subzero/features/inventory/domain/entities/frozen_item.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NotificationDetails());
    // mocktail necesita un valor de referencia para los argumentos no
    // primitivos (enums y TZDateTime).
    registerFallbackValue(tz.TZDateTime(tz.UTC, 2026, 1, 1));
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  });

  group('LocalNotificationService - Generación de IDs', () {
    test('getWarningNotificationId y getUrgentNotificationId deben ser deterministas y seguros en 32-bit', () {
      const itemId = 'food-uuid-1234';

      final warningId = LocalNotificationService.getWarningNotificationId(itemId);
      final urgentId = LocalNotificationService.getUrgentNotificationId(itemId);

      // Deben ser no negativos y menores al límite de enteros de 32 bits
      expect(warningId, greaterThanOrEqualTo(0));
      expect(warningId, lessThan(2147483647));
      expect(urgentId, greaterThanOrEqualTo(0));
      expect(urgentId, lessThan(2147483647));

      // Warning debe ser par y Urgent debe ser impar
      expect(warningId % 2, equals(0));
      expect(urgentId % 2, equals(1));
      expect(urgentId, equals(warningId + 1));

      // Determinismo para el mismo ID
      expect(LocalNotificationService.getWarningNotificationId(itemId), equals(warningId));
      expect(LocalNotificationService.getUrgentNotificationId(itemId), equals(urgentId));
    });

    test('P2-4: el hash es estable entre invocaciones y difiere por item', () {
      // El hash anterior usaba String.hashCode, que no garantiza unicidad
      // ni estabilidad entre ejecuciones del runtime.
      const id1 = 'item-alpha';
      const id2 = 'item-beta';

      final w1 = LocalNotificationService.getWarningNotificationId(id1);
      final w1bis = LocalNotificationService.getWarningNotificationId(id1);
      final w2 = LocalNotificationService.getWarningNotificationId(id2);

      expect(w1, equals(w1bis), reason: 'el ID debe ser determinista');
      expect(w1, isNot(equals(w2)), reason: 'items distintos deben diferir');
    });

    test('P2-4: el aviso de 7 días y el urgente de 1 día nunca colisionan entre items', () {
      // El diseño reserva los pares para "warning" y los impares para
      // "urgent", de modo que el urgente de un item no puede pisar al warning
      // de otro aunque sus hashes sean consecutivos.
      final ids = <String>{
        for (var i = 0; i < 200; i++) 'item-$i',
      };

      final warningIds = <int>{};
      final urgentIds = <int>{};

      for (final id in ids) {
        final w = LocalNotificationService.getWarningNotificationId(id);
        final u = LocalNotificationService.getUrgentNotificationId(id);
        expect(w % 2, equals(0));
        expect(u % 2, equals(1));
        warningIds.add(w);
        urgentIds.add(u);
      }

      // Ningun urgente puede coincidir con un warning de otro item.
      expect(warningIds.intersection(urgentIds), isEmpty);
      // Ningun item repite su propio ID de warning.
      expect(warningIds.length, ids.length);
    });

    test('distintos itemIds deben generar IDs consistentes sin colisionar consigo mismos', () {
      const id1 = 'item-alpha';
      const id2 = 'item-beta';

      final w1 = LocalNotificationService.getWarningNotificationId(id1);
      final u1 = LocalNotificationService.getUrgentNotificationId(id1);
      final w2 = LocalNotificationService.getWarningNotificationId(id2);
      final u2 = LocalNotificationService.getUrgentNotificationId(id2);

      expect(w1, isNot(equals(u1)));
      expect(w2, isNot(equals(u2)));
    });
  });

  group('LocalNotificationService - Modo de alarma (P2-5)', () {
    test('sin permiso de alarma exacta, la alerta se programa en modo inexacto',
        () async {
      final plugin = MockFlutterLocalNotificationsPlugin();
      final service = LocalNotificationService(plugin: plugin);

      AndroidScheduleMode? capturedMode;
      when(() => plugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          )).thenAnswer((invocation) async {
        capturedMode = invocation.namedArguments[#androidScheduleMode]
            as AndroidScheduleMode?;
      });
      when(() => plugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          )).thenAnswer((_) async => true);
      when(() => plugin.cancel(any())).thenAnswer((_) async {});
      when(() => plugin.cancelAll()).thenAnswer((_) async {});

      final item = FrozenItem(
        id: 'item-1',
        name: 'Guiso',
        category: FoodCategory.cooked,
        frozenDate: DateTime.now(),
        expirationDate: DateTime.now().add(const Duration(days: 30)),
      );

      await service.scheduleItemAlerts(item);

      // Sin el permiso concedido no se intenta la alarma exacta: se usa el
      // modo inexacto, que no lanza excepcion.
      expect(capturedMode, AndroidScheduleMode.inexactAllowWhileIdle);
    });
  });

  group('LocalNotificationService - Cálculo de Fechas de Disparo', () {
    test('calculateWarningAlertDate debe restar 7 días y fijar la hora a las 09:00:00 AM', () {
      final expiration = DateTime(2026, 10, 20, 16, 45, 30);
      final warningDate = LocalNotificationService.calculateWarningAlertDate(expiration);

      expect(warningDate.year, equals(2026));
      expect(warningDate.month, equals(10));
      expect(warningDate.day, equals(13));
      expect(warningDate.hour, equals(9));
      expect(warningDate.minute, equals(0));
      expect(warningDate.second, equals(0));
    });

    test('calculateUrgentAlertDate debe restar 1 día y fijar la hora a las 09:00:00 AM', () {
      final expiration = DateTime(2026, 10, 20, 16, 45, 30);
      final urgentDate = LocalNotificationService.calculateUrgentAlertDate(expiration);

      expect(urgentDate.year, equals(2026));
      expect(urgentDate.month, equals(10));
      expect(urgentDate.day, equals(19));
      expect(urgentDate.hour, equals(9));
      expect(urgentDate.minute, equals(0));
      expect(urgentDate.second, equals(0));
    });
  });

  group('LocalNotificationService - Flujos de Programación y Cancelación', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});
    });

    test('scheduleItemAlerts debe omitir programación si el ítem está consumido o reminderEnabled es falso', () async {
      final service = LocalNotificationService(
        plugin: mockPlugin,
        isInitialized: true,
      );

      final consumedItem = FrozenItem(
        id: 'consumed-1',
        name: 'Carne consumida',
        category: FoodCategory.redMeat,
        frozenDate: DateTime(2026, 1, 1),
        expirationDate: DateTime(2026, 12, 1),
        isConsumed: true,
      );

      final reminderDisabledItem = FrozenItem(
        id: 'no-reminder-1',
        name: 'Pan sin recordatorio',
        category: FoodCategory.bakery,
        frozenDate: DateTime(2026, 1, 1),
        expirationDate: DateTime(2026, 12, 1),
        reminderEnabled: false,
      );

      await service.scheduleItemAlerts(consumedItem);
      await service.scheduleItemAlerts(reminderDisabledItem);

      verifyNever(() => mockPlugin.cancel(any()));
    });

    test('cancelItemAlerts debe cancelar ambos IDs (warning y urgent) del ítem', () async {
      final service = LocalNotificationService(
        plugin: mockPlugin,
        isInitialized: true,
      );

      const itemId = 'test-item-to-cancel';
      final warningId = LocalNotificationService.getWarningNotificationId(itemId);
      final urgentId = LocalNotificationService.getUrgentNotificationId(itemId);

      await service.cancelItemAlerts(itemId);

      verify(() => mockPlugin.cancel(warningId)).called(1);
      verify(() => mockPlugin.cancel(urgentId)).called(1);
    });

    test('cancelAllAlerts debe invocar cancelAll en el plugin', () async {
      final service = LocalNotificationService(
        plugin: mockPlugin,
        isInitialized: true,
      );

      await service.cancelAllAlerts();

      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });
}

