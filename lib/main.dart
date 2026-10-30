import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/ads/ad_service.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';
import 'features/inventory/presentation/screens/home_inventory_screen.dart';
import 'features/monetization/data/datasources/in_app_purchase_datasource.dart';
import 'features/monetization/domain/repositories/monetization_repository.dart';
import 'features/monetization/presentation/bloc/monetization_bloc.dart';
import 'features/monetization/presentation/bloc/monetization_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Contenedor de Inversión de Dependencias
  await setupServiceLocator();

  // Los servicios de fondo se inicializan sin bloquear el arranque: ninguna
  // dependencia externa puede impedir que la app muestre su UI.
  await _initServicesSafely();

  // Liberar los anuncios y controladores cuando la app se desvincula del sistema (P1-4, P3-3).
  AppLifecycleListener(
    onDetach: () {
      unawaited(sl<IAdService>().dispose());
      if (sl.isRegistered<IMonetizationRepository>()) {
        sl<IMonetizationRepository>().dispose();
      }
      if (sl.isRegistered<IInAppPurchaseDataSource>()) {
        sl<IInAppPurchaseDataSource>().dispose();
      }
    },
  );

  runApp(const SubZeroApp());
}

/// Inicializa notificaciones y anuncios sin que un fallo pueda bloquear la app.
///
/// Las notificaciones son locales y rápidas, por lo que se esperan. La
/// mediación de anuncios depende de la red: se lanza en segundo plano con un
/// timeout, porque un SDK colgado dejaría la app en pantalla infinita.
Future<void> _initServicesSafely() async {
  try {
    await sl<INotificationService>().initialize();
  } catch (e, stack) {
    AppLogger.error(
      'Error al inicializar notificaciones en el arranque',
      error: e,
      stackTrace: stack,
    );
  }

  unawaited(_initAdsSafely());
}

/// Inicializa la mediación de anuncios en segundo plano.
Future<void> _initAdsSafely() async {
  try {
    await sl<IAdService>().initialize().timeout(const Duration(seconds: 10));
  } catch (e, stack) {
    AppLogger.warning(
      'No se pudo inicializar AdMob en el arranque: $e',
      error: e,
      stackTrace: stack,
    );
  }
}

/// Widget raíz de la aplicación SubZero.
class SubZeroApp extends StatelessWidget {
  const SubZeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InventoryBloc>(
          create: (_) => sl<InventoryBloc>(),
        ),
        BlocProvider<MonetizationBloc>(
          create: (_) => sl<MonetizationBloc>()
            ..add(const CheckProStatusEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'SubZero',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeInventoryScreen(),
      ),
    );
  }
}
