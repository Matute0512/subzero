# ADR-002: Clean Architecture + Feature-First con Puertos de Desacoplamiento

## Estado
Aceptado

## Fecha
2026-10-21

## Contexto
A medida que la aplicación añade compras dentro de la app (IAP), publicidad AdMob, políticas de cuotas y notificaciones nativas, existe el riesgo de acoplar la interfaz gráfica a detalles de bajo nivel o que las distintas features dependan circularmente entre sí.
Se requiere una arquitectura escalable, testeable y mantenible por desarrolladores y agentes de IA, con límites modulares claros y reglas estrictas de inversión de dependencias.

## Decisión
Adoptar **Clean Architecture con organización Feature-First**:
1. El código se divide por features dentro de `lib/features/<feature>/`:
   - `domain/`: Entidades puras Dart, objetos de valor y contratos abstractos de repositorios o políticas. Libre de dependencias externas (sin Flutter, sin Hive, sin IAP).
   - `data/`: Modelos DTO con serialización, DataSources locales/remotos e implementaciones concretas de los repositorios.
   - `presentation/`: BLoCs/Cubits de gestión de estado, pantallas (`screens/`) y componentes visuales (`widgets/`).
2. Módulos compartidos y transversales residen en `lib/core/` (`ads/`, `notifications/`, `theme/`, `errors/`, `utils/`, `di/`).
3. **Inversión de dependencias:** La inyección se resuelve mediante `get_it`. Ningún widget o pantalla interactúa con DataSources o SDKs de plataforma.
4. **Desacoplamiento entre features (Ports & Adapters):**
   - Para evaluar el límite de alimentos (25 en versión gratuita vs ilimitado en Pro), `inventory/domain` no importa `monetization`. En su lugar, define el puerto `IInventoryQuotaPolicy`. La implementación concreta `InventoryQuotaPolicyImpl` reside en `inventory/data` y se inyecta en tiempo de arranque.
   - Para las notificaciones, `core/notifications` no importa la entidad `FrozenItem`. Interactúa únicamente con el contrato polimórfico `NotifiableItem`.

## Alternativas Consideradas

### Arquitectura en Capas Tradicional (Layer-First: /models, /views, /controllers)
- **Pros:** Estructura habitual en proyectos pequeños o tutoriales rápidos.
- **Contras:** A medida que crecen las features (inventario, monetización, ajustes), los archivos relacionados con una misma funcionalidad quedan dispersos en carpetas lejanas, dificultando la navegación, los tests y el mantenimiento incremental.
- **Rechazado:** Menor cohesión y mayor acoplamiento estructural.

### State Management Acoplado Directamente a DataSources (ChangeNotifier / StateProvider simple)
- **Pros:** Menos clases y menos boilerplate inicial.
- **Contras:** La lógica de negocio y las llamadas a Hive o Google Play quedan mezcladas con la UI, impidiendo hacer pruebas unitarias rápidas con dobles de prueba (`mocktail`).
- **Rechazado:** Viola los principios SOLID y la regla de no propagar errores no tipados a la UI.

## Consecuencias
- 100% de la lógica de negocio y casos de uso es testeable sin instanciar widgets ni emuladores.
- `Either<Failure, T>` de `fpdart` garantiza un manejo funcional y explícito de fallos sin excepciones crudas en capas superiores.
- Añadir nuevas reglas de negocio o cambiar la librería de persistencia en el futuro sólo requerirá implementar un nuevo DataSource sin modificar la UI ni el dominio.

