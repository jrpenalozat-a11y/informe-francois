# Informe François

**https://informe-francois.vercel.app**

PWA de un solo `index.html` (sin build, sin backend) para **anotar lo que pasa en el turno** y salir con el **prompt maestro de bitácora** ya armado, listo para pegar en Claude.

## Instalarla en el teléfono

Abre la URL y toca el botón **📲** (arriba a la derecha, o en la pestaña *Datos* → «Instalar en el teléfono»). La ficha muestra los pasos de tu propio dispositivo:

- **Android (Chrome):** normalmente ofrece *Instalar ahora* de una vez; si no, menú ⋮ → *Instalar aplicación*.
- **iPhone (Safari):** *Compartir* → *Agregar a inicio*. Si estás en Chrome iOS te avisa que abras en Safari y te copia la dirección.
- **Computador:** te deja copiar o compartir el enlace para abrirlo en el teléfono (y el navegador también puede instalarla ahí).

Queda con ícono propio, a pantalla completa y **funciona sin señal** (service worker). Las notas viven en ese teléfono: si instalas la app en dos aparatos, cada uno tiene las suyas.

## Qué hace

1. **📝 Notas** — agregas la nota al paso: fecha, hora, área (Sala · Cocina · Caja · Personal · Proveedores · Equipos · Producto · Otro), **qué pasó** y, opcional, la **medida tomada en el momento**. Se pueden editar y borrar; se agrupan por día. `Ctrl + Enter` guarda rápido.

   La medida viaja al prompt en la misma línea, después de `→ MEDIDA:`, y la regla 9 le dice a Claude que eso ya está hecho: lo reporta en pasado dentro del mismo punto, no lo repite como pendiente, y si la medida cierra el tema lo trata como resuelto (si solo lo parcha, lo dice y deja el pendiente de fondo).
2. **📄 Generar** — eliges modo y período y la app arma el prompt completo:
   - **DIARIO** → resumen del día para el grupo (elige un día).
   - **SEMANAL** → resumen de la semana para el grupo (desde/hasta, con atajos «esta semana» / «semana pasada»).
   - **CIERRE** → informe para la reunión del lunes; aparece el campo opcional **Pendientes de la reunión pasada**, que se cruza con las notas del período.

   Las notas del período se insertan en el bloque `NOTAS DEL PERÍODO` con el formato acordado:
   `[lun 18-08 · 14:20] (Caja) diferencia de 3.400 en el arqueo → MEDIDA: se hizo arqueo ciego de nuevo`, en orden cronológico.

   Botones: **Copiar prompt**, **Copiar solo las notas**, **Descargar .txt**, y una fila para
   **abrir el chat con el prompt ya copiado**: 🤖 Claude · ✨ Gemini · 🐋 DeepSeek. Solo Claude
   admite recibir el texto por enlace (`claude.ai/new?q=…`) y la app lo usa cuando el prompt no
   pasa de 4.000 caracteres; sobre eso, y siempre en Gemini y DeepSeek, el prompt queda copiado y
   basta con pegarlo. La casilla *«Incluir las reglas de los tres modos»* pega el prompt maestro completo; por defecto va solo el bloque del modo elegido (más corto y más preciso).
3. **Informe de vuelta** (al pie de Generar) — pegas ahí el texto que devolvió Claude, **lo corriges y lo mandas**. Incluye:

   - **Vista «cómo llega al grupo»**: una burbuja tipo WhatsApp con las negritas y viñetas ya renderizadas, para revisar antes de enviar.
   - **Revisión de formato**: avisa si hay `**doble asterisco**`, encabezados con `#`, viñetas con guion, filas de tabla o un asterisco sin cerrar. **🧹 Arreglar formato** lo pasa todo a formato WhatsApp (`*negrita*`, `• viñeta`), y al enviar, si queda algo, pregunta si lo arregla primero.
   - **Barra de redacción**: `*N*` pone en negrita lo que marques, `*TÍTULO*` convierte la línea en encabezado, `•` le pone viñeta, `⛶` agranda el cuadro.
   - **Borrador automático**: lo que estés escribiendo se guarda (`if_borrador_v1`) y vuelve si cierras la app.

   **Al pegar deja solo el informe**: si viene dentro de ``` ``` usa el bloque, y si trae texto antes o comentarios después, los recorta (empieza en `*Bitácora François*` o en `RESUMEN DE LA SEMANA`; en modo CIERRE no toca la cola porque termina en prosa). El botón **✂️ Dejar solo el informe** repite esa limpieza a mano. Lo que se envía es exactamente lo que quede en el cuadro: el prompt y las notas nunca salen. Botones: **📲 Enviar por WhatsApp** (abre el chat con el informe escrito; sin número WhatsApp te deja elegir el grupo, con número —`56` + celular, sin `+`— va directo), **Copiar**, **Guardar**. Al enviar se guarda solo, sin duplicar. Si el texto pasa de 1.800 caracteres avisa que WhatsApp puede cortarlo y lo deja copiado.
4. **📤 Informes** — los informes guardados con su modo, período y fecha; desde cada uno: WhatsApp, copiar, descargar `.txt` o borrar.
5. **⚙️ Datos** — exportar / importar JSON de respaldo (notas + informes), glosario interno (86, 101, arqueo ciego) y borrado.

El texto del período (`lun 17-08`, `17-08 al 23-08`) se calcula solo, pero es editable a mano.

## Dónde se guarda

Todo en el navegador del dispositivo:

- `if_notas_v1` — las notas.
- `if_informes_v1` — los informes que pegaste de vuelta.
- `if_borrador_v1` — el informe que estás redactando (borrador).
- `if_prefs_v1` — modo claro/oscuro y número de WhatsApp.

No hay servidor ni cuenta: si cambias de teléfono, usa **Exportar JSON** e **Importar JSON**. La importación no duplica (compara por `id`).

## Archivos

- `index.html` — toda la app (datos, estilos, lógica).
- `sw.js` — service worker. Constante `CACHE` (hoy `if-v8`): **súbela** al cambiar assets del núcleo. HTML network-first, el resto cache-first.
- `manifest.json`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`, `icon-maskable-512.png`, `icon.svg` — PWA instalable.
- `skill/SKILL.md` — copia versionada de la skill `bitacora-francois`.
- `vercel.json` / `netlify.toml` — deploy estático sin build; `/sw.js` se sirve con `Cache-Control: no-cache`.

## Correr en local

Servidor estático en la raíz, puerto 5189 (config `informe-francois-dev` en `.claude/launch.json`):

```bash
npx serve . -l 5189
```

⚠️ El navegador puede cachear `index.html`: al verificar cambios usa recarga forzada o `?v=<timestamp>`.

## La skill de Claude

El mismo prompt vive también como **skill** (`bitacora-francois`), instalada en
`~/.claude/skills/bitacora-francois/SKILL.md`. La copia versionada de este repo está en
[`skill/SKILL.md`](skill/SKILL.md): si la editas aquí, cópiala a `~/.claude/skills/` para que
tome efecto.

Con la skill instalada no hace falta pegar el prompt: basta con pegar las notas (o escribir
`/bitacora-francois`) y Claude redacta el informe con las mismas reglas y los mismos tres modos.
El botón **Copiar prompt** de la app sigue siendo útil para pegarlo donde no esté la skill
—claude.ai, otro computador, el teléfono—.

## Deploy

- Repo: https://github.com/jrpenalozat-a11y/informe-francois (rama `master`).
- Producción: https://informe-francois.vercel.app — proyecto Vercel `informe-francois`, **conectado al repo**: cada `git push` a `master` redespliega solo. Sin build, sin variables de entorno.
- Deploy manual, si hiciera falta: `npx vercel --prod --yes` desde la carpeta.

No lleva claves ni datos: las notas nunca salen del dispositivo.
