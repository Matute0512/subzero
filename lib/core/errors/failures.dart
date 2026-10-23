import 'package:equatable/equatable.dart';

/// Clase base inmutable para todos los fallos en la capa de dominio.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Fallo derivado de operaciones en base de datos o almacenamiento local.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Fallo derivado de operaciones de red o sincronización.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Fallo derivado de operaciones con proveedores de anuncios (Google AdMob).
class AdFailure extends Failure {
  const AdFailure({required super.message, super.code});
}

/// Fallo derivado de compras in-app o facturación (Billing).
class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.code});
}

/// Fallo derivado de validaciones de reglas de negocio en UseCases.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Fallo inesperado o genérico no catalogado.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}




