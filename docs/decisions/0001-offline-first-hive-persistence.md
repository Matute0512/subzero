# ADR-001: Persistencia Local 100% Offline-First con Hive NoSQL

## Estado
Aceptado

## Fecha
2026-10-20

## Contexto
SubZero es una aplicación de gestión de inventario para congeladores y despensas. Los usuarios suelen utilizar la aplicación en entornos donde la conectividad puede ser débil o nula (ej. sótanos, despensas subterráneas, garajes) y esperan:
1. Arranque inmediato sin pantallas de login ni esperas de sincronización en la nube.
2. Latencia prácticamente nula al consultar, filtrar o registrar alimentos.
3. Máxima privacidad: los hábitos alimenticios y el inventario del hogar no deben viajar por internet.
4. Portabilidad y mínimo peso en el binario final de la app.

## Decisión
Utilizar **Hive** (`hive` y `hive_flutter`) con adaptadores binarios tipados (`TypeAdapter`) generados mediante `build_runner`.
Los datos se organizan en dos cajas independientes:
- `frozen_items_box`: Almacena instancias de `FrozenItemModel` con identificador único String UUID como clave.
- `monetization_box`: Almacena banderas de configuración local del usuario, como el estado de suscripción `is_pro_user`.

## Alternativas Consideradas

### SQLite / Drift (Moor)
- **Pros:** Consultas relacionales SQL nativas, soporte ACID estricto.
- **Contras:** Requiere compilación de bibliotecas nativas C (`sqlite3`), mayor huella de tamaño en el APK/AAB, esquemas de migración rígidos para una estructura documental sencilla de inventario.
- **Rechazado:** La sobrecarga de configuración relacional no aporta beneficios tangibles frente a colecciones de objetos que caben enteramente en memoria y se filtran velozmente en Dart.

### SharedPreferences / flutter_secure_storage
- **Pros:** Estándar de la plataforma móvil para pares clave-valor.
- **Contras:** No apto para colecciones estructuradas de tamaño dinámico; serializar toda la lista de alimentos en JSON dentro de un string de SharedPreferences degrada el rendimiento de I/O en cada guardado.
- **Rechazado:** Ineficiente para un inventario dinámico con decenas de registros.

### Firebase Firestore / Cloud Database
- **Pros:** Sincronización automática entre múltiples dispositivos.
- **Contras:** Requiere registro obligatorio de usuario, costos recurrentes de infraestructura backend, dependencia de conectividad, posibles penalizaciones de privacidad bajo GDPR/CCPA.
- **Rechazado:** Viola el principio fundamental del producto: experiencia 100% privada, anónima y offline-first.

## Consecuencias
- La inicialización de la base de datos se realiza en milisegundos durante `main()`.
- Lecturas y escrituras atómicas en memoria con persistencia en disco en formato binario ultracompacto.
- Se debe regenerar el código de adaptadores (`build_runner`) siempre que el modelo DTO sufra variaciones en sus campos anotados con `@HiveField`.
- Toda la responsabilidad de respaldo y retención de datos recae localmente en el dispositivo.

