import 'package:equatable/equatable.dart';

/// Entidad inmutable que representa el estado de suscripción y compras del usuario.
class SubscriptionStatus extends Equatable {
  final bool isPro;
  final DateTime? expirationDate;
  final String? purchaseToken;
  final DateTime? purchaseDate;
  final String? activeProductId;

  const SubscriptionStatus({
    required this.isPro,
    this.expirationDate,
    this.purchaseToken,
    this.purchaseDate,
    this.activeProductId,
  });

  const SubscriptionStatus.free()
      : isPro = false,
        expirationDate = null,
        purchaseToken = null,
        purchaseDate = null,
        activeProductId = null;

  SubscriptionStatus copyWith({
    bool? isPro,
    DateTime? expirationDate,
    String? purchaseToken,
    DateTime? purchaseDate,
    String? activeProductId,
  }) {
    return SubscriptionStatus(
      isPro: isPro ?? this.isPro,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      activeProductId: activeProductId ?? this.activeProductId,
    );
  }

  @override
  List<Object?> get props => [
        isPro,
        expirationDate,
        purchaseToken,
        purchaseDate,
        activeProductId,
      ];
}
