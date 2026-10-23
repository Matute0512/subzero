import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../monetization/domain/repositories/monetization_repository.dart';
import '../../domain/repositories/inventory_quota_policy.dart';

/// Adaptador de [IInventoryQuotaPolicy] sobre el repositorio de monetización.
///
/// Es el único punto del código de inventario que conoce la feature de
/// monetización. Gracias a esta costura, `features/inventory/domain` y
/// `features/inventory/presentation` permanecen libres de dependencias hacia
/// `features/monetization`.
class InventoryQuotaPolicyImpl implements IInventoryQuotaPolicy {
  final IMonetizationRepository monetizationRepository;

  const InventoryQuotaPolicyImpl({required this.monetizationRepository});

  @override
  Future<Either<Failure, bool>> canAddItem({
    required int currentActiveCount,
  }) async {
    final statusResult = await monetizationRepository.getSubscriptionStatus();

    return statusResult.fold(
      (failure) => Left(failure),
      (status) => Right(
        status.isPro ||
            currentActiveCount < IInventoryQuotaPolicy.freeTierItemLimit,
      ),
    );
  }
}
