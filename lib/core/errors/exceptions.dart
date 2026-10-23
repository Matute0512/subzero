/// Excepción base para errores originados en fuentes de datos locales.
class CacheException implements Exception {
  final String message;
  final int? code;

  const CacheException({required this.message, this.code});

  @override
  String toString() => 'CacheException(message: $message, code: $code)';
}



/// Excepción para operaciones de conectividad o red.
class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Excepción originada por el SDK de mediación o renderizado de anuncios.
class AdException implements Exception {
  final String message;
  final int? code;

  const AdException({required this.message, this.code});

  @override
  String toString() => 'AdException(message: $message, code: $code)';
}

/// Excepción originada por la plataforma de Google Play Billing / In-App Purchases.
class PaymentException implements Exception {
  final String message;

  const PaymentException({required this.message});

  @override
  String toString() => 'PaymentException(message: $message)';
}

