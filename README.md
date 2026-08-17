# Informe François

PWA de un solo `index.html` (sin build, sin backend) para **anotar lo que pasa en el turno** y salir con el **prompt maestro de bitácora** ya armado, listo para pegar en Claude.

## Qué hace

1. **📝 Notas** — agregas la nota al paso: fecha, hora, área (Sala · Cocina · Caja · Personal · Proveedores · Equipos · Producto · Otro) y el texto tal como lo anotaste. Se pueden editar y borrar; se agrupan por día. `Ctrl + Enter` guarda rápido.
2. **📄 Generar** — eliges modo y período y la app arma el prompt completo:
   - **DIARIO** → resumen del día para el grupo (elige un día).
   - **SEMANAL** → resumen de la semana para el grupo (desde/hasta, con atajos «esta semana» / «semana pasada»).
   - **CIERRE** → informe para la reunión del lunes; aparece el campo opcional **Pendientes de la reunión pasada**, que se cruza con las notas del período.

   Las notas del período se insertan en el bloque `NOTAS DEL PERÍODO` con el formato acordado:
   `[lun 18-08 · 14:20] (Caja) diferencia de 3.400 en el arqueo`, en orden cronológico.

   Botones: **Copiar prompt**, **Copiar solo las notas**, **Descargar .txt**. La casilla *«Incluir las reglas de los tres modos»* pega el prompt maestro completo; por defecto va solo el bloque del modo elegido (más corto y más preciso).
3. **⚙️ Datos** — exportar / importar JSON de respaldo, glosario interno (86, 101, arqueo ciego) y borrado total.

El texto del período (`lun 17-08`, `17-08 al 23-08`) se calcula solo, pero es editable a mano.

## Dónde se guarda

Todo en el navegador del dispositivo:

- `if_notas_v1` — las notas.
- `if_prefs_v1` — modo claro/oscuro.

No hay servidor ni cuenta: si cambias de teléfono, usa **Exportar JSON** e **Importar JSON**. La importación no duplica (compara por `id`).

## Archivos

- `index.html` — toda la app (datos, estilos, lógica).
- `sw.js` — service worker. Constante `CACHE = "if-v1"`: **súbela** al cambiar assets del núcleo. HTML network-first, el resto cache-first.
- `manifest.json`, `icon.svg`, `icon-maskable.svg` — PWA instalable.
- `vercel.json` / `netlify.toml` — deploy estático sin build; `/sw.js` se sirve con `Cache-Control: no-cache`.

## Correr en local

Servidor estático en la raíz, puerto 5189 (config `informe-francois-dev` en `.claude/launch.json`):

```bash
npx serve . -l 5189
```

⚠️ El navegador puede cachear `index.html`: al verificar cambios usa recarga forzada o `?v=<timestamp>`.

## Deploy

Es estático: subir la carpeta a Vercel o Netlify sin comando de build. No lleva claves ni datos: las notas nunca salen del dispositivo.
