import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/frozen_item.dart';
import 'category_icon_helper.dart';
import 'item_options_bottom_sheet.dart';

/// Tarjeta visual de alimento optimizada para SubZero siguiendo las especificaciones
/// exactas del diseño de Figma (Auto-Layout, tokens de color, badges y bordes).
class InventoryItemCard extends StatelessWidget {
  final FrozenItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleConsumed;
  final VoidCallback? onTap;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onToggleConsumed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(item.urgencyStatus),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () => ItemOptionsBottomSheet.show(context, item: item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono redondeado de la categoría (44x44, radius 12)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      item.category.icon,
                      color: AppTheme.secondaryAccent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Centro: Nombre del alimento y metadatos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          color: item.isConsumed
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          decoration: item.isConsumed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitleText(dateFormat),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Derecha: UrgencyBadge + Indicador de campana
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUrgencyBadge(item.urgencyStatus),
                    if (item.hasActiveAlerts) ...[
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 14,
                        color: AppTheme.secondaryAccent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitleText(DateFormat dateFormat) {
    final buffer = StringBuffer();
    if (item.locationNotes != null && item.locationNotes!.trim().isNotEmpty) {
      buffer.write('${item.locationNotes!.trim()} • ');
    }
    final qtyFormatted =
        item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    buffer.write('$qtyFormatted ${item.unit}');
    return buffer.toString();
  }

  Widget _buildUrgencyBadge(UrgencyStatus status) {
    if (item.isConsumed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Consumido',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final bgColor = _getBadgeBackgroundColor(status);
    final textColor = _getBadgeTextColor(status);
    final label = _getBadgeLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == UrgencyStatus.critical
                ? Icons.warning_amber_rounded
                : (status == UrgencyStatus.warning
                    ? Icons.access_time_rounded
                    : Icons.check_circle_outline_rounded),
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getBadgeLabel(UrgencyStatus status) {
    if (item.daysRemaining < 0) {
      return 'Vencido';
    } else if (item.daysRemaining == 0) {
      return 'Vence hoy';
    } else if (item.daysRemaining == 1) {
      return 'Vence en 1 día';
    } else if (item.daysRemaining <= 30) {
      return 'Vence en ${item.daysRemaining} días';
    } else {
      final months = (item.daysRemaining / 30).floor();
      return 'Vence en $months meses';
    }
  }

  Color _getBadgeBackgroundColor(UrgencyStatus status) {
    switch (status) {
      case UrgencyStatus.critical:
        return AppTheme.urgencyCriticalContainer;
      case UrgencyStatus.warning:
        return AppTheme.urgencyWarningContainer;
      case UrgencyStatus.safe:
        return AppTheme.urgencySafeContainer;
    }
  }

  Color _getBadgeTextColor(UrgencyStatus status) {
    switch (status) {
      case UrgencyStatus.critical:
        return AppTheme.urgencyCriticalAccent;
      case UrgencyStatus.warning:
        return AppTheme.urgencyWarningAccent;
      case UrgencyStatus.safe:
        return AppTheme.urgencySafeAccent;
    }
  }

  Color _getBorderColor(UrgencyStatus status) {
    if (item.isConsumed) {
      return AppTheme.surfaceVariant;
    }
    switch (status) {
      case UrgencyStatus.critical:
        return AppTheme.urgencyCriticalAccent.withValues(alpha: 0.35);
      case UrgencyStatus.warning:
        return AppTheme.urgencyWarningAccent.withValues(alpha: 0.25);
      case UrgencyStatus.safe:
        return AppTheme.surfaceVariant;
    }
  }
}
