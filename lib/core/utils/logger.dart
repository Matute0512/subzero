import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Logger estructurado para SubZero.
///
/// Centraliza la emisión de logs formateados y respeta las directrices de producción
/// evitando el uso de llamadas directas a `print()`.
///
/// En modo Release (`kReleaseMode`), los logs de nivel `debug` e `info` son suprimidos
/// automáticamente para prevenir fuga de metadatos o información sensible a través
/// de `adb logcat`.
class AppLogger {
  const AppLogger._();

  static const String _defaultTag = 'SubZero';

  /// Emite un log de nivel informativo (suprimido en Release).
  static void info(String message, {String tag = _defaultTag}) {
    if (kReleaseMode) return;
    developer.log(
      message,
      name: tag,
      level: 800,
      time: DateTime.now(),
    );
  }

  /// Emite un log de nivel depuración (suprimido en Release).
  static void debug(String message, {String tag = _defaultTag}) {
    if (kReleaseMode) return;
    developer.log(
      message,
      name: tag,
      level: 500,
      time: DateTime.now(),
    );
  }

  /// Emite un log de nivel advertencia (warning).
  static void warning(
    String message, {
    String tag = _defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  /// Emite un log de nivel error crítico.
  static void error(
    String message, {
    String tag = _defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}
