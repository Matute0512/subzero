import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/screens/privacy_policy_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/monetization_bloc.dart';
import '../bloc/monetization_event.dart';
import '../bloc/monetization_state.dart';

/// Pantalla de Paywall oficial para SubZero Pro según las especificaciones de Figma (Screen 03).
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PaywallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: BlocConsumer<MonetizationBloc, MonetizationState>(
          listener: (context, state) {
            // Los errores y las incidencias de compra se muestran en linea
            // (bloque _buildStatusMessage): un SnackBar se pierde a los 4
            // segundos y deja al usuario sin saber que fallo.
            if (state.isPurchaseSuccess || state.isPro) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Felicidades! Ahora tienes acceso completo a SubZero Pro.'),
                  backgroundColor: AppTheme.primaryAccent,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final priceFormatted = state.productDetails?.price ?? r'$3.99 USD';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón Cerrar
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hero: Halo Glacial con Icono
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.urgencySafeContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.secondaryAccent, width: 2),
                      boxShadow: AppTheme.cyanGlowShadow,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.ac_unit,
                        size: 48,
                        color: AppTheme.secondaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título y Subtítulo
                  const Text(
                    'Desbloquea SubZero Pro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Espacio ilimitado y tranquilidad total en tu cocina',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Card de Beneficios
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.surfaceVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBenefitRow('Alimentos ilimitados (elimina el tope de 25)'),
                        const SizedBox(height: 16),
                        _buildBenefitRow('100% libre de anuncios para siempre'),
                        const SizedBox(height: 16),
                        _buildBenefitRow('Apoyo directo a un desarrollador independiente'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta de Oferta Destacada
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.secondaryAccent, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.goldContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'UN SOLO PAGO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.goldAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Acceso Vitalicio Único',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          priceFormatted,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mensaje de estado en linea: error de tienda o incidencia
                  // del flujo de compra (cancelacion / pendiente / fallo).
                  _buildStatusMessage(context, state),

                  // Botón Primario con Gradiente
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.primaryGlowShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: state.isLoading
                            ? null
                            : () {
                                context
                                    .read<MonetizationBloc>()
                                    .add(const PurchaseProEvent());
                              },
                        child: Center(
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continuar a SubZero Pro',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Enlace de Restaurar Compras
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            context
                                .read<MonetizationBloc>()
                                .add(const RestorePurchasesEvent());
                          },
                    child: const Text(
                      'Restaurar compras',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Aviso legal y de facturación
                  const Text(
                    'Sin suscripciones recurrentes • Pago seguro con Google Play',
                    style: TextStyle(
                      color: Color(0xFF5A6785),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => PrivacyPolicyScreen.show(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Política de Privacidad',
                      style: TextStyle(
                        color: Color(0xFF5A6785),
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Mensaje de estado en linea (error de tienda o incidencia de compra).
  ///
  /// Se prefiere sobre un SnackBar porque permanece visible mientras el
  /// usuario decide que hacer, y distingue visualmente una cancelacion
  /// (informativa) de un fallo real.
  Widget _buildStatusMessage(BuildContext context, MonetizationState state) {
    final issue = state.purchaseIssue;
    final errorMessage = state.errorMessage;

    final String? message;
    final bool isError;
    if (issue != null) {
      message = issue.message;
      isError = issue.isError;
    } else if (errorMessage != null) {
      message = errorMessage;
      isError = true;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? AppTheme.urgencyCriticalContainer
            : AppTheme.urgencyWarningContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? AppTheme.urgencyCriticalAccent
              : AppTheme.urgencyWarningAccent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError
                ? AppTheme.urgencyCriticalAccent
                : AppTheme.urgencyWarningAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.check, color: AppTheme.secondaryAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
