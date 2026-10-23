import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/exceptions.dart';
import 'package:subzero/core/errors/failures.dart';
import 'package:subzero/features/monetization/data/datasources/in_app_purchase_datasource.dart';
import 'package:subzero/features/monetization/data/repositories/monetization_repository_impl.dart';
import 'package:subzero/features/monetization/domain/entities/subscription_status.dart';

class MockInAppPurchaseDataSource extends Mock
    implements IInAppPurchaseDataSource {}

void main() {
  late MockInAppPurchaseDataSource mockDataSource;
  late MonetizationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_fakePurchaseDetails());
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockDataSource = MockInAppPurchaseDataSource();
    // El repositorio escucha el stream de compras en el constructor.
    when(() => mockDataSource.purchaseStream)
        .thenAnswer((_) => const Stream<List<PurchaseDetails>>.empty());
    repository = MonetizationRepositoryImpl(dataSource: mockDataSource);
  });

  group('restorePurchases', () {
    test(
        'devuelve isPro=true cuando la tienda confirma la ownership (no lee el flag antes de tiempo)',
        () async {
      // La versión anterior hacía:
      //   await dataSource.restorePurchases();
      //   final isPro = await dataSource.getIsProLocal();  <-- leía antes de tiempo
      // y devolvía false, dejando al usuario bloqueado.
      when(() => mockDataSource.restorePurchasesAndWait(
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => true);

      final result = await repository.restorePurchases();

      expect(result, isA<Right<Failure, SubscriptionStatus>>());
      result.fold(
        (failure) => fail('Se esperaba Right, se obtuvo $failure'),
        (status) => expect(status.isPro, isTrue),
      );

      // El repositorio NO debe consultar el flag local por su cuenta.
      verifyNever(() => mockDataSource.getIsProLocal());
    });

    test('propaga el fallo si la tienda no está disponible', () async {
      when(() => mockDataSource.restorePurchasesAndWait(
            timeout: any(named: 'timeout'),
          )).thenThrow(const CacheException(message: 'Hive no disponible.'));

      final result = await repository.restorePurchases();

      expect(result, isA<Left<Failure, SubscriptionStatus>>());
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (status) => fail('Se esperaba Left, se obtuvo $status'),
      );
    });

    test('devuelve isPro=false si la tienda no encuentra compras', () async {
      when(() => mockDataSource.restorePurchasesAndWait(
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => false);

      final result = await repository.restorePurchases();

      result.fold(
        (failure) => fail('Se esperaba Right, se obtuvo $failure'),
        (status) => expect(status.isPro, isFalse),
      );
    });
  });
}

PurchaseDetails _fakePurchaseDetails() {
  return PurchaseDetails(
    purchaseID: 'purchase-1',
    productID: 'subzero_pro_lifetime',
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: '{}',
      source: 'test',
    ),
    transactionDate: '17000000000000',
    status: PurchaseStatus.restored,
  );
}
