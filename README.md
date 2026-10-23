# SubZero

> **Gestor visual e inteligente de alimentos congelados y despensa.**

SubZero es una app Flutter para **Android (Google Play Store) e iOS** que te permite gestionar el inventario de tu congelador y despensa, monitorear la vida útil de cada alimento y planificar su consumo. Funciona bajo un paradigma **100% offline-first**: todos los datos residen localmente en el dispositivo mediante Hive, sin registro de cuentas, sin servidor obligatorio y con arranque instantáneo sin red.

---

## Índice

- [Qué hace SubZero](#qué-hace-subzero)
- [Funcionalidades](#funcionalidades)
- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Persistencia de datos](#persistencia-de-datos)
- [Monetización y Anuncios](#monetización-y-anuncios)
- [Sistema de diseño](#sistema-de-diseño)
- [Puesta en marcha](#puesta-en-marcha)
- [Firma de release (Android)](#firma-de-release-android)
- [Generación de íconos y splash](#generación-de-íconos-y-splash)
- [Testing](#testing)
- [Análisis del proyecto (Graphify)](#análisis-del-proyecto-graphify)
- [Estado actual del proyecto](#estado-actual-del-proyecto)

---

## Qué hace SubZero

SubZero elimina el "inventario mental" del congelador, reemplazándolo por un panel **visual, clasificado por urgencia y con recordatorios automatizados**.

- **Registra alimentos** con nombre, cantidad, unidad, categoría, fecha de congelación, fecha de vencimiento calculada o personalizada y ubicación en el congelador (ej. "Cajón 2", "Tupper azul").
- **Clasifica por urgencia** en tres niveles automáticos:
  - 🔴 **Crítico** (≤ 7 días o ya caducado).
  - 🟠 **Por vencer** (entre 8 y 30 días restantes).
  - 🔵 **Seguro** (> 30 días restantes).
- **Alertas automáticas de caducidad**: programa dos notificaciones locales por alimento: a **7 días** y a **1 día** antes de su vencimiento (a las 09:00 AM hora local).
- **Protección contra toques accidentales**: tocar una tarjeta despliega un menú inferior de opciones rápidas (Modificar / Marcar consumido / Eliminar con confirmación destructiva).
- **Sin cuentas ni internet**: Hive almacena todo en el almacenamiento interno de forma ultraligera; la app arranca y funciona completa sin conexión.
- **SubZero Pro**: compra integrada de pago único que desbloquea almacenamiento ilimitado (eliminando el tope gratuito de 25 alimentos) y navegación 100% libre de publicidad.

---

## Funcionalidades

### Gestión de inventario

| Capacidad | Detalle |
|---|---|
| Alta / Edición | Modal inferior (`AddItemBottomSheet`) con validación de formulario, botón sticky sobre teclado virtual y sugerencia inteligente de fecha según categoría |
| Opciones Rápidas | `ItemOptionsBottomSheet` para editar detalles, alternar estado activo/consumido o eliminar con confirmación |
| Baja destructiva | Confirmación explícita mediante diálogo modal y soporte para swipe con acción "DESHACER" |
| Filtros dinámicos | Chips horizontales por urgencia (*Todos*, *Críticos*, *Por vencer*, *Seguros*) y selector de categorías |
| Tarjeta visual | `InventoryItemCard` con iconografía temática, badges de urgencia, notas de ubicación y atenuación al ser consumido |

### Alertas de caducidad y Notificaciones

`LocalNotificationService` programa dos avisos por alimento utilizando `flutter_local_notifications`:

- **Aviso preventivo** → 7 días antes del vencimiento a las 09:00 AM.
- **Alerta urgente** → 1 día antes del vencimiento a las 09:00 AM.

**Puntos clave del subsistema de notificaciones:**
1. **Desacoplamiento total (`NotifiableItem`):** La capa `core/notifications` no depende de la entidad `FrozenItem`. Solo interactúa con el contrato abstracto `NotifiableItem`.
2. **Cálculo con zona horaria real:** Se utiliza `flutter_timezone` junto con el offset de tiempo del dispositivo (`_toScheduledInstant`), asegurando que las 09:00 AM correspondan a la hora local del usuario (sin desfases por UTC).
3. **Resincronización automática (`SyncInventoryAlertsUseCase`):** Al cargar el inventario, la app cancela alarmas obsoletas y reprograma los alimentos activos, evitando alertas huérfanas tras reinicios del teléfono o cambios de hora.
4. **Permiso de alarma exacta adaptativo:** Soporta `USE_EXACT_ALARM` y `SCHEDULE_EXACT_ALARM`. Si el usuario deniega las alarmas exactas en los ajustes del sistema, la app degrada limpiamente a `AndroidScheduleMode.inexactAllowWhileIdle`.
5. **Notificaciones interactivas:** Tocar una notificación abre directamente el modal de opciones del alimento correspondiente mediante el payload `itemId`.
6. **IDs deterministas:** IDs de notificación generados mediante hash de 32-bit **FNV-1a** (pares para advertencia, impares para urgentes), garantizando estabilidad sin colisiones.

### Plan Pro y Facturación In-App

- **Versión gratuita**: hasta **25 alimentos activos**.
- **SubZero Pro**: desbloqueo vitalicio de pago único de **$3.99 USD** (`subzero_pro_lifetime`) con Google Play Billing.
- **Sin parpadeo publicitario (`isProResolved`):** `MonetizationState` distingue entre *"usuario gratuito confirmado"* y *"estado Pro cargando"*, ocultando los banners en frío hasta confirmar el estado del usuario.
- **Restauración confiable:** `restorePurchasesAndWait()` espera la confirmación real de Google Play antes de resolver el estado, permitiendo recuperar compras tras reinstalar la app o cambiar de teléfono.
- **Gestión de incidencias en línea:** Errores de tienda, pagos pendientes y cancelaciones se exponen en línea en [`PaywallScreen`](lib/features/monetization/presentation/screens/paywall_screen.dart) con mensajes amigables y reintentos automáticos (backoff de 3 intentos en `completePurchase`).

---

## Arquitectura

El proyecto implementa estrictamente **Clean Architecture + Feature-First**, cumpliendo las directrices normativas de [`AGENTS.md`](AGENTS.md):

```
lib/
├── main.dart                          # Punto de entrada, providers globales y ciclo de vida
├── core/                              # Infraestructura y módulos compartidos (sin dependencia de features)
│   ├── ads/                           # IAdService (contrato) + AdMobAdService (impl Google AdMob)
│   ├── di/                            # Service Locator (GetIt) e inyección de dependencias
│   ├── errors/                        # Exception (capa data) y Failure (capa domain)
│   ├── notifications/                 # INotificationService, LocalNotificationService y NotifiableItem
│   ├── theme/                         # AppTheme, tokens cromáticos y elevaciones
│   └── utils/                         # AppLogger estructurado para producción
└── features/
    ├── inventory/
    │   ├── domain/                    # Entidades (FrozenItem), usecases e IInventoryQuotaPolicy
    │   ├── data/                      # Modelos DTO (Hive), datasources e InventoryQuotaPolicyImpl
    │   └── presentation/              # InventoryBloc, HomeInventoryScreen y widgets atómicos
    └── monetization/
        ├── domain/                    # SubscriptionStatus, PurchaseIssue e IMonetizationRepository
        ├── data/                      # InAppPurchaseDataSourceImpl y MonetizationRepositoryImpl
        └── presentation/              # MonetizationBloc, PaywallScreen y ProBadgeWidget
```

### Reglas de Dependencia y Desacoplamiento

1. **Flujo unidireccional hacia adentro:**
   ```
   presentation  ──▶  domain  ◀──  data
   ```
   * `domain/` es completamente puro (Dart puro sin dependencias de Flutter, Hive ni SDKs externos).
   * `presentation/` consume únicamente UseCases y BLoCs; nunca instancia un DataSource directamente.
2. **Costura de Cuota (`IInventoryQuotaPolicy`):**
   * El inventario no importa la feature de monetización.
   * `features/inventory/domain` define el puerto `IInventoryQuotaPolicy`, implementado por `InventoryQuotaPolicyImpl` en `features/inventory/data`.
   * La UI consulta una única fuente de verdad: `InventoryState.canAddItem`.
3. **Core Puro:**
   * `core/notifications` no conoce entidades de inventario; solo el contrato `NotifiableItem`.
   * `core/ads` no conoce pantallas; encapsula la publicidad detrás de `IAdService`.

---

## Stack Tecnológico

| Capa | Paquete | Versión | Uso |
|---|---|---|---|
| **Gestión de Estado** | `flutter_bloc` | ^8.1.6 | BLoCs de inventario y monetización |
| **Inyección de Dependencias** | `get_it` | ^7.7.0 | Service Locator desacoplado |
| **Programación Funcional** | `fpdart` | ^1.1.0 | Manejo de resultados `Either<Failure, T>` |
| **Inmutabilidad** | `equatable` | ^2.0.5 | Comparación por valor en entidades y estados |
| **Persistencia Local** | `hive` · `hive_flutter` | ^2.2.3 / ^1.1.0 | Motor NoSQL ultraligero y offline-first |
| **Alertas Programadas** | `flutter_local_notifications` | ^17.2.1 | Notificaciones locales nativas |
| **Zonas Horarias** | `timezone` · `flutter_timezone` | ^0.9.4 / ^5.1.1 | Detección de zona real del dispositivo y cálculo de alarmas |
| **Publicidad y Banners** | `google_mobile_ads` | ^9.2.0 | SDK oficial de Google AdMob |
| **Compras In-App** | `in_app_purchase` | ^3.2.0 | Google Play Billing oficial |
| **Internacionalización** | `intl` | ^0.19.0 | Formato de fechas y moneda |
| **Generación de IDs** | `uuid` | ^4.4.2 | IDs únicos deterministas para ítems |

---

## Persistencia de Datos

La persistencia se realiza mediante dos cajas de **Hive** con `TypeAdapter` binarios:

| Caja | Contenido | Tipo |
|---|---|---|
| `frozen_items_box` | Alimentos registrados | `FrozenItemModel` (`typeId: 0`) |
| `monetization_box` | Estado de suscripción Pro | `bool` (`is_pro_user`) |

Para regenerar los adaptadores tras modificar un modelo DTO:
```powershell
dart run build_runner build --delete-conflicting-outputs
```

---

## Monetización y Anuncios

Todo el acceso a publicidad se encapsula detrás de la interfaz [`IAdService`](lib/core/ads/ad_service.dart), implementada por [`AdMobAdService`](lib/core/ads/admob_ad_service.dart).

```dart
abstract class IAdService {
  Future<void> initialize();
  Future<void> showInterstitial({required String placementName});
  Future<void> showRewardedVideo({required String placementName, required Function onRewarded});
  Widget getBannerWidget({required String placementName});
  Future<void> dispose();
}
```

### Comportamiento Híbrido Automático (Desarrollo vs Producción)

* **En modo Debug (`flutter run`):** `AdMobAdService` utiliza automáticamente los Ad Unit IDs de prueba oficiales de Google. Permite realizar pruebas sin riesgo de penalizaciones por clics propios.
* **En modo Release (`flutter build appbundle --release --dart-define-from-file=secrets.json`):** Inyecta de forma segura los bloques comerciales privados desde el archivo local `secrets.json` (ignorado por Git):
  * **Banner:** `ADMOB_BANNER_ID` (anuncio inferior colapsable en pantalla principal).
  * **Intersticial:** `ADMOB_INTERSTITIAL_ID` (al registrar alimentos para usuarios gratuitos).
  * **Bonificado:** `ADMOB_REWARDED_ID` (disponible para recompensas).

---

## Sistema de Diseño

El diseño de SubZero se encuentra alineado con **Material 3** e **iOS Human Interface Guidelines**, con tokens visuales centralizados en [`AppTheme`](lib/core/theme/app_theme.dart):

| Token | Hex | Aplicación |
|---|---|---|
| **Background Dark** | `#0A192F` | Fondo nórdico profundo |
| **Surface** | `#112240` | Tarjetas contenedoras y diálogos |
| **Surface Variant** | `#233554` | Bordes y separadores sutiles |
| **Primary Accent** | `#0077B6` | Azul glacial (acciones primarias) |
| **Secondary Accent** | `#48CAE4` | Cian hielo brillante (FAB y contrastes) |
| **Text Primary** | `#F8F9FA` | Tipografía principal de alta legibilidad |
| **Text Secondary** | `#8892B0` | Notas secundarias y etiquetas auxiliares |
| **Urgency Critical** | `#FF5252` | Vencimiento ≤ 7 días o caducado |
| **Urgency Warning** | `#FFA726` | Vencimiento entre 8 y 30 días |
| **Urgency Safe** | `#00B4D8` | Alimentos seguros con más de 30 días |
| **Gold Accent** | `#FFD166` | Insignia y acentos SubZero Pro |

---

## Puesta en Marcha

### Requisitos previos
* Flutter SDK (3.44.2 o superior)
* Java JDK 17
* Android Studio con Android SDK API 34+
* Dispositivo físico o emulador con Google Play Services

### Comandos de ejecución

```powershell
# 1. Obtener dependencias
flutter pub get

# 2. Análisis estático de código
flutter analyze

# 3. Ejecutar suite de pruebas
flutter test

# 4. Iniciar en dispositivo de desarrollo
flutter run
```

---

## Firma de Release (Android)

La configuración de firma se gestiona mediante `android/key.properties` (excluido de git).
Para compilar el Android App Bundle de producción firmado:

```powershell
flutter build appbundle --release
```

Salida generada:
📁 `build/app/outputs/bundle/release/app-release.aab` (**~55.4 MB**)

El archivo `android/app/proguard-rules.pro` protege de ofuscación los modelos DTO de Hive, clases de facturación y del SDK de Google Mobile Ads.

---

## Generación de Íconos y Splash

Los íconos y pantallas de bienvenida se configuran mediante `flutter_launcher_icons` y `flutter_native_splash` para **Android** e **iOS**:

```powershell
# 1. Generar iconos de lanzador (Android e iOS)
dart run flutter_launcher_icons

# 2. Generar pantallas de splash nativas
dart run flutter_native_splash:create
```

* Los iconos para iOS tienen configurado `remove_alpha_ios: true` cumpliendo con los estándares de Apple App Store.

---

## Testing

La aplicación cuenta con una suite integral de **84 pruebas automatizadas** que cubren dominio, datos, BLoCs y widgets:

```powershell
flutter test
```

### Estructura de pruebas
* `test/core/notifications/`: Pruebas de IDs deterministas FNV-1a, modos de alarma y cálculo de fechas.
* `test/features/inventory/domain/`: Validación de entidades `FrozenItem` y categorías `FoodCategory`.
* `test/features/inventory/data/`: Pruebas de la política de cuotas `InventoryQuotaPolicyImpl`.
* `test/features/inventory/presentation/bloc/`: Pruebas de eventos y estados de `InventoryBloc`.
* `test/features/inventory/presentation/widgets/`: Widget tests de renderizado, interacción y badges en `InventoryItemCard`.
* `test/features/monetization/data/`: Pruebas del datasource y repositorio de compras con mocktail.
* `test/features/monetization/presentation/bloc/`: Pruebas de estados, errores y flujos reactivos de `MonetizationBloc`.
* `test/features/monetization/presentation/widgets/`: Widget tests para `ProBadgeWidget`.

---

## Análisis del Proyecto (Graphify)

El repositorio mantiene indexado su grafo de arquitectura y conocimiento en `graphify-out/`:

```powershell
graphify query "Como funciona el flujo de compras e in-app purchases"
graphify explain "InventoryBloc"
graphify path "InventoryBloc" "MonetizationBloc"
```

* `graph.html`: Visualizador interactivo de dependencias y comunidades.
* `GRAPH_REPORT.md`: Informe estructural de nodos centrales y desacoplamiento.
* `graphify-out/memory/`: Registro histórico de sesiones de endurecimiento y auditorías técnicas.

---

## Estado Actual del Proyecto

- [x] Arquitectura Clean Architecture + Feature-First 100% desacoplada.
- [x] Inventario CRUD offline-first con Hive y categorías completas.
- [x] Sistema de caducidad y semáforo visual de urgencias.
- [x] Notificaciones locales programadas a las 09:00 AM con zona horaria real y resincronización.
- [x] Desacoplamiento de `core/notifications` mediante contrato `NotifiableItem`.
- [x] Monetización Google AdMob (`google_mobile_ads: ^9.2.0`) con modo híbrido test/producción.
- [x] Google Play Billing para desbloqueo vitalicio de SubZero Pro ($3.99 USD).
- [x] Eliminación de parpadeo publicitario mediante `isProResolved`.
- [x] Manifiesto de privacidad de Apple [`PrivacyInfo.xcprivacy`](ios/Runner/PrivacyInfo.xcprivacy) configurado para iOS y macOS.
- [x] Íconos de aplicación generados para Android e iOS (`remove_alpha_ios: true`).
- [x] Limpieza completa de shims y código obsoleto.
- [x] 84 tests automáticos en verde (0 fallos).
- [x] Compilación final verificada: Android App Bundle (`app-release.aab`) firmado y listo para Google Play Console.
