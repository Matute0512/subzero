import 'package:equatable/equatable.dart';

import '../../../../core/notifications/notifiable_item.dart';
import 'food_category.dart';

/// Clasificación de urgencia según la proximidad de la fecha de caducidad.
enum UrgencyStatus {
  /// Alimento con 7 días o menos de vida útil restante (o ya vencido).
  critical,

  /// Alimento con entre 8 y 30 días restantes de vida útil.
  warning,

  /// Alimento seguro con más de 30 días de vida útil restante.
  safe,
}

/// Entidad pura e inmutable que representa un alimento en el congelador.
class FrozenItem extends Equatable implements NotifiableItem {
  @override
  final String id;
  @override
  final String name;
  final FoodCategory category;

  @override
  String get categoryDisplayName => category.displayName;

  final DateTime frozenDate;
  @override
  final DateTime expirationDate;
  final double quantity;
  final String unit;
  final String? locationNotes;
  @override
  final bool isConsumed;
  @override
  final bool reminderEnabled;

  const FrozenItem({
    required this.id,
    required this.name,
    required this.category,
    required this.frozenDate,
    required this.expirationDate,
    this.quantity = 1.0,
    this.unit = 'unidad',
    this.locationNotes,
    this.isConsumed = false,
    this.reminderEnabled = true,
  });

  /// Días restantes hasta la fecha de caducidad normalizados al día.
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return target.difference(today).inDays;
  }

  /// Nivel de urgencia de consumo del alimento.
  UrgencyStatus get urgencyStatus {
    final days = daysRemaining;
    if (days <= 7) return UrgencyStatus.critical;
    if (days <= 30) return UrgencyStatus.warning;
    return UrgencyStatus.safe;
  }

  /// Indica si la fecha de caducidad ya ha sido superada.
  bool get isExpired => daysRemaining < 0;

  /// Indica si el ítem tiene alertas activas programadas vigentes.
  bool get hasActiveAlerts => reminderEnabled && !isConsumed && !isExpired;

  FrozenItem copyWith({
    String? id,
    String? name,
    FoodCategory? category,
    DateTime? frozenDate,
    DateTime? expirationDate,
    double? quantity,
    String? unit,
    String? locationNotes,
    bool? isConsumed,
    bool? reminderEnabled,
  }) {
    return FrozenItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      frozenDate: frozenDate ?? this.frozenDate,
      expirationDate: expirationDate ?? this.expirationDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      locationNotes: locationNotes ?? this.locationNotes,
      isConsumed: isConsumed ?? this.isConsumed,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        frozenDate,
        expirationDate,
        quantity,
        unit,
        locationNotes,
        isConsumed,
        reminderEnabled,
      ];
}



