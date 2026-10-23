import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/purchase_issue.dart';

/// Estado inmutable para [MonetizationBloc].
class MonetizationState extends Equatable {
  final bool isPro;

  /// Indica si la consulta inicial de estado Pro ya finalizó (desde Hive o Play Billing).
  ///
  /// Permite distinguir entre "usuario gratuito confirmado" y "estado Pro aún desconocido".
  /// La UI oculta los anuncios durante el arranque en frío mientras `isProResolved == false`,
  /// eliminando el parpadeo de banners publicitarios para los suscriptores Pro (P3-1).
  final bool isProResolved;

  final bool isLoading;
  final ProductDetails? productDetails;
  final String? errorMessage;
  final bool isPurchaseSuccess;

  /// Último incidente del flujo de compra (cancelación, pendiente o fallo).
  ///
  /// Es `null` cuando no hay nada que informar. La interfaz lo muestra en
  /// línea para que el usuario siempre entienda por qué la compra no avanzó.
  final PurchaseIssue? purchaseIssue;

  const MonetizationState({
    this.isPro = false,
    this.isProResolved = false,
    this.isLoading = false,
    this.productDetails,
    this.errorMessage,
    this.isPurchaseSuccess = false,
    this.purchaseIssue,
  });

  const MonetizationState.initial()
      : isPro = false,
        isProResolved = false,
        isLoading = false,
        productDetails = null,
        errorMessage = null,
        isPurchaseSuccess = false,
        purchaseIssue = null;

  MonetizationState copyWith({
    bool? isPro,
    bool? isProResolved,
    bool? isLoading,
    ProductDetails? Function()? productDetails,
    String? Function()? errorMessage,
    bool? isPurchaseSuccess,
    PurchaseIssue? Function()? purchaseIssue,
  }) {
    return MonetizationState(
      isPro: isPro ?? this.isPro,
      isProResolved: isProResolved ?? this.isProResolved,
      isLoading: isLoading ?? this.isLoading,
      productDetails: productDetails != null ? productDetails() : this.productDetails,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isPurchaseSuccess: isPurchaseSuccess ?? this.isPurchaseSuccess,
      purchaseIssue: purchaseIssue != null ? purchaseIssue() : this.purchaseIssue,
    );
  }

  @override
  List<Object?> get props => [
        isPro,
        isProResolved,
        isLoading,
        productDetails,
        errorMessage,
        isPurchaseSuccess,
        purchaseIssue,
      ];
}
