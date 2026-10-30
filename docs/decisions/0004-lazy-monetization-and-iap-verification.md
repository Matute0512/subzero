# ADR-004: Inicialización Asíncrona de Publicidad y Validación Criptográfica de Compras In-App

## Estado
Aceptado

## Fecha
2026-10-29

## Contexto
SubZero combina un modelo freemium basado en publicidad (Google AdMob) con una compra integrada de pago único (Google Play Billing - SubZero Pro).
Problemas detectados durante las pruebas de rendimiento y seguridad:
1. **Bloqueo del arranque inicial (Cold Start):** La invocación síncrona `MobileAds.instance.initialize()` en `main()` demoraba el dibujo del primer frame en dispositivos de gama media y baja, generando una pantalla negra o splash prolongado.
2. **Parpadeo visual ("Ad Flickering"):** Al arrancar la app, si el estado de monetización no se había resuelto aún, los banners publicitarios se renderizaban brevemente antes de que la app descubriera que el usuario era un cliente Pro, dando una pésima impresión de calidad.
3. **Consultas de red redundantes a Google Play Billing:** Al abrir o alternar pestañas del Paywall, cada consulta disparaba `queryProductDetails` hacia los servidores de Google, aumentando la latencia y el consumo de datos innecesariamente.
4. **Spoofing de compras en clientes modificados:** Eventos maliciosos o respuestas falsificadas en el `purchaseStream` podían otorgar estatus Pro si el payload de verificación estaba vacío o era inválido.

## Decisión
1. **Inicialización Asíncrona fuera del hilo de renderizado inicial:**
   - La llamada de `MobileAds.instance.initialize()` se desacopló del bloqueo de `main()`. Se ejecuta en segundo plano tras registrar los bloques del Service Locator, permitiendo que Flutter dibuje el primer frame de inmediato.
2. **Prevención de Parpadeo (`isProResolved`):**
   - El estado de monetización (`MonetizationState`) mantiene la bandera booleana `isProResolved`.
   - La interfaz gráfica oculta deliberadamente cualquier widget de banner publicitario hasta que el estado del usuario esté resuelto con certeza (`isProResolved == true && isPro == false`).
3. **Caché en Memoria de `ProductDetails`:**
   - `MonetizationRepositoryImpl` implementa un caché en memoria con variable privada `_cachedProductDetails`.
   - Una vez obtenidos con éxito los detalles del producto de Google Play (`subzero_pro_lifetime`), las consultas subsiguientes se sirven de forma instantánea sin latencia de red.
4. **Validación Criptográfica en Recepción de Transacciones:**
   - En `InAppPurchaseDataSourceImpl._handlePurchaseUpdates`, se añadió una verificación de seguridad que rechaza compras donde `serverVerificationData` y `localVerificationData` estén vacíos o contengan únicamente espacios en blanco antes de invocar `setProLocal(true)`.

## Alternativas Consideradas

### Inicializar AdMob obligatoriamente antes de `runApp()`
- **Pros:** Garantiza que los anuncios estén listos antes de cualquier widget.
- **Contras:** Penaliza el Time to Interactive (TTI) y la puntuación de rendimiento de Google Play Vitals en frío.
- **Rechazado:** La experiencia de usuario del inventario es la prioridad número uno.

### Validar compras únicamente mediante un servidor backend propio
- **Pros:** Validación 100% segura del token de compra contra la API de Google Play Developer en un servidor seguro.
- **Contras:** Obligaría a mantener infraestructura de servidores en la nube, bases de datos remotas y cuentas de usuario, quebrando la promesa central de arquitectura 100% offline-first de SubZero.
- **Rechazado:** Se adoptó una estrategia de defensa en profundidad en cliente: validación de datos de verificación nativos de Google Play, bloqueo de respaldo por ADB y ofuscación de código.

## Consecuencias
- Arranque de la app instantáneo y fluido.
- Transición limpia entre usuarios gratuitos y Pro sin parpadeos de anuncios.
- Consultas instantáneas de precios en el Paywall gracias a la caché en memoria.
- Protección contra falsificaciones básicas de eventos de compra en el flujo reactivo.

