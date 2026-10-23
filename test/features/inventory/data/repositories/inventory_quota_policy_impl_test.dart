import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:subzero/core/errors/failures.dart';
import 'package:subzero/features/inventory/data/repositories/inventory_quota_policy_impl.dart';
import 'package:subzero/features/inventory/domain/repositories/inventory_quota_policy.dart';
import 'package:subzero/features/monetization/domain/entities/subscription_status.dart';
import 'package:subzero/features/monetization/domain/repositories/monetization_repository.dart';

class MockMonetizationRepository extends Mock
    implements IMonetizationRepository {}

void main() {
  late MockMonetizationRepository mockMonetizationRepository;
  late InventoryQuotaPolicyImpl policy;

  const limit = IInventoryQuotaPolicy.freeTierItemLimit;

  setUp(() {
    mockMonetizationRepository = MockMonetizationRepository();
    policy = InventoryQuotaPolicyImpl(
      monetizationRepository: mockMonetizationRepository,
    );
  });

  void stubSubscription(Either<Failure, SubscriptionStatus> result) {
    when(() => mockMonetizationRepository.getSubscriptionStatus())
        .thenAnswer((_) async => result);
  }

  group('InventoryQuotaPolicyImpl', () {
    test('permite agregar cuando el usuario es Pro aunque estÃ© en el lÃ­mite',
        () async {
      stubSubscription(const Right(SubscriptionStatus(isPro: true)));

      final result = await policy.canAddItem(currentActiveCount: limit);

      expect(result, equals(const Right<Failure, bool>(true)));
    });

    test('permite agregar si el usuario gratuito estÃ¡ por debajo del lÃ­mite',
        () async {
      stubSubscription(const Right(SubscriptionStatus.free()));

      final result = await policy.canAddItem(currentActiveCount: limit - 1);

      expect(result, equals(const Right<Failure, bool>(true)));
    });

    test('bloquea si el usuario gratuito alcanzÃ³ el lÃ­mite', () async {
      stubSubscription(const Right(SubscriptionStatus.free()));

      final result = await policy.canAddItem(currentActiveCount: limit);

      expect(result, equals(const Right<Failure, bool>(false)));
    });

    test('bloquea si el usuario gratuito superÃ³ el lÃ­mite', () async {
      stubSubscription(const Right(SubscriptionStatus.free()));

      final result = await policy.canAddItem(currentActiveCount: limit + 10);

      expect(result, equals(const Right<Failure, bool>(false)));
    });

    test('propaga el fallo cuando no se puede determinar la suscripciÃ³n',
        () async {
      const failure = CacheFailure(message: 'Sin conexiÃ³n con Hive.');
      stubSubscription(const Left<Failure, SubscriptionStatus>(failure));

      final result = await policy.canAddItem(currentActiveCount: 0);

      expect(result, equals(const Left<Failure, bool>(failure)));
    });

    test(
        'resolveWithoutSubscription aplica el lÃ­mite gratuito de forma conservadora',
        () {
      expect(
        IInventoryQuotaPolicy.resolveWithoutSubscription(currentActiveCount: 0),
        isTrue,
      );
      expect(
        IInventoryQuotaPolicy.resolveWithoutSubscription(
          currentActiveCount: limit - 1,
        ),
        isTrue,
      );
      expect(
        IInventoryQuotaPolicy.resolveWithoutSubscription(
          currentActiveCount: limit,
        ),
        isFalse,
      );
    });
  });
}
