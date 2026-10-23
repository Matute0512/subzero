import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/inventory/data/datasources/inventory_local_datasource.dart';
import '../../features/inventory/data/models/food_category_adapter.dart';
import '../../features/inventory/data/models/frozen_item_model.dart';
import '../../features/inventory/data/repositories/inventory_quota_policy_impl.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_quota_policy.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/domain/usecases/usecases.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../../features/monetization/data/datasources/in_app_purchase_datasource.dart';
import '../../features/monetization/data/repositories/monetization_repository_impl.dart';
import '../../features/monetization/domain/repositories/monetization_repository.dart';
import '../../features/monetization/presentation/bloc/monetization_bloc.dart';
import '../ads/ad_service.dart';
import '../ads/admob_ad_service.dart';
import '../notifications/notification_service.dart';
import '../utils/logger.dart';

/// Instancia global de Service Locator (GetIt).
final GetIt sl = GetIt.instance;

/// Configura e inicializa todas las dependencias del proyecto SubZero.
Future<void> setupServiceLocator() async {
  AppLogger.info('Inicializando Inyección de Dependencias (Service Locator)...', tag: 'DI');

  // ==========================================
  // CORE & PLATAFORMA
  // ==========================================
  await Hive.initFlutter();

  // Registrar TypeAdapters de Hive
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(FoodCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FrozenItemModelAdapter());
  }

  // Abrir cajas locales de Hive
  final Box<FrozenItemModel> inventoryBox = await Hive.openBox<FrozenItemModel>(
    InventoryLocalDataSourceImpl.boxName,
  );
  sl.registerLazySingleton<Box<FrozenItemModel>>(() => inventoryBox);

  final Box<dynamic> monetizationBox = await Hive.openBox<dynamic>(
    IInAppPurchaseDataSource.boxName,
  );
  sl.registerLazySingleton<Box<dynamic>>(
    () => monetizationBox,
    instanceName: 'monetization_box',
  );

  // Servicio de Anuncios (IAdService)
  final adService = AdMobAdService();
  sl.registerLazySingleton<IAdService>(() => adService);

  // Servicio de Notificaciones Locales (INotificationService)
  final notificationService = LocalNotificationService();
  sl.registerLazySingleton<INotificationService>(() => notificationService);

  // ==========================================
  // FEATURE: MONETIZACIÓN
  // ==========================================
  // DataSources
  sl.registerLazySingleton<IInAppPurchaseDataSource>(
    () => InAppPurchaseDataSourceImpl(
      box: sl<Box<dynamic>>(instanceName: 'monetization_box'),
    ),
  );

  // Repositorios
  sl.registerLazySingleton<IMonetizationRepository>(
    () => MonetizationRepositoryImpl(dataSource: sl<IInAppPurchaseDataSource>()),
  );

  // BLoCs
  sl.registerFactory<MonetizationBloc>(
    () => MonetizationBloc(repository: sl<IMonetizationRepository>()),
  );

  // ==========================================
  // FEATURE: INVENTARIO
  // ==========================================
  // DataSources
  sl.registerLazySingleton<IInventoryLocalDataSource>(
    () => InventoryLocalDataSourceImpl(sl<Box<FrozenItemModel>>()),
  );

  // Repositorios
  sl.registerLazySingleton<IInventoryRepository>(
    () => InventoryRepositoryImpl(localDataSource: sl<IInventoryLocalDataSource>()),
  );

  // Política de cuota: adapta el estado de suscripción (monetización) a la
  // decisión de dominio del inventario. Es el único punto del código de
  // inventario que conoce la feature de monetización.
  sl.registerLazySingleton<IInventoryQuotaPolicy>(
    () => InventoryQuotaPolicyImpl(
      monetizationRepository: sl<IMonetizationRepository>(),
    ),
  );

  // Casos de Uso (UseCases)
  sl.registerLazySingleton(() => GetInventoryItemsUseCase(sl<IInventoryRepository>()));
  sl.registerLazySingleton(() => AddFrozenItemUseCase(sl<IInventoryRepository>()));
  sl.registerLazySingleton(() => DeleteFrozenItemUseCase(sl<IInventoryRepository>()));
  sl.registerLazySingleton(() => ToggleConsumedUseCase(sl<IInventoryRepository>()));
  sl.registerLazySingleton(() => UpdateFrozenItemUseCase(sl<IInventoryRepository>()));

  // Resincronización de alertas de vencimiento (P1-9).
  sl.registerLazySingleton(
    () => SyncInventoryAlertsUseCase(
      getInventoryItemsUseCase: sl<GetInventoryItemsUseCase>(),
      notificationService: sl<INotificationService>(),
    ),
  );

  // BLoCs
  sl.registerFactory<InventoryBloc>(
    () => InventoryBloc(
      getInventoryItemsUseCase: sl<GetInventoryItemsUseCase>(),
      addFrozenItemUseCase: sl<AddFrozenItemUseCase>(),
      deleteFrozenItemUseCase: sl<DeleteFrozenItemUseCase>(),
      toggleConsumedUseCase: sl<ToggleConsumedUseCase>(),
      updateFrozenItemUseCase: sl<UpdateFrozenItemUseCase>(),
      notificationService: sl<INotificationService>(),
      quotaPolicy: sl<IInventoryQuotaPolicy>(),
      syncInventoryAlertsUseCase: sl<SyncInventoryAlertsUseCase>(),
    ),
  );

  AppLogger.info('Dependencias configuradas correctamente en GetIt.', tag: 'DI');
}
