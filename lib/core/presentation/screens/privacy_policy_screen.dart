import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Pantalla informativa de la Política de Privacidad de SubZero.
/// Cumple con las directrices de Google Play Store y el programa de desarrolladores.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: const Text(
          'Política de Privacidad',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildSection(
                icon: Icons.offline_bolt_rounded,
                title: '1. Arquitectura 100% Offline-First',
                content:
                    'SubZero está diseñada bajo un principio estricto de privacidad local. Todos los datos que ingresas (nombres de alimentos, cantidades, fechas de congelación, fechas de caducidad y notas de ubicación) se almacenan única y exclusivamente de forma local en la memoria de tu dispositivo mediante bases de datos NoSQL cifradas.\n\nSubZero NO cuenta con servidores propios ni bases de datos en la nube: ningún alimento ni nota sale jamás de tu teléfono móvil.',
              ),
              _buildSection(
                icon: Icons.ads_click_rounded,
                title: '2. Publicidad con Google AdMob',
                content:
                    'La versión gratuita de SubZero muestra anuncios patrocinados a través del SDK oficial de Google AdMob para financiar el mantenimiento de la aplicación.\n\nGoogle AdMob puede recopilar y procesar identificadores del dispositivo (como el ID de publicidad de Android / AAID), dirección IP aproximada y métricas de interacción con los anuncios para ofrecer anuncios relevantes y prevenir el fraude.\n\nPuedes consultar la política de privacidad de Google en:\nhttps://policies.google.com/privacy\n\nAl adquirir SubZero Pro, el SDK de anuncios se desactiva permanentemente.',
              ),
              _buildSection(
                icon: Icons.shopping_bag_outlined,
                title: '3. Facturación y Compras Integradas',
                content:
                    'La compra de la versión "SubZero Pro" se procesa de forma directa y segura mediante la pasarela oficial de Google Play Billing.\n\nSubZero no tiene acceso, no procesa ni almacena tus datos de tarjetas de crédito o información financiera; toda la transacción es administrada exclusivamente por Google LLC.',
              ),
              _buildSection(
                icon: Icons.notifications_active_outlined,
                title: '4. Notificaciones y Alarmas Locales',
                content:
                    'Las alertas de caducidad temprana (7 días y 1 día antes del vencimiento) son programadas de manera autónoma en el sistema operativo de tu teléfono usando el reloj del dispositivo. No utilizamos servidores externos de notificaciones push ni servicios de mensajería remota.',
              ),
              _buildSection(
                icon: Icons.delete_outline_rounded,
                title: '5. Retención y Eliminación de Datos',
                content:
                    'Tienes el control absoluto sobre tus datos en todo momento. Puedes modificar o eliminar cualquier registro individual desde el menú del alimento. Si deseas borrar todos los datos por completo, puedes hacerlo borrando los datos de la app desde la configuración de Android o desinstalando la aplicación.',
              ),
              _buildSection(
                icon: Icons.child_care_rounded,
                title: '6. Privacidad de Menores',
                content:
                    'SubZero está destinada al público general para la gestión del hogar y no recopila deliberadamente información de niños menores de 13 años.',
              ),
              _buildSection(
                icon: Icons.mail_outline_rounded,
                title: '7. Contacto del Desarrollador',
                content:
                    'Si tienes dudas, consultas o sugerencias sobre esta Política de Privacidad, puedes ponerte en contacto con el desarrollador a través de:\n\nEmail de soporte: matias.subzero.dev@gmail.com\nPaquete de la app: dev.matute.subzero\nBuenos Aires, Argentina.',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Última actualización: 23 de Octubre de 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.secondaryAccent, size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu privacidad es lo primero',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tus alimentos se quedan en tu teléfono. Sin cuentas, sin rastreo oculto, sin venta de datos.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.secondaryAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppTheme.surfaceVariant, height: 1),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

