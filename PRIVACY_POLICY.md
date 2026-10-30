# Política de Privacidad de SubZero

**Última actualización:** 29 de Octubre de 2026  
**Identificador de la aplicación:** `dev.matute.subzero`  
**Contacto de soporte:** `matiastorr.dev@gmail.com`  

---

## 1. Compromiso de Privacidad y Arquitectura 100% Offline-First

SubZero ha sido desarrollada bajo una filosofía estricta de privacidad local: **tus datos te pertenecen y nunca salen de tu dispositivo**.

- **Sin cuentas ni registros:** No requerimos registro de cuenta, inicio de sesión ni vinculación con redes sociales.
- **Sin datos personales directos:** No recopilamos tu nombre, correo electrónico, número telefónico ni ubicación GPS precisa para utilizar el inventario.
- **Almacenamiento exclusivo en el dispositivo:** Todos los alimentos, cantidades, unidades, categorías, fechas y notas de ubicación se guardan exclusivamente en el almacenamiento interno de tu dispositivo mediante bases de datos locales (`Hive`).
- **Sin servidores en la nube:** SubZero no cuenta con servidores centrales, bases de datos remotas ni servicios de sincronización en la nube propiedad del desarrollador.
- **Protección contra extracción de copias de seguridad:** La aplicación tiene desactivado el respaldo automático y por depuración (`android:allowBackup="false"` y `android:fullBackupContent="false"`), garantizando que tu base de datos local de alimentos no sea transmitida a servicios externos de respaldo sin tu conocimiento.

---

## 2. Publicidad con Google AdMob

La versión gratuita de SubZero integra el SDK oficial de **Google AdMob** (Google LLC) para mostrar anuncios patrocinados (banners inferiores, anuncios intersticiales y recompensados) con el fin de sostener el mantenimiento de la aplicación.

Google AdMob puede recopilar y procesar identificadores del dispositivo y datos técnicos conforme a las políticas de privacidad de Google, tales como:
- Identificador de Publicidad de Android (Google Advertising ID - AAID) o identificadores de proveedor en iOS (IDFV).
- Dirección IP aproximada (utilizada exclusivamente para geolocalización a nivel de país o región geográfica general).
- Diagnósticos de rendimiento, interacción del usuario con los anuncios e informes de fallos relacionados con la entrega publicitaria.

Puedes consultar los detalles de la Política de Privacidad de Google en: [https://policies.google.com/privacy](https://policies.google.com/privacy).

> **Versión Pro Libre de Anuncios:** Al adquirir la licencia **SubZero Pro**, el servicio de Google AdMob se desactiva permanentemente en la aplicación y no se muestra publicidad de ningún tipo.

---

## 3. Facturación y Compras Integradas (Google Play In-App Billing)

La adquisición de la licencia de por vida **SubZero Pro** (`subzero_pro_lifetime`) se procesa directamente a través de la pasarela de pagos oficial de **Google Play In-App Billing**.

- SubZero **no** tiene acceso, no procesa, no transmite ni almacena números de tarjeta de crédito, cuentas bancarias ni credenciales financieras.
- Todas las transacciones financieras y la validación de recibos de compra son gestionadas de forma segura y directa por Google LLC conforme a sus Términos de Servicio de Google Play.

---

## 4. Notificaciones y Alarmas Locales

SubZero programa recordatorios preventivos en el dispositivo para avisar antes del vencimiento de un alimento (7 días y 1 día antes).

- Estas alertas se programan y ejecutan íntegramente en el hardware local de tu teléfono a través del gestor de alarmas nativo del sistema operativo (`AlarmManager` / `NotificationManager` en Android).
- **Sin notificaciones push externas:** No se utilizan servidores push de terceros, servicios de mensajería en la nube ni conexión a internet para emitir las alertas de vencimiento.

---

## 5. Comunicaciones y Tráfico de Red

- SubZero tiene expresamente deshabilitado el tráfico HTTP en texto claro (`android:usesCleartextTraffic="false"`). Cualquier comunicación de red externa requerida por los servicios de Google (Google AdMob o Google Play Billing) se realiza obligatoriamente mediante canales cifrados y autenticados (HTTPS / TLS).

---

## 6. Control, Retención y Eliminación Definitiva de Datos

Usted mantiene control total y absoluto sobre sus registros:
- **Modificación y eliminación individual:** Puede editar o borrar cualquier alimento de su inventario en cualquier momento desde la pantalla principal.
- **Borrado total de datos:** Puede eliminar la totalidad de los datos almacenados desde los ajustes del sistema operativo:  
  *Ajustes > Aplicaciones > SubZero > Almacenamiento > Borrar datos*.
- **Desinstalación:** Al desinstalar la aplicación del dispositivo, todos los archivos de base de datos locales y preferencias se eliminan de forma inmediata, definitiva e irrecuperable.

---

## 7. Privacidad de Menores

SubZero está orientada al público general para la organización de alimentos en el hogar y no recopila de forma deliberada datos personales ni identificables de menores de 13 años.

---

## 8. Contacto y Consultas

Si tienes preguntas sobre esta Política de Privacidad, el tratamiento de datos o requieres asistencia técnica, puedes contactar al desarrollador:
- **Correo Electrónico:** `matiastorr.dev@gmail.com`
- **Ubicación:** Buenos Aires, Argentina
- **Sitio Web Oficial / Documentación:** [https://matiastorr.github.io/subzero/](https://matiastorr.github.io/subzero/)
