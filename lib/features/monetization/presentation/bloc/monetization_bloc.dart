import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/logger.dart';

import '../../domain/entities/purchase_issue.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/monetization_repository.dart';
import 'monetization_event.dart';
import 'monetization_state.dart';

/// BLoC que orquesta la verificación y compra de productos Pro.
class MonetizationBloc extends Bloc<MonetizationEvent, MonetizationState> {
  final IMonetizationRepository repository;
  StreamSubscription<SubscriptionStatus>? _statusSubscription;
  StreamSubscription<PurchaseIssue>? _issueSubscription;

  MonetizationBloc({required this.repository})
      : super(const MonetizationState.initial()) {
    on<CheckProStatusEvent>(_onCheckProStatus);
    on<LoadProductsEvent>(_onLoadProducts);
    on<PurchaseProEvent>(_onPurchasePro);
    on<RestorePurchasesEvent>(_onRestorePurchases);
    on<ProStatusUpdatedEvent>(_onProStatusUpdated);
    on<MonetizationPurchaseIssueEvent>(_onPurchaseIssue);

    // Escuchar actualizaciones reactivas del stream de compras
    _statusSubscription = repository.subscriptionStatusStream.listen((status) {
      add(ProStatusUpdatedEvent(status.isPro));
    });

    // Incidentes del flujo de compra: cancelacion, pago pendiente y fallos.
    // Sin esta suscripcion, una compra cancelada no produce ninguna senal y la
    // UI aparenta estar congelada.
    _issueSubscription = repository.purchaseIssueStream.listen((issue) {
      add(MonetizationPurchaseIssueEvent(issue));
    });
  }

  Future<void> _onCheckProStatus(
    CheckProStatusEvent event,
    Emitter<MonetizationState> emit,
  ) async {
    final result = await repository.getSubscriptionStatus();
    result.fold(
      (failure) => emit(state.copyWith(
        isProResolved: true,
        errorMessage: () => failure.message,
      )),
      (status) => emit(state.copyWith(
        isPro: status.isPro,
        isProResolved: true,
        errorMessage: () => null,
      )),
    );
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<MonetizationState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      purchaseIssue: () => null,
    ));
    final result = await repository.getProductDetails();
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: () => failure.message,
      )),
      (product) => emit(state.copyWith(
        isLoading: false,
        productDetails: () => product,
        errorMessage: () => null,
      )),
    );
  }

  Future<void> _onPurchasePro(
    PurchaseProEvent event,
    Emitter<MonetizationState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      purchaseIssue: () => null,
      isPurchaseSuccess: false,
    ));
    final result = await repository.purchaseProduct(event.productId);
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: () => failure.message,
      )),
      (_) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => null,
        ));
      },
    );
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<MonetizationState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      purchaseIssue: () => null,
      isPurchaseSuccess: false,
    ));
    final result = await repository.restorePurchases();
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        errorMessage: () => failure.message,
      )),
      (status) => emit(state.copyWith(
        isLoading: false,
        isPro: status.isPro,
        isProResolved: true,
        isPurchaseSuccess: status.isPro,
        errorMessage: () => null,
      )),
    );
  }

  void _onProStatusUpdated(
    ProStatusUpdatedEvent event,
    Emitter<MonetizationState> emit,
  ) {
    emit(state.copyWith(
      isPro: event.isPro,
      isProResolved: true,
      isPurchaseSuccess: event.isPro,
    ));
  }

  /// Traduce un incidente del flujo de compra a un estado visible para la UI.
  Future<void> _onPurchaseIssue(
    MonetizationPurchaseIssueEvent event,
    Emitter<MonetizationState> emit,
  ) async {
    AppLogger.info(
      'Incidencia de compra: ${event.issue.runtimeType}',
      tag: 'MonetizationBloc',
    );
    emit(state.copyWith(
      isLoading: false,
      // El incidente reemplaza al errorMessage previo: son excluyentes y
      // mostrar los dos a la vez confunde al usuario.
      errorMessage: () => null,
      purchaseIssue: () => event.issue,
    ));
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _issueSubscription?.cancel();
    return super.close();
  }
}
