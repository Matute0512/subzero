# ADR-003: Notificaciones Locales Deterministas con Hash FNV-1a y Modo de Alarma Adaptativo

## Estado
Aceptado

## Fecha
2026-10-22

## Contexto
SubZero debe alertar a los usuarios antes de que sus alimentos congelados caduquen (a los 7 días y a 1 día del vencimiento, a las 09:00 AM hora local).
Requisitos críticos:
1. Las alertas deben sonar a la hora local exacta del usuario, considerando husos horarios y cambios de horario de verano (DST).
2. Los IDs numéricos de notificación en Android son enteros de 32 bits con signo (`int`). Si se generan IDs aleatorios o contadores incrementales, tras reinicios o reinstalaciones se pierde la correspondencia para cancelarlos o actualizarlos.
3. Si dos notificaciones de un mismo alimento (o de diferentes alimentos) colisionan en su ID numérico, una sobrescribirá a la otra en la barra de estado de Android.
4. En Android 13+ (API 33) y 14+ (API 34), el permiso de alarmas exactas (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) puede ser restringido por el sistema operativo o revocado manualmente por el usuario.

## Decisión
1. **Generación determinista de IDs con FNV-1a de 32 bits:**
   - Se implementa el algoritmo de dispersión Fowler-Noll-Vo (FNV-1a 32-bit) sobre el identificador único String (`itemId`).
   - Se divide el espacio numérico mediante aritmética modular:
     - Notificación de advertencia (7 días antes): número par positivo `(hash << 1) & 0x7FFFFFFF`.
     - Notificación urgente (1 día antes): número impar positivo `((hash << 1) | 1) & 0x7FFFFFFF`.
   - Esto garantiza que un alimento siempre tenga los mismos dos identificadores predecibles y matemáticamente disjuntos, permitiendo cancelaciones individuales inmediatas (`cancelItemAlerts`).
2. **Cálculo con Zona Horaria Nativa:**
   - Detección del huso horario real con `flutter_timezone` y conversión mediante `_toScheduledInstant` para programar siempre a las 09:00:00 AM hora local del dispositivo.
3. **Modo de Alarma Adaptativo:**
   - Antes de programar, se consulta `canScheduleExactAlarms()` de `flutter_local_notifications`.
   - Si el permiso está concedido, se utiliza `AndroidScheduleMode.exactAllowWhileIdle`.
   - Si no está disponible o el usuario lo denegó, se degrada a `AndroidScheduleMode.inexactAllowWhileIdle` en lugar de arrojar una excepción no controlada (`SecurityException`).
4. **Resincronización al inicio (`SyncInventoryAlertsUseCase`):**
   - Cada vez que se inicializa o modifica el inventario, la aplicación resincroniza todas las alarmas activas, cancelando recordatorios de ítems consumidos o eliminados.

## Alternativas Consideradas

### Generación de IDs mediante enteros aleatorios (`Random().nextInt()`)
- **Pros:** Implementación trivial.
- **Contras:** Imposible cancelar una notificación programada previa si no se almacena el ID generado en la base de datos de cada ítem; riesgo de colisiones invisibles.
- **Rechazado:** Falta de determinismo e inconsistencia de estado.

### Almacenar los IDs de notificación como campos en la base de datos de Hive
- **Pros:** Persistencia explícita.
- **Contras:** Incrementa la complejidad del modelo `FrozenItemModel` y obliga a migraciones de esquema ante cualquier cambio de estrategia.
- **Rechazado:** La función pura determinista `f(itemId, tipo)` elimina la necesidad de almacenamiento redundante.

## Consecuencias
- Cero colisiones observadas entre avisos de advertencia y urgencia en pruebas automatizadas y en producción.
- Experiencia de usuario ininterrumpida aun si el usuario restringe permisos de alarmas exactas en los ajustes de ahorro de batería de Android.
- Tocar una notificación transporta al usuario directamente al diálogo de opciones del alimento específico mediante el payload `itemId`.

