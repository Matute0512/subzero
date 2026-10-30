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


---

## 3. Catálogo y Uso de Skills (.agents/skills)

Antigravity y los agentes de desarrollo reconocen e integran las habilidades ubicadas en `.agents/skills/`. Antes de ejecutar tareas complejas, se debe invocar o consultar la skill correspondiente según la fase de desarrollo:

### 3.1. Flujo del Ciclo de Vida (Lifecycle Sequence)
1. **Definición & Requisitos:** `interview-me` → `idea-refine` → `spec-driven-development`
2. **Planificación:** `constraint-driven-development` → `planning-and-task-breakdown`
3. **Construcción & Contexto:** `context-engineering` → `source-driven-development` → `incremental-implementation`
   - *UI:* `frontend-ui-engineering`
   - *APIs & Interfaces:* `api-and-interface-design`
   - *Decisiones críticas / alto riesgo:* `doubt-driven-development`
4. **Verificación & Calidad:** `test-driven-development` → `browser-testing-with-devtools` → `debugging-and-error-recovery`
5. **Revisión:** `code-review-and-quality` → `code-simplification` → `security-and-hardening` → `performance-optimization`
6. **Despliegue & Mantenimiento:** `git-workflow-and-versioning` → `ci-cd-and-automation` → `observability-and-instrumentation` → `documentation-and-adrs` → `deprecation-and-migration` → `shipping-and-launch`

### 3.2. Tabla de Referencia de Skills Disponibles

| Skill | Directorio | Cuándo invocar / Propósito |
|---|---|---|
| **using-agent-skills** | `.agents/skills/using-agent-skills` | Meta-skill para seleccionar y orquestar qué skill aplicar a la tarea. |
| **interview-me** | `.agents/skills/interview-me` | Extrae y clarifica requerimientos ambiguos pregunta a pregunta. |
| **idea-refine** | `.agents/skills/idea-refine` | Refina ideas iniciales mediante pensamiento divergente y convergente. |
| **spec-driven-development** | `.agents/skills/spec-driven-development` | Redacta especificaciones y criterios de aceptación antes de programar. |
| **constraint-driven-development** | `.agents/skills/constraint-driven-development` | Define y salvaguarda estándares y límites de calidad en `CONSTRAINTS.md`. |
| **planning-and-task-breakdown** | `.agents/skills/planning-and-task-breakdown` | Divide specs en tareas ordenadas, pequeñas e independientemente verificables. |
| **context-engineering** | `.agents/skills/context-engineering` | Configura y optimiza el contexto de trabajo y las reglas del agente. |
| **source-driven-development** | `.agents/skills/source-driven-development` | Valida código y patrones contra documentación oficial antes de implementar. |
| **incremental-implementation** | `.agents/skills/incremental-implementation` | Implementación en rebanadas verticales delgadas y verificables paso a paso. |
| **frontend-ui-engineering** | `.agents/skills/frontend-ui-engineering` | Construcción de interfaces responsivas, accesibles (a11y) y con calidad de producción. |
| **api-and-interface-design** | `.agents/skills/api-and-interface-design` | Diseño de contratos, APIs y límites de módulos limpios y desacoplados. |
| **doubt-driven-development** | `.agents/skills/doubt-driven-development` | Revisión adversarial de decisiones no triviales o de alto impacto. |
| **test-driven-development** | `.agents/skills/test-driven-development` | Desarrollo guiado por pruebas (ciclo red-green-refactor). |
| **browser-testing-with-devtools** | `.agents/skills/browser-testing-with-devtools` | Verificación en navegador y DevTools vía MCP. |
| **debugging-and-error-recovery** | `.agents/skills/debugging-and-error-recovery` | Depuración metódica de causas raíz (reproducir → aislar → corregir → proteger). |
| **code-review-and-quality** | `.agents/skills/code-review-and-quality` | Revisión exhaustiva multidimensional antes de mergear cambios. |
| **code-simplification** | `.agents/skills/code-simplification` | Simplificación y refactorización sin alterar comportamiento. |
| **security-and-hardening** | `.agents/skills/security-and-hardening` | Hardening contra vulnerabilidades (OWASP, validaciones, permisos mínimos). |
| **performance-optimization** | `.agents/skills/performance-optimization` | Medición y optimización de rendimiento, memoria y queries. |
| **observability-and-instrumentation** | `.agents/skills/observability-and-instrumentation` | Instrumentación de logs estructurados, métricas RED y alertas. |
| **git-workflow-and-versioning** | `.agents/skills/git-workflow-and-versioning` | Commits atómicos, manejo de ramas, semver y PRs ordenados. |
| **ci-cd-and-automation** | `.agents/skills/ci-cd-and-automation` | Configuración y mantenimiento de pipelines de integración continua. |
| **documentation-and-adrs** | `.agents/skills/documentation-and-adrs` | Registro de decisiones arquitectónicas (ADRs) y documentación de contexto. |
| **deprecation-and-migration** | `.agents/skills/deprecation-and-migration` | Migraciones controladas de esquemas de BD, sunsetting y reemplazo de APIs. |
| **shipping-and-launch** | `.agents/skills/shipping-and-launch` | Listas de comprobación previas al lanzamiento, rollback y despliegue a producción. |
