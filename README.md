# Informe François

**https://informe-francois.vercel.app**

PWA de un solo `index.html` (sin build, sin backend) para **anotar lo que pasa en el turno** y salir con el **prompt maestro de bitácora** ya armado, listo para pegar en Claude.

## Instalarla en el teléfono

Abre la URL y toca el botón **📲** (arriba a la derecha, o en la pestaña *Datos* → «Instalar en el teléfono»). La ficha muestra los pasos de tu propio dispositivo:

- **Android (Chrome):** normalmente ofrece *Instalar ahora* de una vez; si no, menú ⋮ → *Instalar aplicación*.
- **iPhone (Safari):** *Compartir* → *Agregar a inicio*. Si estás en Chrome iOS te avisa que abras en Safari y te copia la dirección.
- **Computador:** te deja copiar o compartir el enlace para abrirlo en el teléfono (y el navegador también puede instalarla ahí).

Queda con ícono propio, a pantalla completa y **funciona sin señal** (service worker). Las notas viven en ese aparato; para que el teléfono y el computador muestren lo mismo, entra con tu cuenta en los dos (ver **[Sincronía](#sincronía-entre-el-teléfono-y-el-computador)**).

## Qué hace

1. **📝 Notas** — agregas la nota al paso: fecha, hora, área (Sala · Cocina · Caja · Personal · Proveedores · Equipos · Producto · Otro), **qué pasó** y, opcional, la **medida tomada en el momento**. Se pueden editar y borrar; se agrupan por día. `Ctrl + Enter` guarda rápido.

   **✍️ Quién anota** — si dos personas comparten la cuenta, cada una pone su nombre una vez en
   ⚙️ Datos → *Quién anota*. La firma se pone **al crear** la nota y no se toca más: editar una nota
   ajena —o una vieja sin firma— no te convierte en su autor. Se ve en la lista y viaja al prompt
   como `— anotó Ángel`. Es una **etiqueta, no una credencial**: quien tenga el aparato puede
   escribir cualquier nombre ahí, así que sirve para organizarse, no para acreditar nada. La regla 11
   le dice a Claude que esa persona es quien **registró** la nota, no la responsable del hecho: que
   la use solo cuando aporte —notas del mismo tema que se contradicen, o a quién preguntarle en el
   CIERRE—. Vive en la columna `quien` de `if_notas`; si el proyecto todavía no la tiene, la app
   sube las notas sin firma y lo avisa en ⚙️ Datos en vez de caerse.

   La medida viaja al prompt en la misma línea, después de `→ MEDIDA:`, y la regla 9 le dice a Claude que eso ya está hecho: lo reporta en pasado dentro del mismo punto, no lo repite como pendiente, y si la medida cierra el tema lo trata como resuelto (si solo lo parcha, lo dice y deja el pendiente de fondo).

   **📷 Fotos** — la nota tiene **dos juegos de fotos**: las de **Foto del hecho**, bajo «Qué pasó», respaldan lo que ocurrió; las de **Foto de la medida**, bajo «Medida tomada en el momento», respaldan lo que se hizo. Cada botón abre la cámara del teléfono y su **Galería** toma una ya sacada (varias a la vez). Se comprimen a 1600 px / JPEG antes de guardarlas (una foto de teléfono queda en ~100-250 KB), aparecen como miniaturas en el formulario y en la nota, y se abren en el visor: pasar entre fotos, **Compartir** (mandarla por WhatsApp desde el teléfono), **Guardar** en el dispositivo o **Borrar**. Si aprietas «Agregar nota» mientras la foto se está guardando, la nota se guarda sola apenas termina.

   Al prompt solo va la marca `[con foto]` / `[con N fotos]`, **pegada a lo que respalda**: después del hecho si la foto es del hecho, y después de `→ MEDIDA:` si es de la medida. **La imagen no viaja al chat**. La regla 10 le dice a Claude que no describa ni suponga lo que muestra, y que como mucho cierre ese punto con «(hay foto)».
2. **📄 Generar** — eliges modo y período y la app arma el prompt completo:
   - **DIARIO** → resumen del día para el grupo (elige un día).
   - **SEMANAL** → resumen de la semana para el grupo (desde/hasta, con atajos «esta semana» / «semana pasada»).
   - **CIERRE** → informe para la reunión del lunes; aparece el campo opcional **Pendientes de la reunión pasada**, que se cruza con las notas del período.

   Las notas del período se insertan en el bloque `NOTAS DEL PERÍODO` con el formato acordado:
   `[lun 18-08 · 14:20] (Caja) diferencia de 3.400 en el arqueo [con foto] → MEDIDA: se hizo arqueo ciego de nuevo [con foto]`, en orden cronológico.

   Botones: **Copiar prompt**, **Copiar solo las notas**, **Descargar .txt**, y una fila para
   **abrir el chat con el prompt ya copiado**: 🤖 Claude · ✨ Gemini · 🐋 DeepSeek · 🪟 Copilot. Solo Claude
   admite recibir el texto por enlace (`claude.ai/new?q=…`) y la app lo usa cuando el prompt no
   pasa de 4.000 caracteres; sobre eso, y siempre en Gemini, DeepSeek y Copilot, el prompt queda copiado y
   basta con pegarlo. La casilla *«Incluir las reglas de los tres modos»* pega el prompt maestro completo; por defecto va solo el bloque del modo elegido (más corto y más preciso).
3. **Informe de vuelta** (al pie de Generar) — pegas ahí el texto que devolvió Claude, **lo corriges y lo mandas**. Incluye:

   - **Vista «cómo llega al grupo»**: una burbuja tipo WhatsApp con las negritas y viñetas ya renderizadas, para revisar antes de enviar.
   - **Revisión de formato**: avisa si hay `**doble asterisco**`, encabezados con `#`, viñetas con guion, filas de tabla o un asterisco sin cerrar. **🧹 Arreglar formato** lo pasa todo a formato WhatsApp (`*negrita*`, `• viñeta`), y al enviar, si queda algo, pregunta si lo arregla primero.
   - **Barra de redacción**: `*N*` pone en negrita lo que marques, `*TÍTULO*` convierte la línea en encabezado, `•` le pone viñeta, `⛶` agranda el cuadro.
   - **Borrador automático**: lo que estés escribiendo se guarda (`if_borrador_v1`) y vuelve si cierras la app.
   - **📎 Fotos del período**: bajo la vista de WhatsApp aparece la tira con las fotos de las notas del período. Tócalas para incluirlas o dejarlas fuera (🔍 las abre grandes) y **📎 Enviar fotos** las manda con el compartir nativo del teléfono, para elegir el mismo grupo justo después del informe — el enlace `wa.me` solo lleva texto, por eso van aparte. Al enviar el informe, un aviso recuerda mandarlas. En el PC, que no comparte archivos, ofrece descargarlas.
   - **🖨️ PDF**: arma una hoja con el título (modo + período) y el informe ya formateado, con **cada foto justo bajo el punto que la menciona** (no todas juntas al final). Como el informe lo redacta la IA con sus propias palabras, la app empareja cada foto con la línea que más se le parece: palabras en común, el «(hay foto)» de la regla 10 y el título del bloque (SALA, CAJA…). Las del hecho buscan la línea del hecho y las de la medida, la de la medida — si el informe junta las dos cosas en un punto, quedan las dos ahí (primero el hecho); si las separa (por ejemplo el hecho en CAJA y la medida en RESUELTOS), cada una va donde corresponde, y las de la medida llevan «respalda la medida» en el pie. Las que no calzan con ninguna línea caen en **«Otras fotos»** al final, con su día · hora · área y el texto de la nota — así ninguna se pierde. Se abre el diálogo de imprimir: en el teléfono, «Guardar como PDF». Ese archivo sí se adjunta al grupo o se lleva a la reunión.

   **Al pegar deja solo el informe**: si viene dentro de ``` ``` usa el bloque, y si trae texto antes o comentarios después, los recorta (empieza en `*Bitácora François*` o en `RESUMEN DE LA SEMANA`; en modo CIERRE no toca la cola porque termina en prosa). El botón **✂️ Dejar solo el informe** repite esa limpieza a mano. Lo que se envía es exactamente lo que quede en el cuadro: el prompt y las notas nunca salen. Botones: **📲 Enviar por WhatsApp** (abre el chat con el informe escrito; sin número WhatsApp te deja elegir el grupo, con número —`56` + celular, sin `+`— va directo), **Copiar**, **Guardar**. Al enviar se guarda solo, sin duplicar. Si el texto pasa de 1.800 caracteres avisa que WhatsApp puede cortarlo y lo deja copiado.
4. **📤 Informes** — los informes guardados con su modo, período y fecha; desde cada uno: WhatsApp, copiar, descargar `.txt` o borrar.
5. **⚙️ Datos** — **cuenta y sincronía** (ver más abajo), exportar / importar JSON de respaldo (notas + informes y, si marcas la casilla, **las fotos**), glosario interno (86, 101, arqueo ciego) y borrado (notas, informes o solo las fotos).

El texto del período (`lun 17-08`, `17-08 al 23-08`) se calcula solo, pero es editable a mano.

## Dónde se guarda

Todo en el navegador del dispositivo:

- `if_notas_v1` — las notas.
- `if_informes_v1` — los informes que pegaste de vuelta.
- `if_borrador_v1` — el informe que estás redactando (borrador).
- `if_prefs_v1` — modo claro/oscuro y número de WhatsApp.

Las **fotos** no caben en `localStorage`, así que van en IndexedDB (base `if_fotos_v1`): el almacén `fotos` guarda la imagen comprimida y `thumbs` la miniatura y el peso; la nota solo lleva los `id` de sus fotos, en dos listas: `fotos` (respaldan el hecho) y `fotosm` (respaldan la medida). Las fotos que quedaron sin nota (la app se cerró antes de guardarla) se limpian solas al abrir.

Sin cuenta, la app funciona igual pero cada aparato tiene lo suyo: para mover las notas a mano usa **Exportar JSON** e **Importar JSON**. La importación no duplica (compara por `id`). El respaldo incluye las fotos en base64 si dejas marcada la casilla — pesa bastante más, así que para mover solo el texto, desmárcala.

## Sincronía entre el teléfono y el computador

Opcional: si entras con tu correo en ⚙️ Datos, las notas, los informes y las fotos suben a
**Supabase** y los dos aparatos muestran lo mismo. El dispositivo sigue mandando —todo se guarda
primero en local y sin señal se anota igual—; la nube es solo la copia común.

- **Proyecto:** el mismo de François (`zmpiqkbvmjvfvxyvcdhi`), compartido con el *Checklist de Turno*.
  Tablas propias con prefijo `if_`, así que no se pisan. La llave pública va en el `index.html`:
  lo que protege los datos son las políticas RLS, que solo dejan ver las filas de tu `uid`.
- **Puesta en marcha (una vez):** correr [`supabase.sql`](supabase.sql) en el SQL Editor y crear el
  usuario en *Authentication → Users → Add user* con **Auto Confirm** marcado.
- **Cómo resuelve los choques:** cada nota e informe llevan `act` (cuándo se tocaron) y gana la
  versión más nueva. Los borrados quedan anotados en `if_borrados_v1` y se suben como
  `borrada = true`, para que la nube no los reviva en el otro aparato.
- **Fotos:** bucket privado `if-fotos`, una carpeta por cuenta (`<uid>/<idFoto>.jpg`). En la tabla, la
  columna `fotos` lleva la lista de siempre cuando todas respaldan el hecho, y `{h:[…], m:[…]}`
  cuando además hay fotos de la medida — así no hubo que tocar el esquema y una versión vieja de la
  app sigue leyendo lo suyo. Suben las que
  el otro aparato no tiene y bajan las que faltan acá (la miniatura se rehace al bajarlas). Se puede
  apagar con la casilla *«Sincronizar también las fotos»*. Las fotos que ya no usa ninguna nota se
  borran de la nube.
- **Qué movió la última vez:** bajo el estado, en ⚙️ Datos, queda escrito el resumen del último
  viaje — *«subieron 12 notas · no bajó nada · en la nube hay 12 notas»* —, porque un «al día» a
  secas no distingue entre «no había nada que traer» y «no subió nada de lo mío». **📋 Copiar el
  detalle** copia ese resumen (y la falla, si la hubo) para mandarlo por WhatsApp.
- **Cuándo sincroniza:** al abrir la app, al volver a ella, al recuperar la señal, 2,5 s después de
  cualquier cambio y a mano con **🔄 Sincronizar ahora** o el botón ☁️ del encabezado.
- ⚠️ **No toques la configuración de Auth del proyecto** (por ejemplo, apagar los registros):
  el Checklist de Turno entra con **sesiones anónimas** y se quedaría afuera.

## Archivos

- `index.html` — toda la app (datos, estilos, lógica).
- `sw.js` — service worker. Constante `CACHE` (hoy `if-v17`): **súbela** al cambiar assets del núcleo. HTML network-first, el resto cache-first. Las llamadas a Supabase **no pasan por la caché** (si no, la app leería siempre la misma respuesta vieja).
- `supabase.sql` — tablas, políticas y bucket de la sincronía. Se corre una sola vez.
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

Sin variables de entorno: la URL y la llave pública de Supabase van en el `index.html` (es su diseño;
lo que protege los datos son las políticas RLS). Sin cuenta, las notas no salen del dispositivo.
