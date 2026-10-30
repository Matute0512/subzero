# ADR-005: Blindaje de Seguridad, Mitigación de Superficie de Ataque y Ofuscación de Release

## Estado
Aceptado

## Fecha
2026-10-29

## Contexto
SubZero se distribuye como aplicación comercial en Google Play Store y gestiona compras integradas y monetización.
La superficie de ataque expone riesgos de:
1. **Extracción y manipulación de datos locales sin root:** Mediante el comando de depuración `adb backup dev.matute.subzero`, un usuario con acceso físico o un script podría extraer los archivos binarios de Hive (`monetization_box.hive`), alterar `is_pro_user: true` y restaurar la base de datos sin haber realizado la compra en Play Store.
2. **Fugas de información en logs del sistema:** `AppLogger` registraba trazas de depuración e información de estado que quedaban expuestas en el buffer general de `logcat` en compilaciones de producción.
3. **Denegación de servicio local (DoS) o corrupción de memoria en Hive:** Usuarios o scripts que envíen cadenas de caracteres arbitrariamente grandes o números exorbitantes a través de los casos de uso de adición o edición de alimentos podrían sobrecargar la memoria o corromper el árbol binario de Hive.
4. **Ingeniería inversa de código binario:** Los binarios AAB de Flutter por defecto conservan nombres de clases, métodos y rutas de librerías Dart, facilitando el análisis con desensambladores o herramientas de desofuscación.
5. **Tráfico en texto claro (Cleartext HTTP):** Riesgo de interceptación de tráfico no cifrado en redes públicas.

## Decisión
Implementar un endurecimiento multidimensional (*defense-in-depth*):
1. **Android Manifest Hardening:**
   - `android:allowBackup="false"`: Impide la extracción y modificación de las cajas de Hive a través de ADB Backup.
   - `android:fullBackupContent="false"`: Deshabilita el respaldo automático no cifrado de Android en la nube.
   - `android:usesCleartextTraffic="false"`: Prohíbe cualquier comunicación HTTP no cifrada a nivel de sistema operativo.
2. **Supresión Automática de Logs de Diagnóstico en Release:**
   - En `lib/core/utils/logger.dart`, `AppLogger.debug` y `AppLogger.info` validan si `kReleaseMode` está activo; si es así, retornan inmediatamente sin emitir información al buffer nativo de Android/iOS.
3. **Validación de Límites en Capa de Dominio (Boundary Validation):**
   - En `AddFrozenItemUseCase` y `UpdateFrozenItemUseCase`, se aplican reglas de validación antes de delegar a la capa de datos:
     - Nombre: `1..100` caracteres (no vacío ni espacios en blanco).
     - Cantidad: `0.001..999999.0` (positiva, no nula ni desbordante).
     - Unidad: `1..30` caracteres.
     - Notas de ubicación: máximo 300 caracteres.
   - Si no se cumplen, retorna un `Left(ValidationFailure)`.
4. **Ofuscación y División de Símbolos en Scripts de Release:**
   - En `scripts/build_release.ps1` y `scripts/build_release.bat`, se agregaron las banderas oficiales de Flutter:
     `--obfuscate --split-debug-info=build/app/outputs/symbols`.
   - Se excluyeron del control de versiones (`.gitignore`) los archivos `.symbols` generados.
5. **Aislamiento de Secretos de Producción:**
   - `secrets.json` permanece estrictamente fuera del repositorio Git mediante regla en `.gitignore`, inyectándose en tiempo de compilación mediante `--dart-define-from-file=secrets.json`.

## Alternativas Consideradas

### Cifrado AES completo de la base de datos de Hive con clave derivada
- **Pros:** Cifrado a nivel de bloque en disco.
- **Contras:** En una app 100% offline sin autenticación de usuario ni servidor backend, la clave criptográfica maestra debe residir en el dispositivo (ej. en Keystore/Keyring). Si bien añade una capa de complejidad al atacante, la desactivación de `allowBackup` ya previene el acceso físico por ADB en dispositivos estándar de forma nativa en el SO sin penalizaciones de CPU en la lectura de listas de alimentos.
- **Decisión:** Desactivar `allowBackup` ofrece la mejor relación seguridad/rendimiento para esta etapa.

### Omitir ofuscación para facilitar el análisis de caídas
- **Pros:** Stacktraces legibles directamente en la consola sin mapeo de símbolos.
- **Contras:** Expone la estructura completa del código fuente, nombres de use cases y lógica de monetización a atacantes.
- **Rechazado:** El archivo de símbolos generado en `build/app/outputs/symbols` permite desofuscar stacktraces en Google Play Console conservando el binario completamente ofuscado para terceros.

## Consecuencias
- Cero fugas de información diagnóstica o claves privadas en compilaciones de producción.
- Protección efectiva contra la manipulación de compras por extracción de copias de seguridad de Android.
- Protección del código propietario de la aplicación ante ingeniería inversa.
- Cobertura completa de pruebas unitarias sobre los límites de validación de dominio.

