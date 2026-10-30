# Registro de Decisiones de Arquitectura (ADRs) - SubZero

Este directorio documenta las decisiones técnicas y arquitectónicas más significativas adoptadas en el desarrollo de SubZero, siguiendo las directrices de [`.agents/skills/documentation-and-adrs`](../../.agents/skills/documentation-and-adrs/SKILL.md).

Cada ADR captura el **porqué** (contexto, restricciones del sistema, alternativas evaluadas y consecuencias) para preservar la integridad del diseño frente a futuras iteraciones por humanos o agentes de IA.

---

## Índice de Decisiones

| Identificador | Título | Estado | Fecha | Área Principal |
|---|---|---|---|---|
| [**ADR-001**](0001-offline-first-hive-persistence.md) | Persistencia Local 100% Offline-First con Hive NoSQL | Aceptado | 2026-10-20 | Persistencia / Datos |
| [**ADR-002**](0002-clean-architecture-feature-first.md) | Clean Architecture + Feature-First con Puertos de Desacoplamiento | Aceptado | 2026-10-21 | Arquitectura / Dominio |
| [**ADR-003**](0003-notification-scheduling-and-fnv1a-ids.md) | Notificaciones Locales Deterministas con Hash FNV-1a y Modo de Alarma Adaptativo | Aceptado | 2026-10-22 | Notificaciones / Android |
| [**ADR-004**](0004-lazy-monetization-and-iap-verification.md) | Inicialización Asíncrona de Publicidad y Validación Criptográfica de Compras In-App | Aceptado | 2026-10-29 | Monetización / Rendimiento |
| [**ADR-005**](0005-security-hardening-and-binary-obfuscation.md) | Blindaje de Seguridad, Mitigación de Superficie de Ataque y Ofuscación de Release | Aceptado | 2026-10-29 | Seguridad / Producción |

