# SubZero UI Kit - Figma Plugin

Este plugin genera programáticamente las 3 pantallas principales y los Design Tokens de **SubZero: Inventario Congelador** directamente en Figma con especificación Material 3 & iOS HIG.

---

## 🚀 Cómo ejecutar en Figma en 20 segundos

### Opción A: Mediante Figma Plugins (Recomendado)
1. Abre tu archivo de Figma (o crea uno nuevo en blanco).
2. Haz clic en el menú principal de Figma (`☰`) -> **Plugins** -> **Development** -> **Import plugin from manifest...**.
3. Selecciona el archivo `manifest.json` ubicado en esta carpeta (`design/figma_plugin/manifest.json`).
4. Ejecuta el plugin: **Plugins** -> **Development** -> **SubZero Design Generator**.
5. ¡Listo! Las 3 pantallas (`home_inventory_screen`, `add_item_bottom_sheet`, `paywall_screen`) se dibujarán automáticamente en tu canvas con Auto-Layout y separadas por 40px.

### Opción B: Copiar y pegar en la Consola de Figma (Web o Desktop)
1. Abre tu archivo de Figma en el navegador o en la app de escritorio.
2. Abre la consola de desarrollo de Figma:
   - **En Figma Web**: Presiona `F12` (o `Cmd + Option + I` en macOS) y ve a la pestaña **Console**.
   - **En Figma Desktop**: Menú `☰` -> **Help and account** -> **Open Console**.
3. Abre el archivo `code.js`, copia todo su contenido y pégalo en la consola.
4. Presiona `Enter`.

