import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/failures.dart';
import 'package:subzero/features/monetization/domain/entities/purchase_issue.dart';
import 'package:subzero/features/monetization/domain/entities/subscription_status.dart';
import 'package:subzero/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:subzero/features/monetization/presentation/bloc/monetization_bloc.dart';
import 'package:subzero/features/monetization/presentation/bloc/monetization_event.dart';
import 'package:subzero/features/monetization/presentation/bloc/monetization_state.dart';

class MockMonetizationRepository extends Mock implements IMonetizationRepository {}

class MockProductDetails extends Mock implements ProductDetails {}

void main() {
  late MonetizationBloc bloc;
  late MockMonetizationRepository mockRepository;
  late StreamController<SubscriptionStatus> statusStreamController;
  late StreamController<PurchaseIssue> issueStreamController;

  setUp(() {
    mockRepository = MockMonetizationRepository();
    statusStreamController = StreamController<SubscriptionStatus>.broadcast();
    issueStreamController = StreamController<PurchaseIssue>.broadcast();

    when(() => mockRepository.subscriptionStatusStream)
        .thenAnswer((_) => statusStreamController.stream);
    when(() => mockRepository.purchaseIssueStream)
        .thenAnswer((_) => issueStreamController.stream);

    bloc = MonetizationBloc(repository: mockRepository);
  });

  tearDown(() {
    statusStreamController.close();
    issueStreamController.close();
    bloc.close();
  });

  test('el estado inicial debe ser MonetizationState.initial()', () {
    expect(bloc.state, equals(const MonetizationState.initial()));
  });

  group('CheckProStatusEvent Tests', () {
    test('debe actualizar isPro a true cuando el usuario tiene Pro persistido', () async {
      when(() => mockRepository.getSubscriptionStatus())
          .thenAnswer((_) async => const Right(SubscriptionStatus(isPro: true)));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(isPro: true, isProResolved: true),
        ]),
      );

      bloc.add(const CheckProStatusEvent());
      await expectation;

      verify(() => mockRepository.getSubscriptionStatus()).called(1);
    });

    test('debe actualizar errorMessage cuando falla la lectura de persistencia', () async {
      when(() => mockRepository.getSubscriptionStatus())
          .thenAnswer((_) async => const Left(CacheFailure(message: 'Error en Hive')));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(errorMessage: 'Error en Hive', isProResolved: true),
        ]),
      );

      bloc.add(const CheckProStatusEvent());
      await expectation;
    });
  });

  group('LoadProductsEvent Tests', () {
    test('debe emitir isLoading y luego cargar productDetails exitosamente', () async {
      final mockProduct = MockProductDetails();
      when(() => mockProduct.id).thenReturn('subzero_pro_lifetime');
      when(() => mockProduct.price).thenReturn(r'$3.99');

      when(() => mockRepository.getProductDetails())
          .thenAnswer((_) async => Right(mockProduct));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(isLoading: true),
          MonetizationState(isLoading: false, productDetails: mockProduct),
        ]),
      );

      bloc.add(const LoadProductsEvent());
      await expectation;

      verify(() => mockRepository.getProductDetails()).called(1);
    });
  });

  group('PurchaseProEvent Tests', () {
    test('debe emitir isLoading y gestionar la llamada a purchaseProduct', () async {
      when(() => mockRepository.purchaseProduct(any()))
          .thenAnswer((_) async => const Right(unit));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(isLoading: true, isPurchaseSuccess: false),
          const MonetizationState(isLoading: false),
        ]),
      );

      bloc.add(const PurchaseProEvent('subzero_pro_lifetime'));
      await expectation;

      verify(() => mockRepository.purchaseProduct('subzero_pro_lifetime')).called(1);
    });

    test('debe emitir errorMessage cuando falla la compra', () async {
      when(() => mockRepository.purchaseProduct(any()))
          .thenAnswer((_) async => const Left(PaymentFailure(message: 'Pago cancelado')));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(isLoading: true, isPurchaseSuccess: false),
          const MonetizationState(isLoading: false, errorMessage: 'Pago cancelado'),
        ]),
      );

      bloc.add(const PurchaseProEvent('subzero_pro_lifetime'));
      await expectation;
    });
  });

  group('RestorePurchasesEvent Tests', () {
    test('debe restaurar compras y actualizar isPro', () async {
      when(() => mockRepository.restorePurchases())
          .thenAnswer((_) async => const Right(SubscriptionStatus(isPro: true)));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(isLoading: true),
          const MonetizationState(isLoading: false, isPro: true, isProResolved: true, isPurchaseSuccess: true),
        ]),
      );

      bloc.add(const RestorePurchasesEvent());
      await expectation;

      verify(() => mockRepository.restorePurchases()).called(1);
    });
  });

  group('Incidencias del flujo de compra', () {
    test('debe exponer la cancelacion del usuario como incidencia no bloqueante',
        () async {
      final expectation = expectLater(
        bloc.stream,
        emitsThrough(predicate<MonetizationState>(
            (state) => state.purchaseIssue is PurchaseCanceled)),
      );

      issueStreamController.add(const PurchaseCanceled());
      await expectation;

      final issue = bloc.state.purchaseIssue!;
      expect(issue, isA<PurchaseCanceled>());
      expect(issue.isError, isFalse);
      expect(bloc.state.isLoading, isFalse);
    });

    test('debe exponer el pago pendiente como incidencia no bloqueante',
        () async {
      final expectation = expectLater(
        bloc.stream,
        emitsThrough(predicate<MonetizationState>(
            (state) => state.purchaseIssue is PurchasePending)),
      );

      issueStreamController.add(const PurchasePending());
      await expectation;

      expect(bloc.state.purchaseIssue, isA<PurchasePending>());
      expect(bloc.state.purchaseIssue!.isError, isFalse);
    });

    test('debe exponer el fallo de la tienda como incidencia bloqueante',
        () async {
      final expectation = expectLater(
        bloc.stream,
        emitsThrough(predicate<MonetizationState>(
            (state) => state.purchaseIssue is PurchaseFailed)),
      );

      issueStreamController.add(
        const PurchaseFailed(code: 'purchase_error', detail: 'Sin conexion.'),
      );
      await expectation;

      final issue = bloc.state.purchaseIssue!;
      expect(issue, isA<PurchaseFailed>());
      expect(issue.isError, isTrue);
      expect(issue.message, contains('Sin conexion'));
    });

    test('la incidencia reemplaza al errorMessage previo', () async {
      when(() => mockRepository.getSubscriptionStatus())
          .thenAnswer((_) async => const Left(CacheFailure(message: 'Fallo')));

      bloc.add(const CheckProStatusEvent());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<MonetizationState>(
            (state) => state.errorMessage != null)),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(predicate<MonetizationState>(
            (state) => state.purchaseIssue != null)),
      );

      issueStreamController.add(const PurchaseCanceled());
      await expectation;

      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.purchaseIssue, isA<PurchaseCanceled>());
    });
  });

  group('Stream reactivo de compras', () {
    test('debe actualizar isPro cuando el stream de compras emite actualización Pro', () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const MonetizationState(isPro: true, isProResolved: true, isPurchaseSuccess: true),
        ]),
      );

      statusStreamController.add(const SubscriptionStatus(isPro: true));
      await expectation;
    });
  });
}

