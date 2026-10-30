import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/logger.dart';
import '../entities/frozen_item.dart';
import 'get_inventory_items_usecase.dart';

/// Reprograma las alertas de vencimiento de todos los alimentos del inventario.
///
/// El sistema operativo puede perder las alarmas programadas: un reinicio del
/// dispositivo, un cambio de zona horaria, la hibernación de apps de Android 12+
/// o una desinstalación. Sin esta resincronización el usuario cree que tiene
/// avisos de vencimiento y no los tiene (P1-9).
///
/// Es idempotente: cada alerta se identifica por el id del alimento, así que
/// reprogramar reemplaza la alarma anterior en lugar de duplicarla.
class SyncInventoryAlertsUseCase {
  static const String _tag = 'SyncInventoryAlerts';

  final GetInventoryItemsUseCase getInventoryItemsUseCase;
  final INotificationService notificationService;

  const SyncInventoryAlertsUseCase({
    required this.getInventoryItemsUseCase,
    required this.notificationService,
  });

  /// Reprograma las alertas y devuelve cuántos alimentos quedaron cubiertos.
  ///
  /// Si se provee [preloadedItems], se reutiliza dicha lista en memoria,
  /// evitando una consulta duplicada a la base de datos de Hive.
  Future<Either<Failure, int>> call([List<FrozenItem>? preloadedItems]) async {
    final List<FrozenItem> items;
    if (preloadedItems != null) {
      items = preloadedItems;
    } else {
      final result = await getInventoryItemsUseCase();

      final Failure? failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        AppLogger.warning(
          'No se pudieron sincronizar las alertas de vencimiento: ${failure.message}',
          tag: _tag,
        );
        return Left(failure);
      }

      items = result.getOrElse((_) => const <FrozenItem>[]);
    }

    // Se cancelan todas las alertas antes de reprogramar: asi se limpian las
    // alarmas huerfanas de alimentos que ya no existen (box reiniciado, copia
    // de seguridad restaurada, etc.) y la resincronizacion es autocurativa
    // (P2-2).
    try {
      await notificationService.cancelAllAlerts();
    } catch (e, stack) {
      AppLogger.warning(
        'No se pudieron cancelar las alertas previas.',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
    }

    var scheduled = 0;
    for (final item in items) {
      if (item.isConsumed || !item.reminderEnabled) continue;

      try {
        await notificationService.scheduleItemAlerts(item);
        scheduled++;
      } catch (e, stack) {
        // Un alimento que falla no debe abortar la resincronización del resto.
        AppLogger.warning(
          'No se pudo reprogramar la alerta de "${item.name}".',
          tag: _tag,
          error: e,
          stackTrace: stack,
        );
      }
    }

    AppLogger.info(
      'Alertas de vencimiento resincronizadas: $scheduled de ${items.length}.',
      tag: _tag,
    );
    return Right(scheduled);
  }
}
