import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/purchase_issue.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/monetization_repository.dart';
import '../datasources/in_app_purchase_datasource.dart';

/// Implementación del repositorio de monetización desacoplado.
class MonetizationRepositoryImpl implements IMonetizationRepository {
  final IInAppPurchaseDataSource dataSource;
  final StreamController<SubscriptionStatus> _statusController =
      StreamController<SubscriptionStatus>.broadcast();
  final StreamController<PurchaseIssue> _issueController =
      StreamController<PurchaseIssue>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  MonetizationRepositoryImpl({required this.dataSource}) {
    _purchaseSub = dataSource.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            if (p.productID == IInAppPurchaseDataSource.proLifetimeProductId) {
              _statusController.add(const SubscriptionStatus(isPro: true));
            }
          case PurchaseStatus.canceled:
            // El usuario cerro el dialogo de la tienda. Sin esta senal la UI
            // queda aparentando estar congelada.
            _issueController.add(const PurchaseCanceled());
          case PurchaseStatus.pending:
            // El pago quedo diferido: Play reintentara la confirmacion.
            _issueController.add(const PurchasePending());
          case PurchaseStatus.error:
            final error = p.error;
            _issueController.add(
              PurchaseFailed(
                code: error?.code ?? 'unknown',
                detail: error?.message ?? 'Error desconocido de la tienda.',
              ),
            );
        }
      }
    });
  }

  @override
  Stream<SubscriptionStatus> get subscriptionStatusStream => _statusController.stream;

  @override
  Stream<PurchaseIssue> get purchaseIssueStream => _issueController.stream;

  @override
  Future<Either<Failure, SubscriptionStatus>> getSubscriptionStatus() async {
    try {
      final isPro = await dataSource.getIsProLocal();
      return Right(SubscriptionStatus(isPro: isPro));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error al consultar estado de suscripción: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductDetails?>> getProductDetails() async {
    try {
      final product = await dataSource.getProductDetails();
      return Right(product);
    } on PaymentException catch (e) {
      return Left(PaymentFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error al consultar producto: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> purchaseProduct([String? productId]) async {
    try {
      await dataSource.buyProLifetime();
      return const Right(unit);
    } on PaymentException catch (e) {
      return Left(PaymentFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error al procesar compra: $e'));
    }
  }

  @override
  Future<Either<Failure, SubscriptionStatus>> restorePurchases() async {
    try {
      // Se espera la confirmación real de la tienda: leer el estado local
      // justo después de disparar el restore devolvía `false` antes de que
      // Play respondiera, y el usuario nunca quedaba desbloqueado.
      final isPro = await dataSource.restorePurchasesAndWait();
      return Right(SubscriptionStatus(isPro: isPro));
    } on PaymentException catch (e) {
      return Left(PaymentFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error al restaurar compras: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setProStatus(bool isPro) async {
    try {
      await dataSource.setProLocal(isPro);
      _statusController.add(SubscriptionStatus(isPro: isPro));
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Error al actualizar estado Pro: $e'));
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _statusController.close();
    _issueController.close();
  }
}
