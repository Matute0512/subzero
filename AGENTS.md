# AGENTS.md - Directrices de Arquitectura y Desarrollo para SubZero

## 1. Visión General del Proyecto

- **Nombre:** SubZero
- **Package Name:** `dev.matute.subzero`
- **Plataforma objetivo:** Android (Google Play Store) y iOS
- **Propósito:** Gestión visual e inteligente de inventario para congelador y despensa (100% offline-first).
- **Monetización:** Google AdMob + In-App Purchases (Google Play Billing).

---

## 2. Principios de Arquitectura y Estilo de Código

1. **Clean Architecture + Feature-First:**
   - La aplicación se estructura por features dentro de `lib/features/<feature_name>/`.
   - Cada feature debe contener sus tres capas estrictas:
     - `domain/`: Entidades puras, Value Objects y contratos de repositorios abstractos (sin dependencias de Flutter ni SDKs externos).
     - `data/`: Modelos DTO, fuentes de datos (DataSources locales) y la implementación de los repositorios.
     - `presentation/`: BLoCs/Cubits (o Notifiers de Riverpod), pantallas (`screens/`), y widgets atómicos (`widgets/`).
   - El código compartido o de infraestructura vive en `lib/core/` (red, anuncios, servicios de notificaciones, temas, extensiones).

2. **SOLID & Inversión de Dependencias:**
   - Ninguna clase de la capa `presentation` puede instanciar directamente un DataSource o Servicio. Toda dependencia debe resolverse a través de abstracciones inyectadas (mediante `get_it` o `Riverpod`).
   - Principio de Responsabilidad Única: separa la lógica de UI de la lógica de negocio y de los efectos colaterales (I/O, llamadas a plugins de plataforma).

3. **Inmutabilidad y Manejo de Errores:**
   - Modelos y estados deben ser estrictamente inmutables (usa `freezed` o extensiones tipadas con constructores `const`).
   - No propagar excepciones crudas a la UI. Mapear todas las excepciones en la capa `data` hacia subclases de `Failure` en `domain`, utilizando tipos Result o `fpdart` (`Either<Failure, T>`).

4. **Monetización desacoplada:**
   - Todo llamado a anuncios (Google AdMob) debe encapsularse detrás de una interfaz `IAdService` en `lib/core/ads/`. Ninguna pantalla debe invocar métodos estáticos ni SDKs de publicidad directamente.

5. **Reglas de Calidad y Git:**
   - Tipado estricto en Dart (`strict-casts`, `strict-inference`, `strict-raw-types`).
   - Ningún `print()` en producción: usar un logger estructurado en `core/utils/logger.dart`.
   - Respetar el ciclo de vida de la aplicación para pausar o liberar recursos de mediación y suscripciones de streams.
