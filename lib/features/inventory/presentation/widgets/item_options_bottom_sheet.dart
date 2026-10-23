import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/frozen_item.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import 'add_item_bottom_sheet.dart';
import 'category_icon_helper.dart';

/// Acciones posibles seleccionables desde el menú de opciones de un alimento.
enum ItemOptionAction {
  edit,
  toggleConsumed,
  delete,
}

/// Menú de acciones rápidas para un alimento de SubZero (Material 3 y dark theme nórdico).
/// Previene acciones destructivas accidentales por tap involuntario.
class ItemOptionsBottomSheet extends StatelessWidget {
  final FrozenItem item;

  const ItemOptionsBottomSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, {required FrozenItem item}) async {
    final action = await showModalBottomSheet<ItemOptionAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => ItemOptionsBottomSheet(item: item),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case ItemOptionAction.edit:
        await AddItemBottomSheet.show(
          context,
          itemToEdit: item,
          onSave: (updatedItem) {
            context.read<InventoryBloc>().add(UpdateInventoryItemEvent(updatedItem));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${updatedItem.name}" actualizado con éxito.'),
                backgroundColor: AppTheme.surface,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      case ItemOptionAction.toggleConsumed:
        final willBeConsumed = !item.isConsumed;
        context.read<InventoryBloc>().add(ToggleConsumedItemEvent(item));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willBeConsumed
                  ? 'Marcado como consumido: "${item.name}".'
                  : 'Marcado como activo en congelador: "${item.name}".',
            ),
            backgroundColor: AppTheme.surface,
            duration: const Duration(seconds: 2),
          ),
        );
      case ItemOptionAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.surfaceVariant),
            ),
            title: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: AppTheme.urgencyCriticalAccent),
                SizedBox(width: 8),
                Text(
                  '¿Eliminar alimento?',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar permanentemente "${item.name}" del congelador? Esta acción no se puede deshacer.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.urgencyCriticalAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          context.read<InventoryBloc>().add(RemoveInventoryItemEvent(item.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${item.name}" ha sido eliminado.'),
              backgroundColor: AppTheme.surface,
              duration: const Duration(seconds: 2),
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.surfaceVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cabecera con info del alimento
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      item.category.icon,
                      color: AppTheme.secondaryAccent,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.category.displayName} • ${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}'
                        '${item.locationNotes != null ? " • ${item.locationNotes}" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.surfaceVariant, height: 1),
            const SizedBox(height: 8),

            // Opción 1: Editar detalles
            _buildOptionTile(
              context: context,
              icon: Icons.edit_outlined,
              iconColor: AppTheme.secondaryAccent,
              title: 'Editar detalles',
              subtitle: 'Modificar nombre, fecha, notas o cantidad',
              onTap: () => Navigator.of(context).pop(ItemOptionAction.edit),
            ),

            // Opción 2: Marcar como consumido / activo
            _buildOptionTile(
              context: context,
              icon: item.isConsumed
                  ? Icons.replay_rounded
                  : Icons.check_circle_outline_rounded,
              iconColor: item.isConsumed
                  ? AppTheme.urgencyWarningAccent
                  : AppTheme.urgencySafeAccent,
              title: item.isConsumed
                  ? 'Reactivar en congelador'
                  : 'Marcar como consumido',
              subtitle: item.isConsumed
                  ? 'Volver a incluir en el inventario activo'
                  : 'Pausar alertas de caducidad',
              onTap: () => Navigator.of(context).pop(ItemOptionAction.toggleConsumed),
            ),

            // Opción 3: Eliminar alimento
            _buildOptionTile(
              context: context,
              icon: Icons.delete_outline_rounded,
              iconColor: AppTheme.urgencyCriticalAccent,
              title: 'Eliminar alimento',
              subtitle: 'Remover definitivamente del congelador',
              titleColor: AppTheme.urgencyCriticalAccent,
              onTap: () => Navigator.of(context).pop(ItemOptionAction.delete),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.surfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

