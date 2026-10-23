import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/exceptions.dart';
import 'package:subzero/features/monetization/data/datasources/in_app_purchase_datasource.dart';

class MockInAppPurchase extends Mock implements InAppPurchase {}

class MockBox extends Mock implements Box<dynamic> {}

PurchaseDetails _purchase({
  String productID = 'subzero_pro_lifetime',
  PurchaseStatus status = PurchaseStatus.restored,
  String? purchaseID = 'purchase-1',
}) {
  return PurchaseDetails(
    purchaseID: purchaseID,
    productID: productID,
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: '{}',
      source: 'test',
    ),
    transactionDate: '17000000000000',
    status: status,
  );
}

ProductDetails _productDetails({required String id}) {
  return ProductDetails(
    id: id,
    title: 'SubZero Pro',
    description: 'Acceso vitalicio a SubZero Pro',
    price: r'$3.99',
    rawPrice: 3.99,
    currencyCode: 'USD',
  );
}

void main() {
  late MockInAppPurchase mockInAppPurchase;
  late MockBox mockBox;
  late StreamController<List<PurchaseDetails>> purchaseStreamController;
  late InAppPurchaseDataSourceImpl dataSource;

  setUpAll(() {
    // mocktail necesita un valor de referencia para los argumentos no primitivos.
    registerFallbackValue(_purchase());
  });

  setUp(() {
    mockInAppPurchase = MockInAppPurchase();
    mockBox = MockBox();
    purchaseStreamController =
        StreamController<List<PurchaseDetails>>.broadcast();

    when(() => mockInAppPurchase.purchaseStream)
        .thenAnswer((_) => purchaseStreamController.stream);
    when(() => mockBox.put(any<dynamic>(), any<dynamic>()))
        .thenAnswer((_) async {});
    when(() => mockBox.get(any<dynamic>(),
            defaultValue: any<dynamic>(named: 'defaultValue')))
        .thenReturn(false);
    when(() => mockInAppPurchase.isAvailable()).thenAnswer((_) async => true);
    when(() => mockInAppPurchase.restorePurchases()).thenAnswer((_) async {});
    when(() => mockInAppPurchase.completePurchase(any()))
        .thenAnswer((_) async {});

    dataSource = InAppPurchaseDataSourceImpl(
      box: mockBox,
      inAppPurchase: mockInAppPurchase,
    );
  });

  tearDown(() async {
    dataSource.dispose();
    await purchaseStreamController.close();
  });

  group('restorePurchasesAndWait (P0-5)', () {
    test(
        'devuelve true cuando Play confirma la ownership DESPUÉS de disparar el restore',
        () async {
      // Reproduce la carrera que hacía que "Restaurar compras" nunca
      // desbloqueara al usuario: la respuesta de Play llega por el stream
      // DESPUÉS de que restorePurchases() hubiera retornado. La versión
      // anterior leía el flag local en ese instante y devolvía false.
      when(() => mockInAppPurchase.restorePurchases()).thenAnswer((_) async {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          purchaseStreamController.add([
            _purchase(status: PurchaseStatus.restored),
          ]);
        });
      });

      final result = await dataSource.restorePurchasesAndWait(
        timeout: const Duration(seconds: 2),
      );

      expect(result, isTrue);
    });

    test('devuelve true si la compra llega con estado purchased', () async {
      when(() => mockInAppPurchase.restorePurchases()).thenAnswer((_) async {
        Future<void>.delayed(const Duration(milliseconds: 20), () {
          purchaseStreamController.add([
            _purchase(status: PurchaseStatus.purchased),
          ]);
        });
      });

      final result = await dataSource.restorePurchasesAndWait(
        timeout: const Duration(seconds: 2),
      );

      expect(result, isTrue);
    });

    test('devuelve false si la tienda no confirma ninguna compra', () async {
      when(() => mockInAppPurchase.restorePurchases()).thenAnswer((_) async {});

      final result = await dataSource.restorePurchasesAndWait(
        timeout: const Duration(milliseconds: 200),
      );

      expect(result, isFalse);
    });

    test('propaga un error si la tienda no está disponible', () async {
      when(() => mockInAppPurchase.isAvailable()).thenAnswer((_) async => false);

      await expectLater(
        dataSource.restorePurchasesAndWait(
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<PaymentException>()),
      );
    });
  });

  group('getProductDetails (P2-7)', () {
    test('devuelve el producto solo si coincide con el id de SubZero', () async {
      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [_productDetails(id: 'subzero_pro_lifetime')],
          notFoundIDs: const [],
        ),
      );

      final result = await dataSource.getProductDetails();

      expect(result, isNotNull);
      expect(result!.id, 'subzero_pro_lifetime');
    });

    test('devuelve null si la tienda devuelve otro producto', () async {
      // `first` habria devuelto el producto equivocado (P2-7).
      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [_productDetails(id: 'otro_producto')],
          notFoundIDs: const [],
        ),
      );

      final result = await dataSource.getProductDetails();

      expect(result, isNull);
    });

    test('devuelve null si la tienda no encuentra el producto', () async {
      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const [],
        ),
      );

      expect(await dataSource.getProductDetails(), isNull);
    });

    test('propaga el error de la tienda', () async {
      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const [],
          error: IAPError(
            source: 'test',
            code: 'store_error',
            message: 'Error de la tienda.',
          ),
        ),
      );

      await expectLater(
        dataSource.getProductDetails(),
        throwsA(isA<PaymentException>()),
      );
    });
  });

  group('completePurchase (P1-3)', () {
    test('confirma la compra en el primer intento si no hay error', () async {
      when(() => mockInAppPurchase.completePurchase(any()))
          .thenAnswer((_) async {});

      await dataSource.completePurchase(_purchase(), retryDelay: Duration.zero);

      verify(() => mockInAppPurchase.completePurchase(any())).called(1);
    });

    test('reintenta hasta 3 veces ante fallos transitorios y termina ok',
        () async {
      var attempts = 0;
      when(() => mockInAppPurchase.completePurchase(any())).thenAnswer((_) async {
        attempts++;
        if (attempts < 3) throw Exception('Fallo de red transitorio');
      });

      await dataSource.completePurchase(_purchase(), retryDelay: Duration.zero);

      expect(attempts, 3);
      verify(() => mockInAppPurchase.completePurchase(any())).called(3);
    });

    test('propaga el error si los 3 intentos fallan', () async {
      when(() => mockInAppPurchase.completePurchase(any()))
          .thenThrow(Exception('Sin conexion con Play'));

      await expectLater(
        dataSource.completePurchase(_purchase()),
        throwsA(isA<CacheException>()),
      );

      verify(() => mockInAppPurchase.completePurchase(any())).called(3);
    });
  });

  group('getIsProLocal (P1-7)', () {
    test('devuelve el valor persistido', () async {
      when(() => mockBox.get(any<dynamic>(),
              defaultValue: any<dynamic>(named: 'defaultValue')))
          .thenReturn(true);

      expect(await dataSource.getIsProLocal(), isTrue);
    });

    test('conserva el ultimo valor conocido si Hive falla al leer', () async {
      // Primero se persiste Pro...
      when(() => mockBox.put(any<dynamic>(), any<dynamic>()))
          .thenAnswer((_) async {});
      await dataSource.setProLocal(true);

      // ...y luego la lectura falla.
      when(() => mockBox.get(any<dynamic>(),
              defaultValue: any<dynamic>(named: 'defaultValue')))
          .thenThrow(Exception('Hive corrupto'));

      // Un fallo de lectura NO debe revocar el Pro del usuario.
      expect(await dataSource.getIsProLocal(), isTrue);
    });

    test('devuelve false si la lectura falla y nunca hubo un valor conocido',
        () async {
      when(() => mockBox.get(any<dynamic>(),
              defaultValue: any<dynamic>(named: 'defaultValue')))
          .thenThrow(Exception('Hive corrupto'));

      expect(await dataSource.getIsProLocal(), isFalse);
    });
  });

  group('procesamiento del purchaseStream', () {
    test('persiste el estado Pro al recibir una compra confirmada', () async {
      purchaseStreamController.add([_purchase(status: PurchaseStatus.purchased)]);

      await Future<void>.delayed(Duration.zero);

      verify(() => mockBox.put('is_pro_user', true)).called(1);
    });

    test('confirma la transacción cuando queda pendiente de acknowledge',
        () async {
      final details = _purchase(status: PurchaseStatus.purchased);
      details.pendingCompletePurchase = true;

      purchaseStreamController.add([details]);

      await Future<void>.delayed(Duration.zero);

      verify(() => mockInAppPurchase.completePurchase(details)).called(1);
    });

    test('no persiste Pro para un producto distinto al de SubZero', () async {
      purchaseStreamController.add([
        _purchase(productID: 'otro_producto', status: PurchaseStatus.purchased),
      ]);

      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockBox.put('is_pro_user', any<dynamic>()));
    });
  });
}
