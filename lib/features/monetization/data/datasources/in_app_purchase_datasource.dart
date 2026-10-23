import 'dart:async';

import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

/// Contrato del DataSource de Facturación y Compras In-App para SubZero.
abstract class IInAppPurchaseDataSource {
  /// Identificador único del producto Pro de por vida.
  static const String proLifetimeProductId = 'subzero_pro_lifetime';

  /// Clave utilizada para la persistencia local en Hive.
  static const String proUserKey = 'is_pro_user';

  /// Nombre de la Box de persistencia de monetización.
  static const String boxName = 'monetization_box';

  Future<bool> getIsProLocal();
  Future<void> setProLocal(bool isPro);
  Future<ProductDetails?> getProductDetails();
  Future<void> buyProLifetime();

  /// Restaura las compras y espera al resultado real de la tienda.
  ///
  /// `InAppPurchase.restorePurchases()` solo *dispara* la petición: la
  /// respuesta llega después por `purchaseStream`. Consultar el estado local
  /// inmediatamente después devuelve `false` y el usuario nunca queda
  /// desbloqueado. Este método espera a que Play confirme la ownership.
  ///
  /// Devuelve `true` si el usuario es propietario del producto Pro.
  Future<bool> restorePurchasesAndWait({
    Duration timeout = const Duration(seconds: 20),
  });

  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<void> completePurchase(
    PurchaseDetails purchaseDetails, {
    Duration retryDelay,
  });
  void dispose();
}

/// Implementación del DataSource que interactúa con Google Play Billing / App Store y Hive.
class InAppPurchaseDataSourceImpl implements IInAppPurchaseDataSource {
  static const String _tag = 'InAppPurchaseDataSource';

  /// Timeout defensivo para las llamadas a la tienda.
  ///
  /// En una red movil degradada estas llamadas pueden tardar minutos; sin un
  /// limite, el paywall quedaria con el spinner indefinido (P2-6).
  static const Duration _storeTimeout = Duration(seconds: 15);

  final Box<dynamic> _box;
  final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final StreamController<List<PurchaseDetails>> _purchaseController =
      StreamController<List<PurchaseDetails>>.broadcast();

  InAppPurchaseDataSourceImpl({
    required Box<dynamic> box,
    InAppPurchase? inAppPurchase,
  })  : _box = box,
        _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _initializePurchaseListener();
  }

  void _initializePurchaseListener() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        AppLogger.error(
          'Error en el stream de compras in-app',
          tag: _tag,
          error: error,
        );
      },
    );
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      AppLogger.info(
        'Procesando actualización de compra: ${purchaseDetails.productID} - Estado: ${purchaseDetails.status}',
        tag: _tag,
      );

      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == IInAppPurchaseDataSource.proLifetimeProductId) {
          await setProLocal(true);
        }

        // Confirmar transacción para evitar reembolsos automáticos tras 3 días en Google Play
        if (purchaseDetails.pendingCompletePurchase) {
          try {
            await completePurchase(purchaseDetails);
          } catch (e, stack) {
            AppLogger.error(
              'No se pudo confirmar la compra ${purchaseDetails.purchaseID}. '
              'Play la reintentará en el próximo arranque de la app.',
              tag: _tag,
              error: e,
              stackTrace: stack,
            );
          }
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        AppLogger.info(
          'El usuario canceló la compra de ${purchaseDetails.productID}.',
          tag: _tag,
        );
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        AppLogger.info(
          'Compra pendiente de confirmación: ${purchaseDetails.productID}.',
          tag: _tag,
        );
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        AppLogger.error(
          'Fallo en transacción de compra: ${purchaseDetails.error?.message}',
          tag: _tag,
          error: purchaseDetails.error,
        );
      }
    }
    _purchaseController.add(purchaseDetailsList);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchaseController.stream;

  /// Último estado Pro conocido.
  ///
  /// Se usa como red de seguridad: un error de lectura transitorio de Hive no
  /// debe revocar el Pro de un usuario que ya lo pagó (P1-7).
  bool _cachedPro = false;

  @override
  Future<bool> getIsProLocal() async {
    try {
      final value = _box.get(IInAppPurchaseDataSource.proUserKey, defaultValue: false);
      _cachedPro = value is bool ? value : false;
      return _cachedPro;
    } catch (e, stack) {
      AppLogger.error(
        'Error al leer estado Pro local desde Hive. '
        'Se conserva el último valor conocido ($_cachedPro).',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      // Conservador con el usuario: un fallo de lectura no revoca el Pro.
      return _cachedPro;
    }
  }

  @override
  Future<void> setProLocal(bool isPro) async {
    try {
      await _box.put(IInAppPurchaseDataSource.proUserKey, isPro);
      _cachedPro = isPro;
      AppLogger.info('Estado Pro actualizado localmente a: $isPro', tag: _tag);
    } catch (e, stack) {
      AppLogger.error(
        'Error al guardar estado Pro local en Hive',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      throw CacheException(message: 'Error al persistir estado Pro: $e');
    }
  }

  @override
  Future<ProductDetails?> getProductDetails() async {
    try {
      final isAvailable = await _inAppPurchase.isAvailable().timeout(
        _storeTimeout,
        onTimeout: () => false,
      );
      if (!isAvailable) {
        AppLogger.warning('Google Play Billing no está disponible en este momento.', tag: _tag);
        return null;
      }

      final response = await _inAppPurchase
          .queryProductDetails({
            IInAppPurchaseDataSource.proLifetimeProductId,
          })
          .timeout(
            _storeTimeout,
            onTimeout: () => ProductDetailsResponse(
              productDetails: const [],
              notFoundIDs: const [],
              error: IAPError(
                source: 'subzero',
                code: 'store_timeout',
                message: 'La tienda no respondió a tiempo. Revisa tu conexión.',
              ),
            ),
          );

      if (response.error != null) {
        AppLogger.error(
          'Error al consultar detalles de producto: ${response.error!.message}',
          tag: _tag,
        );
        throw PaymentException(message: response.error!.message);
      }

      // Se busca el producto por id: la tienda puede devolver varios y
      // `first` podria ser otro (P2-7).
      final matches = response.productDetails.where(
        (p) => p.id == IInAppPurchaseDataSource.proLifetimeProductId,
      );

      if (matches.isEmpty) {
        AppLogger.warning(
          'El producto ${IInAppPurchaseDataSource.proLifetimeProductId} no fue encontrado en la tienda.',
          tag: _tag,
        );
        return null;
      }

      return matches.first;
    } catch (e, stack) {
      if (e is PaymentException) rethrow;
      AppLogger.error(
        'Excepción al consultar productos in-app',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      throw PaymentException(message: 'Error de conexión con la tienda: $e');
    }
  }

  @override
  Future<void> buyProLifetime() async {
    try {
      final isAvailable = await _inAppPurchase.isAvailable().timeout(
        _storeTimeout,
        onTimeout: () => false,
      );
      if (!isAvailable) {
        throw const PaymentException(message: 'La tienda de aplicaciones no está disponible.');
      }

      final product = await getProductDetails();
      if (product == null) {
        throw const PaymentException(
          message: 'El producto SubZero Pro no está configurado en la tienda.',
        );
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        throw const PaymentException(message: 'No se pudo iniciar el flujo de compra in-app.');
      }
    } catch (e, stack) {
      if (e is PaymentException) rethrow;
      AppLogger.error('Error al iniciar compra Pro', tag: _tag, error: e, stackTrace: stack);
      throw PaymentException(message: 'Fallo al procesar compra: $e');
    }
  }

  @override
  Future<bool> restorePurchasesAndWait({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final completer = Completer<bool>();
    late final StreamSubscription<List<PurchaseDetails>> subscription;

    subscription = _purchaseController.stream.listen((purchases) {
      final ownsPro = purchases.any(
        (purchase) =>
            purchase.productID == IInAppPurchaseDataSource.proLifetimeProductId &&
            (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored),
      );
      if (ownsPro && !completer.isCompleted) {
        completer.complete(true);
      }
    });

    try {
      final isAvailable = await _inAppPurchase.isAvailable().timeout(
        _storeTimeout,
        onTimeout: () => false,
      );
      if (!isAvailable) {
        throw const PaymentException(
          message: 'La tienda de aplicaciones no está disponible.',
        );
      }

      await _inAppPurchase.restorePurchases().timeout(_storeTimeout);
      AppLogger.info('Solicitud de restauración enviada a la tienda.', tag: _tag);

      // Se espera a que la tienda confirme la ownership. Si no responde a
      // tiempo, se cae al último estado conocido en lugar de fallar.
      return await completer.future.timeout(
        timeout,
        onTimeout: () async {
          AppLogger.warning(
            'Timeout esperando la confirmación de Play tras restaurar compras.',
            tag: _tag,
          );
          return getIsProLocal();
        },
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// Confirma la compra ante Google Play (acknowledge).
  ///
  /// Play revierte automáticamente toda compra no confirmada en 3 días, así que
  /// un fallo transitorio de red no puede quedar sin reintento. El error se
  /// propaga para que el llamador lo vea en lugar de perderlo en el log.
  @override
  Future<void> completePurchase(
    PurchaseDetails purchaseDetails, {
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    const maxAttempts = 3;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _inAppPurchase.completePurchase(purchaseDetails);
        AppLogger.info(
          'Transacción completada exitosamente: ${purchaseDetails.purchaseID}',
          tag: _tag,
        );
        return;
      } catch (e, stack) {
        AppLogger.warning(
          'No se pudo confirmar la compra ${purchaseDetails.purchaseID} '
          '(intento $attempt de $maxAttempts).',
          tag: _tag,
          error: e,
          stackTrace: stack,
        );
        if (attempt < maxAttempts) {
          // Espera creciente entre reintentos (inyectable para los tests).
          await Future<void>.delayed(retryDelay * attempt);
        }
      }
    }

    throw CacheException(
      message: 'No se pudo confirmar la compra ${purchaseDetails.purchaseID}',
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }
}



