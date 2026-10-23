import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/ad_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/presentation/screens/privacy_policy_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../monetization/presentation/bloc/monetization_bloc.dart';
import '../../../monetization/presentation/bloc/monetization_state.dart';
import '../../../monetization/presentation/screens/paywall_screen.dart';
import '../../../monetization/presentation/widgets/pro_badge_widget.dart';
import '../../domain/entities/frozen_item.dart';
import '../../domain/repositories/inventory_quota_policy.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../widgets/add_item_bottom_sheet.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/item_options_bottom_sheet.dart';

/// Pantalla principal interactiva de SubZero según las especificaciones de Figma (Screen 01).
class HomeInventoryScreen extends StatefulWidget {
  const HomeInventoryScreen({super.key});

  @override
  State<HomeInventoryScreen> createState() => _HomeInventoryScreenState();
}

class _HomeInventoryScreenState extends State<HomeInventoryScreen> {
  final IAdService _adService = sl<IAdService>();
  final INotificationService _notificationService = sl<INotificationService>();
  UrgencyStatus? _selectedUrgencyFilter;

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const LoadInventoryEvent());

    // Reaccion a la pulsacion de la notificacion de vencimiento: abre el
    // alimento sobre el que el usuario toco (P2-3).
    _notificationService.onItemNotificationTapped = _onItemNotificationTapped;

    // Solicitud explícita y no bloqueante de permisos al inicializar la pantalla principal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.requestPermissions();
    });
  }

  @override
  void dispose() {
    // Se libera el handler para no invocar un State desmontado.
    if (_notificationService.onItemNotificationTapped == _onItemNotificationTapped) {
      _notificationService.onItemNotificationTapped = null;
    }
    super.dispose();
  }

  /// Abre el alimento sobre el que el usuario toco la notificacion.
  ///
  /// Se busca en `items` (todos los activos) y no en `filteredItems`, para que
  /// el alimento sea alcanzable aunque el filtro de urgencia lo oculte.
  void _onItemNotificationTapped(String itemId) {
    if (!mounted) return;

    final inventoryState = context.read<InventoryBloc>().state;
    if (inventoryState is! InventoryLoaded) return;

    final match = inventoryState.items.where((i) => i.id == itemId).toList();
    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ese alimento ya no está en tu inventario.'),
          backgroundColor: AppTheme.surface,
        ),
      );
      return;
    }

    ItemOptionsBottomSheet.show(context, item: match.first);
  }

  void _onFilterChanged(UrgencyStatus? filter) {
    setState(() {
      _selectedUrgencyFilter = filter;
    });
    context.read<InventoryBloc>().add(
          FilterInventoryEvent(urgencyFilter: filter),
        );
  }

  void _openAddItemModal() {
    final inventoryState = context.read<InventoryBloc>().state;

    // La cuota la decide el InventoryBloc: su estado es la única fuente de
    // verdad para esta decisión (no se consulta MonetizationBloc).
    if (!inventoryState.canAddItem) {
      _showLimitReachedDialog();
      return;
    }

    _notificationService.requestPermissions();

    AddItemBottomSheet.show(
      context,
      onSave: (newItem) {
        context.read<InventoryBloc>().add(AddInventoryItemEvent(newItem));
        // Disparar anuncio intersticial ocasional solo si NO es usuario Pro
        final monState = context.read<MonetizationBloc>().state;
        if (monState.isProResolved && !monState.isPro) {
          _adService.showInterstitial(placementName: 'OnItemAddedInterstitial');
        }
      },
    );
  }

  void _showLimitReachedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.surfaceVariant),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.secondaryAccent),
            SizedBox(width: 8),
            Text(
              'Límite de espacio',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Has alcanzado el límite de 25 alimentos activos en tu congelador.\n\n'
          'Desbloquea SubZero Pro para disfrutar de espacio ilimitado y navegación 100% libre de anuncios.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              PaywallScreen.show(context);
            },
            icon: const Icon(Icons.workspace_premium_rounded, size: 18),
            label: const Text('Ver SubZero Pro'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // La cuota de inventario depende del estado de suscripción: si cambia
        // (compra o restauración de Pro) hay que reevaluarla al instante.
        BlocListener<MonetizationBloc, MonetizationState>(
          listenWhen: (previous, current) => previous.isPro != current.isPro,
          listener: (context, state) {
            context.read<InventoryBloc>().add(const RefreshInventoryQuotaEvent());
          },
        ),
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryLimitReachedState) {
              _showLimitReachedDialog();
              context.read<InventoryBloc>().add(const LoadInventoryEvent());
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            // Carrusel de Chips de Filtro
            _buildFilterChips(),

            // Lista reactiva de alimentos
            Expanded(
              child: BlocBuilder<InventoryBloc, InventoryState>(
                builder: (context, state) {
                  if (state is InventoryLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.secondaryAccent),
                    );
                  } else if (state is InventoryError) {
                    return _buildErrorState(state.message);
                  } else if (state is InventoryLoaded) {
                    if (state.items.isEmpty) {
                      return _buildEmptyState(
                        title: 'El congelador está vacío',
                        description:
                            'Presiona el botón "+" para registrar alimentos y recibir alertas automáticas de caducidad.',
                      );
                    }

                    if (state.filteredItems.isEmpty) {
                      return _buildEmptyState(
                        title: 'Sin alimentos con este filtro',
                        description:
                            'No hay elementos en esta categoría de urgencia seleccionada.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = state.filteredItems[index];

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppTheme.urgencyCriticalContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    color: AppTheme.urgencyCriticalAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.delete_sweep, color: AppTheme.urgencyCriticalAccent),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            context.read<InventoryBloc>().add(
                                  RemoveInventoryItemEvent(item.id),
                                );
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${item.name}" eliminado del congelador.'),
                                backgroundColor: AppTheme.surface,
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label: 'DESHACER',
                                  textColor: AppTheme.secondaryAccent,
                                  onPressed: () {
                                    context.read<InventoryBloc>().add(AddInventoryItemEvent(item));
                                  },
                                ),
                              ),
                            );
                          },
                          child: InventoryItemCard(
                            item: item,
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Banner inferior desacoplado de AdMob: oculto para usuarios Pro
            BlocBuilder<MonetizationBloc, MonetizationState>(
              builder: (context, state) {
                if (!state.isProResolved || state.isPro) {
                  return const SizedBox.shrink();
                }
                return SafeArea(
                  top: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.surfaceVariant, width: 1),
                      ),
                    ),
                    child: _adService.getBannerWidget(placementName: 'HomeInventoryBanner'),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppTheme.cyanGlowShadow,
          ),
          child: FloatingActionButton(
            onPressed: _openAddItemModal,
            backgroundColor: AppTheme.secondaryAccent,
            foregroundColor: AppTheme.backgroundDark,
            child: const Icon(Icons.add, size: 30, color: AppTheme.backgroundDark),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ac_unit, size: 24, color: AppTheme.secondaryAccent),
          SizedBox(width: 8),
          Text(
            'SubZero',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        BlocBuilder<MonetizationBloc, MonetizationState>(
          builder: (context, monState) {
            return BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, invState) {
                final count = invState is InventoryLoaded ? invState.activeCount : 0;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (monState.isPro)
                      const Padding(
                        padding: EdgeInsets.only(right: 4.0),
                        child: ProBadgeWidget(),
                      )
                    else ...[
                      // Badge contador de cupo: "14 / 25 usados"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.surfaceVariant),
                        ),
                        child: Text(
                          '$count / ${IInventoryQuotaPolicy.freeTierItemLimit} usados',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: count >= IInventoryQuotaPolicy.freeTierItemLimit
                                ? AppTheme.urgencyCriticalAccent
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ProBadgeWidget(
                          onTap: () => PaywallScreen.show(context),
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.shield_outlined, color: AppTheme.textSecondary, size: 20),
                      tooltip: 'Política de Privacidad',
                      splashRadius: 20,
                      onPressed: () => PrivacyPolicyScreen.show(context),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        int allCount = 0;
        int critCount = 0;
        int warnCount = 0;
        int safeCount = 0;

        if (state is InventoryLoaded) {
          final activeItems = state.items.where((i) => !i.isConsumed);
          allCount = activeItems.length;
          critCount = activeItems.where((i) => i.urgencyStatus == UrgencyStatus.critical).length;
          warnCount = activeItems.where((i) => i.urgencyStatus == UrgencyStatus.warning).length;
          safeCount = activeItems.where((i) => i.urgencyStatus == UrgencyStatus.safe).length;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildCustomChip(
                label: 'Todos ($allCount)',
                isSelected: _selectedUrgencyFilter == null,
                onTap: () => _onFilterChanged(null),
              ),
              const SizedBox(width: 8),
              _buildCustomChip(
                label: 'Críticos ($critCount)',
                isSelected: _selectedUrgencyFilter == UrgencyStatus.critical,
                onTap: () => _onFilterChanged(UrgencyStatus.critical),
              ),
              const SizedBox(width: 8),
              _buildCustomChip(
                label: 'Por vencer ($warnCount)',
                isSelected: _selectedUrgencyFilter == UrgencyStatus.warning,
                onTap: () => _onFilterChanged(UrgencyStatus.warning),
              ),
              const SizedBox(width: 8),
              _buildCustomChip(
                label: 'Seguros ($safeCount)',
                isSelected: _selectedUrgencyFilter == UrgencyStatus.safe,
                onTap: () => _onFilterChanged(UrgencyStatus.safe),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String description}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppTheme.surfaceVariant),
              ),
              child: const Icon(
                Icons.kitchen_outlined,
                size: 40,
                color: AppTheme.secondaryAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.urgencyCriticalAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.urgencyCriticalAccent),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                context.read<InventoryBloc>().add(const LoadInventoryEvent());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
